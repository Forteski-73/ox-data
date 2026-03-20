import 'dart:convert';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/product_packing_model.dart';
import 'package:oxdata/app/core/models/product_pack_image_base64.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';

/// Repositório responsável pela comunicação com a API de Embalagens/Packs.
class ProductPackingRepository {
  final ApiClient apiClient;

  ProductPackingRepository({required this.apiClient});

  /// Busca todas as embalagens (ProductPacking) na API.
  Future<ApiResponse<List<ProductPackingModel>>> getAllPackings() async {
    try {
      // Realiza a chamada GET autenticada para a rota de packing
      // Nota: Certifique-se de que ApiRoutes.productPacking corresponda a '/v1/ProductPacking'
      final response = await apiClient.getAuth(ApiRoutes.productPacking);

      if (response.statusCode == 200) {
        // Decodifica o corpo da resposta que é uma lista JSON
        final List<dynamic> jsonList = json.decode(response.body);
        
        // Mapeia os dados para a lista de modelos
        final List<ProductPackingModel> packings = jsonList
            .map((json) => ProductPackingModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true, 
          data: packings,
          message: 'Embalagens carregadas com sucesso.'
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar embalagens: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de embalagens: $e',
      );
    }
  }

  /// Busca os detalhes de uma embalagem específica pelo ID.
  Future<ApiResponse<ProductPackingModel>> getPackingById(int packId) async {
    try {
      final response = await apiClient.getAuth('${ApiRoutes.productPacking}/$packId');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ApiResponse(
          success: true, 
          data: ProductPackingModel.fromJson(jsonData)
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar detalhe da embalagem: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro de conexão: $e',
      );
    }
  }


  /// Busca a lista de imagens de um pack específico em formato Base64 (ZIP).
  Future<ApiResponse<List<ImagePackBase64>>> getPackImagesBase64(int packId) async {
    try {
      final response = await apiClient.getAuth('${ApiRoutes.productPackImage}/$packId');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        
        final List<ImagePackBase64> images = jsonList
            .map((json) => ImagePackBase64.fromJson(json as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true, 
          data: images,
          message: 'Imagens do pack carregadas com sucesso.'
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar imagens do pack: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de imagens: $e',
      );
    }
  }

  /// Realiza o POST para criar uma nova embalagem
  Future<ApiResponse<ProductPackingModel>> createPacking(String name, String user) async {
    try {
      
      final Map<String, dynamic> jsonRequest = {
        "packName": name,
        "packUser": user,
        "packCreated": DateTime.now().toIso8601String(),
      };

      final response = await apiClient.postAuth(
        ApiRoutes.productPacking,
        body: jsonRequest,
      );

      // A API retorna 201 Created quando o registro é inserido
      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        return ApiResponse(
          success: true,
          data: ProductPackingModel.fromJson(jsonData),
          message: 'Embalagem criada com sucesso.'
        );

      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao criar: Código ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na comunicação com o servidor: $e',
      );
    }
  }

}