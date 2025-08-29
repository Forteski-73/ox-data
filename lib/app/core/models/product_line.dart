import 'dart:convert';

class ProductLine {
  final String lineId;
  final String lineDescription;
  final int status;

  ProductLine({
    required this.lineId,
    required this.lineDescription,
    required this.status,
  });

  /// Converte uma instância de ProductLine para um mapa (Map<String, dynamic>).
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'lineId': lineId,
      'lineDescription': lineDescription,
      'status': status,
    };
  }

  /// Cria uma instância de ProductLine a partir de um mapa (Map<String, dynamic>).
  factory ProductLine.fromMap(Map<String, dynamic> map) {
    return ProductLine(
      lineId: map['lineId'] as String,
      lineDescription: map['lineDescription'] as String,
      status: map['status'] is int ? map['status'] : int.tryParse(map['status'].toString()) ?? 0,
    );
  }

  /// Converte uma instância de ProductLine para uma string JSON.
  String toJson() => json.encode(toMap());

  /// Cria uma instância de ProductLine a partir de uma string JSON.
  factory ProductLine.fromJson(String source) => ProductLine.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ProductLine(lineId: $lineId, lineDescription: $lineDescription, status: $status)';
  }

  /// Cria uma nova instância com valores atualizados.
  ProductLine copyWith({
    String? lineId,
    String? lineDescription,
    int? status,
  }) {
    return ProductLine(
      lineId: lineId ?? this.lineId,
      lineDescription: lineDescription ?? this.lineDescription,
      status: status ?? this.status,
    );
  }
}