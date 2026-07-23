import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:oxdata/app/core/widgets/device_session_info.dart';
import 'package:oxdata/app/core/utils/device.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  Future<void> _showSessionInfo(BuildContext context) async {
    final storage = StorageService();

    final credentials = await storage.readCredentials();
    final username = credentials['username'] ?? 'Não identificado';
    final authToken = await storage.readAuthToken();
    final deviceGuid = await DeviceService.getDeviceId();

    if (!context.mounted) return;

    showDeviceSessionInfoDialog(
      context,
      userName: username,
      authToken: authToken ?? 'Não identificado',
      deviceGuid: deviceGuid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (context, AsyncSnapshot<PackageInfo> snapshot) {
        if (snapshot.hasData) {
          final appVersion = snapshot.data!.version;
          return GestureDetector(
            onTap: () => _showSessionInfo(context),
            behavior: HitTestBehavior.opaque,
            child: SafeArea(
              top: false,
              child: Container(
                color: Colors.white,
                child: SizedBox(
                  height: 50,
                  child: Center(
                    child: Text(
                      'Oxford Porcelanas | Versão $appVersion © ${DateTime.now().year}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return SafeArea(
          top: false,
          child: Container(
            color: Colors.white,
            child: const SizedBox(
              height: 50,
              child: Center(
                child: SpinKitThreeBounce(color: Colors.white, size: 30.0),
              ),
            ),
          ),
        );
      },
    );
  }
}