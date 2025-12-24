import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/product.dart';
import 'tables/device_sync.dart';
import 'tables/inventory_mask.dart';
import 'package:oxdata/app/core/models/dto/product_db_local.dart';

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


}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app.sqlite'));
    return NativeDatabase(file);
  });
}
