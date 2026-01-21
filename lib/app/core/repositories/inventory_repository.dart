// -----------------------------------------------------------
// app/core/repositories/inventory_repository.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/inventory_model.dart'; // Assumindo InventoryModel
import 'package:oxdata/app/core/models/inventory_guid_model.dart'; // Assumindo InventoryGuidModel
import 'package:oxdata/app/core/models/inventory_record_model.dart'; // Assumindo InventoryRecordModel
import 'package:oxdata/app/core/models/dto/mask_db_local.dart';
import 'package:oxdata/app/core/models/dto/product_db_local.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/models/InventoryBatchRequest.dart';

/// Repositório responsável pela comunicação com a API de Inventário.
class InventoryRepository {
  final ApiClient apiClient;

  InventoryRepository({required this.apiClient});

  // =========================================================================
  // === MÉTODOS PARA INVENTORY GUID (v1/Inventory)
  // =========================================================================

  /// POST: Cria um novo GUID de inventário (ou confirma a existência).
  ///
  /// Rota: POST v1/Inventory
  Future<ApiResponse<InventoryGuidModel>> createInventoryGuid(
      InventoryGuidModel inventoryGuid) async {
    try {
      final response = await apiClient.postAuth1(
        ApiRoutes.inventory, // Assumindo ApiRoutes.inventory = "v1/Inventory"
        body: inventoryGuid.toMap(),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 201) {
        // 201 Created
        return ApiResponse(success: true, data: InventoryGuidModel.fromMap(body));
      } else if (response.statusCode == 200 && body['data'] != null) {
        // 200 OK (se o GUID já existia)
        return ApiResponse(
          success: true,
          message: body['message'],
          data: InventoryGuidModel.fromMap(body['data']),
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ??
              'Erro ao criar/verificar GUID: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de GUID: $e',
      );
    }
  }

  /// GET: Busca todos os GUIDs de inventário.
  ///
  /// Rota: GET v1/Inventory
  Future<ApiResponse<List<InventoryGuidModel>>> getAllInventoryGuids() async {
    try {
      final response = await apiClient.getAuth(ApiRoutes.inventory);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<InventoryGuidModel> guids = jsonList
            .map((json) => InventoryGuidModel.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: guids);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar GUIDs: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de todos os GUIDs: $e',
      );
    }
  }

  /// GET: Busca GUID de inventário por `invent_guid`.
  ///
  /// Rota: GET v1/Inventory/ByGuid/{inventGuid}
  Future<ApiResponse<InventoryGuidModel>> getInventoryGuidByGuid(
      String inventGuid) async {
    try {
      final route = '${ApiRoutes.inventory}/ByGuid/$inventGuid';
      final response = await apiClient.getAuth(route);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return ApiResponse(
          success: true,
          data: InventoryGuidModel.fromMap(jsonMap),
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(success: false, message: 'GUID não encontrado.');
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar GUID: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de GUID: $e',
      );
    }
  }

  // =========================================================================
  // === MÉTODOS PARA INVENTORY (v1/Inventory/Inventory)
  // =========================================================================

  /// POST: Cria ou atualiza um Inventário principal.
  ///
  /// Rota: POST v1/Inventory/Inventory
    /*
    Future<ApiResponse<InventoryModel>> createOrUpdateInventory(
        InventoryModel inventory) async
    {
      try {
        final response = await apiClient.postAuth1(
          '${ApiRoutes.inventory}/Inventory',
          body: inventory.toMap(),
        );

        final body = json.decode(response.body);

        if (response.statusCode == 201) {
          // 201 Created (Nova criação)
          return ApiResponse(success: true, data: InventoryModel.fromMap(body));
        } else if (response.statusCode == 200 && body['data'] != null) {
          // 200 OK (Atualização)
          return ApiResponse(
            success: true,
            message: body['message'],
            data: InventoryModel.fromMap(body['data']),
          );
        } else {
          return ApiResponse(
            success: false,
            message: body['message'] ??
                'Erro ao salvar/atualizar Inventário: ${response.statusCode}',
          );
        }
      } on Exception catch (e) {
        return ApiResponse(
          success: false,
          message: 'Falha no salvamento do Inventário: $e',
        );
      }
    }

    */

