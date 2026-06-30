import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:oxdata/db/app_database.dart';
import 'package:oxdata/db/daos/sync_queue_dao.dart';
import 'package:oxdata/db/tables/sync_queue.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/models/dto/status_result.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Repositório de InventoryRecords demonstrando o padrão Outbox.
class InventoryRecordsRepository {
  final AppDatabase db;
  final SyncQueueDao queueDao;

  InventoryRecordsRepository(this.db, this.queueDao);

  /// Método utilitário privado para recalcular e persistir o total acumulado do inventário.
  Future<void> _recalculateAndSubtotal(String inventCode) async {
    final allRecords = await (db.select(db.inventoryRecords)
          ..where((t) => t.inventCode.equals(inventCode))).get();

    final newTotal = allRecords.fold<double>( 0.0, (sum, r) => sum + (r.inventTotal ?? 0.0), );

    await (db.update(db.inventory)
          ..where((t) => t.inventCode.equals(inventCode)))
        .write(InventoryCompanion(inventTotal: Value(newTotal)));
  }

  /// Cria ou atualiza uma contagem de inventário localmente e marca para sincronização.
  /*
  Future<InventoryRecord> upsertRecord({
    required String inventCode,
    required String inventGuid,
    required String inventProduct,
    String? inventBarcode,
    String? inventUnitizer,
    String? inventLocation,
    int? inventStandardStack,
    int? inventQtdStack,
    double? inventQtdIndividual,
    double? inventTotal,
  }) async {
    return db.transaction(() async {
      // Grava/atualiza localmente
      final id = await db.into(db.inventoryRecords).insertOnConflictUpdate(
            InventoryRecordsCompanion.insert(
              inventCode:           inventCode,
              inventProduct:        inventProduct,
              inventBarcode:        Value(inventBarcode),
              inventUnitizer:       Value(inventUnitizer),
              inventLocation:       Value(inventLocation),
              inventStandardStack:  Value(inventStandardStack),
              inventQtdStack:       Value(inventQtdStack),
              inventQtdIndividual:  Value(inventQtdIndividual),
              inventTotal:          Value(inventTotal),
              isSynced:             const Value(false),
            ),
          );

      final row = await (db.select(db.inventoryRecords)
            ..where((t) => t.id.equals(id)))
          .getSingle();

      // Recalcula o total reaproveitando o método centralizado
      await _recalculateAndSubtotal(inventCode);

      // Enfileira para envio à API 
      await queueDao.enqueue(
        entityType: SyncEntityType.inventoryRecord,
        entityId:   row.id,
        inventGuid: inventGuid,
        inventCode: row.inventCode,
        operation:  SyncOperation.update,
        payload:    jsonEncode({
          'inventCode':           row.inventCode,
          'inventProduct':        row.inventProduct,
          'inventBarcode':        row.inventBarcode,
          'inventUnitizer':       row.inventUnitizer,
          'inventLocation':       row.inventLocation,
          'inventStandardStack':  row.inventStandardStack,
          'inventQtdStack':       row.inventQtdStack,
          'inventQtdIndividual':  row.inventQtdIndividual,
          'inventTotal':          row.inventTotal,
        }),
      );

      return row;
    });
  }
  */

