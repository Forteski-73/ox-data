import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class AppInfo {
  static PackageInfo? _cachedPackageInfo;

  /// Retorna a versão do app (ex: "1.0.6").
  static Future<String> getAppVersion() async {
    _cachedPackageInfo ??= await PackageInfo.fromPlatform();
    return _cachedPackageInfo!.version;
  }

  /// Retorna versão + build number (ex: "1.0.6+5").
  static Future<String> getAppVersionWithBuild() async {
    _cachedPackageInfo ??= await PackageInfo.fromPlatform();
    return '${_cachedPackageInfo!.version}+${_cachedPackageInfo!.buildNumber}';
  }

  static Future<String> getDeviceName() async {
    final deviceInfoPlugin = DeviceInfoPlugin();

    try {
      if (kIsWeb) {
        final info = await deviceInfoPlugin.webBrowserInfo;
        return info.browserName.name; // ex: "chrome"
      }

      if (Platform.isAndroid) {
        final info = await deviceInfoPlugin.androidInfo;
        return '${info.manufacturer} ${info.model}'; // ex: "samsung SM-S911B"
      }

      if (Platform.isIOS) {
        final info = await deviceInfoPlugin.iosInfo;
        return info.utsname.machine; // ex: "iPhone15,2"
        // ou: return info.name; // nome dado pelo usuário, ex: "iPhone do João"
      }

      if (Platform.isWindows) {
        final info = await deviceInfoPlugin.windowsInfo;
        return info.computerName;
      }

      if (Platform.isMacOS) {
        final info = await deviceInfoPlugin.macOsInfo;
        return info.computerName;
      }

      if (Platform.isLinux) {
        final info = await deviceInfoPlugin.linuxInfo;
        return info.name;
      }
    } catch (e) {
      return 'Desconhecido';
    }

    return 'Desconhecido';
  }
}