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

  // -----------------------------------------------------------
  // MÉTODOS PARA SEQUÊNCIA NUMÉRICA
  // -----------------------------------------------------------

  /// Retorna o próximo número da sequência e o incrementa no storage.
  Future<int> getNextSequence() async {
    try {
      // 1. Lê o valor atual
      String? currentStr = await _storage.read(key: 'inventory_sequence');
      
      // 2. Converte para int (se for nulo, começa em 0)
      int current = currentStr != null ? int.parse(currentStr) : 0;
      
      // 3. Incrementa
      int next = current + 1;
      
      // 4. Salva o novo valor
      await _storage.write(key: 'inventory_sequence', value: next.toString());
      
      return next;
    } catch (e) {
      MessageService.showError('Erro ao gerar sequência: $e');
      return 1; // Fallback para não travar o app
    }
  }

  Future<void> decrementSequence() async {
    try {
      String? currentStr = await _storage.read(key: 'inventory_sequence');
      int current = currentStr != null ? int.parse(currentStr) : 0;

      int next = current > 0 ? current - 1 : 0;
      await _storage.write(key: 'inventory_sequence', value: next.toString(),);

      return;
    } catch (e) {
      return;
    }
  }

  /// Lê o valor atual da sequência sem incrementar.
  Future<int> getCurrentSequence() async {
    String? currentStr = await _storage.read(key: 'inventory_sequence');
    return currentStr != null ? int.parse(currentStr) : 0;
  }

}
