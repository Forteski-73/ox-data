import 'package:oxdata/app/core/models/inventory_record_model.dart';

class InventoryBatchRequest {
  final String inventGuid;
  final String inventCode;
  final List<InventoryRecordModel> records;

  InventoryBatchRequest({
    required this.inventGuid,
    required this.inventCode,
    required this.records,
  });

  /// Converte a instância para um Mapa.
  /// Nota: Usamos r.toMap() para que os registros sejam processados como Mapas 
  /// e não como Strings individuais, permitindo a serialização correta do lote.
  Map<String, dynamic> toJson() => {
        'inventGuid': inventGuid,
        'inventCode': inventCode,
        'records': records.map((r) => r.toMap()).toList(),
      };
}