  Future<InventoryRecord> upsertRecord({
    required String inventCode,
    required String inventGuid,
    required String inventProduct,
    String? inventBarcode,
    String? inventUnitizer,
    String? inventLocation,
    int? inventStandardStack,
    int? inventQtdStack,
    double? inventQtdIndividual,
    double? inventTotal,
  }) async {
    final FlutterSecureStorage _storage = const FlutterSecureStorage();
    final username = await _storage.read(key: 'username');

    return db.transaction(() async {
      // Grava/atualiza localmente usando a unique key composta como target
      await db.into(db.inventoryRecords).insert(
        InventoryRecordsCompanion.insert(
          inventCode:          inventCode,
          inventProduct:       inventProduct,
          inventBarcode:       Value(inventBarcode),
          inventUnitizer:      Value(inventUnitizer),
          inventLocation:      Value(inventLocation),
          inventStandardStack: Value(inventStandardStack),
          inventQtdStack:      Value(inventQtdStack),
          inventQtdIndividual: Value(inventQtdIndividual),
          inventTotal:         Value(inventTotal),
          isSynced:            const Value(false),
          inventUser:          Value(username),
          inventCreated:       Value(DateTime.now()),
        ),
        onConflict: DoUpdate(
          (old) => InventoryRecordsCompanion.custom(
            inventBarcode:       Variable(inventBarcode),
            inventStandardStack: Variable(inventStandardStack),
            inventQtdStack:      Variable(inventQtdStack),
            inventQtdIndividual: Variable(inventQtdIndividual),
            inventTotal:         Variable(inventTotal),
            isSynced:            const Variable(false),
          ),
          target: [
            db.inventoryRecords.inventCode,
            db.inventoryRecords.inventUnitizer,
            db.inventoryRecords.inventLocation,
            db.inventoryRecords.inventProduct,
          ],
        ),
      );

      // Busca pela chave de negócio — garante o row correto após insert ou update
      final row = await (db.select(db.inventoryRecords)
            ..where((t) =>
                t.inventCode.equals(inventCode) &
                t.inventProduct.equals(inventProduct) &
                t.inventUnitizer.equals(inventUnitizer ?? '') &
                t.inventLocation.equals(inventLocation ?? '')))
          .getSingle();

      // Recalcula o total reaproveitando o método centralizado
      await _recalculateAndSubtotal(inventCode);

      // Enfileira para envio à API
      await queueDao.enqueue(
        entityType: SyncEntityType.inventoryRecord,
        entityId:   row.id,
        inventGuid: inventGuid,
        inventCode: row.inventCode,
        operation:  SyncOperation.update,
        payload:    jsonEncode({
          'inventCode':          row.inventCode,
          'inventProduct':       row.inventProduct,
          'inventBarcode':       row.inventBarcode,
          'inventUnitizer':      row.inventUnitizer,
          'inventLocation':      row.inventLocation,
          'inventStandardStack': row.inventStandardStack,
          'inventQtdStack':      row.inventQtdStack,
          'inventQtdIndividual': row.inventQtdIndividual,
          'inventTotal':         row.inventTotal,
          'inventUser':          row.inventUser,
        }),
      );

      final inventoryRow = await (db.select(db.inventory)
            ..where((t) => t.inventCode.equals(inventCode)))
          .getSingle();

        // Enfileira o cabeçalho para não sincronizado
        await queueDao.enqueue(
          entityType: SyncEntityType.inventory,
          entityId:   inventoryRow.id,
          inventGuid: inventoryRow.inventGuid,
          inventCode: inventCode,
          operation:  SyncOperation.update,
          payload:    jsonEncode({
            'inventCode': inventCode,
            'inventGuid': inventoryRow.inventGuid,
          }),
        );

      return row;
    });
  }  

  /// Cria ou atualiza o cabeçalho do inventário localmente e marca para sincronização.
  Future<InventoryData> upsertInventory({
    required String inventCode,
    required String inventGuid,
    required String inventName,
    required InventoryStatus inventStatus,
    required SyncOperation operation,  // ← recebido por parâmetro
    String? inventSector,
    String? inventUser,
    DateTime? inventCreated,
    double? inventTotal,
  }) async {
    return db.transaction(() async {
      final rowid = await db.into(db.inventory).insertOnConflictUpdate(
        InventoryCompanion.insert(
          inventCode:    inventCode,
          inventGuid:    inventGuid,
          inventName:    inventName,
          inventStatus:  inventStatus,
          inventSector:  Value(inventSector),
          inventUser:    Value(inventUser),
          inventCreated: Value(inventCreated),
          inventTotal:   Value(inventTotal),
          isSynced:      const Value(false),
        ),
      );

      final row = await (db.select(db.inventory)
            ..where((t) => t.inventCode.equals(inventCode)))
          .getSingle();

      await queueDao.enqueue(
        entityType: SyncEntityType.inventory,
        entityId:   rowid,
        inventGuid: inventGuid,
        inventCode: inventCode,
        operation:  operation,  // ← usado aqui
        payload:    jsonEncode({}),
      );
      debugPrint('********** INSERIU JSON ********* : $inventCode -> Dados: ${row.toJson()}');
      return row;
    });
  }
  

