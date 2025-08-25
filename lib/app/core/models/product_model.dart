import 'dart:convert';

/// Classe que representa um produto simplificado para o aplicativo,
/// incluindo o zip da imagem em Base64.
class ProductModel {
  final String  productId;
  final String? barcode; // Pode ser nulo, como no seu modelo C#
  final String  name;
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
      'productId':      productId,
      'barcode':        barcode,
      'name':           name,
      'imageZipBase64': imageZipBase64,
    };
  }
  

  /// Cria uma instância de ProductAppModel a partir de um mapa (Map<String, dynamic>).
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      productId:      map['productId'] as String,
      barcode:        map['barcode'] as String?,
      name:           map['name'] as String,
      imageZipBase64: map['imageZipBase64'] as String?,
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

  /// Criar uma nova instância com valores atualizados
  ProductModel copyWith({
    String? productId,
    String? barcode,
    String? name,
    // Adicione este parâmetro
    String? imageZipBase64,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      // Use o novo parâmetro
      imageZipBase64: imageZipBase64 ?? this.imageZipBase64,
    );
  }
}
