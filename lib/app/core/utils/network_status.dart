import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

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