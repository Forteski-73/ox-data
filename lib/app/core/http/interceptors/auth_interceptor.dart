// -----------------------------------------------------------
// app/core/http/interceptors/auth_interceptor.dart
// -----------------------------------------------------------
import 'dart:async';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:flutter/foundation.dart';

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
      
      // Se tivermos o token JWT dinâmico, o usamos.
      // Caso contrário, usamos o token fixo.
      final tokenToUse = _dynamicToken ?? _fixedToken;
      request.headers['Authorization'] = 'Bearer $tokenToUse';
      
    } catch (e) {
      if (kDebugMode) {
        log('Erro ao adicionar cabeçalhos: $e');
      }
    }

    // Adiciona logging detalhado da requisição em modo de depuração.
    if (kDebugMode) {
      // Verifica o tipo de requisição antes de tentar a conversão.
      if (request is http.Request) {
        log('REQUEST -> URL: ${request.url}\nMETHOD:${request.method}\nBODY: ${request.body}\nHEADERS: ${request.headers}');
      } else if (request is http.MultipartRequest) {
        // Para requisições multipart, não há um 'body' simples para ler.
        // O log é adaptado para mostrar os detalhes do formulário.
        log('REQUEST -> URL: ${request.url}\nMETHOD:${request.method}\nHEADERS: ${request.headers}\nFIELDS: ${request.fields}\nFILES: ${request.files.map((file) => file.filename)}');
      } else {
        // Para outros tipos de requisição
        log('REQUEST -> URL: ${request.url}\nMETHOD:${request.method}\nHEADERS: ${request.headers}');
      }
    }

    return request;
  }

  /*
  /// Intercepta a resposta e adiciona logging detalhado.
  @override
  FutureOr<BaseResponse> interceptResponse({required BaseResponse response}) {
    if (kDebugMode) {
      final httpResponse = response as http.Response;
      log('RESPONSE -> STATUS CODE: ${httpResponse.statusCode}\nBODY: ${httpResponse.body}');
    }
    return response;
  }
  */

  @override
  FutureOr<BaseResponse> interceptResponse({required BaseResponse response}) async {
    if (kDebugMode) {
      if (response is http.Response) {
        // Requisições "normais"
        log('RESPONSE -> STATUS CODE: ${response.statusCode}\nBODY: ${response.body}');
      } 
      else if (response is http.StreamedResponse) {
        // Requisições multipart
        final streamedBody = await response.stream.bytesToString();
        log('RESPONSE -> STATUS CODE: ${response.statusCode}\nBODY: $streamedBody');
        
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
      else {
        log('RESPONSE -> STATUS CODE: ${response.statusCode} (tipo desconhecido: ${response.runtimeType})');
      }
    }
    return response;
  }
}