// -----------------------------------------------------------
// app/core/repositories/image_repository.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/image_url_model.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';

/// Repositório responsável pela comunicação com a API de Imagens
/// (endpoints do ImageController: /v1/Image).
class ImageRepository {
  final ApiClient apiClient;

  ImageRepository({required this.apiClient});

  /// Busca todas as imagens de um produto para uma finalidade específica.
  /// GET /v1/Image/Product/{productId}/{finalidade}
  ///
  /// Ex.: getProductImages('002687', 'EMBALAGEM')
  Future<ApiResponse<List<ImageUrlModel>>> getProductImages(
    String productId,
    String finalidade,
  ) async {
    try {
      final response = await apiClient.getAuth(
        '${ApiRoutes.imageProductUrl}/$productId/$finalidade',
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<ImageUrlModel> images = jsonList
            .map((json) => ImageUrlModel.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: images);
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Nenhuma imagem encontrada para o produto informado.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar imagens: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de imagens: $e',
      );
    }
  }
}