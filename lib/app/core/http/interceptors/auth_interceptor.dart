// -----------------------------------------------------------
// app/core/http/interceptors/auth_interceptor.dart
// -----------------------------------------------------------
import 'dart:async';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'dart:convert';

/// Interceptor que gerencia o token de autenticação.
/// O token fixo é usado para obter o token JWT dinâmico.
class AuthInterceptor implements InterceptorContract {
  // Token fixo da API para a requisição de login.
  static const String _fixedToken = 'DF9z9WjjyK7PpESh5rV6lrCLuZkctFLP';
  // Variável para armazenar o token JWT dinâmico, que pode ser nulo.
  String? _dynamicToken;

  void setDynamicToken(String token) {
    _dynamicToken = token;
  }

  @override
  FutureOr<bool> shouldInterceptRequest() => true;

  @override
  FutureOr<bool> shouldInterceptResponse() => true;

  /// Intercepta a requisição e adiciona os cabeçalhos necessários.
  @override
  FutureOr<BaseRequest> interceptRequest({required BaseRequest request}) async {
    try {
      request.headers['Content-Type'] = 'application/json';
      
      // Se tivermos o token JWT dinâmico, usa ele.
      // Caso contrário, usa o token fixo.
      final tokenToUse = _dynamicToken ?? _fixedToken;
      request.headers['Authorization'] = 'Bearer $tokenToUse';
      
    } catch (e) {
      if (kDebugMode) {
        log('Erro ao adicionar cabeçalhos: $e');
      }
      // Lança a exceção para que o código chamador possa tratar.
      rethrow;
    }

    return request;
  }

  // Método para limpar o token dinâmico.
  void clearDynamicToken() {
    _dynamicToken = null;
  }

  @override
  FutureOr<BaseResponse> interceptResponse({required BaseResponse response}) async {

    if (response.statusCode == 401) {
      try {
        // Obter uma nova instância da requisição original
        final originalRequest = response.request;
        if (originalRequest != null) {
          // Obtém o novo token da API de login
          final newToken = await _getNewToken();
          
          if (newToken != null) {
            // Atualiza o token dinâmico no interceptor
            setDynamicToken(newToken);

            // Cria uma nova requisição com o token atualizado
            final newRequest = http.Request(originalRequest.method, originalRequest.url);
            newRequest.headers.addAll(originalRequest.headers);
            newRequest.headers['Authorization'] = 'Bearer $newToken';
            
            // Copia o corpo da requisição original
            if (originalRequest is http.Request) {
              if (originalRequest.bodyBytes.isNotEmpty) {
                newRequest.bodyBytes = originalRequest.bodyBytes;
              }
            }

            // Repete a requisição original com o novo token
            final client = http.Client();
            final newResponse = await client.send(newRequest);

            // Reconstroi a resposta para que o interceptor retorne a nova
            final http.Response finalResponse = await http.Response.fromStream(newResponse);
            
            if (kDebugMode) {
              log('Token renovado e requisição repetida com sucesso! Novo status: ${finalResponse.statusCode}');
            }
            return finalResponse;

          } 
        }
      } catch (e) {
        rethrow;
      }
    }

    if (kDebugMode) {
      if (response is http.Response) {
        // Requisições "normais"
      } 
      else if (response is http.StreamedResponse) {
        // Requisições multipart
        final streamedBody = await response.stream.bytesToString();
        // Precisa reconstruir para não "consumir" o stream
        return http.Response(
          streamedBody,
          response.statusCode,
          headers: response.headers,
          request: response.request,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        );
      } 
    }
    return response;
  }

  Future<String?> _getNewToken() async {
    String? token;
    try {
      final storage = StorageService();
      final client = http.Client();
      
      final creds = await storage.readCredentials();

      final response = await client.post(
        Uri.parse('${ApiRoutes.baseUrl}${ApiRoutes.login}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_fixedToken',
        },
        body: jsonEncode({
          'user'    : creds['username'],
          'password': creds['password'],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        token = data['token'] as String?;
        if (token != null) {
          setDynamicToken(token);
        }
      }
    } catch (e) {
      rethrow;
    }
    return token;
  }

}