import 'package:drift/drift.dart';

class Products extends Table {
  TextColumn get productId    => text().withLength(min: 1, max: 10)();
  TextColumn get barcode      => text().withLength(min: 1, max: 20)();
  TextColumn get productName  => text().withLength(min: 1, max: 255)();
  BoolColumn get status       => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastSync => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {productId};
}