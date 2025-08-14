// -----------------------------------------------------------
// app/core/repositories/auth_repository.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';

// Esta classe representa o resultado de uma operação de API.
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

  // O método de login agora usa o postAuth para enviar o token fixo.
  Future<ApiResponse<String>> login({
    required String username,
    required String password,
    bool lembrarMe = false, 
  }) async {
    try {
      final response = await apiClient.postAuth(
        ApiRoutes.login,
        body: {
          'user': username,
          'password': password,
        },
      );

      //final storage = new FlutterSecureStorage();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'] as String?;
        if (token != null) {
          // Retorna sucesso e o token.
          apiClient.updateToken(token);

          // Se o usuário marcou "Lembrar-me", salve o token
          if (lembrarMe) {
            //await storage.write(key: 'jwt_token', value: token);
            await StorageService().writeAuthToken(token);
          }

          return ApiResponse(success: true, data: token);
        } else {
          // A API retornou 200, mas sem token, o que é um erro.
          return ApiResponse(
            success: false,
            message: 'Token não encontrado na resposta da API.',
          );
        }
      } else {
        // A API retornou um status de erro.
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

  // ---------------------------------------------
  // MÉTODO: register
  // ---------------------------------------------
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
        /*final data = json.decode(response.body);
        final token = data['token'] as String?;
        if (token != null) {
          // Após o registro, atualiza o token do cliente para autenticação futura.
          apiClient.updateToken(token);
          return ApiResponse(success: true, data: token);
        } else {
          return ApiResponse(
            success: false,
            message: 'Token não encontrado na resposta da API após o registro.',
          );
        }*/
          return ApiResponse(
            success: true,
            message: 'Seu cadastro foi feito com sucesso!',
          );
      } else {
        // A API retornou um status de erro.
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