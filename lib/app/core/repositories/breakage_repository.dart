// -----------------------------------------------------------
// app/core/repositories/breakage_repository.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/breakage_history_model.dart';
import 'package:oxdata/app/core/models/breakage_model.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';

/// Resultado da baixa em lote (POST /v1/Breakage/writeoff).
class BreakageWriteOffResult {
  final List<int> succeeded;
  final Map<int, String> failed; // breakageId -> mensagem

  BreakageWriteOffResult({required this.succeeded, required this.failed});
}

/// Repositório responsável pela comunicação com a API de quebras
/// (endpoints do BreakageController: /v1/Breakage).
class BreakageRepository {
  final ApiClient apiClient;

  BreakageRepository({required this.apiClient});

  /// Busca os registros de quebra filtrados.
  /// GET /v1/Breakage?status=&storeId=&dateFrom=&dateTo=
  Future<ApiResponse<List<BreakageModel>>> getAll([BreakageFilter filter = const BreakageFilter()]) async {
    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final query = <String, String>{
        if (filter.statuses.isNotEmpty) 'status': filter.statuses.join(','),
        if (filter.storeId != null) 'storeId': filter.storeId!,
        if (filter.dateFrom != null) 'dateFrom': dateFormat.format(filter.dateFrom!),
        if (filter.dateTo != null) 'dateTo': dateFormat.format(filter.dateTo!),
      };
      final endpoint = query.isEmpty
          ? ApiRoutes.breakage
          : '${ApiRoutes.breakage}?${Uri(queryParameters: query).query}';

      final response = await apiClient.getAuth(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<BreakageModel> breakages = jsonList
            .map((json) => BreakageModel.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: breakages);
      } else {
        return ApiResponse(
          success: false,
          message: _errorMessage(response, 'Erro ao buscar quebras'),
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de quebras: $e',
      );
    }
  }

  /// Cria um registro de quebra (a API define status e preço).
  /// POST /v1/Breakage
  Future<ApiResponse<bool>> create(BreakageModel breakage) {
    return _post(ApiRoutes.breakage, breakage.toCreateMap(), 'Erro ao salvar quebra');
  }

  /// Edita foto e/ou quantidade (somente os campos alterados).
  /// POST /v1/Breakage/{id}/edit
  Future<ApiResponse<bool>> edit(
    int breakageId, {
    int? quantity,
    String? photoUrl,
    required String justification,
  }) {
    return _post(
      ApiRoutes.breakageAction(breakageId, 'edit'),
      {
        if (quantity != null) 'quantity': quantity,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'justification': justification,
      },
      'Erro ao editar quebra',
    );
  }

  /// Aprova a etapa atual (gerente ou Controles Internos).
  /// POST /v1/Breakage/{id}/approve
  Future<ApiResponse<bool>> approve(int breakageId) {
    return _post(ApiRoutes.breakageAction(breakageId, 'approve'), null, 'Erro ao aprovar quebra');
  }

  /// Reprova e devolve ao gerente (Controles Internos).
  /// POST /v1/Breakage/{id}/return
  Future<ApiResponse<bool>> returnToManager(int breakageId, String reason) {
    return _post(ApiRoutes.breakageAction(breakageId, 'return'), {'reason': reason}, 'Erro ao reprovar quebra');
  }

  /// Exclusão lógica (status EXCLUIDO), com motivo obrigatório (gerente).
  /// POST /v1/Breakage/{id}/delete
  Future<ApiResponse<bool>> delete(int breakageId, String reason) {
    return _post(ApiRoutes.breakageAction(breakageId, 'delete'), {'reason': reason}, 'Erro ao excluir quebra');
  }

  /// Reenvia um registro devolvido para Controles Internos (gerente).
  /// POST /v1/Breakage/{id}/resubmit
  Future<ApiResponse<bool>> resubmit(int breakageId, String? reason) {
    return _post(
      ApiRoutes.breakageAction(breakageId, 'resubmit'),
      {'reason': reason},
      'Erro ao reenviar quebra',
    );
  }

  /// Dá baixa em lote nos registros aprovados.
  /// POST /v1/Breakage/writeoff
  Future<ApiResponse<BreakageWriteOffResult>> writeOff(List<int> breakageIds) async {
    try {
      final response = await apiClient.postAuth1(
        ApiRoutes.breakageWriteOff,
        body: {'ids': breakageIds},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = response.body.isEmpty ? {} : json.decode(response.body);
        final succeeded = (body['succeeded'] as List<dynamic>? ?? breakageIds).map((e) => e as int).toList();
        final failed = <int, String>{
          for (final f in (body['failed'] as List<dynamic>? ?? []))
            (f as Map<String, dynamic>)['id'] as int: f['message'] as String? ?? 'Falha',
        };
        return ApiResponse(success: true, data: BreakageWriteOffResult(succeeded: succeeded, failed: failed));
      } else {
        return ApiResponse(
          success: false,
          message: _errorMessage(response, 'Erro ao dar baixa'),
          rawJson: {'statusCode': response.statusCode},
        );
      }
    } on Exception catch (e) {
      return ApiResponse(success: false, message: 'Falha na requisição de baixa: $e');
    }
  }

  /// Linha do tempo do registro.
  /// GET /v1/Breakage/{id}/history
  Future<ApiResponse<List<BreakageHistoryModel>>> getHistory(int breakageId) async {
    try {
      final response = await apiClient.getAuth(ApiRoutes.breakageAction(breakageId, 'history'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final history = jsonList
            .map((json) => BreakageHistoryModel.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: history);
      } else {
        return ApiResponse(success: false, message: _errorMessage(response, 'Erro ao buscar histórico'));
      }
    } on Exception catch (e) {
      return ApiResponse(success: false, message: 'Falha na requisição do histórico: $e');
    }
  }

  /// Indica se a resposta foi um 409 (status mudou: outro usuário já agiu).
  static bool isConflict(ApiResponse<dynamic> response) => response.rawJson?['statusCode'] == 409;

  Future<ApiResponse<bool>> _post(String endpoint, Map<String, dynamic>? body, String errorPrefix) async {
    try {
      final response = await apiClient.postAuth1(endpoint, body: body);

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return ApiResponse(success: true, data: true);
      }
      return ApiResponse(
        success: false,
        message: _errorMessage(response, errorPrefix),
        rawJson: {'statusCode': response.statusCode},
      );
    } on Exception catch (e) {
      return ApiResponse(success: false, message: 'Falha na requisição: $e');
    }
  }

  /// Usa a `message` do corpo de erro quando houver; senão, um texto padrão por status.
  String _errorMessage(http.Response response, String prefix) {
    try {
      final Map<String, dynamic> errorBody = json.decode(response.body);
      final message = errorBody['message'] as String?;
      if (message != null && message.isNotEmpty) return message;
    } catch (_) {}

    return switch (response.statusCode) {
      403 => 'Você não tem permissão para esta ação.',
      409 => 'O registro já foi alterado por outro usuário. A lista foi atualizada.',
      422 => 'Dados inválidos. Verifique os campos e tente novamente.',
      _   => '$prefix: ${response.statusCode}',
    };
  }
}
