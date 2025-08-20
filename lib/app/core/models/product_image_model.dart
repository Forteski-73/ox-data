// -----------------------------------------------------------
// app/core/models/product_image_model.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'dart:typed_data';

/// Modelo para a resposta da API de imagem de produto, retorna bytes de um ZIP.
class ProductImageModel {
  final Uint8List zipBytes; // Alterado para armazenar bytes brutos do ZIP

  ProductImageModel({
    required this.zipBytes,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'zipBytes': base64Encode(zipBytes), // Codifica para base64 para serialização JSON
    };
  }

  factory ProductImageModel.fromMap(Map<String, dynamic> map) {
    return ProductImageModel(
      zipBytes: base64Decode(map['zipBytes'] as String), // Decodifica de base64 para desserialização JSON
    );
  }

  String toJson() => json.encode(toMap());

  factory ProductImageModel.fromJson(String source) =>
      ProductImageModel.fromMap(json.decode(source) as Map<String, dynamic>);
}