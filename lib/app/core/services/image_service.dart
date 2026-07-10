// -----------------------------------------------------------
// app/core/services/image_service.dart
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:oxdata/app/core/models/image_url_model.dart';
import 'package:oxdata/app/core/repositories/image_repository.dart';

class ImageService with ChangeNotifier {
  final ImageRepository _imageRepository;

  ImageService({required ImageRepository imageRepository})
      : _imageRepository = imageRepository;

  static const String _baseImageUrl = 'https://oxfordtec.com.br/Imagens/';

  List<ImageUrlModel> _productImages = [];
  List<ImageUrlModel> get productImages => _productImages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Busca as imagens de um produto para uma finalidade específica
  /// (ex.: 'EMBALAGEM') e atualiza o estado.
  Future<void> fetchProductImages(String productId, String finalidade) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _imageRepository.getProductImages(productId, finalidade);

    if (response.success && response.data != null) {
      // Garante a ordem correta pela sequência, com a imagem principal primeiro.
      final images = List<ImageUrlModel>.from(response.data!)
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      _productImages = images;
    } else {
      _productImages = [];
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Retorna a imagem principal (imageMain == true), ou a primeira
  /// disponível caso nenhuma esteja marcada como principal.
  ImageUrlModel? get mainImage {
    if (_productImages.isEmpty) return null;
    return _productImages.firstWhere(
      (img) => img.imageMain,
      orElse: () => _productImages.first,
    );
  }

  /// Monta a URL completa de exibição a partir do imagePath relativo
  /// retornado pela API.
  String buildFullImageUrl(String imagePath) {
    return '$_baseImageUrl$imagePath';
  }

  /// Retorna a URL completa da imagem principal, ou null se não houver.
  String? get mainImageUrl {
    final main = mainImage;
    if (main == null) return null;
    return buildFullImageUrl(main.imagePath);
  }

  /// Retorna a lista de URLs completas, na ordem de sequência.
  List<String> get allImageUrls {
    return _productImages.map((img) => buildFullImageUrl(img.imagePath)).toList();
  }

  void clear() {
    _productImages = [];
    _errorMessage = null;
    notifyListeners();
  }
}