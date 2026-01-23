import 'dart:convert';

/// Classe que representa um registro individual dentro de um Inventário.
/// Corresponde à tabela `inventory_record`.
class InventoryRecordModel {
  final int? id;                  // Corresponde a `id` (PK)
  final String inventCode;        // Corresponde a `invent_code` (FK)
  final DateTime? inventCreated;  // Corresponde a `invent_created`
  final String? inventUser;       // Corresponde a `invent_user`
  final String? inventUnitizer;   // Corresponde a `invent_unitizer`
  final String? inventLocation;   // Corresponde a `invent_location`
  final String inventProduct;     // Corresponde a `invent_product` (FK)
  final String? inventBarcode;    // Corresponde a `invent_barcode`
  final int? inventStandardStack; // Corresponde a `invent_standard_stack`
  final int? inventQtdStack;      // Corresponde a `invent_qtd_stack`
  final double? inventQtdIndividual; // Corresponde a `invent_qtd_individual`
  final double? inventTotal;         // Corresponde a `invent_total`
  final String? productDescription; // Nome do produto NotMapped
  /// Controle OFFLINE
  final bool? isSynced;

  InventoryRecordModel({
    this.id,
    required this.inventCode,
    this.inventCreated,
    this.inventUser,
    this.inventUnitizer,
    this.inventLocation,
    required this.inventProduct,
    this.inventBarcode,
    this.inventStandardStack,
    this.inventQtdStack,
    this.inventQtdIndividual,
    this.inventTotal,
    this.productDescription,
    this.isSynced,
  });

  // --- MÉTODOS DE CONVERSÃO ---

  /// Converte uma instância de InventoryRecordModel para um mapa.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'inventCode': inventCode,
      'inventCreated': inventCreated?.toIso8601String(),
      'inventUser': inventUser,
      'inventUnitizer': inventUnitizer,
      'inventLocation': inventLocation,
      'inventProduct': inventProduct,
      'inventBarcode': inventBarcode,
      'inventStandardStack': inventStandardStack,
      'inventQtdStack': inventQtdStack,
      'inventQtdIndividual': inventQtdIndividual,
      'inventTotal': inventTotal,
      'productDescription': productDescription,
    };
  }

  /// Cria uma instância de InventoryRecordModel a partir de um mapa.
  factory InventoryRecordModel.fromMap(Map<String, dynamic> map) {
    // Função auxiliar para garantir que o campo inteiro seja parsed corretamente.
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }
      
    double? parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      
      // Converte para String e trata a vírgula antes de tentar o parse
      return double.tryParse(value.toString().replaceAll(',', '.'));
    }

    // Função auxiliar para garantir que o campo string seja parsed corretamente.
    String? parseNullableString(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }


    return InventoryRecordModel(
      id: parseNullableInt(map['id']),
      inventCode: map['inventCode'] as String,
      inventCreated: map['inventCreated'] != null 
          ? DateTime.tryParse(map['inventCreated'].toString()) 
          : null,
      inventUser:           parseNullableString(map['inventUser']),
      inventUnitizer:       parseNullableString(map['inventUnitizer']),
      inventLocation:       parseNullableString(map['inventLocation']),
      inventProduct:        map['inventProduct'] as String,
      inventBarcode:        parseNullableString(map['inventBarcode']),
      inventStandardStack:  parseNullableInt(   map['inventStandardStack']),
      inventQtdStack:       parseNullableInt(   map['inventQtdStack']),
      inventQtdIndividual:  parseNullableDouble(map['inventQtdIndividual']),
      inventTotal:          parseNullableDouble(map['inventTotal']),
      productDescription: parseNullableString(map['productDescription']),
      isSynced:             true,
    );
  }

  // ----------------------------------------------------------------------
  // DRIFT (LOCAL)
  // ----------------------------------------------------------------------

  /// 🔥 Constrói a partir do banco local (Drift)
  /// Note: Ajuste o nome 'InventoryRecordData' para o nome da classe gerada pelo seu Drift
  /* factory InventoryRecordModel.fromLocal(InventoryRecordData data) {
    return InventoryRecordModel(
      id: data.id,
      inventCode: data.inventCode,
      inventCreated: data.inventCreated,
      inventUser: data.inventUser,
      inventUnitizer: data.inventUnitizer,
      inventLocation: data.inventLocation,
      inventProduct: data.inventProduct,
      inventBarcode: data.inventBarcode,
      inventStandardStack: data.inventStandardStack,
      inventQtdStack: data.inventQtdStack,
      inventQtdIndividual: data.inventQtdIndividual,
      inventTotal: data.inventTotal,
      isSynced: data.isSynced,
    );
  }
  */

  /// Converte para JSON.
  String toJson() => json.encode(toMap());

  /// Cria a partir de JSON.
  factory InventoryRecordModel.fromJson(String source) => InventoryRecordModel.fromMap(json.decode(source) as Map<String, dynamic>);

  // --- MÉTODOS DE UTILIDADE ---

  @override
  String toString() {
    return 'InventoryRecordModel(id: $id, inventCode: $inventCode, inventProduct: $inventProduct, inventTotal: $inventTotal)';
  }

  /// Cria uma nova instância com valores atualizados.
  InventoryRecordModel copyWith({
    int? id,
    String? inventCode,
    DateTime? inventCreated,
    String? inventUser,
    String? inventUnitizer,
    String? inventLocation,
    String? inventProduct,
    String? inventBarcode,
    int?    inventStandardStack,
    int?    inventQtdStack,
    double? inventQtdIndividual,
    double? inventTotal,
    String? productDescription,
    bool?   isSynced,
  }) {
    return InventoryRecordModel(
      id: id ?? this.id,
      inventCode: inventCode ?? this.inventCode,
      inventCreated: inventCreated ?? this.inventCreated,
      inventUser: inventUser ?? this.inventUser,
      inventUnitizer: inventUnitizer ?? this.inventUnitizer,
      inventLocation: inventLocation ?? this.inventLocation,
      inventProduct: inventProduct ?? this.inventProduct,
      inventBarcode: inventBarcode ?? this.inventBarcode,
      inventStandardStack: inventStandardStack ?? this.inventStandardStack,
      inventQtdStack: inventQtdStack ?? this.inventQtdStack,
      inventQtdIndividual: inventQtdIndividual ?? this.inventQtdIndividual,
      inventTotal: inventTotal ?? this.inventTotal,
      productDescription: productDescription ?? this.productDescription,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}