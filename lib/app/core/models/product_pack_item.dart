import 'dart:convert';

class ProductPackItem {
  final int     packId;
  final String  packProductId;
  final String  packUser;
  final String? productName;

  ProductPackItem({
    required this.packId,
    required this.packProductId,
    required this.packUser,
    this.productName,
  });

  /// Converte o JSON da API para o objeto Dart
  factory ProductPackItem.fromJson(Map<String, dynamic> json) {
    return ProductPackItem(
      packId:         json['packId']        ?? 0,
      packProductId:  json['packProductId'] ?? '',
      packUser:       json['packUser']      ?? '',
      productName:    json['productName'],
    );
  }

  /// Converte o objeto Dart para JSON (usado no POST)
  Map<String, dynamic> toJson() {
    return {
      'packId':        packId,
      'packProductId': packProductId,
      'packUser':      packUser,
    };
  }

  /// Facilitador para converter uma lista de JSON vinda da API
  static List<ProductPackItem> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((item) => ProductPackItem.fromJson(item)).toList();
  }
}