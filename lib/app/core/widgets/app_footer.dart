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
        final bottomInset = MediaQuery.of(context).padding.bottom;

        Widget content;
        if (snapshot.hasData) {
          final appVersion = snapshot.data!.version;
          content = GestureDetector(
            onTap: () => _showSessionInfo(context),
            behavior: HitTestBehavior.opaque,
            child: Text(
              'Grupo Oxford | Versão $appVersion © ${DateTime.now().year}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                height: 1.0, // remove o espaço extra da fonte
              ),
              strutStyle: const StrutStyle(
                fontSize: 12,
                height: 1.0,
                forceStrutHeight: true, // corta o leading de verdade
              ),
            ),
          );
        } else {
          content = const SpinKitThreeBounce(color: Colors.white, size: 30.0);
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            color: Colors.white,
            width: double.infinity,
            padding: EdgeInsets.only(top: 6, bottom: 6 + bottomInset),
            child: content,
          ),
        );
      },
    );
  }
}