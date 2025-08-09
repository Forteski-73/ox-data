// -----------------------------------------------------------
// app/core/services/auth_service.dart (Lógica de Autenticação)
// -----------------------------------------------------------
import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart'; // Importa o repositório

class AuthService with ChangeNotifier {
  // A dependência do AuthRepository é injetada no construtor.
  final AuthRepository _authRepository;

  // Estado de autenticação do usuário
  bool _isAuthenticated = false;
  String? _authToken;

  bool get isAuthenticated => _isAuthenticated;
  String? get authToken => _authToken;

  // O construtor agora exige uma instância de AuthRepository.
  // Essa dependência é fornecida pelo Provider no injector.dart.
  AuthService(this._authRepository);

  // O método de login usa o repositório para fazer a requisição.
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

    // Notifica os listeners sobre a mudança no estado de autenticação.
    notifyListeners();
    return response;
  }

  // ---------------------------------------------
  // NOVO MÉTODO: userRegister
  // ---------------------------------------------
  /// Método para realizar o cadastro de um novo usuário.
  /// Ele utiliza o AuthRepository para enviar os dados para a API
  /// e atualiza o estado de autenticação do aplicativo.
  Future<ApiResponse<String>> userRegister(String name, String password, String email) async {
    // Chama o método de registro do repositório
    final response = await _authRepository.register(
      name: name,
      password: password,
      email: email,
    );

    // Verifica se a resposta foi bem-sucedida e atualiza o estado
    if (response.success && response.data != null) {
      _authToken = response.data;
      _isAuthenticated = true;
    } else {
      _isAuthenticated = false;
      _authToken = null;
    }
    
    // Notifica os widgets que estão ouvindo as mudanças no estado
    notifyListeners();
    return response;
  }

  // O processo de logout é simples, pois não envolve uma requisição de API.
  Future<void> logout() async {
    _isAuthenticated = false;
    _authToken = null;
    // Notifica os listeners sobre a mudança.
    notifyListeners();
  }
}
