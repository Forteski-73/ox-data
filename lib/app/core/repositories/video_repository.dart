// -----------------------------------------------------------
// app/core/repositories/video_repository.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/video_model.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';

/// Repositório responsável pela comunicação com a API de vídeos
/// (endpoints do VideoController: /v1/Video).
class VideoRepository {
  final ApiClient apiClient;

  VideoRepository({required this.apiClient});

  /// Busca todos os vídeos ativos, já com dados de categoria.
  /// GET /v1/Video
  Future<ApiResponse<List<VideoModel>>> getAllVideos() async {
    try {
      final response = await apiClient.getAuth(ApiRoutes.video);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<VideoModel> videos = jsonList
            .map((json) => VideoModel.fromMap(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: videos);
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar vídeos: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de vídeos: $e',
      );
    }
  }

  /// Busca um vídeo específico pelo id.
  /// GET /v1/Video/{id}
  Future<ApiResponse<VideoModel>> getVideoById(int id) async {
    try {
      final response = await apiClient.getAuth('${ApiRoutes.video}/$id');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        final video = VideoModel.fromMap(jsonMap);
        return ApiResponse(success: true, data: video);
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Vídeo não encontrado.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erro ao buscar vídeo: ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição de vídeo: $e',
      );
    }
  }
}