// -----------------------------------------------------------
// app/core/services/auth_service.dart (Lógica de Autenticação)
// -----------------------------------------------------------
import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 

class AuthService with ChangeNotifier {
  // A dependência do AuthRepository é injetada no construtor.
  final AuthRepository _authRepository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Estado de autenticação do usuário
  bool _isAuthenticated = false;
  String? _authToken;

  bool get isAuthenticated => _isAuthenticated;
  String? get authToken => _authToken;

  // O construtor exige uma instância de AuthRepository.
  // Essa dependência é fornecida pelo Provider no injector.dart.
  AuthService(this._authRepository);

  // O login usa o repositório para fazer a requisição.
  Future<ApiResponse<String>> login(String username, String password, bool rememberMe) async {
    final response = await _authRepository.login(
      username: username,
      password: password,
      lembrarMe: rememberMe,
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

  /// cadastro de usuário utiliza o AuthRepository para enviar os dados para a API
  /// e atualiza o estado de autenticação do aplicativo.
  Future<ApiResponse<String>> userRegister(String name, String password, String email) async {
    // Chama o método de registro do repositório
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

  Future<void> logout() async {
    _isAuthenticated = false;
    _authToken = null;
    
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'password');

    notifyListeners();
  }
}
