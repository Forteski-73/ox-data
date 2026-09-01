// -----------------------------------------------------------
// app/core/repositories/kpi_repository.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/dto/kpi_completude_model.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';

/// Repositório responsável pela comunicação com a API de KPIs
/// (endpoints do KpiController: /v1/Kpi).
class KpiRepository {
  final ApiClient apiClient;

  KpiRepository({required this.apiClient});

  /// Busca os indicadores de completude de imagens dos produtos
  /// (geral e por categoria: Produto, Embalagem, Paletização).
  /// GET /v1/Kpi/Completude
  Future<ApiResponse<KpiCompletudeModel>> getCompletude() async {
    try {
      final response = await apiClient.getAuth(ApiRoutes.kpiCompletude);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        final completude = KpiCompletudeModel.fromMap(jsonMap);
        return ApiResponse(success: true, data: completude);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar indicadores de completude: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de completude: $e',
      );
    }
  }
}
