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
  tables: [Products, DeviceSync, InventoryMask, Inventory, InventoryRecords],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  final _storage = const FlutterSecureStorage();

  // ── DAOs públicos (acesso opcional via composição) ──────────────────────
  late final productDao = _ProductDao(this);
  late final inventoryDao = _InventoryDao(this);
  late final recordDao = _RecordDao(this);
  late final maskDao = _MaskDao(this);

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

  /*
  Future<List<InventoryRecord>> getPending({String? inventCode}) {
    final q = _db.select(_db.inventoryRecords)
      ..where((t) => t.isSynced.equals(false));
    if (inventCode != null) {
      q.where((t) => t.inventCode.equals(inventCode));
    }
    return q.get();
  }
  */

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


/*
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/product.dart';
import 'tables/device_sync.dart';
import 'tables/inventory_mask.dart';
import 'tables/inventory.dart';
import 'tables/inventory_record.dart';
import 'package:oxdata/app/core/models/dto/product_db_local.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/app/core/models/dto/mask_db_local.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';
import 'package:oxdata/app/core/models/dto/inventory_record_input.dart';
import 'package:oxdata/app/core/models/dto/status_result.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
part 'app_database.g.dart';

// Classe para adicionar o nomedo produto na lista para mostrar natela
class InventoryRecordWithProduct {
  final InventoryRecord record;
  final String? productName;

  InventoryRecordWithProduct(this.record, this.productName);
}

@DriftDatabase(
  tables: [
    Products,
    DeviceSync,
    InventoryMask,
    Inventory,
    InventoryRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;


  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // --- MÉTODO PARA LIMPAR PRODUTOS ANTES DA SINCRONIZAÇÃO ---
  Future<void> clearProducts() => delete(products).go();
  Future<void> clearMasks() => delete(inventoryMask).go();

  // ----------------------------------------------------------------------
  // MÉTODO DE GRAVAÇÃO EM LOTE (BATCH INSERT)
  // ----------------------------------------------------------------------
  Future<String?> saveProductsBatch(List<ProductLocal> productsList) async {
    try {
      await batch((b) {
        b.insertAll(
          products,
          productsList.map((p) => ProductsCompanion.insert(
            productId: p.productId,
            barcode: p.barcode,
            productName: p.productName,
            status: Value(p.status ?? true),
            lastSync: Value(DateTime.now()),
          )).toList(),
          mode: InsertMode.insertOrReplace,
        );
      });
      return null; // Retorna null se for sucesso
    } catch (e) {
      return e.toString(); // Retorna a mensagem de erro se falhar
    }
  }
  /*
  Future<Product?> findProductByCode(String code) {
    return (select(products)
          ..where((p) => p.barcode.equals(code) | p.productId.equals(code)))
        .getSingleOrNull();
  }
  */

  Future<Product?> findProductByCode(String code) async {
    final String codeWithZero    = code.startsWith('0') ? code : '0$code';
    final String codeWithoutZero = code.startsWith('0') ? code.substring(1) : code;

    return (select(products)
          ..where((p) =>
              p.barcode.equals(code) |
              p.barcode.equals(codeWithZero) |
              p.barcode.equals(codeWithoutZero) |
              p.productId.equals(code) |
              p.productId.equals(codeWithoutZero)))
        .getSingleOrNull();
  }

  // --- PESQUISA GLOBAL (LIKE) EM MÚLTIPLOS CAMPOS ---
  Future<List<Product>> searchProducts(String query) {
    // Definimos o padrão de busca como %texto%
    final pattern = '%$query%';
    final startPattern = '$query%';
    return (select(products)
          ..where((p) =>
              p.productId.like(startPattern) |
              p.barcode.like(pattern) |
              p.productName.like(pattern))
          ..orderBy([
              (t) => OrderingTerm(expression: t.productId, mode: OrderingMode.asc),
              (t) => OrderingTerm(expression: t.productName, mode: OrderingMode.asc),
          ])
          ..limit(50)) // Limite opcional para performance na UI
        .get();
  }

  // ----------------------------------------------------------------------
  // MÉTODOS PARA INVENTORY MASK
  // ----------------------------------------------------------------------
  /// Grava a lista de máscaras vinda da API no banco local.
  /// Recebe uma lista de [InventoryMaskLocal] (seu modelo de DTO/Sincronização).
  Future<void> saveInventoryMasks(List<InventoryMaskLocal> maskList) async {
    await batch((b) {
      b.insertAll(
        inventoryMask, // Nome da tabela gerada pelo Drift
        maskList.map((m) => InventoryMaskCompanion.insert(
          // Mapeamos o id da API para o maskId da tabela
          maskId: m.maskId != null ? Value(m.maskId!) : const Value.absent(),
          fieldName: m.fieldName,
          fieldMask: m.fieldMask,
        )).toList(),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  // Método para limpar as máscaras (caso precise resetar antes de sincronizar)
  //Future<void> clearInventoryMasks() => delete(inventoryMask).go();
  // Método para buscar todas as máscaras do banco local
  Future<List<InventoryMaskData>> getAllMasks() => select(inventoryMask).get();

  Future<List<InventoryMaskData>> masksByFieldName(MaskFieldName name) {
    return (select(inventoryMask)..where((tbl) => tbl.fieldName.equals(name.name))).get();
  }

  // ----------------------------------------------------------------------
  // INVENTORY (OFFLINE)
  // ----------------------------------------------------------------------

Future<void> insertOrUpdateInventoryOffline(
  InventoryModel model, {
  bool synced = false,
}) async {
  try {
    await into(inventory).insertOnConflictUpdate(
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

    print('Inventory salvo/atualizado offline com sucesso');
  } catch (e, stack) {
    print('Erro ao salvar Inventory offline: $e');
    print(stack);
    rethrow; // 👈 ESSENCIAL
  }
}

  // deleta contagens
  /*Future<int> deleteRecordsByInventCode(String inventCode) {
    return (delete(inventoryRecords)
          ..where((tbl) => tbl.inventCode.equals(inventCode)))
        .go();
  }*/

  Future<int> deleteRecordsByInventCode(String inventCode) async {
    final deletedRecords = await (delete(inventoryRecords)
          ..where((tbl) => tbl.inventCode.equals(inventCode)))
        .go();

    await (delete(inventory)
          ..where((tbl) => tbl.inventCode.equals(inventCode)))
        .go();

    return deletedRecords;
  }

  Future<List<InventoryData>> getAllLocalInventories() {
    return select(inventory).get();
  }

  // Buscar inventários pendentes de sync
  Future<List<InventoryData>> getPendingInventories() {
    return (select(inventory)
          ..where((tbl) => tbl.isSynced.equals(false)))
        .get();
  }

    // Buscar todos os inventários localmente
  Future<List<InventoryData>> getLocalInventories() {
    return select(inventory).get();
  }

  /// Busca um inventário específico pelo código, desde que não esteja sincronizado
  Future<List<InventoryData>> getPendingInventoryByCode(String inventCode) {
    return (select(inventory)
          ..where((tbl) => 
            tbl.inventCode.equals(inventCode) & 
            tbl.isSynced.equals(false)
          ))
        .get();
  }

  // Marcar como sincronizado após sucesso na API
  Future<void> markInventoryAsSynced(String inventCode) {
    return (update(inventory)
          ..where((tbl) => tbl.inventCode.equals(inventCode)))
        .write(
      InventoryCompanion(
        isSynced: const Value(true),
        lastSyncAttempt: Value(DateTime.now()),
      ),
    );
  }

  /*
  Future<StatusResult> insertOrUpdateInventoryRecordOffline(
    InventoryModel inventoryModel,
    InventoryRecordInput input, {
    bool synced = false,
  }) async {
    try {
      final total = ((input.qtdPorPilha ?? 0) * (input.numPilhas ?? 0)) + (input.qtdAvulsa ?? 0);
      final username = await _storage.read(key: 'username');

      final productLocal = await findProductByCode(input.product);
      if (productLocal == null) {
        return StatusResult(status: 0, message: 'Produto não encontrado');
      }

      // 1. TENTAMOS ENCONTRAR O ID DO REGISTRO QUE JÁ ESTÁ LÁ
      // Usando o método que criamos que retorna o .last ou .single
      final existing = await checkDuplicateRecord(
        inventCode: inventoryModel.inventCode,
        unitizer: input.unitizer,
        position: input.position,
        product: input.product,
      );
      
      debugPrint("***************************************************** EXISTE ${existing?.id}");

      // 2. CRIAMOS O COMPANION
      final companion = InventoryRecordsCompanion.insert(
        // SE existir um ID no banco, passamos ele aqui. 
        // Isso força o Drift a fazer UPDATE em vez de INSERT.
        id: existing != null ? Value(existing.id) : const Value.absent(), 
        inventCode: inventoryModel.inventCode,
        inventCreated: Value(DateTime.now()),
        inventUser: Value(username),
        inventUnitizer: Value(input.unitizer),
        inventLocation: Value(input.position),
        inventProduct: productLocal.productId,
        inventBarcode: Value(productLocal.barcode),
        inventStandardStack: Value((input.qtdPorPilha ?? 0).toInt()),
        inventQtdStack: Value((input.numPilhas ?? 0).toInt()),
        inventQtdIndividual: Value(input.qtdAvulsa),
        inventTotal: Value(total),
        isSynced: Value(synced),
        lastSyncAttempt: Value(DateTime.now()),
      );

      // 3. AGORA O CONFLITO SERÁ PELO 'ID' E VAI ATUALIZAR
      await into(inventoryRecords).insertOnConflictUpdate(companion);


        // 5. CALCULA O SUM E ATUALIZA A TABELA INVENTORY
        // Criamos uma expressão de soma para a coluna inventTotal da tabela inventoryRecords
        var totalSumExpression = inventoryRecords.inventTotal.sum();

        if (inventoryModel.isSynced ?? false)
        {
          totalSumExpression = totalSumExpression + Variable(inventoryModel.inventTotal ?? 0.0);

        }

        final query = selectOnly(inventoryRecords)
          ..addColumns([totalSumExpression])
          ..where(inventoryRecords.inventCode.equals(inventoryModel.inventCode));

        // Executamos a query para obter o resultado do SUM
        final row = await query.getSingle();
        final totalGeral = row.read(totalSumExpression) ?? 0;

        // Agora atualizamos o inventário pai com o valor real recalculado do banco
        await (update(inventory)
              ..where((tbl) => tbl.inventCode.equals(inventoryModel.inventCode)))
            .write(
          InventoryCompanion(
            inventTotal: Value(totalGeral.toDouble()), // Garanta que o tipo combine (double/int)
            //lastSyncAttempt: Value(DateTime.now()),
          ),
        );

        debugPrint("✅ Total Geral do Inventário recalculado: $totalGeral");

      return StatusResult(status: 1, message: 'Registro atualizado com sucesso.');

    } catch (e) {
      return StatusResult(status: 0, message: 'Erro: $e');
    }
  }
  */

  /*
  Future<StatusResult> insertOrUpdateInventoryRecordOffline(
  InventoryModel inventoryModel,
  InventoryRecordInput input, {
  bool synced = false,
  }) async {
    try {
      final total = ((input.qtdPorPilha ?? 0) * (input.numPilhas ?? 0)) + (input.qtdAvulsa ?? 0);
      final username = await _storage.read(key: 'username');

      final productLocal = await findProductByCode(input.product);
      if (productLocal == null) {
        return StatusResult(status: 0, message: 'Produto não encontrado');
      }

      final existing = await checkDuplicateRecord(
        inventCode: inventoryModel.inventCode,
        unitizer: input.unitizer,
        position: input.position,
        product: input.product,
      );

      debugPrint("***************************************************** EXISTE ${existing?.id}");

      final companion = InventoryRecordsCompanion.insert(
        id: existing != null ? Value(existing.id) : const Value.absent(),
        inventCode: inventoryModel.inventCode,
        inventCreated: Value(DateTime.now()),
        inventUser: Value(username),
        inventUnitizer: Value(input.unitizer),
        inventLocation: Value(input.position),
        inventProduct: productLocal.productId,
        inventBarcode: Value(productLocal.barcode),
        inventStandardStack: Value((input.qtdPorPilha ?? 0).toInt()),
        inventQtdStack: Value((input.numPilhas ?? 0).toInt()),
        inventQtdIndividual: Value(input.qtdAvulsa),
        inventTotal: Value(total),
        isSynced: Value(synced),
        lastSyncAttempt: Value(DateTime.now()),
      );

      await into(inventoryRecords).insertOnConflictUpdate(companion);

      // Após o insert/update, o banco já reflete o estado correto.
      // O SUM recalcula tudo do zero, sem precisar somar o valor antigo do model.
      final totalSumExpression = inventoryRecords.inventTotal.sum();

      final query = selectOnly(inventoryRecords)
        ..addColumns([totalSumExpression])
        ..where(inventoryRecords.inventCode.equals(inventoryModel.inventCode));

      final row = await query.getSingle();
      final totalGeral = row.read(totalSumExpression) ?? 0;

      await (update(inventory)
            ..where((tbl) => tbl.inventCode.equals(inventoryModel.inventCode)))
          .write(
        InventoryCompanion(
          inventTotal: Value(totalGeral.toDouble()),
        ),
      );

      debugPrint("✅ Total Geral do Inventário recalculado: $totalGeral");

      return StatusResult(status: 1, message: 'Registro atualizado com sucesso.');

    } catch (e) {
      return StatusResult(status: 0, message: 'Erro: $e');
    }
  }
  */

  Future<StatusResult> insertOrUpdateInventoryRecordOffline(
    InventoryModel inventoryModel,
    InventoryRecordInput input, {
    bool synced = false,
  }) async {
    try {
      final total = ((input.qtdPorPilha ?? 0) * (input.numPilhas ?? 0)) + (input.qtdAvulsa ?? 0);
      final username = await _storage.read(key: 'username');

      final productLocal = await findProductByCode(input.product);
      if (productLocal == null) {
        return StatusResult(status: 0, message: 'Produto não encontrado');
      }

      final existing = await checkDuplicateRecord(
        inventCode: inventoryModel.inventCode,
        unitizer: input.unitizer,
        position: input.position,
        product: input.product,
      );

      debugPrint(">>> existing id: ${existing?.id} | existing total: ${existing?.inventTotal} | novo total: $total");

      if (existing != null) {
        // UPDATE explícito pelo ID — garante que não cria duplicata
        await (update(inventoryRecords)
              ..where((tbl) => tbl.id.equals(existing.id)))
            .write(InventoryRecordsCompanion(
          inventCreated:       Value(DateTime.now()),
          inventUser:          Value(username),
          inventStandardStack: Value((input.qtdPorPilha ?? 0).toInt()),
          inventQtdStack:      Value((input.numPilhas ?? 0).toInt()),
          inventQtdIndividual: Value(input.qtdAvulsa),
          inventTotal:         Value(total),
          isSynced:            Value(synced),
          lastSyncAttempt:     Value(DateTime.now()),
        ));

        debugPrint("✏️ Record ${existing.id} atualizado.");
      } else {
        // INSERT limpo sem ID — banco gera o id automaticamente
        await into(inventoryRecords).insert(InventoryRecordsCompanion.insert(
          inventCode:          inventoryModel.inventCode,
          inventCreated:       Value(DateTime.now()),
          inventUser:          Value(username),
          inventUnitizer:      Value(input.unitizer),
          inventLocation:      Value(input.position),
          inventProduct:       productLocal.productId,
          inventBarcode:       Value(productLocal.barcode),
          inventStandardStack: Value((input.qtdPorPilha ?? 0).toInt()),
          inventQtdStack:      Value((input.numPilhas ?? 0).toInt()),
          inventQtdIndividual: Value(input.qtdAvulsa),
          inventTotal:         Value(total),
          isSynced:            Value(synced),
          lastSyncAttempt:     Value(DateTime.now()),
        ));

        debugPrint("➕ Novo record inserido.");
      }

      // Lista todos os records para conferir o estado do banco
      final allRecords = await (select(inventoryRecords)
            ..where((r) => r.inventCode.equals(inventoryModel.inventCode)))
          .get();

      for (var r in allRecords) {
        debugPrint(">>> record id: ${r.id} | total: ${r.inventTotal} | product: ${r.inventProduct}");
      }

      // SUM recalcula do zero com o estado atual do banco
      final totalSumExpression = inventoryRecords.inventTotal.sum();

      final query = selectOnly(inventoryRecords)
        ..addColumns([totalSumExpression])
        ..where(inventoryRecords.inventCode.equals(inventoryModel.inventCode));

      final row = await query.getSingle();
      final totalGeral = row.read(totalSumExpression) ?? 0;

      debugPrint("✅ Total Geral recalculado: $totalGeral");

      await (update(inventory)
            ..where((tbl) => tbl.inventCode.equals(inventoryModel.inventCode)))
          .write(InventoryCompanion(
        inventTotal: Value(totalGeral.toDouble()),
      ));

      return StatusResult(status: 1, message: 'Registro atualizado com sucesso.');

    } catch (e) {
      debugPrint("❌ Erro: $e");
      return StatusResult(status: 0, message: 'Erro: $e');
    }
  }

  /// Busca todos os itens de um inventário específico
  Future<List<InventoryRecord>> getRecordsByInventory(String inventCode) {
    return (select(inventoryRecords)
          ..where((tbl) => tbl.inventCode.equals(inventCode)))
        .get();
  }

  /// Busca registros pendentes de sincronização globalmente ou por inventário
  Future<List<InventoryRecord>> getPendingRecords({String? inventCode}) {
    final query = select(inventoryRecords)..where((tbl) => tbl.isSynced.equals(false));
    if (inventCode != null) {
      query.where((tbl) => tbl.inventCode.equals(inventCode));
    }
    return query.get();
  }

  /// Marca um registro específico como sincronizado
  Future<void> markRecordAsSynced(int id) {
    return (update(inventoryRecords)..where((tbl) => tbl.id.equals(id))).write(
      InventoryRecordsCompanion(
        isSynced: const Value(true),
        lastSyncAttempt: Value(DateTime.now()),
      ),
    );
  }

  /// Exclui um item específico (caso o usuário queira remover uma contagem)
  Future<void> deleteRecord(int id) => 
      (delete(inventoryRecords)..where((tbl) => tbl.id.equals(id))).go();
      

  // ----------------------------------------------------------------------
  // VERIFICAÇÃO DE DUPLICIDADE
  // ----------------------------------------------------------------------
  /// Verifica se já existe um registro no banco local para o mesmo
  /// inventário, unitizador, posição e produto.
  // ----------------------------------------------------------------------
  Future<InventoryRecord?> checkDuplicateRecord({
    required String inventCode,
    required String unitizer,
    required String position,
    required String product,
  }) async {
    // 1. Busca o productId interno
    final productLocal = await findProductByCode(product);
    
    if (productLocal == null) return null;

    // 2. Monta a query
    final query = select(inventoryRecords)..where((tbl) => 
      tbl.inventCode.equals(inventCode) & 
      tbl.inventUnitizer.equals(unitizer) & 
      tbl.inventLocation.equals(position) & 
      tbl.inventProduct.equals(productLocal.productId)
    );

    // 3. Executa o get() para obter a lista completa em vez de getSingleOrNull
    final results = await query.get();

    // 4. Debug: Imprime a quantidade encontrada
    debugPrint("🔍 Verificação de Duplicidade:");
    debugPrint("   Registros encontrados: ${results.length}");
    debugPrint("   Filtros: $inventCode | $unitizer | $position | $product");

    if (results.isEmpty) {
      return null;
    }

    // 5. Se houver mais de um, avisa e retorna o último da lista
    if (results.length > 1) {
      debugPrint("⚠️ ALERTA: Existem ${results.length} registros duplicados no banco local para esta posição!");
      // Retorna o último (o mais recente inserido)
      return results.last; 
    }

    // Se houver apenas um, retorna ele mesmo
    return results.single;
  }

  /// Busca registros pendentes vinculando o nome do produto via JOIN
  Future<List<InventoryRecordWithProduct>> getPendingRecordsWithDescription({String? inventCode}) async {
    // Consulta unindo as duas tabelas
    final query = select(inventoryRecords).join([
      leftOuterJoin(
        products, 
        products.productId.equalsExp(inventoryRecords.inventProduct)
      ),
    ]);

    query.where(inventoryRecords.isSynced.equals(false));
    if (inventCode != null) {
      query.where(inventoryRecords.inventCode.equals(inventCode));
    }

    final rows = await query.get();

    // Mapeia o resultado para a classe junto com o nome do produto
    return rows.map((row) {
      return InventoryRecordWithProduct(
        row.readTable(inventoryRecords),           // Pega os dados da contagem
        row.readTableOrNull(products)?.productName, // Pega o nome do produto
      );
    }).toList();
  }

}

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