// -----------------------------------------------------------
// app/core/services/breakage_service.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oxdata/app/core/models/breakage_history_model.dart';
import 'package:oxdata/app/core/models/breakage_model.dart';
import 'package:oxdata/app/core/models/breakage_profile.dart';
import 'package:oxdata/app/core/models/ftp_image_request.dart';
import 'package:oxdata/app/core/models/ftp_image_response.dart';
import 'package:oxdata/app/core/models/store_model.dart';
import 'package:oxdata/app/core/repositories/admin_repository.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/repositories/breakage_repository.dart';
import 'package:oxdata/app/core/repositories/ftp_repository.dart';
import 'package:oxdata/app/core/repositories/product_repository.dart';
import 'package:oxdata/app/core/repositories/store_repository.dart';
import 'package:oxdata/app/core/services/storage_service.dart';

/// Abas da Gestão de Quebras que carregam registros (cada uma com seus filtros).
enum BreakageTab { approvals, writeOff, history }

/// Service responsável por expor os registros de quebra para a UI,
/// consumindo o BreakageRepository (BreakageController da API),
/// o StoreRepository (lojas do usuário), o AdminRepository (nome do perfil),
/// o FtpRepository (fotos) e o ProductRepository (nome e preço do produto).
class BreakageService with ChangeNotifier {
  final BreakageRepository _breakageRepository;
  final StoreRepository _storeRepository;
  final AdminRepository _adminRepository;
  final FtpRepository _ftpRepository;
  final ProductRepository _productRepository;

  BreakageService({
    required BreakageRepository breakageRepository,
    required StoreRepository storeRepository,
    required AdminRepository adminRepository,
    required FtpRepository ftpRepository,
    required ProductRepository productRepository,
  })  : _breakageRepository = breakageRepository,
        _storeRepository = storeRepository,
        _adminRepository = adminRepository,
        _ftpRepository = ftpRepository,
        _productRepository = productRepository;

  /// Pasta no FTP onde as fotos das quebras são gravadas.
  static const String _ftpFolder    = 'QUEBRAS/';
  static const String _baseImageUrl = 'https://oxfordtec.com.br/Imagens/';
  static const String _lastStoreKey = 'breakage_last_store_id';

  // ── Perfil do usuário ─────────────────────────────────────

  final StorageService _storage = StorageService();

  BreakageProfile _profile = BreakageProfile.none;
  BreakageProfile get profile => _profile;

  bool get isStockist        => _profile.isStockist;
  bool get isStoreManager    => _profile.isStoreManager;
  bool get isInternalControl => _profile.isInternalControl;

  bool _profileLoaded = false;
  bool get profileLoaded => _profileLoaded;

  /// Erro ao descobrir o perfil (ex.: falha no GET User/Profiles).
  String? _profileError;
  String? get profileError => _profileError;

  String _username = '';
  String get username => _username;

  /// Descobre o nome do perfil do usuário logado: o login guarda só o
  /// `profileId`, e o nome vem de GET User/Profiles.
  Future<void> loadProfile() async {
    _profileLoaded = false;
    _profileError = null;
    notifyListeners();

    final credentials = await _storage.readCredentials();
    _username = credentials['username'] ?? '';

    final profileId = await _storage.readProfileId();
    final response = await _adminRepository.getProfiles();

    if (response.success && response.data != null) {
      final names = response.data!.where((p) => p.id == profileId).map((p) => p.name);
      _profile = BreakageProfile.fromNames(names);
    } else {
      _profile = BreakageProfile.none;
      _profileError = response.message ?? 'Não foi possível carregar o seu perfil.';
    }

    _profileLoaded = true;
    notifyListeners();
  }

  bool canAccess(BreakageTab tab) => switch (tab) {
        BreakageTab.approvals => _profile.canApprove,
        BreakageTab.writeOff  => _profile.canWriteOff,
        BreakageTab.history   => _profile.canSeeHistory,
      };

  // ── Lojas ─────────────────────────────────────────────────

