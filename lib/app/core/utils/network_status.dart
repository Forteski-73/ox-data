import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Importante para detectar se é navegador

class NetworkUtils {
  static Future<bool> hasInternetConnection() async {
    try {
      // Checa a conectividade básica
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult.isEmpty || connectivityResult.contains(ConnectivityResult.none)) {
        return false; 
      }

      // Se for WEB, ignoramos o lookup de DNS (InternetAddress não funciona no navegador)
      if (kIsWeb) {
        // No navegador, se o Connectivity passou assumimos que há internet
        return true;
      }

      // Se for MOBILE/DESKTOP continua com o teste real de DNS
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));

      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}

/*import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NetworkUtils {
  static Future<bool> hasInternetConnection() async {
    try {
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult.isEmpty || connectivityResult.contains(ConnectivityResult.none)) {
        return false; 
      }

      // Continua com o teste real (Lookup de DNS)
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));

      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
*/