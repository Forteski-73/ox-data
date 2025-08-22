// -----------------------------------------------------------
// app/core/repositories/product_repository.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/product_model.dart';
import 'package:oxdata/app/core/models/product_complete.dart';
import 'package:oxdata/app/core/models/product_image_model.dart';
import 'package:oxdata/app/core/models/product_tag_model.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

/// Repositório responsável pela comunicação com a API de produtos.
class ProductRepository {
  final ApiClient apiClient;

  ProductRepository({required this.apiClient});

  /// Busca produtos na API com base nos filtros fornecidos.
  Future<ApiProductResponse<List<ProductModel>>> searchProducts(Map<String, dynamic> filters) async {
    final Map<String, dynamic> requestBody = {
      'productId'   : <String>[],
      'name'        : null,
      'brandId'     : <String>[],
      'lineId'      : <String>[],
      'familyId'    : <String>[],
      'decorationId': <String>[],
      'tag'         : <String>[],
      'YesNoImage'  : <String>[],
    };

    // Preenche o corpo da requisição com os filtros ativos
    filters.forEach((key, value) {
      if (requestBody.containsKey(key)) {
        // Para 'name', atribui diretamente o valor da string
        if (key == 'name') {
          requestBody[key] = value;
        } else {
          // Para os outros campos (List<String>), atribui a lista
          if (value is List<String>) {
            requestBody[key] = value;
          }
        }
      }
    });

    // Lógica para o filtro de produto com/sem imagem
    if (filters['yesImage'] != null && filters['yesImage'] != "") {
      requestBody['YesNoImage'] = "yes";
    } else if (filters['noImage'] != null && filters['noImage'] != "") {
      requestBody['YesNoImage'] = "no";
    }
    else
    {
      requestBody['YesNoImage'] = null;
    }

    try {
      final response = await apiClient.postAuth(
        ApiRoutes.productsSearch,
        body: requestBody,
      );

      /*if (response.statusCode == 200) {
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
      }*/

      //---------------------------------------------------------------------------

      if (response.statusCode == 200) {

        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // Acessa a lista de produtos a partir da chave 'products'
        final List<dynamic> jsonList = jsonResponse['products'] ?? [];

        // 3. Mapeia a lista de JSON para a lista de ProductModel
        final List<ProductModel> products = jsonList
            .map((json) => ProductModel.fromMap(json as Map<String, dynamic>))
            .toList();
            
        // Total de produtos.
        final int totalProducts = jsonResponse['totalProducts'] ?? 0;
        // Você pode usar essa variável para atualizar a UI com a contagem total.

        return ApiProductResponse(success: true, data: products, totalCount: totalProducts);
        
      } else {
        return ApiProductResponse(
          success: false,
          message: 'Erro ao buscar produtos: ${response.statusCode}',
          totalCount: 0,
        );
      }

      //---------------------------------------------------------------------------


    } on Exception catch (e) {
      return ApiProductResponse(
        success: false,
        message: 'Falha na requisição de produtos: $e',
        totalCount: 0,
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
        // Alterado para usar response.bodyBytes e o construtor zipBytes do ProductImageModel
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

  /*
  /// Envia novas imagens para um produto específico, substituindo as existentes.
  Future<ApiResponse<bool>> updateProductImages({
    required String productId,
    required String finalidade,
    required List<XFile> images,
  }) async {
    if (images.isEmpty) {
      return ApiResponse(success: false, message: 'Nenhuma imagem selecionada.');
    }

    try {
      // Converte os XFile em MultipartFile, definindo nomes e tipos corretos
      final multipartFiles = <http.MultipartFile>[];

      for (int i = 0; i < images.length; i++) {
        final xFile = images[i];
        final bytes = await xFile.readAsBytes();

        // Nome fixo no formato 0001.jpg, 0002.jpg, ...
        final fileName = '${(i + 1).toString().padLeft(4, '0')}.jpg';

        multipartFiles.add(http.MultipartFile.fromBytes(
          'files', // campo esperado pelo backend lá na API
          bytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      // Envia para a API usando o ApiClient com autenticação
      final response = await apiClient.postAuthMultipart(
        '${ApiRoutes.productImageUpdate}/$productId/$finalidade',
        files: multipartFiles,
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: true);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao enviar imagens: ${response.statusCode} - ${response.body}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha ao enviar imagens: $e',
      );
    }
  }
  */

  // Atualiza as imagens na API
  Future<ApiResponse<bool>> updateProductImagesBase64({
    required String productId,
    required String finalidade,
    required List<String> base64Images,
  }) async {
    if (base64Images.isEmpty) {
      return ApiResponse(success: false, message: 'Nenhuma imagem selecionada.');
    }

    try {
      // Cria o objeto de requisição com as imagens
      final requestBody = {
        'productId': productId,
        'finalidade': finalidade,
        'base64Images': base64Images,
      };

      // Envia a requisição JSON para a API
      final response = await apiClient.postAuth(
        ApiRoutes.productImageUpdateBase64,
        body: requestBody, // Passa o JSON
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: true);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao enviar imagens: ${response.statusCode} - ${response.body}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha ao enviar imagens: $e',
      );
    }
  }

  // Atualiza as TAGs na API
  Future<ApiResponse<bool>> updateTags(List<ProductTagModel> tags) async {
    try {
      // Gera a lista simples
    final listaTags = tags.map((t) => t.toJson()).toList();

    final response = await apiClient.postAuth1(
      ApiRoutes.productTag,
      body: listaTags, // agora aceita List
    );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: true,
          data: true,
          message: 'Tags atualizadas com sucesso.',
        );
      } else {
        String errorMessage = 'Erro desconhecido ao atualizar tags.';
        try {
          final errorBody = json.decode(response.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Erro ao atualizar tags: ${response.statusCode}';
        }
        return ApiResponse(
          success: false,
          data: false,
          message: errorMessage,
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        data: false,
        message: 'Erro de conexão: $e',
      );
    }
  }

  // deletar tag
  Future<ApiResponse<bool>> deleteTag(String productId, String tagId) async {
    try {
      final response = await apiClient.deleteAuth (
        "${ApiRoutes.productTag}/$productId/$tagId",
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse(
          success: true,
          data: true,
          message: 'Tag deletada com sucesso.',
        );
      } else {
        String errorMessage = 'Erro desconhecido ao deletar tag.';
        try {
          final errorBody = json.decode(response.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Erro ao deletar tag: ${response.statusCode}';
        }
        return ApiResponse(
          success: false,
          data: false,
          message: errorMessage,
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        data: false,
        message: 'Erro de conexão: $e',
      );
    }
  }

}
