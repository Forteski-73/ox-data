class ProductBomModel {
  final int id;
  final String productId;
  final String? productBomId;
  final String? productName;
  final int productQty;

  ProductBomModel({
    required this.id,
    required this.productId,
    this.productBomId,
    this.productName,
    required this.productQty,
  });

  factory ProductBomModel.fromJson(Map<String, dynamic> json) {
    return ProductBomModel(
      id:           json['id'] ?? 0,
      productId:    json['productId'] ?? '',
      productBomId: json['productBomId'],
      productName:  json['productName'],
      productQty:   json['productQty'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    "id":           id,
    "productId":    productId,
    "productBomId": productBomId,
    "productName":  productName,
    "productQty":   productQty,
  };
}