  Future<ApiResponse<InventoryModel>> createOrUpdateInventory(
    InventoryModel inventory) async {
    try {
      final response = await apiClient.postAuth1(
        '${ApiRoutes.inventory}/Inventory',
        body: inventory.toMap(),
      );

      dynamic body;

      try {
        body = response.body.isNotEmpty
            ? json.decode(response.body)
            : null;
      } catch (_) {
        body = null; // resposta não é JSON
      }

      if (response.statusCode == 201 && body is Map) {
        return ApiResponse(
          success: true,
          data: InventoryModel.fromMap(Map<String, dynamic>.from(body),),
        );
      }

      if (response.statusCode == 200 &&
          body is Map &&
          body['data'] != null) {
        return ApiResponse(
          success: true,
          message: body['message'],
          data: InventoryModel.fromMap(body['data']),
        );
      }

      return ApiResponse(
        success: false,
        message: body is Map
            ? body['message']
            : response.body, // texto puro vindo da API
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha no salvamento do Inventário: $e',
      );
    }
  }


  /// GET: Busca todos os Inventários principais.
  ///
  /// Rota: GET v1/Inventory/Inventory
  // Assumindo que este código está em InventoryRepository
  Future<ApiResponse<List<InventoryModel>>> getRecentInventoriesByGuid(String guid) async {
    try {
      // Rota correta (como você definiu)
      final route = '${ApiRoutes.inventory}/RecentByGuid/$guid'; 
      final response = await apiClient.getAuth(route);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        
        // Mapeamento para List<InventoryModel>
        final List<InventoryModel> inventories = jsonList
            .map((json) => InventoryModel.fromMap(json as Map<String, dynamic>))
            .toList();
            
        return ApiResponse(success: true, data: inventories); // Retorna List<InventoryModel>
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar Inventários: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de todos os Inventários: $e',
      );
    }
  }

  /// GET: Busca Inventário por GUID.
  ///
  /// Rota: GET v1/Inventory/Inventory/{guid}
  Future<ApiResponse<InventoryModel>> getInventoryByGuid(String guid) async {
    try {
      final route = '${ApiRoutes.inventory}/Inventory/$guid';
      final response = await apiClient.getAuth(route);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return ApiResponse(
          success: true,
          data: InventoryModel.fromMap(jsonMap),
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(success: false, message: 'Inventário não encontrado.');
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar Inventário: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de Inventário: $e',
      );
    }
  }

  /// GET: Busca Inventário por GUID e InventCode.
  ///
  /// Rota: GET v1/Inventory/Inventory/{guid}/{inventCode}
  Future<ApiResponse<InventoryModel>> getInventoryByGuidInventCode(
      String guid, String inventCode) async {
    try {
      final route = '${ApiRoutes.inventory}/Inventory/$guid/$inventCode';
      final response = await apiClient.getAuth(route);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return ApiResponse(
          success: true,
          data: InventoryModel.fromMap(jsonMap),
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(success: false, message: 'Inventário não encontrado.');
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar Inventário: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de Inventário: $e',
      );
    }
  }
  

  /// DELETE: Exclui um Inventário principal.
  ///
  /// Rota: DELETE v1/Inventory/Inventory/{inventCode}
  Future<ApiResponse<String>> deleteInventory(String inventCode) async {
    try {
      final route = '${ApiRoutes.inventory}/Inventory/$inventCode';
      final response = await apiClient.deleteAuth(route);

      if (response.statusCode == 200 || response.statusCode == 204) {
        final body = json.decode(response.body);
        return ApiResponse(
          success: true,
          data: body['message'] ?? 'Inventário excluído com sucesso.',
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(success: false, message: 'Inventário não encontrado.');
      } else {
        return ApiResponse(
          success: false,
          message:
              'Erro ao excluir Inventário: ${response.statusCode} - ${response.body}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de exclusão de Inventário: $e',
      );
    }
  }

  // =========================================================================
  // === MÉTODOS PARA INVENTORY RECORD (v1/Inventory/Record)
  // =========================================================================

  /// Busca a contagem total de produtos
  /// GET: Busca a contagem total de produtos.
  /// Rota: GET v1/Inventory/Product/Count
  Future<ApiResponse<int>> getProductCount() async {
    try {
      final route = '${ApiRoutes.inventory}/Product/Count';
      final response = await apiClient.getAuth(route);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        // Garante que estamos pegando o valor inteiro do campo 'total'
        return ApiResponse(
          success: true, 
          data: body['total'] as int
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao obter contagem: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de contagem: $e',
      );
    }
  }

  /// Busca o lote específico de produtos
Future<ApiResponse<List<ProductLocal>>> getProductsPaged({
    required int page, 
    required int pageSize
  }) async {
    try {
      // Monta a query string manualmente para o getAuth
      final route = '${ApiRoutes.inventory}/Product?page=$page&pageSize=$pageSize';
      final response = await apiClient.getAuth(route);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        
        final List<ProductLocal> products = jsonList
            .map((json) => ProductLocal.fromMap(json as Map<String, dynamic>))
            .toList();

        return ApiResponse(success: true, data: products);
      } else if (response.statusCode == 404) {
        return ApiResponse(success: false, message: 'Fim dos registros ou página não encontrada.');
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

Future<ApiResponse<String>> createOrUpdateInventoryRecords(
      List<InventoryBatchRequest> records) async {
    try {
      final requestBody = records.map((r) => r.toJson()).toList();

      final response = await apiClient.postAuth1(
        '${ApiRoutes.inventory}/Record',
        body: requestBody,
      );

      final body = json.decode(response.body);

      /* body:
      0 = "inventGuid" -> "65c1aa5a-7b26-4fc3-8ea2-b2eb5b9f7102"
      1 = "inventCode" -> "INV-A001"
      2 = "inventTotal" -> 548.7
      3 = "message" -> "Operação concluída. 1 registro(s) inserido(s) e 0 registro(s) atualizado(s)."
      */
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: true,
          // Mapeia o campo 'message' conforme definido no seu DTO C#
          data: body['message'] ?? 'Registros salvos com sucesso.',
          // Passamos o body completo para o Service extrair InventCode e InventTotal
          rawJson: body, 
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ??
              'Erro ao salvar/atualizar registros: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha no salvamento dos Registros: $e',
      );
    }
  }

  /// GET: Busca todos os Records de um dado InventCode.
  ///
  /// Rota: GET v1/Inventory/Record/ByCode/{inventCode}
  Future<ApiResponse<List<InventoryRecordModel>>> getRecordsByInventCode(
      String inventCode) async {
    try {
      final route = '${ApiRoutes.inventory}/Record/ByCode/$inventCode';
      final response = await apiClient.getAuth(route);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<InventoryRecordModel> records = jsonList
            .map((json) =>
                InventoryRecordModel.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: records);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar Registros: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de Registros: $e',
      );
    }
  }

  /// GET: Busca InventoryRecord por ID.
  ///
  /// Rota: GET v1/Inventory/Record/{id}
  Future<ApiResponse<InventoryRecordModel>> getRecordById(int id) async {
    try {
      final route = '${ApiRoutes.inventory}/Record/$id';
      final response = await apiClient.getAuth(route);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return ApiResponse(
          success: true,
          data: InventoryRecordModel.fromMap(jsonMap),
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(success: false, message: 'Registro não encontrado.');
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar Registro: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de Registro: $e',
      );
    }
  }

  /// DELETE: Exclui um Registro de Inventário por ID.
  ///
  /// Rota: DELETE v1/Inventory/Record/{id}
  Future<ApiResponse<String>> deleteInventoryRecord(int id) async {
    try {
      final route = '${ApiRoutes.inventory}/Record/$id';
      final response = await apiClient.deleteAuth(route);

      if (response.statusCode == 200 || response.statusCode == 204) {
        final body = json.decode(response.body);
        return ApiResponse(
          success: true,
          data: body['message'] ?? 'Registro excluído com sucesso.',
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(success: false, message: 'Registro não encontrado.');
      } else {
        return ApiResponse(
          success: false,
          message:
              'Erro ao excluir Registro: ${response.statusCode} - ${response.body}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de exclusão de Registro: $e',
      );
    }
  }

  Future<ApiResponse<List<InventoryMaskLocal>>> getInventoryMasks() async {
    try {
      final route = '${ApiRoutes.inventory}/Masks';
      final response = await apiClient.getAuth(route);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final masks = jsonList
            .map((json) => InventoryMaskLocal.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: masks);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar máscaras: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Falha na requisição: $e');
    }
  }

}