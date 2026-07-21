class ProductPackingBom {
  final int     id;
  final String  productId;
  final String? productBomId;
  final String? productName;
  final int     productQty;
  final int     productSeq;
  final String? updatedUser;

  ProductPackingBom({
    this.id = 0,
    required this.productId,
    this.productBomId,
    this.productName,
    this.productQty = 1,
    this.productSeq = 1,
    this.updatedUser,
  });

  factory ProductPackingBom.fromJson(Map<String, dynamic> json) {
    return ProductPackingBom(
      id:           json['id'] as int? ?? 0,
      productId:    json['productId'] as String? ?? '',
      productBomId: json['productBomId'] as String?,
      productName:  json['productName'] as String?,
      productQty:   json['productQty'] as int? ?? 1,
      productSeq:   json['productSeq'] as int? ?? 1,
      updatedUser:  json['updatedUser'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id":           id,
      "productId":    productId,
      "productBomId": productBomId,
      "productName":  productName,
      "productQty":   productQty,
      "productSeq":   productSeq,
      "updatedUser":  updatedUser,
    };
  }

  /// Usado no payload do POST (não envia productId, pois vai no nível raiz do request)
  Map<String, dynamic> toBomItemJson() {
    return {
      "productBomId": productBomId,
      "productName":  productName,
      "productQty":   productQty,
      "productSeq":   productSeq,
      "updatedUser":  updatedUser,
    };
  }

  ProductPackingBom copyWith({
    int?    id,
    String? productId,
    String? productBomId,
    String? productName,
    int?    productQty,
    int?    productSeq,
    String? updatedUser,
  }) {
    return ProductPackingBom(
      id:           id ?? this.id,
      productId:    productId ?? this.productId,
      productBomId: productBomId ?? this.productBomId,
      productName:  productName ?? this.productName,
      productQty:   productQty ?? this.productQty,
      productSeq:   productSeq ?? this.productSeq,
      updatedUser:  updatedUser ?? this.updatedUser,
    );
  }
}