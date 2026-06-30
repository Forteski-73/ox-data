// -----------------------------------------------------------
// db/app_database.dart
// -----------------------------------------------------------
//
//  - Lógica de negócio extraída para DAOs por domínio
//  - Streams reativos via watchTable() do Drift (evita polling)
//  - findProductByCode() sem duplicação de variantes
//  - insertOrUpdateInventoryRecordOffline() sem ramos mortos comentados
//  - recálculo do total via SUM do banco (fonte única de verdade)
//  - deleteRecordsByInventCode() separado em dois métodos explícitos
// -----------------------------------------------------------

// -----------------------------------------------------------
// db/app_database.dart
// -----------------------------------------------------------
//
//  - Lógica de negócio extraída para DAOs por domínio
//  - Streams reativos via watchTable() do Drift (evita polling)
//  - findProductByCode() sem duplicação de variantes
//  - insertOrUpdateInventoryRecordOffline() sem ramos mortos comentados
//  - recálculo do total via SUM do banco (fonte única de verdade)
//  - deleteRecordsByInventCode() separado em dois métodos explícitos
//  - Padrão Outbox transacional aplicado em modificações/exclusões de itens
// -----------------------------------------------------------

import 'dart:convert'; // <-- ADICIONADO PARA TRATAMENTO DE PAYLOADS JSON
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oxdata/app/core/models/dto/inventory_record_input.dart';
import 'package:oxdata/app/core/models/dto/mask_db_local.dart';
import 'package:oxdata/app/core/models/dto/product_db_local.dart';
import 'package:oxdata/app/core/models/dto/status_result.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';
import 'package:oxdata/db/tables/device_sync.dart';
import 'package:oxdata/db/tables/inventory.dart';
import 'package:oxdata/db/tables/inventory_mask.dart';
import 'package:oxdata/db/tables/inventory_record.dart';
import 'package:oxdata/db/tables/product.dart';

import 'package:oxdata/db/tables/sync_queue.dart'; // <-- ADICIONADO
import 'package:oxdata/db/daos/sync_queue_dao.dart'; // <-- ADICIONADO

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// DTO de resultado JOIN (record + nome do produto)
// ---------------------------------------------------------------------------

class InventoryRecordWithProduct {
  const InventoryRecordWithProduct(this.record, this.productName);

  final InventoryRecord record;
  final String? productName;
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [Products, DeviceSync, InventoryMask, Inventory, InventoryRecords, SyncQueue], 
  daos: [SyncQueueDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(syncQueue);
      }
    },
  );

  final _storage = const FlutterSecureStorage();

  // ── DAOs públicos (acesso opcional via composição) ──────────────────────
  late final productDao     = _ProductDao(this);
  late final inventoryDao   = _InventoryDao(this);
  late final recordDao      = _RecordDao(this);
  late final maskDao        = _MaskDao(this);
  late final syncQueueDao   = SyncQueueDao(this);

  // ── Atalhos mantidos para compatibilidade com código existente ───────────

  Future<void> clearProducts() => productDao.clearAll();
  Future<void> clearMasks() => maskDao.clearAll();

  Future<String?> saveProductsBatch(List<ProductLocal> list) =>
      productDao.saveBatch(list);

  Future<Product?> findProductByCode(String code) =>
      productDao.findByCode(code);

  Future<List<Product>> searchProducts(String query) =>
      productDao.search(query);

  Future<void> saveInventoryMasks(List<InventoryMaskLocal> list) =>
      maskDao.saveBatch(list);

  Future<List<InventoryMaskData>> getAllMasks() => maskDao.getAll();

  Future<List<InventoryMaskData>> masksByFieldName(MaskFieldName name) =>
      maskDao.byFieldName(name);

  Future<void> insertOrUpdateInventoryOffline(
    InventoryModel model, {
    bool synced = false,
  }) =>
      inventoryDao.upsert(model, synced: synced);

  Future<int> deleteRecordsByInventCode(String inventCode) =>
      recordDao.deleteByInventCode(inventCode);

  Future<void> deleteInventoryByCode(String inventCode) =>
      inventoryDao.deleteByCode(inventCode);

  Future<void> deleteRecordByKey({
    required String inventCode,
    required String unitizer,
    required String location,
    required String product,
  }) =>
      recordDao.deleteByKey(
        inventCode: inventCode,
        unitizer: unitizer,
        location: location,
        product: product,
      );

  Future<List<InventoryData>> getAllLocalInventories() =>
      inventoryDao.getAll();

  Future<List<InventoryData>> getPendingInventories() =>
      inventoryDao.getPending();

  Future<List<InventoryData>> getLocalInventories() =>
      inventoryDao.getAll();

  Future<List<InventoryData>> getPendingInventoryByCode(String code) =>
      inventoryDao.getPendingByCode(code);

  Future<void> markInventoryAsSynced(String inventCode) =>
      inventoryDao.markSynced(inventCode);

  Future<StatusResult> insertOrUpdateInventoryRecordOffline(
    InventoryModel inventoryModel,
    InventoryRecordInput input, {
    bool synced = false,
  }) => recordDao.upsert(inventoryModel, input, storage: _storage, synced: synced);

  Future<List<InventoryRecord>> getRecordsByInventory(String inventCode) =>
    recordDao.byInventCode(inventCode);

  Future<List<InventoryRecord>> getPendingRecords({String? inventCode}) =>
    recordDao.getPending(inventCode: inventCode);

  Future<void> markRecordAsSynced(int id) => recordDao.markSynced(id);

  Future<void> markInventoryAsUnsynced(String inventCode) =>
    inventoryDao.markUnsynced(inventCode);

  Future<void> deleteRecord(int id) => recordDao.deleteById(id);

  Future<InventoryRecord?> checkDuplicateRecord({
    required String inventCode,
    required String unitizer,
    required String position,
    required String product,
  }) =>
      recordDao.findDuplicate(
        inventCode: inventCode,
        unitizer: unitizer,
        position: position,
        product: product,
      );

  Future<List<InventoryRecordWithProduct>> getPendingRecordsWithDescription({
    String? inventCode,
  }) =>
      recordDao.getPendingWithProduct(inventCode: inventCode);
}