  /// Exclusão local + enfileiramento do delete remoto.
  Future<void> deleteRecord(int id, {required String inventGuid}) async {
    await db.transaction(() async {
      final row = await (db.select(db.inventoryRecords)..where((t) => t.id.equals(id))).getSingleOrNull();

      if (row == null) return;

      await queueDao.enqueue(
        entityType: SyncEntityType.inventoryRecord,
        entityId:   id,
        inventGuid: inventGuid,
        inventCode: row.inventCode,
        operation:  SyncOperation.delete,
        deleted:    true,
        payload:    jsonEncode({
          'id':             id,
          'inventCode':     row.inventCode,
          'inventUnitizer': row.inventUnitizer,
          'inventLocation': row.inventLocation,
          'inventBarcode':  row.inventBarcode,
        }),
      );

      await (db.delete(db.inventoryRecords)..where((t) => t.id.equals(id))).go();

      // Recalcula o total após o delete reaproveitando o método centralizado
      await _recalculateAndSubtotal(row.inventCode);
    });
  }

  /// Finaliza um inventário localmente e enfileira tudo para sincronização.
  Future<StatusResult> finalizeInventory(String inventCode) async {
    try {
      await db.transaction(() async {
        // 1) Atualiza o cabeçalho: status = Finalizado, isSynced = false
        await (db.update(db.inventory)
              ..where((t) => t.inventCode.equals(inventCode)))
            .write(InventoryCompanion(
              inventStatus: Value(InventoryStatus.Finalizado),
              isSynced:     const Value(false),
            ));

        final inventoryRow = await (db.select(db.inventory)
              ..where((t) => t.inventCode.equals(inventCode)))
            .getSingle();

        // 2) Enfileira o cabeçalho
        await queueDao.enqueue(
          entityType: SyncEntityType.inventory,
          entityId:   inventoryRow.id,
          inventGuid: inventoryRow.inventGuid,
          inventCode: inventCode,
          operation:  SyncOperation.update,
          payload:    jsonEncode({
            'inventCode': inventCode,
            'inventGuid': inventoryRow.inventGuid,
          }),
        );

        // 3) Busca todos os records filhos
        final records = await (db.select(db.inventoryRecords)
              ..where((t) => t.inventCode.equals(inventCode)))
            .get();

        final now = DateTime.now();

        for (final record in records) {
          // 4) Atualiza cada record: isSynced = false, lastSyncAttempt = agora
          await (db.update(db.inventoryRecords)
                ..where((t) => t.id.equals(record.id)))
              .write(InventoryRecordsCompanion(
                isSynced:        const Value(false),
                lastSyncAttempt: Value(now),
              ));

          // 5) Enfileira cada record
          await queueDao.enqueue(
            entityType: SyncEntityType.inventoryRecord,
            entityId:   record.id,
            inventGuid: inventoryRow.inventGuid,
            inventCode: inventCode,
            operation:  SyncOperation.update,
            payload:    jsonEncode({
              'inventCode':          record.inventCode,
              'inventProduct':       record.inventProduct,
              'inventBarcode':       record.inventBarcode,
              'inventUnitizer':      record.inventUnitizer,
              'inventLocation':      record.inventLocation,
              'inventStandardStack': record.inventStandardStack,
              'inventQtdStack':      record.inventQtdStack,
              'inventQtdIndividual': record.inventQtdIndividual,
              'inventTotal':         record.inventTotal,
            }),
          );
        }
      });
    } catch (e) {
      debugPrint('❌ finalizeInventory: $e');
      return StatusResult(status: 0, message: 'Erro ao finalizar inventário: $e');
    }

    /*
    try {
      await syncManager.syncNow();
    } catch (e) {
      debugPrint('⚠️ finalizeInventory: sync falhou, será retentado: $e');
    }

    await refreshSelectedInventoryState(inventCode);
    notifyListeners();
    */   
     
    return StatusResult(status: 1, message: 'Inventário finalizado.');
  }

