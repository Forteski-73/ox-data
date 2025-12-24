import 'package:drift/drift.dart';

enum TypeWork {
  InventoryProduct,
  InventoryMask,
}

class DeviceSync extends Table {
  TextColumn get guid         => text()();
  TextColumn get typeWork     => textEnum<TypeWork>()();
  IntColumn get version       => integer()();
  DateTimeColumn get lastSync => dateTime().nullable()();
  TextColumn get user         => text()();

  @override
  Set<Column> get primaryKey => {guid, typeWork};
}