// -----------------------------------------------------------
// app/core/services/inventory_service.dart
// -----------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/app/core/models/inventory_guid_model.dart';
import 'package:oxdata/app/core/models/inventory_record_model.dart';
import 'package:oxdata/app/core/models/dto/inventory_record_input.dart';
import 'package:oxdata/app/core/repositories/inventory_repository.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/models/dto/status_result.dart';
import 'package:oxdata/app/core/utils/network_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oxdata/app/core/models/InventoryBatchRequest.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';
import 'package:oxdata/db/app_database.dart';
import 'package:uuid/uuid.dart';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';

/// Serviço responsável pela lógica de negócios e gerenciamento de estado
/// (via ChangeNotifier) para as operações de Inventário.
class InventoryService with ChangeNotifier {
  final InventoryRepository inventoryRepository;
  final AppDatabase database;
  String? _deviceId;

  InventoryService({required this.inventoryRepository,required this.database,}) {
    //initializeDeviceId(); // Inicializa o ID do dispositivo logo após a criação do serviço
  }

  // --- Estado Local ---
  // 🔑 ADICIONADO: Lista completa (fonte da verdade)
  List<InventoryModel> _allInventories = []; 
  
  // 🔑 MODIFICADO: Lista filtrada/exibida
  List<InventoryModel> _inventories = [];
  List<InventoryRecordModel> _inventoryRecords = [];
  List<InventoryGuidModel> _inventoryGuids = [];
  InventoryModel? _selectedInventory;

  // 🔑 Produtos filtrados
  List<Product> _searchResults = [];
  List<Product> get searchResults => _searchResults;

  List<InventoryMaskData> _listMask = [];
  List<InventoryMaskData> get listMask => _listMask;

  // SINCRONIZAÇÃO
  int totalSynchronize = 0;
  double progressSynchronize = 0.0;
  String infoSynchronize = "";
  bool isSyncing = false;

  // Getter para expor o ID do Dispositivo
  String? get deviceId => _deviceId;

  // 🔑 O getter continua retornando a lista exibida (filtrada ou completa)
  List<InventoryModel> get inventories => _inventories; 
  List<InventoryRecordModel> get inventoryRecords => _inventoryRecords;
  List<InventoryGuidModel> get inventoryGuids => _inventoryGuids;

  InventoryModel? get selectedInventory => _selectedInventory;


  InventoryRecordInput? _draft;
  InventoryRecordInput? get draft => _draft;

  // --- NOVAS VARIÁVEIS DE CONFIGURAÇÃO DE SINCRONIZAÇÃO ---
  bool _isSetupEnabled = true;
  bool _isContagemEnabled = false;

  bool get isSetupEnabled => _isSetupEnabled;
  bool get isContagemEnabled => _isContagemEnabled;

  void setSetupEnabled(bool value) {
    _isSetupEnabled = value;
    notifyListeners();
  }

  void setContagemEnabled(bool value) {
    _isContagemEnabled = value;
    notifyListeners();
  }

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

  Future<void> updateDraft(InventoryRecordInput input) async {

    /// Verifica se ja existe uma contagem para o mesmo  input.unitizer, input.position e input.product 
    // Verifica se os campos essenciais não estão vazios ou nulos
    /*final bool hasMinimumData = 
        (input.unitizer.isNotEmpty) &&
        (input.position.isNotEmpty) &&
        (input.product.isNotEmpty);
        
    if (hasMinimumData) {
      final InventoryRecord? existingRecord = await checkExistingContagem(input);

    if (existingRecord != null) {
          // Se existe, atualiza o input com os valores que já estão no banco
          input = input.copyWith(
            id: existingRecord.id,
            qtdPorPilha: existingRecord.inventStandardStack?.toDouble(),
            numPilhas: existingRecord.inventQtdStack?.toDouble(),
            qtdAvulsa: existingRecord.inventQtdIndividual?.toDouble(),
          );
        }
    }*/

    _draft = input;
    notifyListeners();
  }

  /// Verifica se já existe uma contagem local e retorna o objeto completo
  Future<InventoryRecord?> checkExistingContagem(InventoryRecordInput input) async {
    if (_selectedInventory == null) return null;

    // Agora o retorno é o objeto InventoryRecord (ou null caso não exista)
    final InventoryRecord? existingRecord = await database.checkDuplicateRecord(
      inventCode: _selectedInventory!.inventCode,
      unitizer: input.unitizer,
      position: input.position,
      product: input.product,
    );

    return existingRecord;
  }
  