  /// Deleta um inventário inteiro, todos os seus records associados e enfileira as operações de exclusão na SyncQueue.
  Future<void> deleteInventoryWithRecords({
    required String inventCode, 
    required String inventGuid,
  }) async {
    await db.transaction(() async {
      // 1) Enfileira a deleção de todos os RECORDS deste inventário para a API
      final recordsToDelete = await (db.select(db.inventoryRecords)
            ..where((t) => t.inventCode.equals(inventCode)))
          .get();

      for (final record in recordsToDelete) {
        await queueDao.enqueue(
          entityType: SyncEntityType.inventoryRecord,
          entityId: record.id,
          inventGuid: inventGuid,
          inventCode: inventCode,
          operation: SyncOperation.delete,
          deleted: true,
          payload: jsonEncode({
            'id': record.id,
            'inventCode': record.inventCode,
          }),
        );
      }

      // Enfileira a deleção do INVENTÁRIO (Pai) para a API
      await queueDao.enqueue(
        entityType: SyncEntityType.inventory, 
        entityId: 0, 
        inventGuid: inventGuid,
        inventCode: inventCode,
        operation: SyncOperation.delete,
        deleted: true,
        payload: jsonEncode({
          'inventCode': inventCode,
          'inventGuid': inventGuid,
        }),
      );

      // 3) Deleta fisicamente os registros filhos do banco local
      await (db.delete(db.inventoryRecords)
            ..where((t) => t.inventCode.equals(inventCode)))
          .go();

      // 4) Deleta fisicamente o cabeçalho do inventário do banco local
      await (db.delete(db.inventory)
            ..where((t) => t.inventCode.equals(inventCode)))
          .go();
          
      // Nota: Não é necessário chamar _recalculateAndSubtotal aqui,
      // pois o inventário pai acabou de ser deletado completamente.
    });
  }
}

