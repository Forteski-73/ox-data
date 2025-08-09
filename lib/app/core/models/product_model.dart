// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

/// Classe que representa um produto simplificado para o aplicativo,
/// incluindo o zip da imagem em Base64.
class ProductModel {
  final String productId;
  final String? barcode; // Pode ser nulo, como no seu modelo C#
  final String name;
  final String? imageZipBase64; // Campo para o zip da imagem em Base64

  ProductModel({
    required this.productId,
    this.barcode,
    required this.name,
    this.imageZipBase64,
  });

  /// Converte uma instância de ProductAppModel para um mapa (Map<String, dynamic>).
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'productId': productId,
      'barcode': barcode,
      'name': name,
      'imageZipBase64': imageZipBase64,
    };
  }

  /// Cria uma instância de ProductAppModel a partir de um mapa (Map<String, dynamic>).
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      productId: map['productId'] as String,
      barcode: map['barcode'] as String?, // Usar 'as String?' para nullable
      name: map['name'] as String,
      imageZipBase64: map['imageZipBase64'] as String?, // Usar 'as String?' para nullable
    );
  }

  /// Converte uma instância de ProductAppModel para uma string JSON.
  String toJson() => json.encode(toMap());

  /// Cria uma instância de ProductAppModel a partir de uma string JSON.
  factory ProductModel.fromJson(String source) =>
      ProductModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ProductAppModel(productId: $productId, barcode: $barcode, name: $name, imageZipBase64: ${imageZipBase64?.length ?? 0} bytes)';
  }
}
