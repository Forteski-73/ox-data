// -----------------------------------------------------------
// app/core/services/storage_service.dart
// -----------------------------------------------------------
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Classe de serviço para operações de armazenamento
class StorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Limpa o token de autenticação salvo.
  Future<void> clearAuthToken() async {
    try {
      await _storage.delete(key: 'jwt_token');
      print('Token de autenticação removido com sucesso.');
    } catch (e) {
      print('Erro ao tentar remover o token: $e');
    }
  }

  /// Lê e retorna o token de autenticação salvo, se existir.
  Future<String?> readAuthToken() async {
    try {
      String? token = await _storage.read(key: 'jwt_token');
      return token;
    } catch (e) {
      return null;
    }
  }

  /// Salva o token de autenticação no armazenamento seguro.
  Future<void> writeAuthToken(String token) async {
    try {
      await _storage.write(key: 'jwt_token', value: token);
    } catch (e) {
      print('Erro ao tentar salvar o token: $e');
    }
  }
}
