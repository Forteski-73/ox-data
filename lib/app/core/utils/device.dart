import 'package:shared_preferences/shared_preferences.dart';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  // Chave constante para evitar erros de digitação
  static const String _storageKey = "device_uuid";

  /// Retorna o UUID original (com letras e traços)
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_storageKey);

    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_storageKey, id);

      // ** Enviar para a API **

    }

    return id;
  }

  /// Retorna os números da primeira parte do UUID + Data + Hora
  static Future<String> getDeviceFineNumber() async {
    // 1. Busca o ID completo
    final String fullId = await getDeviceId();

    // 2. Pega apenas o que está antes do primeiro hífen (Ex: 550e8400)
    final String firstPart = fullId.split('-')[0];
    
    // 3. Limpa as letras dessa parte (Ex: 5508400)
    final String idNumerico = firstPart.replaceAll(RegExp(r'[^0-9]'), '');

    // 4. Pega a Data e Hora atual e limpa os caracteres especiais (mantendo apenas números)
    final now = DateTime.now();
    final String datePart = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final String timePart = "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";

    final storage = StorageService();
    final int sequence = await storage.getNextSequence();

    // 5. Concatena tudo: ID + Data + Hora + sequencial
    return "INV-$idNumerico$datePart$timePart-$sequence";
  }
}