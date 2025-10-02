// lib/models/ftp_image_response.dart

import 'dart:convert';

class FtpImageResponse {
  /// A URL original da imagem que foi solicitada.
  final String url;

  /// O conteúdo da imagem codificado em Base64.
  final String base64Content;

  /// O status do download (ex: "Success", "Error").
  final String status;

  /// Mensagem detalhada de erro ou sucesso.
  final String message;

  FtpImageResponse({
    required this.url,
    required this.base64Content,
    required this.status,
    this.message = '',
  });

  // Construtor factory para criar uma instância a partir de um mapa JSON
  factory FtpImageResponse.fromJson(Map<String, dynamic> json) {
    return FtpImageResponse(
      // As chaves devem corresponder exatamente ao que o JSON retorna (por padrão, PascalCase)
      url: json['url'] as String? ?? '', 
      base64Content: json['base64Content'] as String? ?? '',
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  // Método de conveniência para verificar se o download foi bem-sucedido
  bool get isSuccessful => status.toLowerCase() == 'success';
}