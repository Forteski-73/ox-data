class ProductImageBase64Request {
  final String        productId;
  final String        finalidade;
  final List<String>  base64Images;

  ProductImageBase64Request({
    required this.productId,
    required this.finalidade,
    required this.base64Images,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId':    productId,
      'finalidade':   finalidade,
      'base64Images': base64Images,
    };
  }
}