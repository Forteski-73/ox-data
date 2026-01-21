import 'package:drift/drift.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';

class Inventory extends Table {
  /// Código do inventário (PK – igual API)
  TextColumn get inventCode => text().withLength(min: 1, max: 50)();

  /// Nome do inventário
  TextColumn get inventName => text().withLength(min: 1, max: 50)();

  /// GUID do dispositivo / inventário
  TextColumn get inventGuid => text().withLength(min: 1, max: 36)();

  /// Setor
  TextColumn get inventSector => text().nullable().withLength(min: 1, max: 100)();

  /// Data de criação
  DateTimeColumn get inventCreated => dateTime().nullable()();

  /// Usuário
  TextColumn get inventUser => text().nullable().withLength(min: 1, max: 100)();

  /// Status do inventário (ENUM)
  TextColumn get inventStatus => textEnum<InventoryStatus>()();

  /// Total contado
  RealColumn get inventTotal => real().nullable()();

  /// 🔑 CONTROLE OFFLINE
  /// Indica se já foi sincronizado com a API
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Data da última tentativa de sync
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => { inventCode };

}
