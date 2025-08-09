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
      final httpRequest = request as http.Request;
      // Loga a URL, método, corpo e agora também os cabeçalhos.
      log('REQUEST -> URL: ${httpRequest.url}\nMETHOD:${httpRequest.method}\nBODY: ${httpRequest.body}\nHEADERS: ${httpRequest.headers}');
    }

    return request;
  }

  /// Intercepta a resposta e adiciona logging detalhado.
  @override
  FutureOr<BaseResponse> interceptResponse({required BaseResponse response}) {
    if (kDebugMode) {
      final httpResponse = response as http.Response;
      log('RESPONSE -> STATUS CODE: ${httpResponse.statusCode}\nBODY: ${httpResponse.body}');
    }
    return response;
  }
}