  Future<InventoryRecord?> checkExistingRecord(String unitizer, String position, String product) async {
    // Use IF em vez de !
    if (selectedInventory == null) {
      debugPrint("Aviso: selectedInventory está nulo em checkExistingRecord");
      return null;
    }

    return await database.checkDuplicateRecord(
      inventCode: selectedInventory!.inventCode, // Aqui agora é seguro
      unitizer: unitizer,
      position: position,
      product: product,
    );
  }

  void clearDraft() {
    _draft = null;
    notifyListeners();
  }
  
  Future<StatusResult> confirmDraft(InventoryRecordInput draft1) async {
    // 1. Proteção inicial (Removido o ! de draft1 pois ele já é checado no if)
    if (draft1 == null) {
      return StatusResult(status: 0, message: 'CONTAGEM INVÁLIDA!');
    }

    final hasInternet = await NetworkUtils.hasInternetConnection();

    if (hasInternet) {
      // Passamos draft1, que é o que veio da tela
      final result = await saveInventoryRecord(draft1);

      if (result.status == 1) {
        _draft = null;
        notifyListeners();
      }
      return result;
    }

    // -----------------------------
    // OFFLINE (ou fallback)
    // -----------------------------
    
    // 2. Proteção para o Inventário Selecionado
    if (selectedInventory == null) {
      return StatusResult(
        status: 0, 
        message: 'ERRO: Nenhum inventário selecionado para gravação offline.'
      );
    }

    // 3. CORREÇÃO: Usar 'draft1' (o parâmetro) em vez de '_draft' (a variável da classe)
    final result = await database.insertOrUpdateInventoryRecordOffline(
      selectedInventory!,
      draft1, // <--- Mudança aqui: use o que veio da UI
      synced: false,
    );


    await refreshSelectedInventoryState(selectedInventory!.inventCode);

    _draft = null;
    notifyListeners();

    return result;
  }

