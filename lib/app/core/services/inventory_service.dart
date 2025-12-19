// -----------------------------------------------------------
// app/core/services/inventory_service.dart
// -----------------------------------------------------------
import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/app/core/models/inventory_guid_model.dart';
import 'package:oxdata/app/core/models/inventory_record_model.dart';
import 'package:oxdata/app/core/repositories/inventory_repository.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oxdata/app/core/models/InventoryBatchRequest.dart';
import 'package:uuid/uuid.dart';

/// Serviço responsável pela lógica de negócios e gerenciamento de estado
/// (via ChangeNotifier) para as operações de Inventário.
class InventoryService with ChangeNotifier {
  final InventoryRepository inventoryRepository;
  String? _deviceId;

  InventoryService({required this.inventoryRepository}) {
    initializeDeviceId(); // Inicializa o ID do dispositivo logo após a criação do serviço
  }

  // --- Estado Local ---
  // 🔑 ADICIONADO: Lista completa (fonte da verdade)
  List<InventoryModel> _allInventories = []; 
  
  // 🔑 MODIFICADO: Lista filtrada/exibida
  List<InventoryModel> _inventories = [];
  List<InventoryRecordModel> _inventoryRecords = [];
  List<InventoryGuidModel> _inventoryGuids = [];
  InventoryModel? _selectedInventory;

  // Getter para expor o ID do Dispositivo
  String? get deviceId => _deviceId;

  // 🔑 O getter continua retornando a lista exibida (filtrada ou completa)
  List<InventoryModel> get inventories => _inventories; 
  List<InventoryRecordModel> get inventoryRecords => _inventoryRecords;
  List<InventoryGuidModel> get inventoryGuids => _inventoryGuids;

  InventoryModel? get selectedInventory => _selectedInventory;

  // =========================================================================
  // === INVENTORY GUID (v1/Inventory)
  // =========================================================================

