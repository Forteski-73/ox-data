import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/product.dart';
import 'tables/device_sync.dart';
import 'tables/inventory_mask.dart';
import 'package:oxdata/app/core/models/dto/product_db_local.dart';
import 'package:oxdata/app/core/models/dto/mask_db_local.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    DeviceSync,
    InventoryMask,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

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

  Future<Product?> findProductByCode(String code) {
    return (select(products)
          ..where((p) => p.barcode.equals(code) | p.productId.equals(code)))
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

}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app.sqlite'));
    return NativeDatabase(file);
  });
}
