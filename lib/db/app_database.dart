
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

    final codeWithZero = '0$code';
    // 2. Executar a busca e salvar em uma variável
    final Product? result = await (select(products)
          ..where((p) => p.barcode.equals(codeWithZero) | p.productId.equals(code) | p.barcode.equals(code)))
        .getSingleOrNull();

    return result;
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


  Future<List<InventoryData>> getAllLocalInventories() {
    return select(inventory).get();
  }

  // Buscar inventários pendentes de sync
  Future<List<InventoryData>> getPendingInventories() {
    return (select(inventory)
          ..where((tbl) => tbl.isSynced.equals(false)))
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
    Future<void> insertOrUpdateInventoryRecordOffline(
      InventoryRecordModel model, {
      bool synced = false,
    }) async {

    }
  */

  // ----------------------------------------------------------------------
  // INVENTORY RECORD (OFFLINE)
  // ----------------------------------------------------------------------
  /// Insere ou atualiza um item contado no inventário
  /*Future<void> insertOrUpdateInventoryRecordOffline(
    InventoryModel inventory,
    InventoryRecordInput input, {
    bool synced = false,
  }) async {
    try {
      final total = (input.qtdPorPilha * input.numPilhas) + input.qtdAvulsa;
      const String username = "Diones";

      final productLocal = await findProductByCode(input.product);
      if (productLocal == null) {
        throw Exception('Produto não encontrado: ${input.product}');
      }

      await into(inventoryRecords).insertOnConflictUpdate(
        InventoryRecordsCompanion.insert(
          id: input.id != null ? Value(input.id!) : const Value.absent(),
          inventCode: inventory.inventCode,
          inventCreated: Value(DateTime.now()),
          inventUser: const Value(username),
          inventUnitizer: Value(input.unitizer),
          inventLocation: Value(input.position),
          inventProduct: productLocal.productId,
          inventBarcode: Value(productLocal.barcode),
          inventStandardStack: Value(input.qtdPorPilha.toInt()),
          inventQtdStack: Value(input.numPilhas.toInt()),
          inventQtdIndividual: Value(input.qtdAvulsa),
          inventTotal: Value(total),
          isSynced: Value(synced),
          lastSyncAttempt: Value(DateTime.now()),
        ),
      );

      debugPrint('InventoryRecord salvo com sucesso (offline)');
    } catch (e, stack) {
      debugPrint('Erro ao salvar InventoryRecord offline: $e');
      debugPrint(stack.toString());
      rethrow; // 👈 importante: deixa a camada acima decidir
    }
  }
*/

  Future<StatusResult> insertOrUpdateInventoryRecordOffline(
    InventoryModel inventory,
    InventoryRecordInput input, {
    bool synced = false,
  }) async {
    try {
      final total = ((input.qtdPorPilha ?? 0) * (input.numPilhas ?? 0)) + (input.qtdAvulsa ?? 0);
      final username = await _storage.read(key: 'username');
      //const String username = "Diones";

      final productLocal = await findProductByCode(input.product);
      if (productLocal == null) {
        return StatusResult(status: 0, message: 'Produto não encontrado: ${input.product}',);
      }

      await into(inventoryRecords).insertOnConflictUpdate(
        InventoryRecordsCompanion.insert(
          id: input.id != null ? Value(input.id!) : const Value.absent(),
          inventCode:           inventory.inventCode,
          inventCreated:        Value(DateTime.now()),
          inventUser:           Value(username),
          inventUnitizer:       Value(input.unitizer),
          inventLocation:       Value(input.position),
          inventProduct:        productLocal.productId,
          inventBarcode:        Value(productLocal.barcode),
          inventStandardStack:  Value((input.qtdPorPilha ?? 0).toInt()),
          inventQtdStack:       Value((input.numPilhas ?? 0).toInt()),
          inventQtdIndividual:  Value(input.qtdAvulsa),
          inventTotal:          Value(total),
          isSynced:             Value(synced),
          lastSyncAttempt:      Value(DateTime.now()),
        ),
      );

      return StatusResult( status: 1, message: 'Registro salvo localmente com sucesso.', );

    } catch (e) {

      return StatusResult( status: 0, message: 'Erro ao salvar registro localmente: $e', );
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

/*LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app.sqlite'));
    return NativeDatabase(file);
  });
}*/
