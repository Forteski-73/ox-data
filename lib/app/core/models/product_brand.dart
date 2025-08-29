import 'dart:convert';

class ProductBrand {
  final String brandId;
  final String brandDescription;
  final int status;

  ProductBrand({
    required this.brandId,
    required this.brandDescription,
    required this.status,
  });

  /// Converte uma instância de ProductBrand para um mapa (Map<String, dynamic>).
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'brandId': brandId,
      'brandDescription': brandDescription,
      'status': status,
    };
  }

  /// Cria uma instância de ProductBrand a partir de um mapa (Map<String, dynamic>).
  factory ProductBrand.fromMap(Map<String, dynamic> map) {
    return ProductBrand(
      brandId: map['brandId'] as String,
      brandDescription: map['brandDescription'] as String,
      // A propriedade 'status' pode ser um número inteiro ou um string
      // dependendo do seu JSON, então usamos um fallback seguro.
      status: map['status'] is int ? map['status'] : int.tryParse(map['status'].toString()) ?? 0,
    );
  }

  /// Converte uma instância de ProductBrand para uma string JSON.
  String toJson() => json.encode(toMap());

  /// Cria uma instância de ProductBrand a partir de uma string JSON.
  factory ProductBrand.fromJson(String source) => ProductBrand.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ProductBrand(brandId: $brandId, brandDescription: $brandDescription, status: $status)';
  }

  /// Cria uma nova instância com valores atualizados.
  ProductBrand copyWith({
    String? brandId,
    String? brandDescription,
    int? status,
  }) {
    return ProductBrand(
      brandId: brandId ?? this.brandId,
      brandDescription: brandDescription ?? this.brandDescription,
      status: status ?? this.status,
    );
  }
}