  /// POST: Cria ou verifica a existência de um GUID de inventário na API.
  Future<InventoryGuidModel> createInventoryGuid(
      InventoryGuidModel guidModel) async {
    final ApiResponse<InventoryGuidModel> response =
        await inventoryRepository.createInventoryGuid(guidModel);

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      //debugPrint('Erro ao criar/verificar GUID: ${response.message}');
      throw Exception('Erro ao criar/verificar GUID: ${response.message}');
    }
  }

  /// GET: Busca todos os GUIDs de inventário da API e atualiza a lista.
  Future<void> fetchAllInventoryGuids() async {
    final ApiResponse<List<InventoryGuidModel>> response =
        await inventoryRepository.getAllInventoryGuids();

    if (response.success && response.data != null) {
      _inventoryGuids = response.data!;
    } else {
      _inventoryGuids = [];
      debugPrint('Erro ao buscar todos os GUIDs: ${response.message}');
    }
    notifyListeners();
  }

  /// GET: Busca um GUID de inventário específico por `invent_guid`.
  Future<InventoryGuidModel?> getInventoryGuidByGuid(String inventGuid) async {
    final ApiResponse<InventoryGuidModel> response =
        await inventoryRepository.getInventoryGuidByGuid(inventGuid);

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      debugPrint('GUID não encontrado: $inventGuid. ${response.message}');
      return null;
    }
  }

  // =========================================================================
  // === INVENTORY (v1/Inventory/Inventory)
  // =========================================================================

  /// POST: Cria ou atualiza um Inventário principal e atualiza a lista local.
  Future<void> createOrUpdateInventory(InventoryModel inventory) async {
    final ApiResponse<InventoryModel> response =
        await inventoryRepository.createOrUpdateInventory(inventory);

    if (response.success) {
      // Recarrega todos os Inventários para refletir a mudança
      await fetchAllInventories();
    } else {
      debugPrint('Erro ao salvar Inventário: ${response.message}');
      throw Exception('Erro ao salvar Inventário: ${response.message}');
    }
  }

  // 🔑 MUDANÇA 1: Armazena o resultado nas duas listas
  Future<void> fetchAllInventories() async {
    _deviceId = "65c1aa5a-7b26-4fc3-8ea2-b2eb5b9f7102"; // RETIRAR EM PRODUÇÃO ****************************************************################################

    // 2. Garante que o ID não é nulo. Se for, tenta inicializar.
    if (_deviceId == null) {
      await initializeDeviceId(); // Tenta carregar o ID
      if (_deviceId == null) {
        debugPrint('Erro: deviceId não está disponível para buscar inventários.');
        _inventories = [];
        _allInventories = []; // Limpa também a lista completa
        notifyListeners();
        return;
      }
    }

    // 3. Chama o Repositório com o ID do dispositivo.
    final ApiResponse<List<InventoryModel>> response =
        await inventoryRepository.getRecentInventoriesByGuid(_deviceId!);

    if (response.success && response.data != null) {
      // 🔑 Salva na lista completa
      _allInventories = response.data!; 
      // 🔑 Define a lista exibida (inventories) como a lista completa inicialmente
      _inventories = List.from(_allInventories); 

      if (_allInventories.isNotEmpty) {
            _selectedInventory = _allInventories.first;
        } else {
            _selectedInventory = null;
        }
      
    } else {
      debugPrint('Inventário não encontrado: ${response.message}');
      _inventories = []; // Limpa a lista exibida
      _allInventories = []; // Limpa a lista completa
    }
    
    // 4. Notifica a UI
    notifyListeners();
  }

  /// GET: Busca Inventário por GUID.
  Future<InventoryModel?> getInventoryByGuid(String guid) async {
    final ApiResponse<InventoryModel> response =
        await inventoryRepository.getInventoryByGuid(guid);

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      debugPrint('Inventário não encontrado: $guid. ${response.message}');
      return null;
    }
  }

  /// GET: Busca Inventário por GUID e InventCode.
  Future<InventoryModel?> getInventoryByGuidInventCode(
      String guid, String inventCode) async {
    final ApiResponse<InventoryModel> response =
        await inventoryRepository.getInventoryByGuidInventCode(guid, inventCode);

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      debugPrint('Inventário não encontrado: $guid/$inventCode. ${response.message}');
      return null;
    }
  }

  void setSelectedInventory(InventoryModel inventory) {
    _selectedInventory = inventory;

    
    notifyListeners(); 
  }

  /// DELETE: Exclui um Inventário principal.
  Future<void> deleteInventory(String inventCode) async {
    final ApiResponse<String> response =
        await inventoryRepository.deleteInventory(inventCode);

    if (response.success) {
      // Remove da lista local (ambas) e notifica
      _inventories.removeWhere((i) => i.inventCode == inventCode);
      _allInventories.removeWhere((i) => i.inventCode == inventCode);
      notifyListeners();
    } else {
      debugPrint('Erro ao excluir Inventário: ${response.message}');
      throw Exception('Erro ao excluir Inventário: ${response.message}');
    }
  }

  // =========================================================================
  // === INVENTORY RECORD (v1/Inventory/Record)
  // =========================================================================

