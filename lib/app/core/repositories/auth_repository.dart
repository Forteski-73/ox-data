// -----------------------------------------------------------
// app/core/repositories/auth_repository.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';

// Classe para o response da API.
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
  });
}

// O AuthRepository é responsável por toda a comunicação com a API de autenticação.
class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  // O método de login usa o postAuth para enviar o token fixo.
  Future<ApiResponse<String>> login({
    required String username,
    required String password,
    bool lembrarMe = false, 
  }) async {
    try {
      final response = await apiClient.postAuth(
        ApiRoutes.login,
        body: {
          'user':     username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'] as String?;

        if (token != null) {

          apiClient.updateToken(token);

          // Salva as credenciais
          if (lembrarMe) {
            final storage = StorageService();

            await storage.writeAuthToken(token);
            await storage.writeCredentials(username, password);
          }

          return ApiResponse(success: true, data: token);
        } else {
          // A API retornou 200, mas sem token.
          return ApiResponse(
            success: false,
            message: 'Token não encontrado na resposta da API.',
          );
        }
      } else {
        // Retorno de erro da API.
        return ApiResponse(
          success: false,
          message: 'Falha no login: ${response.body}',
        );
      }
    } on Exception catch (e) {
      // Captura erros de rede ou outros problemas.
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