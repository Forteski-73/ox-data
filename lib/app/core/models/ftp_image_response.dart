// lib/app/core/models/ftp_image_response.dart

import 'dart:convert';
import 'package:uuid/uuid.dart'; // Você precisará adicionar 'uuid' ao seu pubspec.yaml

// Instância única para gerar IDs.
const Uuid uuid = Uuid();

class FtpImageResponse {
  /// ID único usado apenas para gerenciar o estado no cache do app (provider).
  /// Útil para lidar com imagens temporárias (fotos recém-tiradas).
  final String cacheId; 

  /// A URL original da imagem ou o caminho sequencial temporário (ex: produto_123_001.jpg).
  final String url;

  /// O conteúdo da imagem codificado em Base64.
  final String? base64Content;

  /// O status do download (ex: "Success", "Error").
  final String? status;

  /// Mensagem detalhada de erro ou sucesso.
  final String message;

  FtpImageResponse({
    String? cacheId, // Se não for fornecido, um novo ID será gerado.
    required this.url,
    this.base64Content,
    this.status,
    this.message = '',
  }) : cacheId = cacheId ?? uuid.v4(); // Inicializa o cacheId

  // Construtor factory para criar uma instância a partir de um mapa JSON
  factory FtpImageResponse.fromJson(Map<String, dynamic> json) {
    return FtpImageResponse(
      // Não há cacheId no JSON da API, então ele é gerado.
      url: json['url'] as String? ?? '', 
      base64Content: json['base64Content'] as String? ?? '',
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  // Método que facilita a criação de uma nova instância com valores alterados.
  FtpImageResponse copyWith({
    String? url,
    String? base64Content,
    String? status,
    String? message,
  }) {
    return FtpImageResponse(
      cacheId: cacheId, // Mantém o cacheId
      url: url ?? this.url,
      base64Content: base64Content ?? this.base64Content,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }

  // Método de conveniência para verificar se o download foi bem-sucedido
  bool get isSuccessful => status?.toLowerCase() == 'success';
}
