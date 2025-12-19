import 'dart:convert';

/// Classe que representa o modelo de GUID do Inventário, usado para rastreamento.
/// Corresponde à tabela `inventory_guid`.
class InventoryGuidModel {
  final String inventGuid;        // Corresponde a `invent_guid` (PK, VARCHAR 36)
  final int inventExpSeq;         // Corresponde a `invent_exp_seq` (INT, NOT NULL)
  final DateTime? inventCreated;  // Corresponde a `invent_created` (DATETIME NULL)

  InventoryGuidModel({
    required this.inventGuid,
    required this.inventExpSeq,
    this.inventCreated,
  });

  // --- MÉTODOS DE CONVERSÃO ---

  /// Converte uma instância de InventoryGuidModel para um mapa.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'invent_guid': inventGuid,
      'invent_exp_seq': inventExpSeq,
      // Converte DateTime para String ISO 8601
      'invent_created': inventCreated?.toIso8601String(), 
    };
  }

  /// Cria uma instância de InventoryGuidModel a partir de um mapa.
  factory InventoryGuidModel.fromMap(Map<String, dynamic> map) {
    // Função auxiliar para garantir que o campo inteiro seja parsed corretamente.
    int parseRequiredInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0; // Assume 0 se falhar, já que é Required na API
    }

    return InventoryGuidModel(
      inventGuid: map['invent_guid'] as String,
      inventExpSeq: parseRequiredInt(map['invent_exp_seq']),
      // Tenta parsear a string para DateTime
      inventCreated: map['invent_created'] != null 
          ? DateTime.tryParse(map['invent_created'].toString()) 
          : null,
    );
  }

  /// Converte para JSON.
  String toJson() => json.encode(toMap());

  /// Cria a partir de JSON.
  factory InventoryGuidModel.fromJson(String source) => InventoryGuidModel.fromMap(json.decode(source) as Map<String, dynamic>);

  // --- MÉTODOS DE UTILIDADE ---

  @override
  String toString() {
    return 'InventoryGuidModel(inventGuid: $inventGuid, inventExpSeq: $inventExpSeq, inventCreated: $inventCreated)';
  }

  /// Cria uma nova instância com valores atualizados.
  InventoryGuidModel copyWith({
    String? inventGuid,
    int? inventExpSeq,
    DateTime? inventCreated,
  }) {
    return InventoryGuidModel(
      inventGuid: inventGuid ?? this.inventGuid,
      inventExpSeq: inventExpSeq ?? this.inventExpSeq,
      inventCreated: inventCreated ?? this.inventCreated,
    );
  }
  
  // Sobrecarga de operadores para comparação de igualdade (melhores práticas em Dart)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is InventoryGuidModel &&
      other.inventGuid == inventGuid &&
      other.inventExpSeq == inventExpSeq &&
      other.inventCreated == inventCreated;
  }

  @override
  int get hashCode {
    return inventGuid.hashCode ^
      inventExpSeq.hashCode ^
      inventCreated.hashCode;
  }
}