// ---------------------------------------------------------------------------
// DAO – Products
// ---------------------------------------------------------------------------

class _ProductDao {
  _ProductDao(this._db);

  final AppDatabase _db;

  Future<void> clearAll() => _db.delete(_db.products).go();

  Future<String?> saveBatch(List<ProductLocal> list) async {
    try {
      await _db.batch((b) {
        b.insertAll(
          _db.products,
          list.map(
            (p) => ProductsCompanion.insert(
              productId: p.productId,
              barcode: p.barcode,
              productName: p.productName,
              status: Value(p.status ?? true),
              lastSync: Value(DateTime.now()),
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Busca por código de barras ou ID interno, tentando variantes com/sem zero inicial.
  Future<Product?> findByCode(String code) async {
    if (code.isEmpty) return null;

    final variants = _buildBarcodeVariants(code);

    return (_db.select(_db.products)
          ..where(
            (p) => variants.fold<Expression<bool>>(
              const Constant(false),
              (prev, v) => prev | p.barcode.equals(v) | p.productId.equals(v),
            ),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<Product>> search(String query) {
    final pattern = '%$query%';
    return (_db.select(_db.products)
          ..where(
            (p) =>
                p.productId.like('$query%') |
                p.barcode.like(pattern) |
                p.productName.like(pattern),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.productId),
            (t) => OrderingTerm(expression: t.productName),
          ])
          ..limit(50))
        .get();
  }

  // Gera variantes sem duplicatas (com e sem zero à esquerda)
  static List<String> _buildBarcodeVariants(String code) {
    final withZero = code.startsWith('0') ? code : '0$code';
    final withoutZero = code.startsWith('0') ? code.substring(1) : code;
    return {code, withZero, withoutZero}.toList();
  }
}

// ---------------------------------------------------------------------------
// DAO – InventoryMask
// ---------------------------------------------------------------------------

class _MaskDao {
  _MaskDao(this._db);

  final AppDatabase _db;

  Future<void> clearAll() => _db.delete(_db.inventoryMask).go();

  Future<void> saveBatch(List<InventoryMaskLocal> list) async {
    await _db.batch((b) {
      b.insertAll(
        _db.inventoryMask,
        list.map(
          (m) => InventoryMaskCompanion.insert(
            maskId: m.maskId != null ? Value(m.maskId!) : const Value.absent(),
            fieldName: m.fieldName,
            fieldMask: m.fieldMask,
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<List<InventoryMaskData>> getAll() =>
      _db.select(_db.inventoryMask).get();

  Future<List<InventoryMaskData>> byFieldName(MaskFieldName name) =>
      (_db.select(_db.inventoryMask)
            ..where((t) => t.fieldName.equals(name.name)))
          .get();
}

// ---------------------------------------------------------------------------
// DAO – Inventory (cabeçalho)
// ---------------------------------------------------------------------------

class _InventoryDao {
  _InventoryDao(this._db);

  final AppDatabase _db;

  Future<void> upsert(InventoryModel model, {required bool synced}) async {
    try {
      await _db.into(_db.inventory).insertOnConflictUpdate(
            InventoryCompanion.insert(
              inventCode: model.inventCode,
              inventName: model.inventName,
              inventGuid: model.inventGuid,
              inventSector: Value(model.inventSector),
              inventCreated: Value(model.inventCreated),
              inventUser: Value(model.inventUser),
              inventStatus: model.inventStatus,
              inventTotal: Value(model.inventTotal),
              isSynced: Value(synced),
              lastSyncAttempt: Value(DateTime.now()),
            ),
          );

          // Se o inventário foi marcado como sincronizado,
          // todos os records filhos também devem ser marcados
          if (synced) {
            await (_db.update(_db.inventoryRecords)
                  ..where((t) => t.inventCode.equals(model.inventCode)))
                .write(
              InventoryRecordsCompanion(
                isSynced:        const Value(true),
                lastSyncAttempt: Value(DateTime.now()),
              ),
            );
            
            debugPrint('✅ Records do inventário ${model.inventCode} marcados como sincronizados.');
          }

    } catch (e, stack) {
      debugPrint('❌ Inventory.upsert: $e\n$stack');
      rethrow;
    }
  }

  Future<void> deleteByCode(String inventCode) =>
      (_db.delete(_db.inventory)
            ..where((t) => t.inventCode.equals(inventCode)))
          .go();

  Future<List<InventoryData>> getAll() => _db.select(_db.inventory).get();

  Future<List<InventoryData>> getPending() => 
      _db.select(_db.inventory).get();

  Future<List<InventoryData>> getPendingByCode(String code) =>
      (_db.select(_db.inventory)
            ..where((t) => t.inventCode.equals(code) & t.isSynced.equals(false)))
          .get();

  Future<void> markSynced(String inventCode) =>
      (_db.update(_db.inventory)
            ..where((t) => t.inventCode.equals(inventCode)))
          .write(
        InventoryCompanion(
          isSynced: const Value(true),
          lastSyncAttempt: Value(DateTime.now()),
        ),
      );

  Future<void> markUnsynced(String inventCode) =>
      (_db.update(_db.inventory)
            ..where((t) => t.inventCode.equals(inventCode)))
          .write(
        InventoryCompanion(
          isSynced: const Value(false),
          lastSyncAttempt: Value(DateTime.now()),
        ),
      );

  /// Atualiza apenas o total do inventário (pós recálculo de records)
  Future<void> updateTotal(String inventCode, double total) =>
      (_db.update(_db.inventory)
            ..where((t) => t.inventCode.equals(inventCode)))
          .write(InventoryCompanion(inventTotal: Value(total)));

  /// Stream reativo: reemite sempre que a tabela inventory mudar.
  Stream<List<InventoryData>> watch() => _db.select(_db.inventory).watch();

  /// Stream reativo para um inventário específico.
  Stream<InventoryData?> watchByCode(String inventCode) =>
      (_db.select(_db.inventory)
            ..where((t) => t.inventCode.equals(inventCode)))
          .watchSingleOrNull();
}

// ---------------------------------------------------------------------------
// DAO – InventoryRecords (itens)
// ---------------------------------------------------------------------------

class _RecordDao {
  _RecordDao(this._db);

  final AppDatabase _db;

  /// Upsert principal com padrão Outbox: grava no banco de domínio e insere na SyncQueue
  /// de forma estritamente transacional (Rollback automático se um dos dois falhar).
  Future<StatusResult> upsert(
    InventoryModel inventoryModel,
    InventoryRecordInput input, {
    required FlutterSecureStorage storage,
    bool synced = false,
  }) async {
    return _db.transaction(() async {
      try {
        final total = ((input.qtdPorPilha ?? 0) * (input.numPilhas ?? 0)) + (input.qtdAvulsa ?? 0);
        final username = await storage.read(key: 'username');

        final product = await _db.productDao.findByCode(input.product);
        if (product == null) {
          return StatusResult(status: 0, message: 'Produto não encontrado: ${input.product}');
        }

        final existing = await findDuplicate(
          inventCode: inventoryModel.inventCode,
          unitizer: input.unitizer,
          position: input.position,
          product: input.product,
        );

        int recordId;

        if (existing != null) {
          recordId = existing.id;
          await (_db.update(_db.inventoryRecords)
                ..where((t) => t.id.equals(existing.id)))
              .write(
            InventoryRecordsCompanion(
              inventCreated: Value(DateTime.now()),
              inventUser: Value(username),
              inventStandardStack: Value((input.qtdPorPilha ?? 0).toInt()),
              inventQtdStack: Value((input.numPilhas ?? 0).toInt()),
              inventQtdIndividual: Value(input.qtdAvulsa),
              inventTotal: Value(total),
              isSynced: Value(synced),
              lastSyncAttempt: Value(DateTime.now()),
            ),
          );
        } else {
          recordId = await _db.into(_db.inventoryRecords).insert(
                InventoryRecordsCompanion.insert(
                  inventCode: inventoryModel.inventCode,
                  inventCreated: Value(DateTime.now()),
                  inventUser: Value(username),
                  inventUnitizer: Value(input.unitizer),
                  inventLocation: Value(input.position),
                  inventProduct: product.productId,
                  inventBarcode: Value(product.barcode),
                  inventStandardStack: Value((input.qtdPorPilha ?? 0).toInt()),
                  inventQtdStack: Value((input.numPilhas ?? 0).toInt()),
                  inventQtdIndividual: Value(input.qtdAvulsa),
                  inventTotal: Value(total),
                  isSynced: Value(synced),
                  lastSyncAttempt: Value(DateTime.now()),
                ),
              );
        }

        await _recalculateInventoryTotal(inventoryModel.inventCode);

        // Se NÃO for uma carga retroativa já sincronizada, agrava a fila outbox
        if (!synced) {
          await _db.syncQueueDao.enqueue(
            entityType: SyncEntityType.inventoryRecord,
            entityId: recordId,
            inventGuid: inventoryModel.inventGuid,
            inventCode: inventoryModel.inventCode,
            operation: SyncOperation.update,
            payload: jsonEncode({
              'inventCode': inventoryModel.inventCode,
              'inventProduct': product.productId,
              'inventUnitizer': input.unitizer,
              'inventLocation': input.position,
              'inventTotal': total,
              'inventBarcode': product.barcode,
              'inventQtdStack': input.numPilhas,
              'inventQtdIndividual': input.qtdAvulsa,
            }),
          );
        }

        return StatusResult(status: 1, message: 'Registro salvo com sucesso.');
      } catch (e) {
        debugPrint('❌ RecordDao.upsert: $e');
        return StatusResult(status: 0, message: 'Erro: $e');
      }
    });
  }

  Future<List<InventoryRecord>> byInventCode(String inventCode) =>
      (_db.select(_db.inventoryRecords)
            ..where((t) => t.inventCode.equals(inventCode)))
          .get();

  Future<List<InventoryRecord>> getPending({String? inventCode}) {
    final q = _db.select(_db.inventoryRecords);
    
    if (inventCode != null) {
      q.where((t) => t.inventCode.equals(inventCode));
    }
    
    return q.get();
  }

  Future<void> markSynced(int id) =>
      (_db.update(_db.inventoryRecords)..where((t) => t.id.equals(id))).write(
        InventoryRecordsCompanion(
          isSynced: const Value(true),
          lastSyncAttempt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteById(int id) =>
      (_db.delete(_db.inventoryRecords)..where((t) => t.id.equals(id))).go();

  Future<int> deleteByInventCode(String inventCode) =>
      (_db.delete(_db.inventoryRecords)
            ..where((t) => t.inventCode.equals(inventCode)))
          .go();

  /// Exclusão local estruturada com Outbox remota sob mesma transação
  Future<void> deleteByKey({
    required String inventCode,
    required String unitizer,
    required String location,
    required String product,
  }) async {
    await _db.transaction(() async {
      final existing = await findDuplicate(
        inventCode: inventCode,
        unitizer: unitizer,
        position: location,
        product: product,
      );

      if (existing == null) return;

      // 1) Registra na fila de sincronização que o item deve ser apagado remotamente
      await _db.syncQueueDao.enqueue(
        entityType: SyncEntityType.inventoryRecord,
        entityId: existing.id,
        inventGuid: '', 
        inventCode: inventCode,
        operation: SyncOperation.delete,
        deleted: true,
        payload: jsonEncode({
          'inventCode': inventCode,
          'inventUnitizer': unitizer,
          'inventLocation': location,
          'inventProduct': existing.inventProduct,
        }),
      );

      // 2) Executa o delete físico local na tabela de domínio
      await (_db.delete(_db.inventoryRecords)
            ..where((t) => t.id.equals(existing.id)))
          .go();

      await _recalculateInventoryTotal(inventCode);
    });
  }

  /// Verifica duplicata pelo trio (unitizer, location, product).
  Future<InventoryRecord?> findDuplicate({
    required String inventCode,
    required String unitizer,
    required String position,
    required String product,
  }) async {
    final productLocal = await _db.productDao.findByCode(product);
    if (productLocal == null) return null;

    final results = await (_db.select(_db.inventoryRecords)
          ..where(
            (t) =>
                t.inventCode.equals(inventCode) &
                t.inventUnitizer.equals(unitizer) &
                t.inventLocation.equals(position) &
                t.inventProduct.equals(productLocal.productId),
          ))
        .get();

    if (results.length > 1) {
      debugPrint('⚠️ ${results.length} duplicatas no banco para $inventCode/$unitizer/$position');
    }

    return results.isNotEmpty ? results.last : null;
  }

  /// JOIN records + products para obter nome do produto sem N+1 queries.
  Future<List<InventoryRecordWithProduct>> getPendingWithProduct({
    String? inventCode,
  }) async {
    final q = _db.select(_db.inventoryRecords).join([
      leftOuterJoin(
        _db.products,
        _db.products.productId.equalsExp(_db.inventoryRecords.inventProduct),
      ),
    ]);

    if (inventCode != null) {
      q.where(_db.inventoryRecords.inventCode.equals(inventCode));
    }

    return (await q.get())
        .map(
          (row) => InventoryRecordWithProduct(
            row.readTable(_db.inventoryRecords),
            row.readTableOrNull(_db.products)?.productName,
          ),
        )
        .toList();
  }

  /// Stream reativo dos records de um inventário.
  Stream<List<InventoryRecord>> watchByInventCode(String inventCode) =>
      (_db.select(_db.inventoryRecords)
            ..where((t) => t.inventCode.equals(inventCode)))
          .watch();

  // ── privado ──────────────────────────────────────────────────────────────

  /// Recalcula o total do inventário somando todos os records locais.
  Future<void> _recalculateInventoryTotal(String inventCode) async {
    final sumExpr = _db.inventoryRecords.inventTotal.sum();
    final query = _db.selectOnly(_db.inventoryRecords)
      ..addColumns([sumExpr])
      ..where(_db.inventoryRecords.inventCode.equals(inventCode));

    final row = await query.getSingle();
    final total = (row.read(sumExpr) ?? 0).toDouble();

    debugPrint('✅ Total recalculado para $inventCode: $total');

    await _db.inventoryDao.updateTotal(inventCode, total);
  }
}

// ---------------------------------------------------------------------------
// Conexão
// ---------------------------------------------------------------------------

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return driftDatabase(
      name: 'app.sqlite',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  });
}

/*
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oxdata/app/core/models/dto/inventory_record_input.dart';
import 'package:oxdata/app/core/models/dto/mask_db_local.dart';
import 'package:oxdata/app/core/models/dto/product_db_local.dart';
import 'package:oxdata/app/core/models/dto/status_result.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';
import 'package:oxdata/db/tables/device_sync.dart';
import 'package:oxdata/db/tables/inventory.dart';
import 'package:oxdata/db/tables/inventory_mask.dart';
import 'package:oxdata/db/tables/inventory_record.dart';
import 'package:oxdata/db/tables/product.dart';

import 'package:oxdata/db/tables/sync_queue.dart'; // <-- ADICIONADO
import 'package:oxdata/db/daos/sync_queue_dao.dart'; // <-- ADICIONADO

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// DTO de resultado JOIN (record + nome do produto)
// ---------------------------------------------------------------------------

class InventoryRecordWithProduct {
  const InventoryRecordWithProduct(this.record, this.productName);

  final InventoryRecord record;
  final String? productName;
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [Products, DeviceSync, InventoryMask, Inventory, InventoryRecords, SyncQueue], daos: [SyncQueueDao,],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(syncQueue);
      }
    },
  );

  final _storage = const FlutterSecureStorage();

  // ── DAOs públicos (acesso opcional via composição) ──────────────────────
  late final productDao     = _ProductDao(this);
  late final inventoryDao   = _InventoryDao(this);
  late final recordDao      = _RecordDao(this);
  late final maskDao        = _MaskDao(this);
  late final syncQueueDao   = SyncQueueDao(this);

  // ── Atalhos mantidos para compatibilidade com código existente ───────────

  Future<void> clearProducts() => productDao.clearAll();
  Future<void> clearMasks() => maskDao.clearAll();

  Future<String?> saveProductsBatch(List<ProductLocal> list) =>
      productDao.saveBatch(list);

  Future<Product?> findProductByCode(String code) =>
      productDao.findByCode(code);

  Future<List<Product>> searchProducts(String query) =>
      productDao.search(query);

  Future<void> saveInventoryMasks(List<InventoryMaskLocal> list) =>
      maskDao.saveBatch(list);

  Future<List<InventoryMaskData>> getAllMasks() => maskDao.getAll();

  Future<List<InventoryMaskData>> masksByFieldName(MaskFieldName name) =>
      maskDao.byFieldName(name);

  Future<void> insertOrUpdateInventoryOffline(
    InventoryModel model, {
    bool synced = false,
  }) =>
      inventoryDao.upsert(model, synced: synced);

  Future<int> deleteRecordsByInventCode(String inventCode) =>
      recordDao.deleteByInventCode(inventCode);

  Future<void> deleteInventoryByCode(String inventCode) =>
      inventoryDao.deleteByCode(inventCode);

  Future<void> deleteRecordByKey({
    required String inventCode,
    required String unitizer,
    required String location,
    required String product,
  }) =>
      recordDao.deleteByKey(
        inventCode: inventCode,
        unitizer: unitizer,
        location: location,
        product: product,
      );

  Future<List<InventoryData>> getAllLocalInventories() =>
      inventoryDao.getAll();

  Future<List<InventoryData>> getPendingInventories() =>
      inventoryDao.getPending();

  Future<List<InventoryData>> getLocalInventories() =>
      inventoryDao.getAll();

  Future<List<InventoryData>> getPendingInventoryByCode(String code) =>
      inventoryDao.getPendingByCode(code);

  Future<void> markInventoryAsSynced(String inventCode) =>
      inventoryDao.markSynced(inventCode);

  Future<StatusResult> insertOrUpdateInventoryRecordOffline(
    InventoryModel inventoryModel,
    InventoryRecordInput input, {
    bool synced = false,
  }) => recordDao.upsert(inventoryModel, input, storage: _storage, synced: synced);

  Future<List<InventoryRecord>> getRecordsByInventory(String inventCode) =>
      recordDao.byInventCode(inventCode);

  Future<List<InventoryRecord>> getPendingRecords({String? inventCode}) =>
      recordDao.getPending(inventCode: inventCode);

  Future<void> markRecordAsSynced(int id) => recordDao.markSynced(id);

  Future<void> deleteRecord(int id) => recordDao.deleteById(id);

  Future<InventoryRecord?> checkDuplicateRecord({
    required String inventCode,
    required String unitizer,
    required String position,
    required String product,
  }) =>
      recordDao.findDuplicate(
        inventCode: inventCode,
        unitizer: unitizer,
        position: position,
        product: product,
      );

  Future<List<InventoryRecordWithProduct>> getPendingRecordsWithDescription({
    String? inventCode,
  }) =>
      recordDao.getPendingWithProduct(inventCode: inventCode);
}

// ---------------------------------------------------------------------------
// DAO – Products
// ---------------------------------------------------------------------------

class _ProductDao {
  _ProductDao(this._db);

  final AppDatabase _db;

  Future<void> clearAll() => _db.delete(_db.products).go();

  Future<String?> saveBatch(List<ProductLocal> list) async {
    try {
      await _db.batch((b) {
        b.insertAll(
          _db.products,
          list.map(
            (p) => ProductsCompanion.insert(
              productId: p.productId,
              barcode: p.barcode,
              productName: p.productName,
              status: Value(p.status ?? true),
              lastSync: Value(DateTime.now()),
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Busca por código de barras ou ID interno, tentando variantes com/sem zero inicial.
  Future<Product?> findByCode(String code) async {
    if (code.isEmpty) return null;

    final variants = _buildBarcodeVariants(code);

    return (_db.select(_db.products)
          ..where(
            (p) => variants.fold<Expression<bool>>(
              const Constant(false),
              (prev, v) => prev | p.barcode.equals(v) | p.productId.equals(v),
            ),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<Product>> search(String query) {
    final pattern = '%$query%';
    return (_db.select(_db.products)
          ..where(
            (p) =>
                p.productId.like('$query%') |
                p.barcode.like(pattern) |
                p.productName.like(pattern),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.productId),
            (t) => OrderingTerm(expression: t.productName),
          ])
          ..limit(50))
        .get();
  }

  // Gera variantes sem duplicatas (com e sem zero à esquerda)
  static List<String> _buildBarcodeVariants(String code) {
    final withZero = code.startsWith('0') ? code : '0$code';
    final withoutZero = code.startsWith('0') ? code.substring(1) : code;
    return {code, withZero, withoutZero}.toList();
  }
}

// ---------------------------------------------------------------------------
// DAO – InventoryMask
// ---------------------------------------------------------------------------

class _MaskDao {
  _MaskDao(this._db);

  final AppDatabase _db;

  Future<void> clearAll() => _db.delete(_db.inventoryMask).go();

  Future<void> saveBatch(List<InventoryMaskLocal> list) async {
    await _db.batch((b) {
      b.insertAll(
        _db.inventoryMask,
        list.map(
          (m) => InventoryMaskCompanion.insert(
            maskId: m.maskId != null ? Value(m.maskId!) : const Value.absent(),
            fieldName: m.fieldName,
            fieldMask: m.fieldMask,
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<List<InventoryMaskData>> getAll() =>
      _db.select(_db.inventoryMask).get();

  Future<List<InventoryMaskData>> byFieldName(MaskFieldName name) =>
      (_db.select(_db.inventoryMask)
            ..where((t) => t.fieldName.equals(name.name)))
          .get();
}

// ---------------------------------------------------------------------------
// DAO – Inventory (cabeçalho)
// ---------------------------------------------------------------------------

class _InventoryDao {
  _InventoryDao(this._db);

  final AppDatabase _db;

  Future<void> upsert(InventoryModel model, {required bool synced}) async {
    try {
      await _db.into(_db.inventory).insertOnConflictUpdate(
            InventoryCompanion.insert(
              inventCode: model.inventCode,
              inventName: model.inventName,
              inventGuid: model.inventGuid,
              inventSector: Value(model.inventSector),
              inventCreated: Value(model.inventCreated),
              inventUser: Value(model.inventUser),
              inventStatus: model.inventStatus,
              inventTotal: Value(model.inventTotal),
              isSynced: Value(synced),
              lastSyncAttempt: Value(DateTime.now()),
            ),
          );

          // Se o inventário foi marcado como sincronizado,
          // todos os records filhos também devem ser marcados
          if (synced) {
            await (_db.update(_db.inventoryRecords)
                  ..where((t) => t.inventCode.equals(model.inventCode)))
                .write(
              InventoryRecordsCompanion(
                isSynced:        const Value(true),
                lastSyncAttempt: Value(DateTime.now()),
              ),
            );
            
            debugPrint('✅ Records do inventário ${model.inventCode} marcados como sincronizados.');
          }

    } catch (e, stack) {
      debugPrint('❌ Inventory.upsert: $e\n$stack');
      rethrow;
    }
  }

  Future<void> deleteByCode(String inventCode) =>
      (_db.delete(_db.inventory)
            ..where((t) => t.inventCode.equals(inventCode)))
          .go();

  Future<List<InventoryData>> getAll() => _db.select(_db.inventory).get();

  /*Future<List<InventoryData>> getPending() =>
      (_db.select(_db.inventory)..where((t) => t.isSynced.equals(false))).get();*/

  Future<List<InventoryData>> getPending() => 
      _db.select(_db.inventory).get();

  Future<List<InventoryData>> getPendingByCode(String code) =>
      (_db.select(_db.inventory)
            ..where((t) => t.inventCode.equals(code) & t.isSynced.equals(false)))
          .get();

  Future<void> markSynced(String inventCode) =>
      (_db.update(_db.inventory)
            ..where((t) => t.inventCode.equals(inventCode)))
          .write(
        InventoryCompanion(
          isSynced: const Value(true),
          lastSyncAttempt: Value(DateTime.now()),
        ),
      );

  /// Atualiza apenas o total do inventário (pós recálculo de records)
  Future<void> updateTotal(String inventCode, double total) =>
      (_db.update(_db.inventory)
            ..where((t) => t.inventCode.equals(inventCode)))
          .write(InventoryCompanion(inventTotal: Value(total)));

  /// Stream reativo: reemite sempre que a tabela inventory mudar.
  Stream<List<InventoryData>> watch() => _db.select(_db.inventory).watch();

  /// Stream reativo para um inventário específico.
  Stream<InventoryData?> watchByCode(String inventCode) =>
      (_db.select(_db.inventory)
            ..where((t) => t.inventCode.equals(inventCode)))
          .watchSingleOrNull();
}

// ---------------------------------------------------------------------------
// DAO – InventoryRecords (itens)
// ---------------------------------------------------------------------------

class _RecordDao {
  _RecordDao(this._db);

  final AppDatabase _db;

  /// Upsert principal: insere ou atualiza pelo trio (inventCode, unitizer, position, product).
  /// Recalcula o total do inventário pai via SUM após cada operação.
  Future<StatusResult> upsert(
    InventoryModel inventoryModel,
    InventoryRecordInput input, {
    required FlutterSecureStorage storage,
    bool synced = false,
  }) async {
    try {
      final total = ((input.qtdPorPilha ?? 0) * (input.numPilhas ?? 0)) + (input.qtdAvulsa ?? 0);
      final username = await storage.read(key: 'username');

      final product = await _db.productDao.findByCode(input.product);
      if (product == null) {
        return StatusResult(status: 0, message: 'Produto não encontrado: ${input.product}');
      }

      final existing = await findDuplicate(
        inventCode: inventoryModel.inventCode,
        unitizer: input.unitizer,
        position: input.position,
        product: input.product,
      );

      debugPrint('>>> upsert record: existing=${existing?.id}, total=$total');

      if (existing != null) {
        await (_db.update(_db.inventoryRecords)
              ..where((t) => t.id.equals(existing.id)))
            .write(
          InventoryRecordsCompanion(
            inventCreated: Value(DateTime.now()),
            inventUser: Value(username),
            inventStandardStack: Value((input.qtdPorPilha ?? 0).toInt()),
            inventQtdStack: Value((input.numPilhas ?? 0).toInt()),
            inventQtdIndividual: Value(input.qtdAvulsa),
            inventTotal: Value(total),
            isSynced: Value(synced),
            lastSyncAttempt: Value(DateTime.now()),
          ),
        );
      } else {
        await _db.into(_db.inventoryRecords).insert(
              InventoryRecordsCompanion.insert(
                inventCode: inventoryModel.inventCode,
                inventCreated: Value(DateTime.now()),
                inventUser: Value(username),
                inventUnitizer: Value(input.unitizer),
                inventLocation: Value(input.position),
                inventProduct: product.productId,
                inventBarcode: Value(product.barcode),
                inventStandardStack: Value((input.qtdPorPilha ?? 0).toInt()),
                inventQtdStack: Value((input.numPilhas ?? 0).toInt()),
                inventQtdIndividual: Value(input.qtdAvulsa),
                inventTotal: Value(total),
                isSynced: Value(synced),
                lastSyncAttempt: Value(DateTime.now()),
              ),
            );
      }

      await _recalculateInventoryTotal(inventoryModel.inventCode);

      return StatusResult(status: 1, message: 'Registro salvo com sucesso.');
    } catch (e) {
      debugPrint('❌ RecordDao.upsert: $e');
      return StatusResult(status: 0, message: 'Erro: $e');
    }
  }

  Future<List<InventoryRecord>> byInventCode(String inventCode) =>
      (_db.select(_db.inventoryRecords)
            ..where((t) => t.inventCode.equals(inventCode)))
          .get();

  Future<List<InventoryRecord>> getPending({String? inventCode}) {
    final q = _db.select(_db.inventoryRecords);
    
    if (inventCode != null) {
      q.where((t) => t.inventCode.equals(inventCode));
    }
    
    return q.get();
  }

  Future<void> markSynced(int id) =>
      (_db.update(_db.inventoryRecords)..where((t) => t.id.equals(id))).write(
        InventoryRecordsCompanion(
          isSynced: const Value(true),
          lastSyncAttempt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteById(int id) =>
      (_db.delete(_db.inventoryRecords)..where((t) => t.id.equals(id))).go();

  Future<int> deleteByInventCode(String inventCode) =>
      (_db.delete(_db.inventoryRecords)
            ..where((t) => t.inventCode.equals(inventCode)))
          .go();

  Future<void> deleteByKey({
    required String inventCode,
    required String unitizer,
    required String location,
    required String product,
  }) async {
    await (_db.delete(_db.inventoryRecords)
          ..where((t) =>
              t.inventCode.equals(inventCode) &
              t.inventUnitizer.equals(unitizer) &
              t.inventLocation.equals(location) &
              t.inventProduct.equals(product)))
        .go();

    await _recalculateInventoryTotal(inventCode);
  }

  /// Verifica duplicata pelo trio (unitizer, location, product).
  /// Retorna null se não encontrado; o último registro se houver múltiplos (aviso de inconsistência).
  Future<InventoryRecord?> findDuplicate({
    required String inventCode,
    required String unitizer,
    required String position,
    required String product,
  }) async {
    final productLocal = await _db.productDao.findByCode(product);
    if (productLocal == null) return null;

    final results = await (_db.select(_db.inventoryRecords)
          ..where(
            (t) =>
                t.inventCode.equals(inventCode) &
                t.inventUnitizer.equals(unitizer) &
                t.inventLocation.equals(position) &
                t.inventProduct.equals(productLocal.productId),
          ))
        .get();

    if (results.length > 1) {
      debugPrint('⚠️ ${results.length} duplicatas no banco para $inventCode/$unitizer/$position');
    }

    return results.isNotEmpty ? results.last : null;
  }

  /// JOIN records + products para obter nome do produto sem N+1 queries.
  Future<List<InventoryRecordWithProduct>> getPendingWithProduct({
    String? inventCode,
  }) async {
    final q = _db.select(_db.inventoryRecords).join([
      leftOuterJoin(
        _db.products,
        _db.products.productId.equalsExp(_db.inventoryRecords.inventProduct),
      ),
    ]);
      //..where(_db.inventoryRecords.isSynced.equals(false));

    if (inventCode != null) {
      q.where(_db.inventoryRecords.inventCode.equals(inventCode));
    }

    return (await q.get())
        .map(
          (row) => InventoryRecordWithProduct(
            row.readTable(_db.inventoryRecords),
            row.readTableOrNull(_db.products)?.productName,
          ),
        )
        .toList();
  }

  /// Stream reativo dos records de um inventário.
  Stream<List<InventoryRecord>> watchByInventCode(String inventCode) =>
      (_db.select(_db.inventoryRecords)
            ..where((t) => t.inventCode.equals(inventCode)))
          .watch();

  // ── privado ──────────────────────────────────────────────────────────────

  /// Recalcula o total do inventário somando todos os records locais.
  /// Fonte única de verdade: o banco, não a memória.
  Future<void> _recalculateInventoryTotal(String inventCode) async {
    final sumExpr = _db.inventoryRecords.inventTotal.sum();
    final query = _db.selectOnly(_db.inventoryRecords)
      ..addColumns([sumExpr])
      ..where(_db.inventoryRecords.inventCode.equals(inventCode));

    final row = await query.getSingle();
    final total = (row.read(sumExpr) ?? 0).toDouble();

    debugPrint('✅ Total recalculado para $inventCode: $total');

    await _db.inventoryDao.updateTotal(inventCode, total);
  }
}

// ---------------------------------------------------------------------------
// Conexão
// ---------------------------------------------------------------------------

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return driftDatabase(
      name: 'app.sqlite',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  });
}

*/