// -----------------------------------------------------------
// app/core/services/auth_service.dart (Lógica de Autenticação)
// -----------------------------------------------------------
import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oxdata/app/core/http/api_client.dart'; // Importe o ApiClient
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:oxdata/app/core/models/dto/login_response.dart';

class AuthService with ChangeNotifier {
  final AuthRepository _authRepository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiClient _apiClient; // Adicione esta propriedade para o ApiClient

  bool _isAuthenticated = false;
  String? _authToken;

  bool get isAuthenticated => _isAuthenticated;
  String? get authToken => _authToken;

  // O construtor agora exige uma instância de AuthRepository E ApiClient.
  // para expor a variável que guarda o token dinâmico e permitir limpá-lo no logout
  AuthService(this._authRepository, this._apiClient);

  Future<ApiResponse<LoginResponse>> login(String username, String password, bool rememberMe) async {
    final response = await _authRepository.login(
      username: username,
      password: password,
      lembrarMe: rememberMe,
    );

    if (response.success && response.data != null) {
      _authToken = response.data!.token;
      _isAuthenticated = true;
    } else {
      _isAuthenticated = false;
      _authToken = null;
    }
    notifyListeners();

    return response;
  }

  Future<ApiResponse<String>> userRegister(String name, String password, String email) async {
    final response = await _authRepository.register(
      name: name,
      password: password,
      email: email,
    );

    if (response.success && response.data != null) {
      _authToken = response.data;
      _isAuthenticated = true;
    } else {
      _isAuthenticated = false;
      _authToken = null;
    }

    notifyListeners();

    return response;
  }

  /// Registra (ou atualiza) o dispositivo atual vinculado ao usuário
  /// autenticado, delegando a chamada de rede para o AuthRepository.
  Future<ApiResponse<String>> registerDevice({
    required String guid,
    required String platform,
    String? deviceName,
    String? appVersion,
  }) async {
    final response = await _authRepository.registerDevice(
      guid: guid,
      platform: platform,
      deviceName: deviceName,
      appVersion: appVersion,
    );

    if (!response.success) {
      debugPrint('⚠️ Falha ao registrar device: ${response.message}');
    }

    return response;
  }

  Future<void> logout() async {
    final storage = StorageService();
    _isAuthenticated = false;
    _authToken = null;

    // Limpa o token dinâmico no interceptor
    _apiClient.authInterceptor.clearDynamicToken();
    
    await storage.clearStorage();

    notifyListeners();
  }
}