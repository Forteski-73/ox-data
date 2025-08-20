// app/core/models/tag_model.dart
class ProductTagModel {
  final String productId;
  final String valueTag;

  ProductTagModel({
    required this.productId,
    required this.valueTag,
  });

  Map<String, dynamic> toJson() {
    return {
      'ProductId':  productId,
      'ValueTag':   valueTag,
    };
  }

  factory ProductTagModel.fromJson(Map<String, dynamic> json) {
    return ProductTagModel(
      productId:  json['productId'] as String,
      valueTag:   json['valueTag'] as String,
    );
  }
}