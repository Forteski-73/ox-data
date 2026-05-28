// -----------------------------------------------------------
// app/core/repositories/admin_repository.dart
// -----------------------------------------------------------
import 'dart:convert';

import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/user_model.dart';
import 'package:oxdata/app/core/models/profile_model.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';

/// Repositório responsável pela comunicação
/// com endpoints administrativos.
class AdminRepository {

  final ApiClient apiClient;

  AdminRepository({
    required this.apiClient,
  });

  /// =========================================================
  /// USERS
  /// =========================================================

  /// Busca todos os usuários cadastrados.
  Future<ApiResponse<List<UserModel>>> getUsers() async {

    try {

      final response = await apiClient.getAuth(
        ApiRoutes.users,
      );

      if (response.statusCode == 200) {

        final List<dynamic> data =
            json.decode(response.body);

        final List<UserModel> users = data
            .map(
              (json) => UserModel.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();

        return ApiResponse(
          success: true,
          data: users,
        );

      } else {

        return ApiResponse(
          success: false,
          message:
              'Erro ao buscar usuários: ${response.statusCode}',
        );
      }

    } on Exception catch (e) {

      return ApiResponse(
        success: false,
        message:
            'Falha na requisição de usuários: $e',
      );
    }
  }
  
  /// =========================================================
  /// PROFILES (MÉTODO NOVO ADICIONADO)
  /// =========================================================

  /// Busca todos os perfis cadastrados no sistema.
  Future<ApiResponse<List<ProfileModel>>> getProfiles() async {
    try {
      // Faz o GET autenticado utilizando o seu ApiClient padrão
      final response = await apiClient.getAuth(
        ApiRoutes.profiles,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Mapeia o JSON vindo da sua API C# diretamente para objetos Dart
        final List<ProfileModel> profiles = data
            .map(
              (json) => ProfileModel.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();

        return ApiResponse(
          success: true,
          data: profiles,
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar perfis: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de perfis: $e',
      );
    }
  }

}