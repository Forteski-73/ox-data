import 'dart:convert';

class ProductDecoration {
  final String decorationId;
  final String decorationDescription;
  final int status;

  ProductDecoration({
    required this.decorationId,
    required this.decorationDescription,
    required this.status,
  });

  /// Converte uma instância de ProductDecoration para um mapa (Map<String, dynamic>).
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'decorationId': decorationId,
      'decorationDescription': decorationDescription,
      'status': status,
    };
  }

  /// Cria uma instância de ProductDecoration a partir de um mapa (Map<String, dynamic>).
  factory ProductDecoration.fromMap(Map<String, dynamic> map) {
    return ProductDecoration(
      decorationId: map['decorationId'] as String,
      decorationDescription: map['decorationDescription'] as String,
      status: map['status'] is int ? map['status'] : int.tryParse(map['status'].toString()) ?? 0,
    );
  }

  /// Converte uma instância de ProductDecoration para uma string JSON.
  String toJson() => json.encode(toMap());

  /// Cria uma instância de ProductDecoration a partir de uma string JSON.
  factory ProductDecoration.fromJson(String source) => ProductDecoration.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ProductDecoration(decorationId: $decorationId, decorationDescription: $decorationDescription, status: $status)';
  }

  /// Cria uma nova instância com valores atualizados.
  ProductDecoration copyWith({
    String? decorationId,
    String? decorationDescription,
    int? status,
  }) {
    return ProductDecoration(
      decorationId: decorationId ?? this.decorationId,
      decorationDescription: decorationDescription ?? this.decorationDescription,
      status: status ?? this.status,
    );
  }
}