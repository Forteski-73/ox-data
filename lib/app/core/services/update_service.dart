// app/core/services/update_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/models/app_update_model.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum UpdateStatus {
  idle,
  checking,
  available,
  upToDate,
  downloading,
  downloaded,
  error,
}

class UpdateService with ChangeNotifier {
  UpdateService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  // Domínio público do link do json da versão
  static const String _versionUrl =
  'https://oxfordtec.com.br/acep/apk/version.json';

  UpdateStatus status = UpdateStatus.idle;
  double progress = 0.0; // 0.0 a 1.0
  String? errorMessage;

  AppUpdateModel? _remoteUpdate;
  AppUpdateModel? get remoteUpdate => _remoteUpdate;

  int _installedVersionCode = 0;
  String _installedVersionName = '';
  String get installedVersionName => _installedVersionName;

  String? _downloadedApkPath;

  // =========================================================================
  // VERIFICAÇÃO
  // =========================================================================

  /// Consulta o version.json remoto e compara com a versão instalada.
  /// Retorna true se houver atualização disponível.
  Future<bool> checkForUpdate() async {

    if (kIsWeb || !Platform.isAndroid) return false; /* SEM ISSO VAI DAR PAU QUANDO ABRIR NA WEB OU iOS */
    
    status = UpdateStatus.checking;
    errorMessage = null;
    notifyListeners();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _installedVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;
      _installedVersionName = packageInfo.version;

      final response = await _dio.get(
        _versionUrl,
        options: Options(
          responseType: ResponseType.json,
          // Evita cache de CDN/proxy servindo um version.json antigo
          headers: {'Cache-Control': 'no-cache'},
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Resposta inválida do servidor (${response.statusCode}).');
      }

      _remoteUpdate = AppUpdateModel.fromJson(
        response.data is String ? _decodeIfString(response.data) : response.data,
      );

      final hasUpdate = _remoteUpdate!.versionCode > _installedVersionCode;

      status = hasUpdate ? UpdateStatus.available : UpdateStatus.upToDate;
      notifyListeners();
      return hasUpdate;
    } catch (e) {
      debugPrint('❌ checkForUpdate: $e');
      status = UpdateStatus.error;
      errorMessage = 'Não foi possível verificar atualizações.';
      notifyListeners();
      return false;
    }
  }

  Map<String, dynamic> _decodeIfString(dynamic data) {
    // fallback caso o servidor sirva o JSON como texto puro
    return data is Map<String, dynamic> ? data : {};
  }

  // =========================================================================
  // DOWNLOAD
  // =========================================================================

  Future<void> downloadUpdate() async {
    if (_remoteUpdate == null) return;

    status = UpdateStatus.downloading;
    progress = 0.0;
    errorMessage = null;
    notifyListeners();

    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/oxdata_update.apk';

      await _dio.download(
        _remoteUpdate!.apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          progress = received / total;
          notifyListeners();
        },
      );

      _downloadedApkPath = savePath;
      status = UpdateStatus.downloaded;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ downloadUpdate: $e');
      status = UpdateStatus.error;
      errorMessage = 'Falha ao baixar a atualização: $e';
      notifyListeners();
    }
  }

  // =========================================================================
  // INSTALAÇÃO
  // =========================================================================

  Future<void> installUpdate() async {
    if (_downloadedApkPath == null) return;

    try {
      // No Android 8+, instalar de fonte desconhecida exige permissão explícita.
      // O install_packages handler abre a tela de "permitir instalação" se necessário.
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.status;
        if (!status.isGranted) {
          await Permission.requestInstallPackages.request();
        }
      }

      final result = await OpenFilex.open(_downloadedApkPath!);

      if (result.type != ResultType.done) {
        errorMessage = 'Não foi possível abrir o instalador: ${result.message}';
        status = UpdateStatus.error;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ installUpdate: $e');
      status = UpdateStatus.error;
      errorMessage = 'Erro ao iniciar instalação: $e';
      notifyListeners();
    }
  }

  // =========================================================================
  // UTIL
  // =========================================================================

  void reset() {
    status = UpdateStatus.idle;
    progress = 0.0;
    errorMessage = null;
    notifyListeners();
  }
}