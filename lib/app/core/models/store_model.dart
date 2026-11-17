// -----------------------------------------------------------
// app/core/models/store_model.dart
// -----------------------------------------------------------

/// Loja retornada pelo endpoint `/API/v1/Store`
/// (somente as lojas que o usuário autenticado pode ver).
class StoreModel {
  final String storeId;
  final String name;

  StoreModel({
    required this.storeId,
    required this.name,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map) {
    return StoreModel(
      storeId: map['storeId']?.toString() ?? '',
      name:    map['name'] as String? ?? '',
    );
  }

  /// Ex.: "01 - Loja Centro".
  String get displayName => name.isEmpty ? storeId : '$storeId - $name';
}
