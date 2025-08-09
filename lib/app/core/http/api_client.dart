// -----------------------------------------------------------
// app/core/http/api_client.dart
// -----------------------------------------------------------
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/interceptors/auth_interceptor.dart';

/// Classe responsável por fazer todas as requisições HTTP da API.
/// Usa o Interceptor para centralizar a lógica de cabeçalhos e tokens.
class ApiClient {
  final http.Client _publicClient;
  late final InterceptedClient _authenticatedClient;
  final AuthInterceptor _authInterceptor;

  // Construtor privado para o padrão Singleton.
  ApiClient._internal()
      : _publicClient = http.Client(),
        _authInterceptor = AuthInterceptor() {
    _authenticatedClient = InterceptedClient.build(
      interceptors: [
        _authInterceptor,
      ],
    );
  }

  // Instância única do Singleton.
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() {
    return _instance;
  }

  /// Método para requisições POST sem autenticação.
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('${ApiRoutes.baseUrl}$endpoint');

    try {
      final response = await _publicClient.post(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      
      return response;
    } on Exception catch (e) {
      throw Exception('Erro de rede: $e');
    }
  }

  /// Método para requisições POST com autenticação.
  Future<http.Response> postAuth(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('${ApiRoutes.baseUrl}$endpoint');

    try {
      // Usa o cliente com o interceptor para adicionar o token.
      final response = await _authenticatedClient.post(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      
      return response;
    } on Exception catch (e) {
      throw Exception('Erro de rede: $e');
    }
  }
  
  /// Método para requisições GET com autenticação.
  Future<http.Response> getAuth(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('${ApiRoutes.baseUrl}$endpoint');
    //final url = Uri.parse(endpoint); // O endpoint já deve ser a URL completa

    try {
      // Usa o cliente com o interceptor para adicionar o token.
      final response = await _authenticatedClient.get(
        url,
        headers: headers,
      );
      
      return response;
    } on Exception catch (e) {
      throw Exception('Erro de rede: $e');
    }
  }

  /// Método para atualizar o token JWT dinâmico no interceptor após o login.
  void updateToken(String token) {
    _authInterceptor.setDynamicToken(token);
  }
}