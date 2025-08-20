// -----------------------------------------------------------
// app/core/services/storage_service.dart
// -----------------------------------------------------------
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oxdata/app/core/services/message_service.dart';

// Classe de serviço para operações de armazenamento das credênciais
class StorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Limpa o token de autenticação salvo.
  Future<void> clearAuthToken() async {
    try {
      await _storage.delete(key: 'jwt_token');
    } catch (e) {
      MessageService.showError('Erro ao remover credencial: $e');
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
      MessageService.showError('Erro ao registrar credencial: $e');
    }
  }

  // Usuário e senha
  Future<void> writeCredentials(String username, String password) async {
    await _storage.write(key: 'username', value: username);
    await _storage.write(key: 'password', value: password);
  }

  Future<Map<String, String?>> readCredentials() async {
    final username = await _storage.read(key: 'username');
    final password = await _storage.read(key: 'password');
    return {"username": username, "password": password};
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'password');
  }

}
