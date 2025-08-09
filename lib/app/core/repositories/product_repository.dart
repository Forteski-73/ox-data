// -----------------------------------------------------------
// app/core/repositories/product_repository.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'dart:typed_data'; // Importe para Uint8List
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/product_model.dart';
import 'package:oxdata/app/core/models/product_complete.dart';
import 'package:oxdata/app/core/models/product_image_model.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';

/// Repositório responsável pela comunicação com a API de produtos.
class ProductRepository {
  final ApiClient apiClient;

  ProductRepository({required this.apiClient});

  /// Busca produtos na API com base nos filtros fornecidos.
  Future<ApiResponse<List<ProductModel>>> searchProducts(Map<String, dynamic> filters) async {
    final Map<String, dynamic> requestBody = {
      'productId': <String>[],
      'name': null,
      'brandId': <String>[],
      'lineId': <String>[],
      'familyId': <String>[],
      'decorationId': <String>[],
    };

    // Preenche o corpo da requisição com os filtros ativos
    filters.forEach((key, value) {
      if (requestBody.containsKey(key)) {
        // Para 'name', atribua diretamente o valor da string
        if (key == 'name') {
          requestBody[key] = value; // Assume que 'value' para 'name' já é uma String ou null
        } else {
          // Para os outros campos (List<String>), atribua a lista
          if (value is List<String>) {
            requestBody[key] = value;
          }
        }
      }
    });

    try {
      final response = await apiClient.postAuth(
        ApiRoutes.productsSearch,
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<ProductModel> products = jsonList
            .map((json) => ProductModel.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: products);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar produtos: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de produtos: $e',
      );
    }
  }

  /// Busca os detalhes completos de um produto específico na API.
  /// Retorna uma ApiResponse contendo uma lista de ProductComplete (espera-se 1 ou 0 itens).
  Future<ApiResponse<List<ProductComplete>>> getAppProduct(String productId) async {
    try {
      final response = await apiClient.getAuth('${ApiRoutes.appProduct}/$productId');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<ProductComplete> productsComplete = jsonList
            .map((json) => ProductComplete.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: productsComplete);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar detalhes do produto: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição dos detalhes do produto: $e',
      );
    }
  }

  /// Recupera a imagem de um produto específico como bytes de um ZIP.
  Future<ApiResponse<ProductImageModel>> getImageProduct(String productId) async {
    try {
      // Constrói a URL da imagem usando as rotas definidas em ApiRoutes
      final response = await apiClient.getAuth(
        '${ApiRoutes.baseUrl}${ApiRoutes.productImage}/$productId/PRODUTO/true',
      );

      if (response.statusCode == 200) {
        // A resposta é o ZIP em bytes, então criamos o modelo diretamente com bodyBytes
        // Corrigido para usar response.bodyBytes e o construtor zipBytes do ProductImageModel
        return ApiResponse(success: true, data: ProductImageModel(zipBytes: response.bodyBytes));
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar imagem do produto: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição da imagem: $e',
      );
    }
  }
}
