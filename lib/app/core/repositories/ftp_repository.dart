// -----------------------------------------------------------
// app/core/repositories/ftp_repository.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'package:http/http.dart' as http; 
import 'package:oxdata/app/core/globals/ApiRoutes.dart'; 
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/ftp_image_request.dart'; 
import 'package:oxdata/app/core/models/ftp_image_response.dart'; 
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';

/// Repositório responsável pela comunicação com a API de serviços FTP (base64).
class FtpRepository {
  final ApiClient apiClient;

  FtpRepository({required this.apiClient});

  /// 
  /// Faz uma requisição para a API para baixar uma lista de imagens 
  /// a partir de URLs de FTP e retorna o conteúdo em Base64.
  /// 
  Future<ApiResponse<List<FtpImageResponse>>> getImagesBase64(FtpImageRequest request) async {
    // Verifica se há URLs para processar
    if (request.imageUrls.isEmpty) {
      return ApiResponse(success: false, message: 'Nenhuma URL de imagem fornecida para download.');
    }

    try {

      final response = await apiClient.postAuth(
        ApiRoutes.ftpImage,
        body: request.toJson(),
      );

      //---------------------------------------------------------------------------

      if (response.statusCode == 200) {
        // A resposta é uma lista de objetos FtpImageResponse
        final List<dynamic> jsonList = json.decode(response.body);

        // Mapeia a lista de JSON para a lista de FtpImageResponse
        final List<FtpImageResponse> results = jsonList
            .map((jsonItem) => FtpImageResponse.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
            
        // Conta quantas falharam
        final int errorCount = results.where((r) => !r.isSuccessful).length;

        // Retorna a lista completa de resultados
        return ApiResponse(
          success: true, 
          data: results, 
          message: errorCount > 0 
            ? 'Processamento concluído com $errorCount falhas.'
            : 'Todas as imagens processadas com sucesso.'
        );
        
      } else {
        // Tenta decodificar o erro do corpo da resposta, se possível
        String errorMessage = 'Erro ao processar imagens FTP: ${response.statusCode}';
        try {
           final Map<String, dynamic> errorBody = json.decode(response.body);
           errorMessage = errorBody['message'] ?? errorMessage;
        } catch (_) {
          // Ignora se o corpo não for JSON
        }
        
        return ApiResponse(
          success: false,
          message: errorMessage,
        );
      }

      //---------------------------------------------------------------------------


    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição da API de FTP: $e',
      );
    }
  }
}