Future<String> createOrUpdateInventoryRecords(List<InventoryBatchRequest> batches) async {
  final ApiResponse<String> response =
      await inventoryRepository.createOrUpdateInventoryRecords(batches);

  if (response.success) {
    final data = response.rawJson;

    if (data != null) {
      // Ajustado para bater com o DTO C#: InventCode, InventTotal e Message
      final String? returnedCode = data['InventCode'] ?? data['inventCode'];
      final double? newTotal = (data['InventTotal'] ?? data['inventTotal'] as num?)?.toDouble();

      if (selectedInventory != null && selectedInventory!.inventCode == returnedCode) {
        selectedInventory!.inventTotal = newTotal ?? selectedInventory!.inventTotal;
        
        // Isso fará o contador na UI (Header) atualizar instantaneamente
        notifyListeners();
      }

      // Retorna a mensagem vinda do C#
      return data['Message'] ?? data['message'] ?? 'Registros salvos com sucesso.';
    }
    
    return response.data ?? 'Registros salvos com sucesso.';
  } else {
    // Caso o sucesso seja false, usamos a message do ApiResponse
    final errorMsg = response.message ?? 'Erro desconhecido ao salvar registros';
    debugPrint('Erro no Service: $errorMsg');
    throw Exception(errorMsg);
  }
}
  /// GET: Busca todos os Records de um dado InventCode e atualiza a lista local.
  Future<void> fetchRecordsByInventCode(String inventCode) async {
    final ApiResponse<List<InventoryRecordModel>> response =
        await inventoryRepository.getRecordsByInventCode(inventCode);

    if (response.success && response.data != null) {
      _inventoryRecords = response.data!;
    } else {
      _inventoryRecords = [];
      debugPrint('Erro ao buscar Records por código $inventCode: ${response.message}');
    }
    notifyListeners();
  }

  /// GET: Busca InventoryRecord por ID.
  Future<InventoryRecordModel?> getRecordById(int id) async {
    final ApiResponse<InventoryRecordModel> response =
        await inventoryRepository.getRecordById(id);

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      debugPrint('Registro de Inventário não encontrado: $id. ${response.message}');
      return null;
    }
  }

  /// GET: Busca UMA LISTA de InventoryRecords por inventCode.
  /// Retorna List<InventoryRecordModel> ou lista vazia.
  Future<List<InventoryRecordModel>> getRecordsListByInventCode(String inventCode) async {
    // 🔑 O Service agora espera e retorna List<InventoryRecordModel>
    final ApiResponse<List<InventoryRecordModel>> response =
        await inventoryRepository.getRecordsByInventCode(inventCode); // <-- Chamada ao método que retorna lista

    if (response.success && response.data != null) {
      
      _inventoryRecords = response.data!;
      
      notifyListeners();

      return _inventoryRecords;

    } else {
      debugPrint('Nenhum Registro de Inventário encontrado para: $inventCode. ${response.message}');
      // Retorna uma lista vazia em caso de falha ou dados nulos, evitando `null`.
      return [];
    }
  }

  // 🔑 MUDANÇA 2: Agora filtra a lista _allInventories (em memória)
  /// Realiza a filtragem dos inventários já carregados por GUID ou InventCode.
  void filterInventoryByGuid(String searchTerm) {
    if (searchTerm.isEmpty) {
      // Se vazio, volta para a lista completa
      _inventories = List.from(_allInventories);
    } else {
      final lowerCaseSearch = searchTerm.toLowerCase();
      
      // Filtra _allInventories
      _inventories = _allInventories.where((item) {
        final codeMatch = item.inventCode?.toLowerCase().contains(lowerCaseSearch) ?? false;
        final guidMatch = item.inventGuid?.toLowerCase().contains(lowerCaseSearch) ?? false;
        
        // Retorna true se corresponder ao código ou ao GUID
        return codeMatch || guidMatch;
      }).toList();
    }
    // Notifica a UI com a lista filtrada/completa
    notifyListeners();
  }

  /// DELETE: Exclui um Registro de Inventário por ID.
  Future<void> deleteInventoryRecord(int id) async {
    final ApiResponse<String> response =
        await inventoryRepository.deleteInventoryRecord(id);

    if (response.success) {
      // Remove da lista local e notifica
      _inventoryRecords.removeWhere((r) => r.id == id);
      notifyListeners();
    } else {
      debugPrint('Erro ao excluir Registro: ${response.message}');
      throw Exception('Erro ao excluir Registro: ${response.message}');
    }
  }

