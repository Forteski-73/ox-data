// app/core/models/product_simple_model.dart

import 'dart:convert';

/// Modelo simples para receber a resposta do endpoint GET /API/v1/Product/{id}
class ProductSimpleModel {
  final String productId;
  final String productName;
  final String? barcode;
  final bool status;
  final String? note;

  ProductSimpleModel({
    required this.productId,
    required this.productName,
    this.barcode,
    required this.status,
    this.note,
  });

  /// Constrói o modelo a partir de um Map (JSON decodificado)
  factory ProductSimpleModel.fromMap(Map<String, dynamic> map) {
    return ProductSimpleModel(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      barcode: map['barcode'] as String?,
      status: map['status'] as bool? ?? false,
      note: map['note'] as String?,
    );
  }

  /// Constrói o modelo diretamente de uma String em formato JSON
  factory ProductSimpleModel.fromJson(String source) =>
      ProductSimpleModel.fromMap(json.decode(source) as Map<String, dynamic>);
}