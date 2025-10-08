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
        ApiRoutes.ftpGetImage,
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

  Future<ApiResponse<List<FtpImageResponse>>> setImagesBase64(
    List<FtpImageResponse> imagesToUpload,
  ) async {
    // 1️⃣ Validação inicial
    if (imagesToUpload.isEmpty) {
      return ApiResponse(success: false, message: 'Nenhuma imagem fornecida para upload.');
    }

    // 2️⃣ Prepara os caminhos das imagens existentes (para exclusão no FTP)
    final List<String> existingUrls = imagesToUpload
        .where((img) => img.url.isNotEmpty)
        .map((img) => img.url)
        .toList();

    // 3️⃣ Monta o corpo do DELETE (mesma estrutura que o controller FtpController espera)
    final Map<String, dynamic> deleteBody = {
      'ImageUrls': existingUrls,
    };

    try {
      
      // --------------------------------------------------------------------------
      // 🔹 PRIMEIRA ETAPA: Exclui as imagens antigas no FTP
      // --------------------------------------------------------------------------

      print('--------------------------------------------------');
      print('🧹 Iniciando exclusão das imagens existentes no FTP...');
      print('DELETE BODY: ${json.encode(deleteBody)}');
      print('--------------------------------------------------');

      final deleteResponse = await apiClient.deleteNAuth(
        ApiRoutes.ftpDelImage,
        body: deleteBody,
      );

      if (deleteResponse.statusCode == 200) {
        print('✅ Imagens anteriores excluídas com sucesso do FTP.');
      } else {
        print('⚠️ Falha ao excluir imagens anteriores. Status: ${deleteResponse.statusCode}');
        print('Resposta: ${deleteResponse.body}');
        // Você pode decidir continuar mesmo assim
      }

      // --------------------------------------------------------------------------
      // 🔹 SEGUNDA ETAPA: Envia as novas imagens
      // --------------------------------------------------------------------------
      final List<Map<String, dynamic>> jsonList = imagesToUpload
          .map((img) => {
                'Url': img.url,
                'Base64Content': img.base64Content,
              })
          .toList();

      final Map<String, dynamic> requestBody = {
        'Images': jsonList,
      };

      final String jsonString = json.encode(requestBody);
      print('--------------------------------------------------');
      print('🚀 POSTMAN BODY (API Upload: ${ApiRoutes.ftpSetImage})');
      print(jsonString);
      print('--------------------------------------------------');

      final response = await apiClient.postAuth(
        ApiRoutes.ftpSetImage,
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<FtpImageResponse> results = jsonList
            .map((jsonItem) => FtpImageResponse.fromJson(jsonItem as Map<String, dynamic>))
            .toList();

        final int errorCount = results.where((r) => !r.isSuccessful).length;

        return ApiResponse(
          success: true,
          data: results,
          message: errorCount > 0
              ? 'Processamento concluído com $errorCount falhas de upload.'
              : 'Todas as imagens enviadas com sucesso.',
        );
      } else {
        String errorMessage = 'Erro ao fazer upload de imagens: ${response.statusCode}';
        try {
          final Map<String, dynamic> errorBody = json.decode(response.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (_) {}
        return ApiResponse(success: false, message: errorMessage);
      }
    } on Exception catch (e) {
      return ApiResponse(
        success: false,
        message: 'Falha na requisição da API de upload de FTP: $e',
      );
    }
  }


/*
  Future<ApiResponse<List<FtpImageResponse>>> setImagesBase64(
    List<FtpImageResponse> imagesToUpload,
  ) async {

    // 1. Verifica se a lista de FtpImageResponse está vazia
    if (imagesToUpload.isEmpty) { 
      return ApiResponse(success: false, message: 'Nenhuma imagem fornecida para upload.');
    }

    final List<Map<String, dynamic>> jsonList = imagesToUpload
        .map((img) => {
             // As chaves que a API espera para cada item da imagem
             'Url': img.url, 
             'Base64Content': img.base64Content,
        })
        .toList();

    // ⭐️ AJUSTE CRÍTICO: Cria o Mapa raiz esperado pelo postAuth
    // Envolve a lista dentro de uma chave ('Data' ou 'Images'). 
    // Mantenha apenas 'Data' se for a chave correta.
    final Map<String, dynamic> requestBody = {
        'Images': jsonList, // ⬅️ O backend C# espera a chave 'Images'
    };

    final String jsonString = json.encode(requestBody);
    print('--------------------------------------------------');
    print('********************** POSTMAN BODY (API Upload: ${ApiRoutes.ftpSetImage})');
    print(jsonString);
    print('--------------------------------------------------');

    try {
      
      final response = await apiClient.postAuth(
        // Assumindo que a rota de upload é ApiRoutes.ftpImage ou ApiRoutes.ftpImageUpload.
        ApiRoutes.ftpSetImage, 
        body: requestBody, 
      );

      //---------------------------------------------------------------------------

      if (response.statusCode == 200) {
        // A resposta deve ser uma lista de objetos FtpImageResponse (o status de cada upload)
        final List<dynamic> jsonList = json.decode(response.body);

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
            ? 'Processamento concluído com $errorCount falhas de upload.'
            : 'Todas as imagens enviadas com sucesso.'
        );
        
      } else {
        // Lógica de tratamento de erro 
        String errorMessage = 'Erro ao fazer upload de imagens: ${response.statusCode}';
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
        message: 'Falha na requisição da API de upload de FTP: $e',
      );
    }
  }
*/

}
