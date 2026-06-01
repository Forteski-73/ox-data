// -----------------------------------------------------------
// app/core/repositories/admin_repository.dart
// -----------------------------------------------------------
import 'dart:convert';

import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/user_model.dart';
import 'package:oxdata/app/core/models/profile_model.dart';
import 'package:oxdata/app/core/models/profiles_menu.dart';
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

  /// =========================================================
  /// PROFILES & MENUS
  /// =========================================================

  /// Busca a relação completa de menus padrões e perfis vinculados.
  Future<ApiResponse<ProfilesMenu>> getProfilesMenu() async {
    try {
      // Faz o GET autenticado apontando para o novo endpoint
      // Nota: Certifique-se de adicionar 'profilesForMenu' na sua classe ApiRoutes
      final response = await apiClient.getAuth(
        ApiRoutes.profilesMenu, 
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        // Mapeia o objeto principal usando o factory do modelo criado abaixo
        final ProfilesMenu data = ProfilesMenu.fromJson(jsonMap);

        return ApiResponse(
          success: true,
          data: data,
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar menus por perfil: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de menus por perfil: $e',
      );
    }
  }

  /// =========================================================
  /// UPDATE USER PROFILE
  /// =========================================================

  /// Atualiza o profileId de um usuário.
  Future<ApiResponse<String>> updateUserProfile({
    required int id,
    required String user,
    required int profileId,
  }) async {
    try {
      final response = await apiClient.putAuth(
        ApiRoutes.updateUserProfile,
        body: {
          "id": id,
          "user": user,
          "password": '',
          "account": '',
          "profileId": profileId,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap =
            json.decode(response.body);

        return ApiResponse(
          success: true,
          data: jsonMap['message'] ??
              'Perfil do usuário atualizado com sucesso!',
        );
      } else {
        return ApiResponse(
          success: false,
          message:
              'Erro ao atualizar perfil do usuário: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message:
            'Falha na requisição ao atualizar perfil do usuário: $e',
      );
    }
  }

  /// Atualiza os menus vinculados a um perfil específico.
/// =========================================================
  /// UPDATE PROFILE MENUS
  /// =========================================================

  /// Atualiza os menus vinculados a um perfil específico.
  Future<ApiResponse<String>> updateProfileMenus({
    required int profileId,
    required String profileName,
    required List<Map<String, dynamic>> menus,
  }) async {
    try {
      // Faz o POST autenticado passando o Map direto, sem json.encode
      final response = await apiClient.postAuth(
        ApiRoutes.updateProfileMenus,
        body: {
          "id": profileId,
          "name": profileName,
          "menus": menus,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        return ApiResponse(
          success: true,
          data: jsonMap['message'] ?? 'Menus atualizados com sucesso!',
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao atualizar menus do perfil: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição ao atualizar menus do perfil: $e',
      );
    }
  }
}