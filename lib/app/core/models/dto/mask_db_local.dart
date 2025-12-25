import 'package:oxdata/db/enums/mask_field_name.dart';

class InventoryMaskLocal {
  final int? maskId;
  final MaskFieldName fieldName;
  final String fieldMask;

  InventoryMaskLocal({
    this.maskId,
    required this.fieldName,
    required this.fieldMask,
  });

  factory InventoryMaskLocal.fromMap(Map<String, dynamic> map) {
    return InventoryMaskLocal(
      // Se o ID vier da API, usamos, senão o Drift gera (autoIncrement)
      maskId: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      
      // Converte a String da API ('Unitizador', 'Posicao', 'Codigo') para o Enum
      fieldName: MaskFieldName.values.firstWhere(
        (e) => e.name == map['fieldName'],
        orElse: () => MaskFieldName.Codigo, // Default caso venha algo estranho
      ),
      
      fieldMask: map['fieldMask']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maskId': maskId,
      'fieldName': fieldName.name, // Grava o nome do enum como string
      'fieldMask': fieldMask,
    };
  }
}