  /// Busca um inventário específico no banco local e atualiza o estado do serviço.
  /// Útil para refletir mudanças de totais após inserções offline.
  Future<void> refreshSelectedInventoryState(String inventCode) async {
    try {
      // 1. Busca o registro atualizado diretamente do banco Drift
      final updatedRow = await (database.select(database.inventory)
            ..where((tbl) => tbl.inventCode.equals(inventCode)))
          .getSingleOrNull();

      if (updatedRow != null) {
        final updatedModel = InventoryModel.fromLocal(updatedRow);

        // 2. Atualiza o objeto selecionado se ele for o mesmo que foi alterado
        if (_selectedInventory?.inventCode == inventCode) {
          _selectedInventory = updatedModel;
        }

        // 3. Atualiza o item correspondente na lista completa (_allInventories)
        final index = _allInventories.indexWhere((i) => i.inventCode == inventCode);
        if (index != -1) {
          _allInventories[index] = updatedModel;
        }

        // 4. Sincroniza a lista de exibição com a lista completa
        _inventories = List.from(_allInventories);

        debugPrint("🔄 Estado do Inventário $inventCode atualizado localmente.");
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Erro ao atualizar estado do inventário: $e");
    }
  }


  /// Busca um produto no banco local pelo código de barras ou ID interno.
  Future<Product?> searchProductLocallyByCode(String code) async {
    if (code.isEmpty) return null;

    try {
      // Chama o banco de dados injetado no construtor
      final product = await database.findProductByCode(code);
      
      if (product != null) {
        debugPrint("Produto encontrado: ${product.productName}");
        return product;
      } else {
        debugPrint("Produto não encontrado no banco local: $code");
        return null;
      }
    } catch (e) {
      debugPrint("Erro na busca local: $e");
      return null;
    }
  }

  /// Pesquisa produtos por qualquer texto
  Future<void> searchProductLocally(String query) async {
    if (query.length < 4) { // Evita pesquisar com apenas 1 letra por performance
      _searchResults = [];
      notifyListeners();
      return;
    }

    _searchResults = await database.searchProducts(query);
    notifyListeners();
  }

  /// Método mestre chamado pelo botão na UI
  Future<void> performSync() async {
    if (_isSetupEnabled) {
      // Se setup estiver ativo, faz a carga completa (Produtos + Máscaras)
      await startSyncSetUp();
    }
    if (_isContagemEnabled) {
      // Se apenas contagem estiver ativa
      await startSyncInventory();
    } else {
      infoSynchronize = "Selecione ao menos uma opção para sincronizar.";
      notifyListeners();
    }
  }

  /// Sincroniza Produtos
  Future<void> startSyncSetUp() async {
    isSyncing = true;
    progressSynchronize = 0.0;
    infoSynchronize = "Iniciando sincronização...";
    notifyListeners();

    try {
      // 1. Obter a contagem total de produtos do servidor
      infoSynchronize = "Consultando base de dados remota...";
      notifyListeners();
      
      final countResponse = await inventoryRepository.getProductCount();
      
      if (!countResponse.success || countResponse.data == null) {
        throw Exception(countResponse.message ?? "Falha ao obter contagem de produtos");
      }

      final int totalProducts = countResponse.data!; // Valor que veio do body['total']
      const int pageSize = 10000;

      // CALCULO DINÂMICO:
      // Se total for 25.000 / 10.000 = 2.5 -> ceil() transforma em 3 páginas.
      final int totalPages = (totalProducts / pageSize).ceil();
      
      if (totalPages == 0) {
        infoSynchronize = "Nenhum produto encontrado para sincronizar.";
        isSyncing = false;
        notifyListeners();
        return;
      }

      totalSynchronize = totalPages;
      
      // 2. Limpeza da base local
      infoSynchronize = "Limpando base local...";
      progressSynchronize = 1.0;
      notifyListeners();
      await database.clearProducts();
      await database.clearMasks();

      
      infoSynchronize = "Sincronizando padrões..";
      notifyListeners();
      syncMasks(); // sincroniza mascaras
      await Future.delayed(const Duration(seconds: 1));
      progressSynchronize = 0.0;
      notifyListeners();

      // 3. Loop de sincronização baseado nas páginas calculadas
      for (int currentPage = 1; currentPage <= totalPages; currentPage++) {
        //infoSynchronize = "Baixando lote $currentPage de $totalPages...";
        infoSynchronize = "Sincronizando produtos.. ${(progressSynchronize * 100).toInt()}%";
        notifyListeners();

        final response = await inventoryRepository.getProductsPaged(
          page: currentPage,
          pageSize: pageSize,
        );

        if (response.success && response.data != null) {
          //infoSynchronize = "Gravando lote $currentPage de $totalPages...";
          //notifyListeners();

          final error = await database.saveProductsBatch(response.data!);
          if (error != null) {
            throw Exception("Falha ao gravar no banco: $error");
          }
        } else {
          throw Exception("Erro no lote $currentPage: ${response.message}");
        }

        // Atualiza o progresso: de 0.0 a 1.0
        progressSynchronize = currentPage / totalPages;
        if (progressSynchronize == 1)
        {
          infoSynchronize = "Sincronizado produtos.. 100%";
          await Future.delayed(const Duration(seconds: 1));
          //syncMasks(); // sincroniza mascaras

          notifyListeners();
          await Future.delayed(const Duration(seconds: 1));
        }
        else
        {
          notifyListeners();
        }
      }

      infoSynchronize = "Sincronização concluída: $totalProducts produtos atualizados.";
    } catch (e) {
      infoSynchronize = "Erro na sincronização: $e";
      debugPrint(e.toString());
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }


  Future<void> startSyncInventory() async {
    isSyncing = true;
    progressSynchronize = 0.0;
    infoSynchronize = "Verificando conexão...";
    notifyListeners();

    try {
      // 1. Validação de Internet Real
      final hasInternet = await NetworkUtils.hasInternetConnection();
      if (!hasInternet) {
        infoSynchronize = "Sem conexão com a internet.";
        notifyListeners();
        await Future.delayed(const Duration(seconds: 2));
        return;
      }

      // 2. Busca Inventários pai pendentes
      final List<InventoryData> pendingInventories = await database.getPendingInventories();
      
      // 3. Busca Records (filhos) pendentes (de qualquer inventário)
      final List<InventoryRecord> allPendingRecords = await database.getPendingRecords();

      if (pendingInventories.isEmpty && allPendingRecords.isEmpty) {
        progressSynchronize = 1.0;
        infoSynchronize = "Tudo em dia! Nada pendente.";
        notifyListeners();
        await Future.delayed(const Duration(seconds: 2));
        return;
      }

      // --- PASSO A: Sincronizar os Cabeçalhos (Pai) ---
      for (var item in pendingInventories) {
        infoSynchronize = "Sincronizando Cabeçalho: ${item.inventName}";
        notifyListeners();

        final modelToSync = InventoryModel.fromLocal(item);
        final response = await inventoryRepository.createOrUpdateInventory(modelToSync);

        if (response.success) {
          await database.markInventoryAsSynced(item.inventCode);
        }
      }

      // --- PASSO B: Sincronizar os Itens (Filhos) ---
      // Agrupamos os registros por inventCode para enviar em lotes conforme sua API espera (InventoryBatchRequest)
      final Map<String, List<InventoryRecord>> groupedRecords = {};
      for (var rec in allPendingRecords) {
        groupedRecords.putIfAbsent(rec.inventCode, () => []).add(rec);
      }

      int totalGroups = groupedRecords.length;
      int currentGroup = 0;

      for (var entry in groupedRecords.entries) {
        final String inventCode = entry.key;
        final List<InventoryRecord> records = entry.value;

        infoSynchronize = "Enviando registros do inventário: $inventCode";
        notifyListeners();

        // Criamos o lote para a API conforme o seu cURL/BatchRequest
        final batchRequest = InventoryBatchRequest(
          inventGuid: _deviceId ?? "", // Usando o deviceId guardado no service
          inventCode: inventCode,
          records: records.map((r) => InventoryRecordModel(
            id: r.id,
            inventCode: r.inventCode,
            inventCreated: r.inventCreated,
            inventUser: r.inventUser ?? "Diones",
            inventUnitizer: r.inventUnitizer,
            inventLocation: r.inventLocation,
            inventProduct: r.inventProduct,
            inventBarcode: r.inventBarcode,
            inventStandardStack: r.inventStandardStack ?? 0,
            inventQtdStack: r.inventQtdStack ?? 0,
            inventQtdIndividual: r.inventQtdIndividual ?? 0,
            inventTotal: r.inventTotal ?? 0,
          )).toList(),
        );

        try {
          // Envia para: https://oxfordonline.com.br/API/v1/Inventory/Record
          final response = await inventoryRepository.createOrUpdateInventoryRecords([batchRequest]);
          
          // Se a API retornou sucesso (String de confirmação)
          // Marcar cada item do lote como sincronizado no Drift
          for (var r in records) {
            await database.markRecordAsSynced(r.id);
          }
        } catch (e) {
          debugPrint("Erro ao sincronizar lote de registros: $e");
        }

        currentGroup++;
        progressSynchronize = currentGroup / totalGroups;
        notifyListeners();
      }

      infoSynchronize = "Sincronização concluída com sucesso!";
      
    } catch (e) {
      infoSynchronize = "Erro inesperado: $e";
      debugPrint(e.toString());
    } finally {
      await Future.delayed(const Duration(seconds: 1));
      isSyncing = false;
      notifyListeners();
    }
  }

  /*
  /// Sincronização de Inventário (Contagem)
  Future<void> startSyncInventory() async {
    isSyncing = true;
    progressSynchronize = 0.0;
    infoSynchronize = "Verificando conexão...";
    notifyListeners();

    try {
      // 1. Validação de Internet
      final hasInternet = await NetworkUtils.hasInternetConnection();
      if (!hasInternet) {
        infoSynchronize = "Sem conexão com a internet.";
        notifyListeners();
        await Future.delayed(const Duration(seconds: 2));
        return;
      }

      // 2. Busca os dados pendentes no banco local (Drift)
      final List<InventoryData> pendingList = await database.getPendingInventories();

      if (pendingList.isEmpty) {
        progressSynchronize = 1.0;
        infoSynchronize = "Tudo em dia! Nenhum inventário pendente.";
        notifyListeners();
        await Future.delayed(const Duration(seconds: 2));
        return;
      }

      int totalItems = pendingList.length;
      int successCount = 0;

      // 3. Loop de envio unitário
      for (int i = 0; i < totalItems; i++) {
        final item = pendingList[i];
        
        // Atualiza status na tela
        infoSynchronize = "Sincronizando: ${item.inventName}";
        notifyListeners();

        try {
          // Converte o dado do banco para o modelo da API
          final modelToSync = InventoryModel.fromLocal(item);

          // Envia para o endpoint https://oxfordonline.com.br/API/v1/Inventory/Inventory
          final response = await inventoryRepository.createOrUpdateInventory(modelToSync);

          if (response.success) {
            // Marca como sincronizado localmente para não enviar de novo
            await database.markInventoryAsSynced(item.inventCode);
            successCount++;
          }
        } catch (e) {
          debugPrint("Erro ao enviar item ${item.inventCode}: $e");
        }

        // 4. Cálculo do progresso (volta a 0.0 no início e vai até 1.0)
        // Adicionamos um pequeno delay para a barra não "voar" se for rápido demais
        progressSynchronize = (i + 1) / totalItems;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      infoSynchronize = "Sucesso: $successCount de $totalItems sincronizados.";
      
    } catch (e) {
      infoSynchronize = "Erro inesperado: $e";
    } finally {
      await Future.delayed(const Duration(seconds: 1));
      isSyncing = false;
      notifyListeners();
    }
  }
  */

  /// Sincroniza Mascaras
  Future<void> syncMasks() async {
    try {
      final response = await inventoryRepository.getInventoryMasks();

      if (response.success && response.data != null) {
        // 1. Opcional: Limpar as antigas para não acumular lixo se mudarem IDs
        await database.delete(database.inventoryMask).go();

        // 2. Salva o lote que veio da API
        await database.saveInventoryMasks(response.data!);
        debugPrint("Máscaras sincronizadas com sucesso.");
      }
    } catch (e) {
      debugPrint("Erro ao sincronizar máscaras: $e");
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
  /*Future<void> createOrUpdateInventory(InventoryModel inventory) async {

    final hasInternet = await NetworkUtils.hasInternetConnection();

    if (hasInternet) { // Tem internet
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
    else // Não tem internet
    {

    }
  }
  */
  Future<void> createOrUpdateInventory(InventoryModel inventory) async {
    final hasInternet = await NetworkUtils.hasInternetConnection();

    if (hasInternet) {
      // -----------------------------
      // ONLINE
      // -----------------------------
      final ApiResponse<InventoryModel> response =
          await inventoryRepository.createOrUpdateInventory(inventory);

      if (response.success) {
        // Atualiza local como sincronizado
        await database.insertOrUpdateInventoryOffline(
          response.data ?? inventory,
          synced: true,
        );

        await fetchAllInventories();
        return;
      }

      // Se falhou online, faz fallback offline
      debugPrint('Falha online, salvando offline: ${response.message}');
    }

    // -----------------------------
    // OFFLINE (ou fallback)
    // -----------------------------
    await database.insertOrUpdateInventoryOffline(
      inventory,
      synced: false,
    );
    
    await fetchAllInventories();
    debugPrint('Inventário salvo OFFLINE (${inventory.inventCode})');
  }

  Future<void> setDecrementSequence() async {
    final storage = StorageService();
    await storage.decrementSequence();
  }
  

  // 🔑 MUDANÇA 1: Armazena o resultado nas duas listas
  /*Future<void> fetchAllInventories() async {
    //_deviceId = "65c1aa5a-7b26-4fc3-8ea2-b2eb5b9f7102"; // RETIRAR EM PRODUÇÃO ****************************************************################################

    // 2. Garante que o ID não é nulo. Se for, tenta inicializar.
    if (_deviceId == null) {
      //await initializeDeviceId(); // Tenta carregar o ID
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
          _selectedInventory ??= _allInventories.first; // ?? dispensa o IF = null
          
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
  }*/

  Future<void> fetchAllInventories() async {
    // 1. Garante deviceId
    if (_deviceId == null) {
      debugPrint('Erro: deviceId não disponível.');
      _inventories = [];
      _allInventories = [];
      notifyListeners();
      return;
    }

    // 2. Busca LOCAL (Drift)
    final localRows = await database.getPendingInventories();

    final Map<String, InventoryModel> merged = {
      for (final row in localRows)
        row.inventCode: InventoryModel.fromLocal(row),
    };

    // 3. Busca REMOTO (API)
    final ApiResponse<List<InventoryModel>> response =
        await inventoryRepository.getRecentInventoriesByGuid(_deviceId!);

    if (response.success && response.data != null) {
      for (final remote in response.data!) {
        final local = merged[remote.inventCode];

        // Se não existe local ou local está sincronizado, usa remoto
        if (local == null || local.isSynced == true) {
          merged[remote.inventCode] = remote;

          // Atualiza banco local como sincronizado
          await database.insertOrUpdateInventoryOffline(
            remote,
            synced: true,
          );
        }
      }
    } else {
      debugPrint('Falha ao buscar inventários remotos: ${response.message}');
    }

    // 4. Atualiza listas
    _allInventories = merged.values.toList()
      ..sort((a, b) => b.inventCreated?.compareTo(a.inventCreated ?? DateTime(0)) ?? 0);

    _inventories = List.from(_allInventories);

    // 5. Mantém inventário selecionado
    if (_allInventories.isNotEmpty) {
      _selectedInventory ??= _allInventories.first;
    } else {
      _selectedInventory = null;
    }

    // 6. Notifica UI
    notifyListeners();
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

  // SALVAR NOVO INVENTARIO
  Future<StatusResult> saveInventoryRecord(InventoryRecordInput input) async {
    final currentInventory = selectedInventory;

    if (currentInventory == null) {
      return StatusResult(status: 0, message: 'Nenhum inventário selecionado', );
    }

    if (input.product.isEmpty) {
      return StatusResult(status: 0, message: 'Produto obrigatório', );
    }

    final productLocal = await searchProductLocallyByCode(input.product);

    final total = ((input.qtdPorPilha ?? 0) * (input.numPilhas ?? 0)) + (input.qtdAvulsa ?? 0);


    final record = InventoryRecordModel(
      inventCode: currentInventory.inventCode,
      inventUnitizer: input.unitizer,
      inventLocation: input.position,
      inventProduct: productLocal!.productId,
      inventBarcode: productLocal.barcode,
      inventStandardStack: (input.qtdPorPilha ?? 0).toInt(),
      inventQtdStack: (input.numPilhas ?? 0).toInt(),
      inventQtdIndividual: input.qtdAvulsa,
      inventTotal: total,
      inventCreated: DateTime.now(),
      inventUser: "Diones",
    );

    final batch = InventoryBatchRequest(
      inventGuid: currentInventory.inventGuid ?? "",
      inventCode: currentInventory.inventCode,
      records: [record],
    );

    final StatusResult result = await createOrUpdateInventoryRecords([batch]);

    return result;
  }

  // =========================================================================
  // === INVENTORY RECORD (v1/Inventory/Record)
  // =========================================================================

  Future<StatusResult> createOrUpdateInventoryRecords(List<InventoryBatchRequest> batches) async {
    final ApiResponse<String> response =
        await inventoryRepository.createOrUpdateInventoryRecords(batches);

    if (response.success) {
      final data = response.rawJson;

      if (data != null) {
        // Ajustado para bater com o DTO C#: InventCode, InventTotal e Message
        final String? returnedCode = data['InventCode'] ?? data['inventCode'];
        final double? newTotal = (data['InventTotal'] ?? data['inventTotal'] as num?)?.toDouble();

        if (_selectedInventory != null &&
            _selectedInventory!.inventCode == returnedCode) {
          
          _selectedInventory = _selectedInventory!.copyWith(
            inventTotal: newTotal ?? _selectedInventory!.inventTotal,
          );

          notifyListeners();
        }

        // Retorna a mensagem vinda do C#
        return StatusResult( status: 1, message:data['Message'] ?? data['message'] ?? 'Registros salvos com sucesso.',);
      }
      
      return StatusResult(status: 1, message: response.data ?? 'Registros salvos com sucesso.',);

    } else {
      // Caso o sucesso seja false, usamos a message do ApiResponse
      final errorMsg = response.message ?? 'Erro desconhecido ao salvar registros';
      return StatusResult(status: 0, message: errorMsg,);
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
  /*Future<void> initializeDeviceId() async {
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
  */

  Future<void> initializeDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString("device_uuid");

    if (id == null) {
      // Se não existir, gera um novo UUID v4
      id = const Uuid().v4();
      await prefs.setString("device_uuid", id);
    }

    _deviceId = id;

    // =====================================================
    // ** Enviar para a API **
    // =====================================================
    try {
      final guidModel = InventoryGuidModel(
        inventGuid: _deviceId!,
        inventExpSeq: 0,
      );

      await createInventoryGuid(guidModel);
      debugPrint("GUID do dispositivo registrada/verificada com sucesso: $_deviceId");
    } catch (e) {
      debugPrint("Erro ao registrar GUID do dispositivo na API: $e");
      // ⚠️ Não interrompe o app — GUID local continua válida
    }

    notifyListeners();
  }

  // =========================================================================
  // === MÉTODOS DE MÁSCARA (LOCAIS)
  // =========================================================================

  /// Recupera todas as máscaras armazenadas no banco de dados local (Drift).
  Future<List<InventoryMaskData>> getMasksByFieldName(MaskFieldName name) async {
    try {
      // 1. Busca os dados do banco
      final masks = await database.masksByFieldName(name);
      
      // 2. Grava na variável local
      _listMask = masks;
      
      // 3. Notifica os interessados (UI) que os dados mudaram
      //notifyListeners();
      
      return _listMask;

    } catch (e) {
      //debugPrint("Erro ao buscar máscaras locais: $e");
      _listMask = [];
      notifyListeners();
      return [];
    }
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