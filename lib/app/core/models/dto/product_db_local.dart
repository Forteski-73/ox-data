class ProductLocal {
  final String productId; // ID interno do ERP
  final String barcode;
  final String productName;
  final bool status;

  ProductLocal({
    required this.productId,
    required this.barcode,
    required this.productName,
    this.status = true,
  });

  factory ProductLocal.fromMap(Map<String, dynamic> map) {
    return ProductLocal(
      // Usando ?? '' para evitar nulos que quebrem o looping de 10k
      productId:    map['productId']?.toString() ?? '',
      barcode:      map['barcode']?.toString() ?? '',
      productName:  map['productName']?.toString() ?? '',
      status:       map['status'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId':    productId,
      'barcode':      barcode,
      'productName':  productName,
      'status':       status,
    };
  }
}