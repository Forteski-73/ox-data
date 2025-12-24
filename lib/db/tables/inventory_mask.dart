import 'package:drift/drift.dart';

enum MaskFieldName {
  Unitizador,
  Posicao,
  Codigo,
}

class InventoryMask extends Table {
  IntColumn get maskId      => integer().autoIncrement()();
  TextColumn get fieldName  => textEnum<MaskFieldName>()();
  TextColumn get fieldMask  => text().withLength(min: 1, max: 255)();
}