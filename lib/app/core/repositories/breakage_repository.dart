// -----------------------------------------------------------
// app/core/repositories/breakage_repository.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/breakage_model.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';

/// Repositório responsável pela comunicação com a API de quebras
/// (endpoints do BreakageController: /v1/Breakage).
class BreakageRepository {
  final ApiClient apiClient;

  BreakageRepository({required this.apiClient});

  /// Busca todos os registros de quebra.
  /// GET /v1/Breakage
  Future<ApiResponse<List<BreakageModel>>> getAll() async {
    try {
      final response = await apiClient.getAuth(ApiRoutes.breakage);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<BreakageModel> breakages = jsonList
            .map((json) => BreakageModel.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: breakages);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar quebras: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de quebras: $e',
      );
    }
  }

  /// Cria (breakageId = 0) ou atualiza (breakageId > 0) um registro de quebra.
  /// POST /v1/Breakage
  Future<ApiResponse<bool>> save(BreakageModel breakage) async {
    try {
      final response = await apiClient.postAuth1(
        ApiRoutes.breakage,
        body: breakage.toMap(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(success: true, data: true);
      } else {
        String errorMessage = 'Erro ao salvar quebra: ${response.statusCode}';
        try {
          final Map<String, dynamic> errorBody = json.decode(response.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (_) {}
        return ApiResponse(success: false, message: errorMessage);
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de salvar quebra: $e',
      );
    }
  }

  /// Exclui um registro de quebra pelo id.
  /// DELETE /v1/Breakage/{id}
  Future<ApiResponse<bool>> delete(int breakageId) async {
    try {
      final response = await apiClient.deleteAuth('${ApiRoutes.breakage}/$breakageId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse(success: true, data: true);
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Registro de quebra não encontrado.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao excluir quebra: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de excluir quebra: $e',
      );
    }
  }
}
