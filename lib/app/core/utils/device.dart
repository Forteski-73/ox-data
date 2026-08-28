import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/inventory_guid_model.dart';
import 'package:oxdata/app/core/repositories/inventory_repository.dart';

class DeviceService {
  // Chave constante para evitar erros de digitação
  static const String _storageKey = "device_uuid";
  // Confirma que o GUID já foi registrado com sucesso na API — evita
  // reenviar a cada chamada depois de confirmado.
  static const String _registeredKey = "device_uuid_registered";

  /// Retorna o UUID original (com letras e traços). Garante que o GUID
  /// esteja registrado na API (`inventory_guid`) antes de devolvê-lo —
  /// tanto para um GUID recém-gerado quanto para um já existente
  /// localmente que ainda não tenha sido confirmado como registrado
  /// (self-healing: instalações antigas, ou tentativas anteriores que
  /// falharam por falta de internet). Sem isso, qualquer tela que crie
  /// um inventário (ex.: NewInventoryPopup) usando esse GUID é rejeitada
  /// pela API com 404 ("GUID não encontrado em InventoryGuid"), pois o
  /// servidor exige que o GUID já exista antes de aceitar um inventário
  /// vinculado a ele.
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_storageKey);

    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_storageKey, id);
    }

    if (!(prefs.getBool(_registeredKey) ?? false)) {
      try {
        final repository = InventoryRepository(apiClient: ApiClient());

        // Preserva o invent_header_id já vinculado (ex.: trocado via
        // InventoryTabConfig) — a API sobrescreve com o que for enviado,
        // então reenviar sem isso reverteria pro default (1).
        final existingResponse = await repository.getInventoryGuidByGuid(id);
        final existing = existingResponse.success ? existingResponse.data : null;

        await repository.createInventoryGuid(
          InventoryGuidModel(
            inventGuid: id,
            inventExpSeq: existing?.inventExpSeq ?? 0,
            inventHeaderId: existing?.inventHeaderId ?? 1,
          ),
        );
        await prefs.setBool(_registeredKey, true);
      } catch (e) {
        debugPrint('⚠️ Falha ao registrar GUID do device na API: $e');
      }
    }

    return id;
  }

  static Future<String?> getExistingDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageKey);
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