// ----------------------------------------------------------------------
  // MÉTODO: Inicializa o ID Único do Dispositivo (device_uuid)
  // ----------------------------------------------------------------------
  Future<void> initializeDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString("device_uuid");

    if (id == null) {
      // Se não existir, gera um novo UUID v4
      id = const Uuid().v4();
      await prefs.setString("device_uuid", id);
    }
    
    // Atualiza o estado interno e notifica os listeners
    _deviceId = id;
    notifyListeners();
  }

  // =========================================================================
  // === UTILITÁRIOS LOCAIS (Manipulação de Records no Client)
  // =========================================================================

  /// Adiciona um novo Record à lista local temporária.
  void addRecordLocally(InventoryRecordModel record) {
    _inventoryRecords.add(record);
    notifyListeners();
  }

  /// Remove um Record específico da lista local temporária.
  void removeRecordLocally(InventoryRecordModel record) {
    _inventoryRecords.removeWhere((r) => r.id == record.id);
    notifyListeners();
  }
  
  /// Limpa a lista local de Records.
  void clearInventoryRecords() {
    _inventoryRecords = [];
    notifyListeners();
  }

  /// Limpa a lista local de Inventários.
  void clearInventories() {
    _inventories = [];
    _allInventories = []; // Limpa a fonte também
    notifyListeners();
  }
}


