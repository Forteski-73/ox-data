/// Representa um cabeçalho de inventário cadastrado via
/// `POST /API/v1/Inventory/Header` e listado via
/// `GET /API/v1/Inventory/Header/Recent`.
class InventoryHeaderModel {
  final int id;
  final String inventName;
  final String inventDescription;
  final bool salesChannelOnly;
  final bool active;

  InventoryHeaderModel({
    required this.id,
    required this.inventName,
    required this.inventDescription,
    required this.salesChannelOnly,
    required this.active,
  });

  InventoryHeaderModel copyWith({
    String? inventName,
    String? inventDescription,
    bool? salesChannelOnly,
    bool? active,
  }) {
    return InventoryHeaderModel(
      id: id,
      inventName: inventName ?? this.inventName,
      inventDescription: inventDescription ?? this.inventDescription,
      salesChannelOnly: salesChannelOnly ?? this.salesChannelOnly,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'inventName': inventName,
      'inventDescription': inventDescription,
      'salesChannelOnly': salesChannelOnly,
      'active': active,
    };
  }

  factory InventoryHeaderModel.fromMap(Map<String, dynamic> map) {
    return InventoryHeaderModel(
      id: map['id'] as int? ?? 0,
      inventName: map['inventName'] as String? ?? '',
      inventDescription: map['inventDescription'] as String? ?? '',
      salesChannelOnly: map['salesChannelOnly'] as bool? ?? false,
      active: map['active'] as bool? ?? true,
    );
  }
}
