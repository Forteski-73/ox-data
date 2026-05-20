import 'dart:convert';
import 'package:oxdata/app/core/utils/logger.dart';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AiService {
  final String _url =
      'https://oxfordonline.com.br/AI/analisarBase64';

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

        // Sucesso da API
        if (responseData['data'] != null) {
          return responseData['data'];
        }

        // Erro interno da API
        final msgErro = responseData['data']?['msg'] ?? 'Erro ao identificar a decoração.';

        throw Exception(msgErro);
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
}