// -----------------------------------------------------------
// app/core/services/breakage_service.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oxdata/app/core/models/breakage_model.dart';
import 'package:oxdata/app/core/models/ftp_image_request.dart';
import 'package:oxdata/app/core/models/ftp_image_response.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/repositories/breakage_repository.dart';
import 'package:oxdata/app/core/repositories/ftp_repository.dart';
import 'package:oxdata/app/core/repositories/product_repository.dart';

/// Service responsável por expor os registros de quebra para a UI,
/// consumindo o BreakageRepository (BreakageController da API),
/// o FtpRepository (upload da foto) e o ProductRepository (nome do produto).
class BreakageService with ChangeNotifier {
  final BreakageRepository _breakageRepository;
  final FtpRepository _ftpRepository;
  final ProductRepository _productRepository;

  BreakageService({
    required BreakageRepository breakageRepository,
    required FtpRepository ftpRepository,
    required ProductRepository productRepository,
  })  : _breakageRepository = breakageRepository,
        _ftpRepository = ftpRepository,
        _productRepository = productRepository;

  /// Pasta no FTP onde as fotos das quebras são gravadas.
  static const String _ftpFolder    = 'QUEBRAS/';
  static const String _baseImageUrl = 'https://oxfordtec.com.br/Imagens/';

  List<BreakageModel> _breakages = [];
  List<BreakageModel> get breakages => _breakages;

