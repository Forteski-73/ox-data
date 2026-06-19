// -----------------------------------------------------------
// app/core/repositories/inventory_repository.dart
// -----------------------------------------------------------
//
//  - _request<T>() genérico elimina try/catch repetido em todo método
//  - _decodeBody() centraliza json.decode + tratamento de body vazio
//  - _parseList<T>() para rotas que retornam arrays
//  - Todos os métodos ficam ≤ 10 linhas (lógica de rede isolada)
//  - Nenhuma funcionalidade removida; assinaturas públicas preservadas
// -----------------------------------------------------------

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/InventoryBatchRequest.dart';
import 'package:oxdata/app/core/models/dto/mask_db_local.dart';
import 'package:oxdata/app/core/models/dto/product_db_local.dart';
import 'package:oxdata/app/core/models/inventory_guid_model.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/app/core/models/inventory_record_model.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/utils/logger.dart';
import 'dart:developer' as dev;

class InventoryRepository {
  InventoryRepository({required this.apiClient});

  final ApiClient apiClient;

  // Base de todas as rotas deste repositório
  String get _base => ApiRoutes.inventory;

  // =========================================================================
  // GUID
  // =========================================================================

  Future<ApiResponse<InventoryGuidModel>> createInventoryGuid(
    InventoryGuidModel model,
  ) =>
      _request(
        () => apiClient.postAuth1(_base, body: model.toMap()),
        onSuccess: (body, status) {
          if (status == 201) return InventoryGuidModel.fromMap(body);
          if (status == 200 && body['data'] != null) {
            return InventoryGuidModel.fromMap(body['data']);
          }
          return null;
        },
      );

  Future<ApiResponse<List<InventoryGuidModel>>> getAllInventoryGuids() =>
      _requestList(
        () => apiClient.getAuth(_base),
        fromMap: InventoryGuidModel.fromMap,
      );

  Future<ApiResponse<InventoryGuidModel>> getInventoryGuidByGuid(
    String inventGuid,
  ) =>
      _request(
        () => apiClient.getAuth('$_base/ByGuid/$inventGuid'),
        onSuccess: (body, _) => InventoryGuidModel.fromMap(body),
      );

  // =========================================================================
  // INVENTORY (cabeçalho)
  // =========================================================================

  Future<ApiResponse<List<InventoryModel>>> getAllInventories() =>
      _requestList(
        () => apiClient.getAuth('$_base/All'),
        fromMap: InventoryModel.fromMap,
      );

  Future<ApiResponse<List<InventoryModel>>> getRecentInventoriesByGuid(
    String guid,
  ) =>
      _requestList(
        () => apiClient.getAuth('$_base/RecentByGuid/$guid'),
        fromMap: InventoryModel.fromMap,
      );

  Future<ApiResponse<InventoryModel>> getInventoryByGuid(String guid) =>
      _request(
        () => apiClient.getAuth('$_base/Inventory/$guid'),
        onSuccess: (body, _) => InventoryModel.fromMap(body),
      );

  Future<ApiResponse<InventoryModel>> getInventoryByGuidInventCode(
    String guid,
    String inventCode,
  ) =>
      _request(
        () => apiClient.getAuth('$_base/Inventory/$guid/$inventCode'),
        onSuccess: (body, _) => InventoryModel.fromMap(body),
      );

  Future<ApiResponse<InventoryModel>> createOrUpdateInventory(
    InventoryModel inventory,
  ) =>
      _request(
        () => apiClient.postAuth1('$_base/Inventory', body: inventory.toMap()),
        onSuccess: (body, status) {
          if (status == 201) return InventoryModel.fromMap(body);
          if (status == 200 && body['data'] != null) {
            return InventoryModel.fromMap(body['data']);
          }
          return null;
        },
      );

  Future<ApiResponse<String>> deleteInventory(String inventCode) =>
      _requestString(
        () => apiClient.deleteAuth('$_base/Inventory/$inventCode'),
        fallback: 'Inventário excluído com sucesso.',
      );

  // =========================================================================
  // PRODUCTS
  // =========================================================================

  Future<ApiResponse<int>> getProductCount() => _request(
        () => apiClient.getAuth('$_base/Product/Count'),
        onSuccess: (body, _) => body['total'] as int,
      );

  Future<ApiResponse<List<ProductLocal>>> getProductsPaged({
    required int page,
    required int pageSize,
  }) =>
      _requestList(
        () => apiClient.getAuth('$_base/Product?page=$page&pageSize=$pageSize'),
        fromMap: ProductLocal.fromMap,
      );

  // =========================================================================
  // RECORDS (itens de inventário)
  // =========================================================================

