import 'package:drift/drift.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';

class InventoryMask extends Table {
  IntColumn get maskId      => integer().autoIncrement()();
  TextColumn get fieldName  => textEnum<MaskFieldName>()();
  TextColumn get fieldMask  => text().withLength(min: 1, max: 255)();
}