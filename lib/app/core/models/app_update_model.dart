// app/core/models/app_update_model.dart

class AppUpdateModel {
  final int versionCode;
  final String versionName;
  final String apkUrl;
  final String releaseNotes;

  AppUpdateModel({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    required this.releaseNotes,
  });

  factory AppUpdateModel.fromJson(Map<String, dynamic> json) {
    return AppUpdateModel(
      versionCode: json['versionCode'] as int,
      versionName: json['versionName'] as String,
      apkUrl: json['apkUrl'] as String,
      releaseNotes: json['releaseNotes'] as String? ?? '',
    );
  }
}