
// lib/models/ftp_image_request.dart

import 'dart:convert';

class FtpImageRequest {
  /// Lista de URLs (FTP ou outro protocolo) das imagens a serem baixadas.
  final List<String> imageUrls;

  FtpImageRequest({
    required this.imageUrls,
  });

  // Método de conveniência para criar um objeto a partir de um JSON (útil para testes, mas não para o corpo da requisição POST)
  factory FtpImageRequest.fromJson(Map<String, dynamic> json) {
    return FtpImageRequest(
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
    );
  }

  /// Converte o objeto para um mapa, pronto para ser serializado como JSON
  /// e enviado no corpo de uma requisição HTTP.
  Map<String, dynamic> toJson() {
    return {
      // O nome da chave deve corresponder exatamente ao nome da propriedade no C#: 'ImageUrls'
      'ImageUrls': imageUrls, 
    };
  }
}