import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (context, AsyncSnapshot<PackageInfo> snapshot) {
        if (snapshot.hasData) {
          final appVersion = snapshot.data!.version;
          return Container(
            height: 50,
            color: Colors.white,
            child: Center(
              child: Text(
                'Oxford Porcelanas | Versão $appVersion © ${DateTime.now().year}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ),
          );
        }
        return Container(
          height: 50,
          color: Colors.white,
          child: const Center(
            child: SpinKitThreeBounce(color: Colors.white, size: 30.0),
          ),
        );
      },
    );
  }
}