// -----------------------------------------------------------
// app/core/models/tv_device_model.dart
// -----------------------------------------------------------
class TvDeviceModel {
  final int deviceId;
  final String setor;
  final String? deviceName;
  final String? customDeviceName;
  final String? platform;
  final String? transCode;

  TvDeviceModel({
    required this.deviceId,
    required this.setor,
    this.deviceName,
    this.customDeviceName,
    this.platform,
    this.transCode,
  });

  factory TvDeviceModel.fromMap(Map<String, dynamic> map) {
    return TvDeviceModel(
      deviceId: map['deviceId'] as int,
      setor: map['setor'] as String,
      transCode: map['transCode'] as String?,
      deviceName: map['device']?['deviceName'] as String?,
      customDeviceName: map['device']?['customDeviceName'] as String?,
      platform: map['device']?['platform'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'setor': setor,
      if (transCode != null) 'transCode': transCode,
    };
  }
}