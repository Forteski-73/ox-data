import 'dart:convert';
import 'package:oxdata/app/core/utils/logger.dart';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AiService {
  final String _url = 'https://oxfordonline.com.br/AI/analisarBase64';
  final Uri _urlTreinar = Uri.parse('https://oxfordonline.com.br/AI/treinar');

  /// Envia a imagem em Base64 para a API
  Future<Map<String, dynamic>> analisarImagem(
    String base64Image,
  ) async {
    try {
      // Request
      final url = Uri.parse(_url);

      final headers = {
        "Content-Type": "application/json",
      };

      final body = jsonEncode({
        "image_base64": base64Image,
      });

      // POST
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      // HTTP OK
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        return responseData;
        
      }

      // Erro HTTP
      throw Exception(
        'Erro no servidor: Código ${response.statusCode}',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }


Future<String> treinarImagem({
    required String categoria,
    String? base64Image,
    String? imageUrl,
    int augmentations = 10,
    String embeddingModel = "dinov2-base",
  }) async {
    try {
      // Validação rápida de segurança antes de disparar o HTTP
      if ((base64Image == null || base64Image.isEmpty) && (imageUrl == null || imageUrl.isEmpty)) {
        throw Exception('É necessário fornecer ou o "base64Image" ou a "imageUrl" para o treinamento.');
      }

      final Map<String, dynamic> payload = {
        "image_url": imageUrl ?? "",
        "image_base64": base64Image ?? "",
        "categoria": categoria.trim().toUpperCase(), // Normaliza para evitar duplicados por erro de digitação
        "embedding_model": embeddingModel,
        "augmentations": augmentations,
      };

      final response = await http.post(
        _urlTreinar,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        // 1. Decodifica o corpo como um Mapa (Json Object)
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // 2. Extrai a string que está dentro da chave 'message'
        final String message = data['message'] ?? 'Treinamento concluído com sucesso.';
        
        return message;
      }

      // Tratamento para o erro de validação 422 da API FastAPI
      if (response.statusCode == 422) {
        final errorDetail = jsonDecode(response.body);
        throw Exception('Erro de validação nos dados enviados: ${errorDetail["detail"]}');
      }

      throw Exception('Erro no servidor ao treinar: Código ${response.statusCode}');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}