// -----------------------------------------------------------
// app/core/repositories/auth_repository.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/dto/login_response.dart';

// Classe para o response da API.
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? rawJson; // Campo adicionado para transportar o JSON bruto

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.rawJson,
  });
}

// Classe para o response dos produtos da API.
class ApiProductResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? totalCount;

  ApiProductResponse({
    required this.success,
    this.message,
    this.data,
    this.totalCount,
  });
}

// O AuthRepository é responsável por toda a comunicação com a API de autenticação.
class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  // O método de login usa o postAuth para enviar o token fixo.
  Future<ApiResponse<LoginResponse>> login({
    required String username,
    required String password,
    bool lembrarMe = false, 
  }) async {
    try {
      final response = await apiClient.postAuth(
        ApiRoutes.loginUser,
        body: {
          'user': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final loginResponse = LoginResponse.fromJson(data);
        final storage = StorageService();

        apiClient.updateToken(loginResponse.token);

        // Salva credenciais
        if (lembrarMe) {
          await storage.writeAuthToken(loginResponse.token);
          await storage.writeCredentials(username, password);
        }
        await storage.writeMenus(loginResponse.menus);

        return ApiResponse(
          success: true,
          data: loginResponse,
        );
        
      } else {
        return ApiResponse(
          success: false,
          message: 'Falha no login: ${response.body}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro de rede: $e',
      );
    }
  }

  /// Método para registrar um novo usuário na API.
  Future<ApiResponse<String>> register({
    required String name,
    required String password,
    required String email,
  }) async {
    try {
      final response = await apiClient.postAuth(
        ApiRoutes.loginRegister, // Rota para cadastro
        body: {
          'user':     name,
          'password': password,
          'account':  email,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: 'Seu cadastro foi feito com sucesso!',
        );
      } else {
        // Retorno de erro da API.
        return ApiResponse(
          success: false,
          message: 'Falha no registro: ${response.body}',
        );
      }
    } on Exception catch (e) {
      // Captura erros de rede ou outros problemas.
      return ApiResponse(
        success: false,
        message: 'Erro de rede durante o registro: $e',
      );
    }
  }
}