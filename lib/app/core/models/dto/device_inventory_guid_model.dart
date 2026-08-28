import 'package:oxdata/app/core/models/dto/inventory_header_model.dart';

/// Representa um device retornado pelo endpoint
/// `GET /API/v1/Device/InventoryGuid`, que lista os devices vinculados
/// a um inventory_guid, já com o username do usuário dono do device e o
/// cabeçalho de inventário (`inventory_header`) vinculado via
/// `inventory_guid.invent_header_id`.
class DeviceInventoryGuidModel {
  final int id;
  final String guid;
  final int userId;
  final String username;
  final String? deviceName;
  final String? customDeviceName;
  final String platform;
  final bool isActive;
  final InventoryHeaderModel? header;

  DeviceInventoryGuidModel({
    required this.id,
    required this.guid,
    required this.userId,
    required this.username,
    this.deviceName,
    this.customDeviceName,
    required this.platform,
    required this.isActive,
    this.header,
  });

  DeviceInventoryGuidModel copyWith({
    String? customDeviceName,
    bool? isActive,
    InventoryHeaderModel? header,
  }) {
    return DeviceInventoryGuidModel(
      id: id,
      guid: guid,
      userId: userId,
      username: username,
      deviceName: deviceName,
      customDeviceName: customDeviceName ?? this.customDeviceName,
      platform: platform,
      isActive: isActive ?? this.isActive,
      header: header ?? this.header,
    );
  }

  factory DeviceInventoryGuidModel.fromJson(Map<String, dynamic> json) {
    return DeviceInventoryGuidModel(
      id: json['id'] as int? ?? 0,
      guid: json['guid'] as String? ?? '',
      userId: json['userId'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      deviceName: json['deviceName'] as String?,
      customDeviceName: json['customDeviceName'] as String?,
      platform: json['platform'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      header: json['header'] != null
          ? InventoryHeaderModel.fromMap(json['header'] as Map<String, dynamic>)
          : null,
    );
  }
}