  Future<ApiResponse<String>> createOrUpdateInventoryRecords(
    List<InventoryBatchRequest> records,
  ) async {
    final requestBody = records.map((r) => r.toJson()).toList();

    logger.d('🚀 POST $_base/Record');
    dev.log(json.encode(requestBody));

    return _request(
      () => apiClient.postAuth1('$_base/Record', body: requestBody),
      onSuccess: (body, _) => body['message'] ?? 'Registros salvos com sucesso.',
      includeRawJson: true,
    );
  }

  Future<ApiResponse<List<InventoryRecordModel>>> getRecordsByInventCode(
    String inventCode,
  ) =>
      _requestList(
        () => apiClient.getAuth('$_base/Record/ByCode/$inventCode'),
        fromMap: InventoryRecordModel.fromMap,
      );

  Future<ApiResponse<InventoryRecordModel>> getRecordById(int id) =>
      _request(
        () => apiClient.getAuth('$_base/Record/$id'),
        onSuccess: (body, _) => InventoryRecordModel.fromMap(body),
      );

  Future<ApiResponse<String>> deleteInventoryRecord(int id) =>
      _requestString(
        () => apiClient.deleteAuth('$_base/Record/$id'),
        fallback: 'Registro excluído com sucesso.',
      );

  // =========================================================================
  // MASKS
  // =========================================================================

  Future<ApiResponse<List<InventoryMaskLocal>>> getInventoryMasks() =>
      _requestList(
        () => apiClient.getAuth('$_base/Masks'),
        fromMap: InventoryMaskLocal.fromMap,
      );

  // =========================================================================
  // HELPERS PRIVADOS
  // =========================================================================

  /// Executa uma requisição HTTP e mapeia o resultado para [ApiResponse<T>].
  ///
  /// [onSuccess] recebe o body decodificado e o status code, e deve retornar
  /// o dado tipado ou null (que gera falha com mensagem genérica).
  /// [includeRawJson] repassa o body bruto em [ApiResponse.rawJson].
  Future<ApiResponse<T>> _request<T>(
    Future<dynamic> Function() call, {
    required T? Function(Map<String, dynamic> body, int status) onSuccess,
    bool includeRawJson = false,
  }) async {
    try {
      final response = await call();
      final status = response.statusCode as int;
      final body = _decodeBody(response.body);

      if (status == 200 || status == 201) {
        final data = onSuccess(body, status);
        if (data != null) {
          return ApiResponse(
            success: true,
            data: data,
            rawJson: includeRawJson ? body : null,
          );
        }
      }
      // 404 → mensagem específica; outros → mensagem do body ou genérica
      final message = status == 404 ? 'Recurso não encontrado.' : _messageFrom(body) ?? 'Erro HTTP $status';

      return ApiResponse(success: false, message: message);

    } catch (e) {
      debugPrint('❌ InventoryRepository._request: $e');
      return ApiResponse(success: false, message: 'Falha na requisição: $e');
    }
  }

  /// Versão de [_request] para rotas que retornam arrays JSON.
  Future<ApiResponse<List<T>>> _requestList<T>(
    Future<dynamic> Function() call, {
    required T Function(Map<String, dynamic>) fromMap,
  }) async {
    try {
      final response = await call();
      final status = response.statusCode as int;

      if (status == 200) {
        final list = json.decode(response.body) as List<dynamic>;
        return ApiResponse(
          success: true,
          data: list.map((e) => fromMap(e as Map<String, dynamic>)).toList(),
        );
      }

      return ApiResponse(
        success: false,
        message: status == 404 ? 'Nenhum registro encontrado.' : 'Erro HTTP $status',
      );
    } catch (e) {
      debugPrint('❌ InventoryRepository._requestList: $e');
      return ApiResponse(success: false, message: 'Falha na requisição: $e');
    }
  }

  /// Versão de [_request] para rotas DELETE que retornam uma mensagem de texto.
  Future<ApiResponse<String>> _requestString(
    Future<dynamic> Function() call, {
    required String fallback,
  }) async {
    try {
      final response = await call();
      final status = response.statusCode as int;

      if (status == 200 || status == 204) {
        final body =
            response.body.isNotEmpty ? _decodeBody(response.body) : <String, dynamic>{};
        return ApiResponse(
          success: true,
          data: _messageFrom(body) ?? fallback,
        );
      }

      return ApiResponse(success: false, message: 'Erro HTTP $status');
    } catch (e) {
      debugPrint('❌ InventoryRepository._requestString: $e');
      return ApiResponse(success: false, message: 'Falha na requisição: $e');
    }
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) return {};
    try {
      final decoded = json.decode(body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  String? _messageFrom(Map<String, dynamic> body) =>
      (body['message'] ?? body['Message']) as String?;
}