// -----------------------------------------------------------
// app/core/repositories/pallet_repository.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/pallet_model.dart';
import 'package:oxdata/app/core/models/pallet_item_model.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/models/ftp_image_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Repositório responsável pela comunicação com a API de paletes.
class PalletRepository {
  final ApiClient apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  PalletRepository({required this.apiClient});

  /// Busca todos os paletes da API.
  Future<ApiResponse<List<PalletModel>>> getAllPallets() async {
    try {
      final response = await apiClient.getAuth(ApiRoutes.pallets);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<PalletModel> pallets = jsonList
            .map((json) => PalletModel.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: pallets);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar paletes: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de paletes: $e',
      );
    }
  }

  Future<ApiResponse<List<PalletModel>>> getFiltersPallets(String? status, String txtFilter) async {

    final safeTxtFilter = txtFilter.trim().isEmpty ? null : txtFilter.trim();
    Map<String, dynamic> queryParams = {};

    if (status != null) {
      queryParams['status'] = status;
    }
    
    if (safeTxtFilter != null) {
      queryParams['txtFilter'] = safeTxtFilter;
    }

    final uri = Uri(
      path: ApiRoutes.palletSearch, 
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    
    final routeFilter = uri.toString();
    
    try {
      final response = await apiClient.getAuth(routeFilter);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<PalletModel> pallets = jsonList
            .map((json) => PalletModel.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: pallets);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar paletes: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de paletes: $e',
      );
    }
  }

  /// Cria ou atualiza uma lista de paletes (Upsert).
  Future<ApiResponse<String>> upsertPallets(List<PalletModel> pallets, List<String>? imagePaths) async {

    try {
      final requestBody = pallets.map((p) => p.toMap()).toList();

      final response = await apiClient.postAuth1(
        ApiRoutes.pallets,
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);

        if (imagePaths != null && imagePaths.isNotEmpty)
        {
          // Corrigido: Mapeia cada String (caminho da imagem) para um objeto Map.
          final requestBodyImages = imagePaths.map((path) => {
            "palletId": pallets.first.palletId,
            'imagePath': path,
          }).toList();

          // Corrigido: Envia a lista de Maps (o formato JSON correto) no body.
          final responseImg = await apiClient.postAuth1(
            ApiRoutes.palletImages,
            body: requestBodyImages, // Usando o Map criado
          );
          
          // Se precisar verificar o sucesso do upload das imagens também:
          if (responseImg.statusCode != 200 && responseImg.statusCode != 201) {
              // Lidar com erro no upload das imagens
              return ApiResponse(
                  success: false,
                  message: 'Erro ao enviar imagens: ${responseImg.statusCode}',
              );
          }
        }
        return ApiResponse(success: true, data: result['message'] ?? 'Paletes salvos com sucesso.');
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao salvar paletes: ${response.statusCode}',
        );
      }

    } on Exception catch (e) {
      return ApiResponse(success: false, message: 'Falha no salvamento de paletes: $e');
    }
    
  }

  /// Envia (Upsert) os caminhos das imagens associadas a um Palete.
  /// 
  /// Recebe o ID do palete e a lista de caminhos de arquivos de imagem.
  /// Retorna um ApiResponse indicando sucesso ou falha na comunicação com a API.
  Future<ApiResponse<String>> upsertPalletImages(
      int palletId, List<String> imagePaths) async {

    if (imagePaths.isEmpty) {
      // Se não houver caminhos de imagem, consideramos um "sucesso" em não fazer nada.
      return ApiResponse(success: true, data: 'Nenhuma imagem para enviar.');
    }

    try {
      // Mapeia cada String (caminho da imagem) para um objeto Map.
      final requestBodyImages = imagePaths.map((path) => {
            "palletId": palletId,
            'imagePath': path,
          }).toList();

      // Envia a lista de Maps (o formato JSON correto) no body.
      final responseImg = await apiClient.postAuth1(
        ApiRoutes.palletImages,
        body: requestBodyImages, // Usando o Map criado
      );

      if (responseImg.statusCode == 200 || responseImg.statusCode == 201) {
        final result = json.decode(responseImg.body);
        return ApiResponse(
            success: true, data: result['message'] ?? 'Caminhos de imagem salvos com sucesso.');
      } else {
        return ApiResponse(
          success: false,
          message:
              'Erro ao salvar caminhos de imagem: ${responseImg.statusCode} - ${responseImg.body}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
          success: false, message: 'Falha na comunicação ao salvar caminhos de imagem: $e');
    }
  }

  /// Atualiza situação do pallet
  Future<ApiResponse<String>> updatePalletStatus(int pallet, String status) async {

    try {
      final username = await _storage.read(key: 'username');
      final Map<String, dynamic> requestBody = {
        "PalletId":     pallet,
        "Status":       status,
        "UpdatedUser":  username,
      };

      final response = await apiClient.putAuth(
        ApiRoutes.palletStatus,
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);

        return ApiResponse(success: true, data: result['message'] ?? 'Palete salvo com sucesso.');
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro: ${response.statusCode}',
        );
      }

    } on Exception catch (e) {
      return ApiResponse(success: false, message: 'Falha no salvamento de paletes: $e');
    }
    
  }

  /// Cria ou atualiza uma lista de itens de palete (Upsert).
  Future<ApiResponse<String>> upsertPalletItems(List<PalletItemModel> items) async {
    try {
      final requestBody = items.map((i) => i.toMap()).toList();

      final response = await apiClient.postAuth1(
        '${ApiRoutes.pallets}/Item',
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);
        return ApiResponse(success: true, data: result['message'] ?? 'Itens salvos com sucesso.');
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao salvar itens: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(success: false, message: 'Falha no salvamento de itens: $e');
    }
  }

  /// Exclui um palete específico na API.
  Future<ApiResponse<String>> deletePallet(int palletId) async {
    try {
      final response = await apiClient.deleteAuth('${ApiRoutes.pallets}/$palletId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse(
          success: true,
          data: 'Palete $palletId excluído com sucesso.',
        );
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Erro ao excluir palete.';
        return ApiResponse(
          success: false,
          message: 'Erro ao excluir palete: ${response.statusCode} - $errorMessage',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de exclusão de palete: $e',
      );
    }
  }

  /// Exclui um item (produto) específico de um palete na API.
  Future<ApiResponse<String>> deletePalletItem(int palletId, String productId) async {
    try {
      final response =
          await apiClient.deleteAuth('${ApiRoutes.pallets}/Item/$palletId/$productId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse(
          success: true,
          data: 'Item $productId excluído do palete $palletId com sucesso.',
        );
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Erro ao excluir item do palete.';
        return ApiResponse(
          success: false,
          message: 'Erro ao excluir item do palete: ${response.statusCode} - $errorMessage',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de exclusão de item do palete: $e',
      );
    }
  }

  /// Busca todos os itens de um palete específico da API.
  Future<ApiResponse<List<PalletItemModel>>> getPalletItems(int palletId) async {
    try {
      final response = await apiClient.getAuth('${ApiRoutes.palletItems}/$palletId');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<PalletItemModel> items = jsonList
            .map((json) => PalletItemModel.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: items);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Erro ao buscar itens do palete.';
        return ApiResponse(
          success: false,
          message: 'Erro: ${response.statusCode} - $errorMessage',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de itens do palete: $e',
      );
    }
  }

  /// Busca TODOS os itens de TODOS os paletes da API.
  Future<ApiResponse<List<PalletItemModel>>> getAllPalletItems() async {
    try {
      // Assumindo que a API tem uma rota que retorna todos os itens de todos os paletes.
      // Substitua ApiRoutes.palletItems pela rota correta se necessário.
      final response = await apiClient.getAuth(ApiRoutes.allPalletItems); 

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<PalletItemModel> items = jsonList
            .map((json) => PalletItemModel.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: items);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Erro ao buscar todos os itens de palete.';
        return ApiResponse(
          success: false,
          message: 'Erro: ${response.statusCode} - $errorMessage',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de todos os itens de palete: $e',
      );
    }
  }

  Future<ApiResponse<List<PalletItemModel>>> getFilterPalletItems(String? status, String txtFilter) async {

    final safeTxtFilter = txtFilter.trim().isEmpty ? null : txtFilter.trim();
    Map<String, dynamic> queryParams = {};

    if (status != null) {
      queryParams['status'] = status;
    }
    
    if (safeTxtFilter != null) {
      queryParams['txtFilter'] = safeTxtFilter;
    }

    final uri = Uri(
      path: ApiRoutes.palletSearchItem, 
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    
    final routeFilter = uri.toString();
    
    try {
      final response = await apiClient.getAuth(routeFilter);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<PalletItemModel> itemsPallet = jsonList
            .map((json) => PalletItemModel.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: itemsPallet);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar os itens: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição: $e',
      );
    }
  }

  /// Busca todos os paletes da API.
  Future<ApiResponse<List<dynamic>>> getPalletImagesPath(int palletId) async {
    try {
      final response = await apiClient.getAuth("${ApiRoutes.palletImages}/$palletId");

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);

        return ApiResponse(success: true, data: jsonList);

        /*
        final List<FtpImageResponse> pallets = jsonList
            .map((json) => FtpImageResponse.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: pallets);
        */
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar paletes: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de paletes: $e',
      );
    }
  }

}
