class ProductPackingBomAxModel {
  final int id;
  final String productId;
  final String? productPackingBomId;
  final String? productName;
  final int productQty;

  ProductPackingBomAxModel({
    required this.id,
    required this.productId,
    this.productPackingBomId,
    this.productName,
    required this.productQty,
  });

  factory ProductPackingBomAxModel.fromJson(Map<String, dynamic> json) {
    return ProductPackingBomAxModel(
      id: json['id'] ?? 0,
      productId: json['productId'] ?? '',
      productPackingBomId: json['productPackingBomId'],
      productName: json['productName'],
      productQty: json['productQty'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "productId": productId,
    "productPackingBomId": productPackingBomId,
    "productName": productName,
    "productQty": productQty,
  };
  
}