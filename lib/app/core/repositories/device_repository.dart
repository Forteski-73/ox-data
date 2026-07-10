// -----------------------------------------------------------
// app/core/repositories/device_repository.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/tv_device_model.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';


/// Repositório responsável pela comunicação com a API de TV Devices
/// (endpoints do DeviceController: /v1/Device).
class DeviceRepository {
  final ApiClient apiClient;

  DeviceRepository({required this.apiClient});

  /// Busca todos os registros de tv_device.
  /// GET /v1/Device
  Future<ApiResponse<List<TvDeviceModel>>> getAllTvDevices() async {
    try {
      final response = await apiClient.getAuth(ApiRoutes.device);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<TvDeviceModel> devices = jsonList
            .map((json) => TvDeviceModel.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: devices);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar devices: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de devices: $e',
      );
    }
  }

  /// Busca um registro de tv_device pelo DeviceId.
  /// GET /v1/Device/{deviceId}
  Future<ApiResponse<TvDeviceModel>> getTvDeviceByDeviceId(int deviceId) async {
    try {
      final response = await apiClient.getAuth('${ApiRoutes.device}/$deviceId');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        final device = TvDeviceModel.fromMap(jsonMap);
        return ApiResponse(success: true, data: device);
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Nenhum registro de TV encontrado para o device informado.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar device: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de device: $e',
      );
    }
  }

  /// Busca todos os devices vinculados a um setor.
  /// GET /v1/Device/Setor/{setor}
  Future<ApiResponse<List<TvDeviceModel>>> getTvDevicesBySetor(String setor) async {
    try {
      final response = await apiClient.getAuth('${ApiRoutes.device}/$setor');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<TvDeviceModel> devices = jsonList
            .map((json) => TvDeviceModel.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: devices);
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Nenhum device encontrado para o setor informado.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar devices por setor: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de devices por setor: $e',
      );
    }
  }

  /// Vincula um device a um setor (cria o registro em tv_device).
  /// POST /v1/Device
  Future<ApiResponse<TvDeviceModel>> createTvDevice(int deviceId, String setor) async {
    try {
      final requestBody = {
        'deviceId': deviceId,
        'setor': setor,
      };

      final response = await apiClient.postAuth1(
        ApiRoutes.device,
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        final created = TvDeviceModel.fromMap(jsonMap);
        return ApiResponse(success: true, data: created);
      } else if (response.statusCode == 409) {
        return ApiResponse(
          success: false,
          message: 'Este device já possui um setor configurado.',
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Device não encontrado.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao vincular device: ${response.statusCode} - ${response.body}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha ao vincular device: $e',
      );
    }
  }

  /// Atualiza o setor de um device já vinculado.
  /// PUT /v1/Device/{deviceId}
  Future<ApiResponse<TvDeviceModel>> updateTvDevice(int deviceId, String setor) async {
    try {
      final requestBody = {
        'deviceId': deviceId,
        'setor': setor,
      };

      final response = await apiClient.putAuth(
        '${ApiRoutes.device}/$deviceId',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        final updated = TvDeviceModel.fromMap(jsonMap);
        return ApiResponse(success: true, data: updated);
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Nenhum registro de TV encontrado para o device informado.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao atualizar device: ${response.statusCode} - ${response.body}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha ao atualizar device: $e',
      );
    }
  }

  /// Remove o vínculo de um device com o setor.
  /// DELETE /v1/Device/{deviceId}
  Future<ApiResponse<String>> deleteTvDevice(int deviceId) async {
    try {
      final response = await apiClient.deleteAuth('${ApiRoutes.device}/$deviceId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse(
          success: true,
          data: 'Device $deviceId removido com sucesso.',
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Nenhum registro de TV encontrado para o device informado.',
        );
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Erro ao remover device.';
        return ApiResponse(
          success: false,
          message: 'Erro ao remover device: ${response.statusCode} - $errorMessage',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de remoção de device: $e',
      );
    }
  }

  /// Envia/atualiza o transCode de uma TV específica vinculada ao setor.
  /// POST /v1/Device/TvDevice/{deviceId}
  ///
  /// Ex.: sendTransCode(4, setor: 'EMBALAGEM', transCode: '171')
  Future<ApiResponse<TvDeviceModel>> sendTransCode({
    required int deviceId,
    required String setor,
    required String transCode,
  }) async {
    try {
      final requestBody = {
        'setor': setor,
        'transCode': transCode,
      };

      final response = await apiClient.postAuth1(
        '${ApiRoutes.tvDevice}/$deviceId',
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        final updated = TvDeviceModel.fromMap(jsonMap);
        return ApiResponse(success: true, data: updated);
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Device não encontrado.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao enviar transCode: ${response.statusCode} - ${response.body}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha ao enviar transCode: $e',
      );
    }
  }

}