  /// Cache de nomes de produto (productId -> nome).
  final Map<String, String> _productNames = {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<BreakageModel> byStatus(String status) =>
      _breakages.where((b) => b.status == status).toList();

  /// Registros já revisados (APROVADO ou REJEITADO) que aguardam baixa no estoque.
  List<BreakageModel> get notWrittenOff => _breakages
      .where((b) => b.status == BreakageStatus.aprovado || b.status == BreakageStatus.rejeitado)
      .toList();

  /// Nome do produto, quando já resolvido; caso contrário o próprio código.
  String productName(String productId) => _productNames[productId] ?? productId;

  /// Registra o nome de um produto já conhecido (ex.: selecionado na busca).
  void cacheProductName(String productId, String name) {
    _productNames[productId] = name;
  }

  /// Cache das fotos baixadas do FTP (photoUrl -> bytes).
  final Map<String, Uint8List> _photos = {};
  final Set<String> _loadingPhotos = {};

  Uint8List? photo(String photoUrl) => _photos[photoUrl];
  bool isPhotoLoading(String photoUrl) => _loadingPhotos.contains(photoUrl);

  /// Caminho relativo no FTP (ex.: QUEBRAS/002687/05112026_1426_001.jpg).
  String _ftpPath(String photoUrl) =>
      photoUrl.startsWith(_baseImageUrl) ? photoUrl.substring(_baseImageUrl.length) : photoUrl;

  /// Baixa (via API de FTP, em Base64) as fotos dos registros ainda não presentes no cache.
  Future<void> fetchPhotos(List<BreakageModel> breakages) async {
    final pending = breakages
        .map((b) => b.photoUrl)
        .where((url) => url.isNotEmpty && !_photos.containsKey(url) && !_loadingPhotos.contains(url))
        .toSet()
        .toList();
    if (pending.isEmpty) return;

    _loadingPhotos.addAll(pending);
    notifyListeners();

    final paths = pending.map(_ftpPath).toList();
    final response = await _ftpRepository.getImagesBase64(FtpImageRequest(imageUrls: paths));

    if (response.success && response.data != null) {
      for (var i = 0; i < response.data!.length; i++) {
        final img = response.data![i];
        if (!img.isSuccessful || (img.base64Content ?? '').isEmpty) continue;

        // Associa pelo caminho retornado; se não vier, pela ordem da requisição.
        final index = paths.indexWhere((p) => img.url.isNotEmpty && (img.url == p || img.url.endsWith(p)));
        final url = index >= 0 ? pending[index] : (i < pending.length ? pending[i] : null);
        if (url == null) continue;

        try {
          _photos[url] = base64Decode(img.base64Content!);
        } catch (_) {}
      }
    }

    _loadingPhotos.removeAll(pending);
    notifyListeners();
  }

  /// Busca todos os registros de quebra.
  Future<void> fetchBreakages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _breakageRepository.getAll();

    if (response.success && response.data != null) {
      _breakages = List<BreakageModel>.from(response.data!)
        ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      await _resolveProductNames();
      // Miniaturas das listas (aprovação e histórico), carregadas em segundo plano.
      fetchPhotos(_breakages);
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Envia a foto para o FTP e cria um novo registro de quebra (status PENDENTE).
  Future<ApiResponse<bool>> registerBreakage({
    required String productId,
    required int quantity,
    required String reason,
    required Uint8List photoBytes,
    required String createdBy,
  }) async {
    // QUEBRAS/[codigo_do_produto]/[DDMMAAAA_HHMM]_001.jpg
    final fileName = '$_ftpFolder$productId/${DateFormat('ddMMyyyy_HHmm').format(DateTime.now())}_001.jpg';

    final upload = await _ftpRepository.setImagesBase64([
      FtpImageResponse(url: fileName, base64Content: base64Encode(photoBytes)),
    ]);

    final uploaded = upload.success &&
        upload.data != null &&
        upload.data!.isNotEmpty &&
        upload.data!.every((r) => r.isSuccessful);

    if (!uploaded) {
      return ApiResponse(
        success: false,
        message: 'Falha ao enviar a foto: ${upload.message ?? ''}',
      );
    }

    final response = await _breakageRepository.save(BreakageModel(
      productId: productId,
      quantity: quantity,
      reason: reason,
      photoUrl: '$_baseImageUrl${upload.data!.first.url.isNotEmpty ? upload.data!.first.url : fileName}',
      createdBy: createdBy,
    ));

    if (response.success) await fetchBreakages();
    return response;
  }

  Future<ApiResponse<bool>> approve(BreakageModel breakage, String reviewedBy) {
    return _updateStatus([
      breakage.copyWith(status: BreakageStatus.aprovado, reviewedBy: reviewedBy),
    ]);
  }

  Future<ApiResponse<bool>> reject(BreakageModel breakage, String reviewedBy, String rejectionReason) {
    return _updateStatus([
      breakage.copyWith(
        status: BreakageStatus.rejeitado,
        reviewedBy: reviewedBy,
        rejectionReason: rejectionReason,
      ),
    ]);
  }

  /// Dá baixa no estoque dos registros aprovados informados.
  Future<ApiResponse<bool>> writeOff(List<BreakageModel> breakages, String writtenOffBy) {
    return _updateStatus(breakages
        .map((b) => b.copyWith(status: BreakageStatus.baixado, writtenOffBy: writtenOffBy))
        .toList());
  }

  Future<ApiResponse<bool>> deleteBreakage(BreakageModel breakage) async {
    final response = await _breakageRepository.delete(breakage.breakageId);

    if (response.success) {
      _breakages.removeWhere((b) => b.breakageId == breakage.breakageId);
      notifyListeners();
    }
    return response;
  }

  Future<ApiResponse<bool>> _updateStatus(List<BreakageModel> updated) async {
    final results = await Future.wait(updated.map(_breakageRepository.save));
    final failures = results.where((r) => !r.success).toList();

    await fetchBreakages();

    if (failures.isEmpty) return ApiResponse(success: true, data: true);
    return ApiResponse(
      success: false,
      message: failures.length == 1
          ? failures.first.message
          : '${failures.length} de ${updated.length} registros falharam: ${failures.first.message}',
    );
  }

  /// Busca o nome dos produtos ainda não presentes no cache.
  Future<void> _resolveProductNames() async {
    final missing = _breakages
        .map((b) => b.productId)
        .where((id) => id.isNotEmpty && !_productNames.containsKey(id))
        .toSet();

    await Future.wait(missing.map((id) async {
      final response = await _productRepository.getProductById(id);
      if (response.success && response.data != null && response.data!.productName.isNotEmpty) {
        _productNames[id] = response.data!.productName;
      }
    }));
  }
}