  List<StoreModel> _stores = [];
  List<StoreModel> get stores => _stores;

  String? _lastStoreId;
  String? get lastStoreId => _lastStoreId;

  Future<void> fetchStores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastStoreId = prefs.getString(_lastStoreKey);
    } catch (_) {}

    final response = await _storeRepository.getStores();
    if (response.success && response.data != null) {
      _stores = response.data!..sort((a, b) => a.storeId.compareTo(b.storeId));
    }
    notifyListeners();
  }

  /// Lembra a última loja escolhida no registro.
  Future<void> rememberStore(String storeId) async {
    _lastStoreId = storeId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastStoreKey, storeId);
    } catch (_) {}
  }

  /// Nome da loja para exibição (o da API tem prioridade).
  String storeName(BreakageModel b) {
    if ((b.storeName ?? '').isNotEmpty) return b.storeName!;
    final store = _stores.where((s) => s.storeId == b.storeId).firstOrNull;
    return store?.name ?? b.storeId;
  }

  // ── Registros por aba e filtros ───────────────────────────

  final Map<BreakageTab, List<BreakageModel>> _lists = {
    for (final tab in BreakageTab.values) tab: <BreakageModel>[],
  };

  final Map<BreakageTab, BreakageFilter> _filters = {
    BreakageTab.approvals: const BreakageFilter(),
    BreakageTab.writeOff:  const BreakageFilter(),
    BreakageTab.history:   BreakageFilter(dateFrom: _daysAgo(29), dateTo: _today()),
  };

  /// Status escolhido nos chips do Histórico (null = todos, sem excluídos).
  String? _historyStatus;
  String? get historyStatus => _historyStatus;

  List<BreakageModel> breakages(BreakageTab tab) => _lists[tab]!;
  BreakageFilter filter(BreakageTab tab) => _filters[tab]!;

  /// Fila do GERENTE_LOJA (reprovados primeiro).
  List<BreakageModel> get managerQueue => breakages(BreakageTab.approvals)
      .where((b) => b.status == BreakageStatus.pendenteGerente || b.status == BreakageStatus.devolvido)
      .toList();

  /// Fila de CONTROLES_INT (etapa 2).
  List<BreakageModel> get internalControlQueue =>
      breakages(BreakageTab.approvals).where((b) => b.status == BreakageStatus.pendenteCi).toList();

  int get approvalsBadge => breakages(BreakageTab.approvals).length;
  int get writeOffBadge  => breakages(BreakageTab.writeOff).length;

  void setFilter(BreakageTab tab, BreakageFilter filter) {
    _filters[tab] = filter;
    notifyListeners();
    fetchTab(tab);
  }

  void setHistoryStatus(String? status) {
    _historyStatus = status;
    notifyListeners();
    fetchTab(BreakageTab.history);
  }

  /// Filtro efetivo: período/loja da aba + status que o perfil pode ver nela.
  BreakageFilter _effectiveFilter(BreakageTab tab) {
    final statuses = switch (tab) {
      BreakageTab.approvals => [
          if (isStoreManager) ...[BreakageStatus.pendenteGerente, BreakageStatus.devolvido],
          if (isInternalControl) BreakageStatus.pendenteCi,
        ],
      BreakageTab.writeOff => [BreakageStatus.aprovado],
      BreakageTab.history  => historyStatus == null ? <String>[] : [historyStatus!],
    };
    return filter(tab).copyWith(statuses: statuses);
  }

  int _loadingCount = 0;
  bool get isLoading => _loadingCount > 0;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Recarrega todas as abas que o usuário pode ver.
  Future<void> fetchBreakages() async {
    await Future.wait(BreakageTab.values.where(canAccess).map(fetchTab));
  }

  Future<void> fetchTab(BreakageTab tab) async {
    if (!canAccess(tab)) return;

    _loadingCount++;
    _errorMessage = null;
    notifyListeners();

    final effective = _effectiveFilter(tab);
    final response = await _breakageRepository.getAll(effective);

    if (response.success && response.data != null) {
      // Mais recentes primeiro; na fila de aprovação, os reprovados (DEVOLVIDO) vêm antes.
      int rank(BreakageModel b) => tab == BreakageTab.approvals && b.status == BreakageStatus.devolvido ? 0 : 1;
      final list = response.data!.where(effective.matches).toList()
        ..sort((a, b) {
          final byRank = rank(a).compareTo(rank(b));
          if (byRank != 0) return byRank;
          return (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
        });
      _lists[tab] = list;
      await _resolveProductNames(list);
      // Miniaturas carregadas em segundo plano.
      fetchPhotos(list);
    } else {
      _errorMessage = response.message;
    }

    _loadingCount--;
    notifyListeners();
  }

  // ── Produto (nome e preço) ────────────────────────────────

  /// Cache de nomes de produto (productId -> nome) para registros sem `productName`.
  final Map<String, String> _productNames = {};

  /// Nome do produto: o da API, o do cache ou o próprio código.
  String productName(BreakageModel b) {
    if ((b.productName ?? '').isNotEmpty) return b.productName!;
    return _productNames[b.productId] ?? b.productId;
  }

  /// Registra o nome de um produto já conhecido (ex.: selecionado na busca).
  void cacheProductName(String productId, String name) {
    _productNames[productId] = name;
  }

  /// Preço unitário atual do produto, só para exibição antes de salvar
  /// (o valor que vale é o gravado pela API no registro).
  Future<double?> fetchUnitPrice(String productId) async {
    final response = await _productRepository.getAppProduct(productId);
    if (!response.success || response.data == null || response.data!.isEmpty) return null;
    return response.data!.first.location?.price;
  }

  Future<void> _resolveProductNames(List<BreakageModel> list) async {
    final missing = list
        .where((b) => (b.productName ?? '').isEmpty)
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

  // ── Fotos ─────────────────────────────────────────────────

  /// Cache das fotos baixadas do FTP (photoUrl -> bytes).
  final Map<String, Uint8List> _photos = {};
  final Set<String> _loadingPhotos = {};

  Uint8List? photo(String photoUrl) => _photos[photoUrl];
  bool isPhotoLoading(String photoUrl) => _loadingPhotos.contains(photoUrl);

  /// Caminho relativo no FTP (ex.: QUEBRAS/002687/05112026_1426_001.jpg).
  String _ftpPath(String photoUrl) =>
      photoUrl.startsWith(_baseImageUrl) ? photoUrl.substring(_baseImageUrl.length) : photoUrl;

  Future<void> fetchPhotos(List<BreakageModel> breakages) => fetchPhotoUrls(breakages.map((b) => b.photoUrl));

  /// Baixa (via API de FTP, em Base64) as fotos ainda não presentes no cache.
  Future<void> fetchPhotoUrls(Iterable<String> urls) async {
    final pending = urls
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

  /// Envia a foto ao FTP em QUEBRAS/[produto]/[DDMMAAAA_HHMM]_[seq].jpg
  /// e devolve a URL pública. Fotos anteriores não são apagadas.
  Future<ApiResponse<String>> _uploadPhoto(String productId, Uint8List bytes, int sequence) async {
    final seq = sequence.toString().padLeft(3, '0');
    final fileName = '$_ftpFolder$productId/${DateFormat('ddMMyyyy_HHmm').format(DateTime.now())}_$seq.jpg';

    final upload = await _ftpRepository.setImagesBase64([
      FtpImageResponse(url: fileName, base64Content: base64Encode(bytes)),
    ]);

    final uploaded = upload.success &&
        upload.data != null &&
        upload.data!.isNotEmpty &&
        upload.data!.every((r) => r.isSuccessful);

    if (!uploaded) {
      return ApiResponse(success: false, message: 'Falha ao enviar a foto: ${upload.message ?? ''}');
    }

    final path = upload.data!.first.url.isNotEmpty ? upload.data!.first.url : fileName;
    final url = '$_baseImageUrl$path';
    _photos[url] = bytes;
    return ApiResponse(success: true, data: url);
  }

  // ── Ações ─────────────────────────────────────────────────

  /// Envia a foto e cria o registro (a API define PENDENTE_GERENTE e o preço).
  Future<ApiResponse<bool>> registerBreakage({
    required String storeId,
    required String productId,
    required int quantity,
    required String reason,
    required Uint8List photoBytes,
  }) async {
    final upload = await _uploadPhoto(productId, photoBytes, 1);
    if (!upload.success) return ApiResponse(success: false, message: upload.message);

    final response = await _breakageRepository.create(BreakageModel(
      storeId: storeId,
      productId: productId,
      quantity: quantity,
      reason: reason,
      photoUrl: upload.data!,
    ));

    if (response.success) {
      await rememberStore(storeId);
      await fetchBreakages();
    }
    return response;
  }

  /// Edita foto e/ou quantidade com justificativa (somente o Gerente).
  Future<ApiResponse<bool>> editBreakage(
    BreakageModel breakage, {
    int? quantity,
    Uint8List? photoBytes,
    required String justification,
  }) async {
    String? photoUrl;
    if (photoBytes != null) {
      // Sequência da foto: 001 é a original; cada edição usa um arquivo novo.
      final upload = await _uploadPhoto(breakage.productId, photoBytes, breakage.editCount + 2);
      if (!upload.success) return ApiResponse(success: false, message: upload.message);
      photoUrl = upload.data;
    }

    final response = await _breakageRepository.edit(
      breakage.breakageId,
      quantity: quantity,
      photoUrl: photoUrl,
      justification: justification,
    );
    return _afterAction(response);
  }

  /// Aprova a etapa atual (gerente: → PENDENTE_CI; CI: → APROVADO).
  Future<ApiResponse<bool>> approve(BreakageModel breakage) async =>
      _afterAction(await _breakageRepository.approve(breakage.breakageId));

  /// Reprova (CONTROLES_INT): o registro volta ao gerente como DEVOLVIDO.
  Future<ApiResponse<bool>> returnToManager(BreakageModel breakage, String reason) async =>
      _afterAction(await _breakageRepository.returnToManager(breakage.breakageId, reason));

  Future<ApiResponse<bool>> resubmit(BreakageModel breakage, String? reason) async =>
      _afterAction(await _breakageRepository.resubmit(breakage.breakageId, reason));

  /// Dá baixa no estoque dos registros aprovados informados.
  Future<ApiResponse<bool>> writeOff(List<BreakageModel> breakages) async {
    final response = await _breakageRepository.writeOff(breakages.map((b) => b.breakageId).toList());
    await fetchBreakages();

    if (!response.success) return ApiResponse(success: false, message: response.message);

    final failed = response.data!.failed;
    if (failed.isEmpty) return ApiResponse(success: true, data: true);
    return ApiResponse(
      success: false,
      message: '${failed.length} de ${breakages.length} registros falharam: '
          '${failed.entries.map((e) => '#${e.key}: ${e.value}').join('; ')}',
    );
  }

  /// Exclusão lógica (GERENTE_LOJA): status EXCLUIDO, com motivo.
  Future<ApiResponse<bool>> deleteBreakage(BreakageModel breakage, String reason) async =>
      _afterAction(await _breakageRepository.delete(breakage.breakageId, reason));

  Future<ApiResponse<List<BreakageHistoryModel>>> fetchHistory(int breakageId) =>
      _breakageRepository.getHistory(breakageId);

  /// A ação falhou com 409 (outro usuário já agiu no registro).
  static bool isConflict(ApiResponse<dynamic> response) => BreakageRepository.isConflict(response);

  Future<ApiResponse<bool>> _afterAction(ApiResponse<bool> response) async {
    // Recarrega também em caso de 409 (o registro mudou no servidor).
    await fetchBreakages();
    return response;
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _daysAgo(int days) => _today().subtract(Duration(days: days));
}
