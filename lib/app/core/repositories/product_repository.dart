// -----------------------------------------------------------
// app/core/repositories/product_repository.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'dart:typed_data'; // Importe para Uint8List
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/product_model.dart';
import 'package:oxdata/app/core/models/product_complete.dart';
import 'package:oxdata/app/core/models/product_image_model.dart';
import 'package:oxdata/app/core/models/product_image_base64.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oxdata/app/core/utils/logger.dart';
import 'package:http_parser/http_parser.dart';

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

  /// Envia novas imagens para um produto específico, substituindo as existentes.
  /// `finalidade` deve ser uma string que representa a enum `Finalidade` no backend.
  /// `images` é uma lista de XFile (do ImagePicker).
  Future<ApiResponse<bool>> updateProductImages({
    required String productId,
    required String finalidade,
    required List<XFile> images,
  }) async {
    if (images.isEmpty) {
      return ApiResponse(success: false, message: 'Nenhuma imagem selecionada.');
    }

    try {
      // 1. Converte os XFile em MultipartFile, definindo nomes e tipos corretos
      final multipartFiles = <http.MultipartFile>[];

      for (int i = 0; i < images.length; i++) {
        final xFile = images[i];
        final bytes = await xFile.readAsBytes();

        // Nome fixo no formato 0001.jpg, 0002.jpg, ...
        final fileName = '${(i + 1).toString().padLeft(4, '0')}.jpg';

        multipartFiles.add(http.MultipartFile.fromBytes(
          'files', // campo esperado pelo backend
          bytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      // 2. Envia para o backend usando o ApiClient com autenticação
      final response = await apiClient.postAuthMultipart(
        '${ApiRoutes.productImageUpdate}/$productId/$finalidade',
        files: multipartFiles,
      );

      // 3. Verifica resposta do servidor
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

  // Seu método no serviço
  Future<ApiResponse<bool>> updateProductImagesBase64({
    required String productId,
    required String finalidade,
    required List<String> base64Images,
  }) async {
    if (base64Images.isEmpty) {
      return ApiResponse(success: false, message: 'Nenhuma imagem selecionada.');
    }

    try {
      // Cria o objeto de requisição com os dados necessários
      final requestBody = {
        'productId': productId,
        'finalidade': finalidade,
        'base64Images': base64Images,
      };

      // Envia a requisição JSON para o novo endpoint
      // Remova o jsonEncode aqui, a função apiClient.postAuth já faz isso.
      final response = await apiClient.postAuth(
        ApiRoutes.productImageUpdateBase64,
        body: requestBody, // Passa o mapa diretamente
      );

      // Verifica a resposta do servidor
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

}