/*
// -----------------------------------------------------------
// app/core/services/inventory_service.dart
// -----------------------------------------------------------
import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/app/core/models/inventory_guid_model.dart';
import 'package:oxdata/app/core/models/inventory_record_model.dart';
import 'package:oxdata/app/core/repositories/inventory_repository.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Serviço responsável pela lógica de negócios e gerenciamento de estado
/// (via ChangeNotifier) para as operações de Inventário.
class InventoryService with ChangeNotifier {
  final InventoryRepository inventoryRepository;
  String? _deviceId;

 InventoryService({required this.inventoryRepository}) {
    initializeDeviceId(); // Inicializa o ID do dispositivo logo após a criação do serviço
  }

  // --- Estado Local ---
  List<InventoryModel> _inventories = [];
  List<InventoryRecordModel> _inventoryRecords = [];
  List<InventoryGuidModel> _inventoryGuids = [];

  // Getter para expor o ID do Dispositivo
  String? get deviceId => _deviceId;

  List<InventoryModel> get inventories => _inventories;
  List<InventoryRecordModel> get inventoryRecords => _inventoryRecords;
  List<InventoryGuidModel> get inventoryGuids => _inventoryGuids;

  // =========================================================================
  // === INVENTORY GUID (v1/Inventory)
  // =========================================================================

  /// POST: Cria ou verifica a existência de um GUID de inventário na API.
  Future<InventoryGuidModel> createInventoryGuid(
      InventoryGuidModel guidModel) async {
    final ApiResponse<InventoryGuidModel> response =
        await inventoryRepository.createInventoryGuid(guidModel);

    if (response.success && response.data != null) {
      // O GUID foi criado ou encontrado. Retorna o objeto completo.
      // Pode ser útil atualizar a lista de guids se necessário.
      return response.data!;
    } else {
      debugPrint('Erro ao criar/verificar GUID: ${response.message}');
      throw Exception('Erro ao criar/verificar GUID: ${response.message}');
    }
  }

  /// GET: Busca todos os GUIDs de inventário da API e atualiza a lista.
  Future<void> fetchAllInventoryGuids() async {
    final ApiResponse<List<InventoryGuidModel>> response =
        await inventoryRepository.getAllInventoryGuids();

    if (response.success && response.data != null) {
      _inventoryGuids = response.data!;
    } else {
      _inventoryGuids = [];
      debugPrint('Erro ao buscar todos os GUIDs: ${response.message}');
    }
    notifyListeners();
  }

  /// GET: Busca um GUID de inventário específico por `invent_guid`.
  Future<InventoryGuidModel?> getInventoryGuidByGuid(String inventGuid) async {
    final ApiResponse<InventoryGuidModel> response =
        await inventoryRepository.getInventoryGuidByGuid(inventGuid);

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      debugPrint('GUID não encontrado: $inventGuid. ${response.message}');
      return null;
    }
  }

  // =========================================================================
  // === INVENTORY (v1/Inventory/Inventory)
  // =========================================================================

  /// POST: Cria ou atualiza um Inventário principal e atualiza a lista local.
  Future<void> createOrUpdateInventory(InventoryModel inventory) async {
    final ApiResponse<InventoryModel> response =
        await inventoryRepository.createOrUpdateInventory(inventory);

    if (response.success) {
      // Recarrega todos os Inventários para refletir a mudança
      await fetchAllInventories();
    } else {
      debugPrint('Erro ao salvar Inventário: ${response.message}');
      throw Exception('Erro ao salvar Inventário: ${response.message}');
    }
  }

  Future<void> fetchAllInventories() async {
    // 1. Acessa o estado (deviceId) da classe


    _deviceId = "65c1aa5a-7b26-4fc3-8ea2-b2eb5b9f7102"; // RETIRAR EM PRODUÇÃO ****************************************************################################

    final String? deviceGuid = _deviceId;

    // 2. Garante que o ID não é nulo. Se for, tenta inicializar.
    if (deviceGuid == null) {
      await initializeDeviceId(); // Tenta carregar o ID
      if (_deviceId == null) {
        debugPrint('Erro: deviceId não está disponível para buscar inventários.');
        _inventories = [];
        notifyListeners();
        return;
      }
    }

    // 3. Chama o Repositório com o ID do dispositivo.
    // CORREÇÃO: A chamada deve ser para o método renomeado e o retorno é List<InventoryModel>.
    final ApiResponse<List<InventoryModel>> response =
        await inventoryRepository.getRecentInventoriesByGuid(_deviceId!);

    if (response.success && response.data != null) {
      // CORREÇÃO: Atualizar a lista de estado interna
      _inventories = response.data!; 
    } else {
      debugPrint('Inventário não encontrado: ${response.message}');
      _inventories = []; // Limpa a lista em caso de falha ou 404
    }
    
    // 4. Notifica a UI
    notifyListeners();
  }

  /// GET: Busca Inventário por GUID.
  Future<InventoryModel?> getInventoryByGuid(String guid) async {
    final ApiResponse<InventoryModel> response =
        await inventoryRepository.getInventoryByGuid(guid);

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      debugPrint('Inventário não encontrado: $guid. ${response.message}');
      return null;
    }
  }

  /// GET: Busca Inventário por GUID e InventCode.
  Future<InventoryModel?> getInventoryByGuidInventCode(
      String guid, String inventCode) async {
    final ApiResponse<InventoryModel> response =
        await inventoryRepository.getInventoryByGuidInventCode(guid, inventCode);

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      debugPrint('Inventário não encontrado: $guid/$inventCode. ${response.message}');
      return null;
    }
  }

  /// DELETE: Exclui um Inventário principal.
  Future<void> deleteInventory(String inventCode) async {
    final ApiResponse<String> response =
        await inventoryRepository.deleteInventory(inventCode);

    if (response.success) {
      // Remove da lista local e notifica
      _inventories.removeWhere((i) => i.inventCode == inventCode);
      notifyListeners();
    } else {
      debugPrint('Erro ao excluir Inventário: ${response.message}');
      throw Exception('Erro ao excluir Inventário: ${response.message}');
    }
  }

  // =========================================================================
  // === INVENTORY RECORD (v1/Inventory/Record)
  // =========================================================================

  /// POST: Insere ou Atualiza uma lista de Registros de Inventário (Records) em lote.
  Future<String> createOrUpdateInventoryRecords(
      List<InventoryRecordModel> records) async {
    final ApiResponse<String> response =
        await inventoryRepository.createOrUpdateInventoryRecords(records);

    if (response.success) {
      // Opcional: Recarregar a lista de records ou o inventário pai, se necessário.
      // Por enquanto, apenas retorna a mensagem de sucesso.
      return response.data ?? 'Registros salvos com sucesso.';
    } else {
      debugPrint('Erro ao salvar registros: ${response.message}');
      throw Exception('Erro ao salvar registros: ${response.message}');
    }
  }

  /// GET: Busca todos os Records de um dado InventCode e atualiza a lista local.
  Future<void> fetchRecordsByInventCode(String inventCode) async {
    final ApiResponse<List<InventoryRecordModel>> response =
        await inventoryRepository.getRecordsByInventCode(inventCode);

    if (response.success && response.data != null) {
      _inventoryRecords = response.data!;
    } else {
      _inventoryRecords = [];
      debugPrint('Erro ao buscar Records por código $inventCode: ${response.message}');
    }
    notifyListeners();
  }

  /// GET: Busca InventoryRecord por ID.
  Future<InventoryRecordModel?> getRecordById(int id) async {
    final ApiResponse<InventoryRecordModel> response =
        await inventoryRepository.getRecordById(id);

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      debugPrint('Registro de Inventário não encontrado: $id. ${response.message}');
      return null;
    }
  }

  /// Busca um Inventário por GUID e atualiza a lista local com este único item.
  /// Este método substitui o uso direto de getInventoryByGuid para fins de UI de listagem/filtro.
  Future<void> filterInventoryByGuid(String guid) async {
    // Se o campo estiver vazio, recarrega todos os inventários
    if (guid.isEmpty) {
      await fetchAllInventories();
      return;
    }
      
    // Caso contrário, tenta buscar pelo GUID
    final ApiResponse<InventoryModel> response =
        await inventoryRepository.getInventoryByGuid(guid);

    if (response.success && response.data != null) {
      // Se encontrado, define a lista local apenas com este item (o resultado do filtro).
      _inventories = [response.data!];
    } else {
      // Se não encontrado, limpa a lista.
      _inventories = [];
      debugPrint('Inventário não encontrado: $guid. ${response.message}');
    }
    notifyListeners();
  }

  /// DELETE: Exclui um Registro de Inventário por ID.
  Future<void> deleteInventoryRecord(int id) async {
    final ApiResponse<String> response =
        await inventoryRepository.deleteInventoryRecord(id);

    if (response.success) {
      // Remove da lista local e notifica
      _inventoryRecords.removeWhere((r) => r.id == id);
      notifyListeners();
    } else {
      debugPrint('Erro ao excluir Registro: ${response.message}');
      throw Exception('Erro ao excluir Registro: ${response.message}');
    }
  }

// ----------------------------------------------------------------------
  // MÉTODO: Inicializa o ID Único do Dispositivo (device_uuid)
  // ----------------------------------------------------------------------
  Future<void> initializeDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString("device_uuid");

    if (id == null) {
      // Se não existir, gera um novo UUID v4
      id = const Uuid().v4();
      await prefs.setString("device_uuid", id);
    }
    
    // Atualiza o estado interno e notifica os listeners
    _deviceId = id;
    notifyListeners();
  }

  // =========================================================================
  // === UTILITÁRIOS LOCAIS (Manipulação de Records no Client)
  // =========================================================================

  /// Adiciona um novo Record à lista local temporária.
  void addRecordLocally(InventoryRecordModel record) {
    _inventoryRecords.add(record);
    notifyListeners();
  }

  /// Remove um Record específico da lista local temporária.
  void removeRecordLocally(InventoryRecordModel record) {
    _inventoryRecords.removeWhere((r) => r.id == record.id);
    notifyListeners();
  }
  
  /// Limpa a lista local de Records.
  void clearInventoryRecords() {
    _inventoryRecords = [];
    notifyListeners();
  }

  /// Limpa a lista local de Inventários.
  void clearInventories() {
    _inventories = [];
    notifyListeners();
  }
}
*/
