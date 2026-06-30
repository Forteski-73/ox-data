// app/core/sync/sync_api_client_impl.dart

import 'package:oxdata/app/core/models/InventoryBatchRequest.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/app/core/models/inventory_record_model.dart';
import 'package:oxdata/app/core/repositories/inventory_repository.dart';
import 'package:oxdata/app/core/repositories/admin_repository.dart';
import 'package:oxdata/app/core/services/sync_manager.dart';
import 'package:oxdata/db/tables/sync_queue.dart';
import 'package:oxdata/db/app_database.dart';
import 'package:flutter/foundation.dart';

class SyncApiClientImpl implements SyncApiClient {
  final InventoryRepository inventoryRepository;
  final AdminRepository adminRepository;
  final AppDatabase database;

  SyncApiClientImpl({required this.inventoryRepository, required this.adminRepository, required this.database,});

  @override
  Future<void> pushEntity({
    required SyncEntityType entityType,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    switch (entityType) {
      case SyncEntityType.inventoryRecord:
        await _pushRecord(operation, payload);
        break;
      case SyncEntityType.inventory:
        await _pushInventory(operation, payload);
        break;
    }
  }

  Future<void> _pushRecord(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    if (operation == SyncOperation.delete) {
      final response = await inventoryRepository.deleteInventoryRecord(
        payload['inventCode'] as String,
        payload['inventUnitizer'] as String? ?? '',
        payload['inventLocation'] as String? ?? '',
        payload['inventBarcode'] as String? ?? '',
      );
      if (!response.success) throw Exception(response.message);
      return;
    }

    debugPrint('🐛🐛🐛🐛🐛  Dados Completos do record: $payload');

    // insert ou update
    final batch = InventoryBatchRequest(
      inventGuid: payload['inventGuid'] as String? ?? '',
      inventCode: payload['inventCode'] as String,
      records: [InventoryRecordModel.fromMap(payload)],
    );
    final response =
        await inventoryRepository.createOrUpdateInventoryRecords([batch]);
    if (!response.success) throw Exception(response.message);
  }

  /*
  Future<void> _pushInventory(Map<String, dynamic> payload) async {
    final response = await inventoryRepository.createOrUpdateInventory(InventoryModel.fromMap(payload));
    if (!response.success) throw Exception(response.message);
  }*/

  /*
  Future<void> _pushInventory(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    if (operation == SyncOperation.delete) {
      final response = await inventoryRepository.deleteInventory(
        payload['inventCode'] as String,
      );
      if (!response.success) throw Exception(response.message);
      return;
    }

    // insert ou update
    final response = await inventoryRepository.createOrUpdateInventory(
      InventoryModel.fromMap(payload),
    );
    if (!response.success) throw Exception(response.message);
  }
  */

  Future<void> _pushInventory(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    final inventCode = payload['inventCode'] as String;
    //final inventGuid = payload['inventGuid'] as String;

    if (operation == SyncOperation.delete) {
      final response = await inventoryRepository.deleteInventory(inventCode);
      if (!response.success) throw Exception(response.message);
      return;
    }

    // Busca do banco local
    final row = await (database.select(database.inventory)
          ..where((t) => t.inventCode.equals(inventCode)))
        .getSingleOrNull();

    if (row != null) {
      debugPrint('📦 📦 📦 📦 📦 📦 📦 ****************DADOS DO BANCO: ${row.toJson()}');
    } else {
      debugPrint('📦 📦 📦 📦 📦 📦 📦 **********DADOS DO BANCO: Nenhum registro encontrado para o código $inventCode');
    }

    if (row == null) throw Exception('Inventário não encontrado localmente: $inventCode');

    final response = await inventoryRepository.createOrUpdateInventory(
      InventoryModel.fromLocal(row),
    );
    if (!response.success) throw Exception(response.message);
  }

  @override
  Future<bool> hasRealConnection() async {
    try {
      final response = await adminRepository.apiClient.getAuth('User/api'); 
      debugPrint('📦 📦 📦 📦 📦 📦 📦 RETORNO API: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

}