/*
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:oxdata/db/app_database.dart';
import 'package:oxdata/db/daos/sync_queue_dao.dart';
import 'package:oxdata/db/tables/sync_queue.dart';
import 'package:oxdata/db/tables/inventory_record.dart';

/// Repositório de InventoryRecords demonstrando o padrão Outbox.
///
/// PONTO CRÍTICO: a escrita na tabela de domínio e o enqueue na SyncQueue
/// acontecem dentro da MESMA transação (db.transaction). Se a gravação
/// local falhar, nada é enfileirado. Se o enqueue falhar, a gravação local
/// é desfeita (rollback). Isso elimina o cenário "gravei mas não vou
/// sincronizar nunca" sem precisar de nenhuma lógica extra de reconciliação.
class InventoryRecordsRepository {
  final AppDatabase db;
  final SyncQueueDao queueDao;

  InventoryRecordsRepository(this.db, this.queueDao);

  /// Cria ou atualiza uma contagem de inventário localmente e marca
  /// para sincronização.
  Future<InventoryRecord> upsertRecord({
    required String inventCode,
    required String inventGuid,
    required String inventProduct,
    String? inventBarcode,
    String? inventUnitizer,
    String? inventLocation,
    int? inventStandardStack,
    int? inventQtdStack,
    double? inventQtdIndividual,
    double? inventTotal,
  }) async {
    return db.transaction(() async {
      // 1) grava/atualiza localmente (fonte de verdade imediata para a UI)
      final id = await db.into(db.inventoryRecords).insertOnConflictUpdate(
            InventoryRecordsCompanion.insert(
              inventCode:           inventCode,
              inventProduct:        inventProduct,
              inventBarcode:        Value(inventBarcode),
              inventUnitizer:       Value(inventUnitizer),
              inventLocation:       Value(inventLocation),
              inventStandardStack:  Value(inventStandardStack),
              inventQtdStack:       Value(inventQtdStack),
              inventQtdIndividual:  Value(inventQtdIndividual),
              inventTotal:          Value(inventTotal),
              isSynced:             const Value(false),
            ),
          );

      final row = await (db.select(db.inventoryRecords)
            ..where((t) => t.id.equals(id)))
          .getSingle();

      // Recalcula o total do inventário somando todos os records
      final allRecords = await (db.select(db.inventoryRecords)
            ..where((t) => t.inventCode.equals(inventCode))).get();

      final newTotal = allRecords.fold<double>(0.0,(sum, r) => sum + (r.inventTotal ?? 0.0),);

      // Persiste o total atualizado no cabeçalho
      await (db.update(db.inventory)
            ..where((t) => t.inventCode.equals(inventCode)))
          .write(InventoryCompanion(inventTotal: Value(newTotal)));

      // Enfileira para envio à API (colapsa com qualquer pendência anterior
      // da mesma entidade — ver SyncQueueDao.enqueue)
      await queueDao.enqueue(
        entityType: SyncEntityType.inventoryRecord,
        entityId:   row.id,
        inventGuid: inventGuid,
        inventCode: row.inventCode,
        operation:  SyncOperation.update,
        payload:    jsonEncode({
          'inventCode':           row.inventCode,
          'inventProduct':        row.inventProduct,
          'inventBarcode':        row.inventBarcode,
          'inventUnitizer':       row.inventUnitizer,
          'inventLocation':       row.inventLocation,
          'inventStandardStack':  row.inventStandardStack,
          'inventQtdStack':       row.inventQtdStack,
          'inventQtdIndividual':  row.inventQtdIndividual,
          'inventTotal':          row.inventTotal,
        }),
      );

      return row;
    });
  }

  /// Exclusão local + enfileiramento do delete remoto.
  ///
  /// Note que o registro é removido da tabela de domínio IMEDIATAMENTE
  /// (a UI não deve mostrar algo que o usuário já apagou). A SyncQueue é
  /// quem guarda a "memória" de que esse delete ainda precisa ser
  /// replicado para a API.
  Future<void> deleteRecord(int id, {required String inventGuid}) async {
    await db.transaction(() async {
      final row = await (db.select(db.inventoryRecords)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();

      if (row == null) return;

      await queueDao.enqueue(
        entityType: SyncEntityType.inventoryRecord,
        entityId:   id,
        inventGuid: inventGuid,
        inventCode: row.inventCode,
        operation:  SyncOperation.delete,
        deleted:    true,
        payload:    jsonEncode({
          'id':             id,
          'inventCode':     row.inventCode,
          'inventUnitizer': row.inventUnitizer,
          'inventLocation': row.inventLocation,
          'inventBarcode':  row.inventBarcode,
        }),
      );

      await (db.delete(db.inventoryRecords)..where((t) => t.id.equals(id))).go();

      // Recalcula o total após o delete
      final remaining = await (db.select(db.inventoryRecords)
            ..where((t) => t.inventCode.equals(row.inventCode)))
          .get();

      final newTotal = remaining.fold<double>(
        0.0,
        (sum, r) => sum + (r.inventTotal ?? 0.0),
      );

      await (db.update(db.inventory)
            ..where((t) => t.inventCode.equals(row.inventCode)))
          .write(InventoryCompanion(inventTotal: Value(newTotal)));
    });
  }

  /// Deleta um inventário inteiro, todos os seus records associados
  /// e enfileira as operações de exclusão na SyncQueue.
  Future<void> deleteInventoryWithRecords({
    required String inventCode, 
    required String inventGuid,
  }) async {
    await db.transaction(() async {
      // 1) Enfileira a deleção de todos os RECORDS deste inventário para a API
      // Buscamos os records antes de deletar para termos os IDs para a fila
      final recordsToDelete = await (db.select(db.inventoryRecords)
            ..where((t) => t.inventCode.equals(inventCode)))
          .get();

      for (final record in recordsToDelete) {
        await queueDao.enqueue(
          entityType: SyncEntityType.inventoryRecord,
          entityId: record.id,
          inventGuid: inventGuid,
          inventCode: inventCode,
          operation: SyncOperation.delete,
          deleted: true,
          payload: jsonEncode({
            'id': record.id,
            'inventCode': record.inventCode,
          }),
        );
      }

      // 2) Enfileira a deleção do INVENTÁRIO (Pai) para a API
      await queueDao.enqueue(
        entityType: SyncEntityType.inventory, // Certifique-se que este enum existe
        entityId: 0, // Se não houver ID numérico sequencial para o pai, use 0 ou adapte conforme seu schema
        inventGuid: inventGuid,
        inventCode: inventCode,
        operation: SyncOperation.delete,
        deleted: true,
        payload: jsonEncode({
          'inventCode': inventCode,
          'inventGuid': inventGuid,
        }),
      );

      // 3) Deleta fisicamente os registros filhos do banco local
      await (db.delete(db.inventoryRecords)
            ..where((t) => t.inventCode.equals(inventCode)))
          .go();

      // 4) Deleta fisicamente o cabeçalho do inventário do banco local
      await (db.delete(db.inventory)
            ..where((t) => t.inventCode.equals(inventCode)))
          .go();
    });
  }

}

*/