// lib/app/core/services/image_cache_service.dart

import 'package:flutter/material.dart';
import 'package:oxdata/app/core/models/ftp_image_response.dart';

class ImageCacheService extends ChangeNotifier {
  // Lista privada para armazenar o cache de imagens.
  // Usei List<FtpImageResponse> que já contém a URL e o conteúdo Base64.
  List<FtpImageResponse> _cachedImages = [];

  /// Retorna o cache atual de imagens.
  List<FtpImageResponse> get cachedImages => _cachedImages;

  /// Retorna apenas a lista de caminhos (URL/ImagePath) como String.
  List<String> get imagePaths => 
      _cachedImages.map((image) => image.url).toList();

  /// Limpa todas as imagens armazenadas no cache.
  void clearCache() {
    _cachedImages = [];
    notifyListeners();
  }

  /// Adiciona uma única imagem ao cache.
  void addImage(FtpImageResponse image) {
    // Pode ser útil adicionar lógica para evitar URLs duplicadas, se necessário.
    _cachedImages.add(image);
    notifyListeners();
  }

  /// Define o cache com uma nova lista de imagens (útil para substituir o cache inteiro).
  void setCacheImages(List<FtpImageResponse> newImages) {
    clearCache();
    _cachedImages = newImages;
    notifyListeners();
  }

  void setCacheFromMap(Map<String, String> imageMap) {
    _cachedImages = imageMap.entries.map((entry) => FtpImageResponse(
        url: entry.key,             // O caminho sequencial gerado
        base64Content: entry.value, // O conteúdo Base64 da imagem
        status: 'CachedFromPicker', // Status para indicar a origem
        message: 'Image base64 loaded from picker map.',
    )).toList();
    
    notifyListeners();
  }

  void clearAllImages() {
    _cachedImages.clear();
    notifyListeners();
  }

  /// Atualiza o Base64 de uma imagem específica, se ela existir no cache.
  /// Útil para atualizar o conteúdo da imagem (Base64) mantendo a URL.
  void updateImageBase64(String url, String newBase64Content) {
    final index = _cachedImages.indexWhere((img) => img.url == url);
    
    if (index != -1) {
      // Cria uma nova instância para garantir que o cache seja imutável (melhor prática com Provider)
      // Como FtpImageResponse é imutável, precisa de um método copyWith       
      _cachedImages[index] = FtpImageResponse(
        url: url,
        base64Content: newBase64Content,
        status: _cachedImages[index].status,
        message: _cachedImages[index].message,
      );

      notifyListeners();
    }
  }

  /// Remove uma imagem do cache com base na URL.
  void removeImage(String url) {
    final initialLength = _cachedImages.length;
    _cachedImages.removeWhere((img) => img.url == url);
    
    if (_cachedImages.length != initialLength) {
        notifyListeners();
    }
  }

  /// Remove uma imagem do cache com base na URL/caminho.
  void removeImageByPath(String path) {
    final initialLength = _cachedImages.length;
    // Remove o objeto FtpImageResponse onde a URL é igual ao caminho
    _cachedImages.removeWhere((img) => img.url == path);
    
    if (_cachedImages.length != initialLength) {
        notifyListeners();
    }
  }

}