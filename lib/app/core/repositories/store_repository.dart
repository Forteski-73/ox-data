// -----------------------------------------------------------
// app/core/repositories/store_repository.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/store_model.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';

/// Repositório responsável pela comunicação com a API de lojas
/// (endpoints do StoreController: /v1/Store).
class StoreRepository {
  final ApiClient apiClient;

  StoreRepository({required this.apiClient});

  /// Lojas que o usuário autenticado pode ver.
  /// GET /v1/Store
  Future<ApiResponse<List<StoreModel>>> getStores() async {
    try {
      final response = await apiClient.getAuth(ApiRoutes.store);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<StoreModel> stores = jsonList
            .map((json) => StoreModel.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: stores);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar lojas: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de lojas: $e',
      );
    }
  }
}
