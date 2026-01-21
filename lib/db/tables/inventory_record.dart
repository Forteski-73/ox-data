import 'package:drift/drift.dart';
import 'package:oxdata/db/tables/inventory.dart';

class InventoryRecords extends Table {
  /// ID Autoincremento local
  IntColumn get id => integer().autoIncrement()();

  /// FK para a tabela Inventory (inventCode)
  TextColumn get inventCode => text()
      .withLength(min: 1, max: 50)
      .references(Inventory, #inventCode)();

  DateTimeColumn get inventCreated => dateTime().nullable()();
  TextColumn get inventUser => text().nullable().withLength(min: 1, max: 100)();
  TextColumn get inventUnitizer => text().nullable().withLength(min: 1, max: 100)();
  TextColumn get inventLocation => text().nullable().withLength(min: 1, max: 100)();

  /// Produto (FK ou Código)
  TextColumn get inventProduct => text().withLength(min: 1, max: 50)();
  TextColumn get inventBarcode => text().nullable().withLength(min: 1, max: 100)();

  /// Quantidades
  IntColumn get inventStandardStack => integer().nullable()();
  IntColumn get inventQtdStack => integer().nullable()();
  RealColumn get inventQtdIndividual => real().nullable()();
  RealColumn get inventTotal => real().nullable()();

  /// 🔑 CONTROLE OFFLINE
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();

  /// ÍNDICE ÚNICO
  /// Garante que não existam duplicatas para a mesma contagem na mesma posição.
  @override
  List<Set<Column>> get uniqueKeys => [
        {inventCode, inventUnitizer, inventLocation, inventProduct}
      ];
}