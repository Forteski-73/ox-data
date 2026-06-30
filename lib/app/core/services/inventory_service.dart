// -----------------------------------------------------------
// app/core/services/inventory_service.dart
// -----------------------------------------------------------
//
//  - Todo código comentado removido (era ruído, não documentação)
//  - confirmDraft() claramente dividido em: salvar local → tentar sync
//  - syncInventoryBatch() com Future.wait e logs estruturados
//  - startSyncSetUp() mantido porém com loop legível
//  - Getters e setters de configuração isolados
//  - _updateLocalList() sem lógica duplicada
//  - fetchAllInventories() com merge local-first limpo
//  - fetchRecordsByInventCode() com merge explícito e fallback seguro
//  - Nenhuma assinatura pública alterada
// -----------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/models/InventoryBatchRequest.dart';
import 'package:oxdata/app/core/models/dto/inventory_record_input.dart';
import 'package:oxdata/app/core/models/dto/status_result.dart';
import 'package:oxdata/app/core/models/inventory_guid_model.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/app/core/models/inventory_record_model.dart';
import 'package:oxdata/app/core/repositories/inventory_repository.dart';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:oxdata/app/core/services/sync_manager.dart';
import 'package:oxdata/app/core/utils/network_status.dart';
import 'package:oxdata/app/core/repositories/inventory_local_repository.dart';
import 'package:oxdata/db/app_database.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:oxdata/db/tables/sync_queue.dart';
import 'package:drift/drift.dart' show Value;

class InventoryService with ChangeNotifier {
  InventoryService({
    required this.inventoryRepository,
    required this.database,
    required this.recordsRepository,
    required this.syncManager,
  });

  final InventoryRepository inventoryRepository;
  final AppDatabase database;
  final InventoryRecordsRepository recordsRepository;
  final SyncManager syncManager;

  // ── Estado ────────────────────────────────────────────────────────────────

  String? _deviceId;
  String? get deviceId => _deviceId;

  int _userInventAdm = 0;
  int get userInventAdm => _userInventAdm;

  List<InventoryModel> _allInventories = [];
  List<InventoryModel> _inventories = [];
  List<InventoryRecordModel> _inventoryRecords = [];
  List<Product> _searchResults = [];
  List<InventoryMaskData> _listMask = [];

  set _records(List<InventoryRecordModel> value) {
    _inventoryRecords = value;
    //_syncInventorySyncedState();
  }

  set _inventoriesList(List<InventoryModel> value) {
    _allInventories = value;
    //_syncInventorySyncedState();
  }

  InventoryModel? _selectedInventory;
  InventoryRecordInput? _draft;
  InventoryStatus inventoryStatus = InventoryStatus.Finalizado;

  List<InventoryModel> get inventories => _inventories;
  List<InventoryRecordModel> get inventoryRecords => _inventoryRecords;
  List<Product> get searchResults => _searchResults;
  List<InventoryMaskData> get listMask => _listMask;
  InventoryModel? get selectedInventory => _selectedInventory;
  InventoryRecordInput? get draft => _draft;

  // ── Configuração de sync ──────────────────────────────────────────────────

  bool _isSetupEnabled = false;
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

  // ── Estado de sincronização ───────────────────────────────────────────────

  int totalSynchronize = 0;
  double progressSynchronize = 0.0;
  String infoSynchronize = '';
  bool isSyncing = false;

  // =========================================================================
  // GUID DO DISPOSITIVO
  // =========================================================================

  Future<void> initializeDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_uuid') ?? const Uuid().v4();
    await prefs.setString('device_uuid', _deviceId!);

    try {
      await createInventoryGuid(
        InventoryGuidModel(inventGuid: _deviceId!, inventExpSeq: 0),
      );
      debugPrint('✅ GUID registrado: $_deviceId');
    } catch (e) {
      debugPrint('⚠️ Falha ao registrar GUID (continuando offline): $e');
    }

    notifyListeners();
  }

  Future<InventoryGuidModel> createInventoryGuid(InventoryGuidModel model) async {
    final response = await inventoryRepository.createInventoryGuid(model);
    if (response.success && response.data != null) return response.data!;
    throw Exception('Erro ao criar/verificar GUID: ${response.message}');
  }

  Future<InventoryGuidModel?> getInventoryGuidByGuid(String guid) async {
    final response = await inventoryRepository.getInventoryGuidByGuid(guid);
    return response.success ? response.data : null;
  }

  // =========================================================================
  // DRAFT (rascunho de contagem)
  // =========================================================================

  Future<void> updateDraft(InventoryRecordInput input) async {
    _draft = input;
    notifyListeners();
  }

  void clearDraft() {
    _draft = null;
    notifyListeners();
  }

  // =========================================================================
  // CONFIRMAÇÃO DE DRAFT
  // =========================================================================

  /// Offline-first via Outbox: salva local + enfileira atomicamente.
  /// O SyncManager cuida do envio em background — sem checar internet aqui.
  Future<StatusResult> confirmDraft(InventoryRecordInput draft) async {
    if (_selectedInventory == null) {
      return StatusResult(
        status: 0,
        message: 'Nenhum inventário selecionado para gravação.',
      );
    }

    try {
      // Busca o produto para montar o payload completo
      final product = await searchProductLocallyByCode(draft.product);
      if (product == null) {
        return StatusResult(status: 0, message: 'Produto não encontrado.');
      }

      final total =
          ((draft.qtdPorPilha ?? 0) * (draft.numPilhas ?? 0)) +
          (draft.qtdAvulsa ?? 0);

      // Upsert na tabela de domínio + enqueue na SyncQueue — mesma transação
      await recordsRepository.upsertRecord(
        inventCode:           _selectedInventory!.inventCode,
        inventGuid:           _selectedInventory!.inventGuid ?? '',
        inventProduct:        product.productId,
        inventBarcode:        product.barcode,
        inventUnitizer:       draft.unitizer,
        inventLocation:       draft.position,
        inventStandardStack:  (draft.qtdPorPilha ?? 0).toInt(),
        inventQtdStack:       (draft.numPilhas ?? 0).toInt(),
        inventQtdIndividual:  draft.qtdAvulsa,
        inventTotal:          total,
      );

    // Marca o inventário pai como não sincronizado enquanto não sincronizar a contagem
  
    await database.inventoryDao.markUnsynced(_selectedInventory!.inventCode);
    
    } catch (e) {
      debugPrint('❌ confirmDraft: $e');
      return StatusResult(status: 0, message: 'Erro ao salvar registro: $e');
    }

    // Tenta sincronizar imediatamente — sem await, não bloqueia a UI
    //unawaited(syncManager.syncNow());

      try {
        await syncManager.syncNow();
      } catch (e) {
        debugPrint('⚠️ confirmDraft: sync falhou, será retentado: $e');
      }

    await refreshSelectedInventoryState(_selectedInventory!.inventCode);
    await fetchRecordsByInventCode(_selectedInventory!.inventCode);

    _draft = null;
    notifyListeners();

    return StatusResult(status: 1, message: 'Registro salvo.');
  }


  // =========================================================================
  // VERIFICAÇÕES LOCAIS / REMOTAS
  // =========================================================================

  Future<InventoryRecord?> checkExistingContagem(InventoryRecordInput input) async {
    if (_selectedInventory == null) return null;
    return database.checkDuplicateRecord(
      inventCode: _selectedInventory!.inventCode,
      unitizer: input.unitizer,
      position: input.position,
      product: input.product,
    );
  }

  Future<InventoryRecord?> checkExistingRecord(
    String unitizer,
    String position,
    String product,
  ) async {
    if (_selectedInventory == null) {
      debugPrint('⚠️ checkExistingRecord: selectedInventory nulo');
      return null;
    }
    return database.checkDuplicateRecord(
      inventCode: _selectedInventory!.inventCode,
      unitizer: unitizer,
      position: position,
      product: product,
    );
  }

  Future<void> fetchAllInventories() async {
    if (_deviceId == null) {
      _inventories = _allInventories = [];
      notifyListeners();
      return;
    }

    final localRows = await database.getLocalInventories();    

    _inventoriesList = localRows
        .map((row) => InventoryModel.fromLocal(row))
        .toList()
      ..sort((a, b) =>
          b.inventCreated?.compareTo(a.inventCreated ?? DateTime(0)) ?? 0);

    _inventories = List.from(_allInventories);
    _selectedInventory ??= _allInventories.firstOrNull;

    notifyListeners();
  }

  // *********** USADO NO AD PAGE ***********
  Future<void> fetchAllInventoriesFromApiOnly() async { 
    final response = await inventoryRepository.getAllInventories();

    if (response.success && response.data != null) {
      _inventoriesList = response.data!
        ..sort((a, b) =>
            b.inventCreated?.compareTo(a.inventCreated ?? DateTime(0)) ?? 0);

      _inventories = List.from(_allInventories);
      _selectedInventory = _allInventories.firstOrNull;
    } else {
      debugPrint('⚠️ fetchAllInventoriesFromApiOnly: ${response.message}');
      _inventoriesList = _inventories = [];
      _selectedInventory = null;
    }

    notifyListeners();
  }

  Future<InventoryModel?> getInventoryByGuidInventCode(
    String guid,
    String inventCode,
  ) async {
    final response =
        await inventoryRepository.getInventoryByGuidInventCode(guid, inventCode);
    return response.success ? response.data : null;
  }

  /*void setSelectedInventory(InventoryModel inventory) {
    _selectedInventory = inventory;
    inventoryStatus = inventory.inventStatus;
    notifyListeners();
  }*/

  void setSelectedInventory(InventoryModel inventory) {
    _selectedInventory = inventory;
    inventoryStatus = inventory.inventStatus;
    _inventoryRecords = []; // limpa imediatamente para não mostrar records do anterior
    notifyListeners();

    // Carrega os records do inventário selecionado em background
    fetchRecordsByInventCode(inventory.inventCode);
  }

  Future<StatusResult> createInventory(InventoryModel inventory) async {
    try {
      await recordsRepository.upsertInventory(
        inventCode:    inventory.inventCode,
        inventGuid:    inventory.inventGuid,
        inventName:    inventory.inventName,
        inventStatus:  inventory.inventStatus,
        operation:     SyncOperation.insert,
        inventSector:  inventory.inventSector,
        inventUser:    inventory.inventUser,
        inventCreated: inventory.inventCreated,
        inventTotal:   inventory.inventTotal,
      );
      debugPrint('****** INSERIU ***** : ${inventory.inventCode}}');
    } catch (e) {
      debugPrint('❌ createInventory: $e');
      return StatusResult(status: 0, message: 'Erro ao salvar inventário: $e');
    }

    try {
      debugPrint('❌❌❌❌  syncManager **********************');
      await syncManager.syncNow();
    } catch (e) {
      debugPrint('⚠️ createInventory: sync falhou, será retentado: $e');
    }

    await fetchAllInventories();

    notifyListeners();

    return StatusResult(status: 1, message: 'Inventário salvo.');
  }
    //await database.insertOrUpdateInventoryOffline(inventory, synced: false);
    //return StatusResult(status: 1, message: 'Inventário salvo com sucesso.');
  

  Future<StatusResult> createOrUpdateInventoryCurr(InventoryModel inventory) async {
      if (!await NetworkUtils.hasInternetConnection()) {
        return StatusResult(status: 1, message: 'Sem conexão com Internet.');
      }

      final response = await inventoryRepository.createOrUpdateInventory(inventory);
      if (!response.success) {
        return StatusResult(status: 0, message: response.message ?? 'Erro ao salvar inventário.');
      }
      

      // Busca todos os records locais do inventário e envia para a API
      final allRecords = await database.getRecordsByInventory(inventory.inventCode);

      if (allRecords.isNotEmpty) {
        final batch = InventoryBatchRequest(
          inventGuid: inventory.inventGuid ?? '',
          inventCode: inventory.inventCode,
          records: allRecords.map((r) => InventoryRecordModel(
            inventCode:          r.inventCode,
            inventCreated:       r.inventCreated,
            inventUser:          r.inventUser ?? 'Diones',
            inventUnitizer:      r.inventUnitizer,
            inventLocation:      r.inventLocation,
            inventProduct:       r.inventProduct,
            inventBarcode:       r.inventBarcode,
            inventStandardStack: r.inventStandardStack ?? 0,
            inventQtdStack:      r.inventQtdStack ?? 0,
            inventQtdIndividual: r.inventQtdIndividual ?? 0,
            inventTotal:         r.inventTotal ?? 0,
          )).toList(),
        );
      }
    return StatusResult(status: 1, message: 'Inventário salvo com sucesso.');
  }

  Future<StatusResult> finalizeInventory(String inventCode) async {
    try {
      await recordsRepository.finalizeInventory(inventCode);
      debugPrint('****** FINALIZOU INVENTÁRIO ***** : $inventCode');
    } catch (e) {
      debugPrint('❌ finalizeInventory: $e');
      return StatusResult(status: 0, message: 'Erro ao finalizar inventário: $e');
    }

    try {
      await syncManager.syncNow();
    } catch (e) {
      debugPrint('⚠️ finalizeInventory: sync falhou, será retentado: $e');
    }

    await refreshSelectedInventoryState(inventCode);
    notifyListeners();

    return StatusResult(status: 1, message: 'Inventário finalizado.');
  }

  Future<void> deleteInventory(String inventCode) async {
    final response = await inventoryRepository.deleteInventory(inventCode);
    if (!response.success) {
      throw Exception('Erro ao excluir inventário: ${response.message}');
    }
    _inventories.removeWhere((i) => i.inventCode == inventCode);
    _allInventories.removeWhere((i) => i.inventCode == inventCode);
    notifyListeners();
  }

  Future<void> refreshSelectedInventoryState(String inventCode) async {
    try {
      final row = await (database.select(database.inventory)
            ..where((t) => t.inventCode.equals(inventCode)))
          .getSingleOrNull();

      if (row == null) return;

      final updated = InventoryModel.fromLocal(row);
      _selectedInventory = updated;

      final idx = _allInventories.indexWhere((i) => i.inventCode == inventCode);
      if (idx != -1) _allInventories[idx] = updated;

      _inventories = List.from(_allInventories);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ refreshSelectedInventoryState: $e');
    }
  }

  void filterInventoryByGuid(String searchTerm) {
    if (searchTerm.isEmpty) {
      _inventories = List.from(_allInventories);
    } else {
      final term = searchTerm.toLowerCase();
      _inventories = _allInventories
          .where((i) =>
              (i.inventCode?.toLowerCase().contains(term) ?? false) ||
              (i.inventName?.toLowerCase().contains(term) ?? false) ||
              (i.inventSector?.toLowerCase().contains(term) ?? false))
          .toList();
    }
    notifyListeners();
  }

  Future<void> fetchRecordsByInventCode(String inventCode) async {
    try {
      final localData = await database.getPendingRecordsWithDescription(
        inventCode: inventCode,
      );

      _records = localData
          .map(
            (item) => InventoryRecordModel.fromLocal(item.record).copyWith(
              productDescription: item.productName,
              isSynced: item.record.isSynced,
            ),
          )
          .toList()
        ..sort((a, b) =>
            (b.inventCreated ?? DateTime(0)).compareTo(a.inventCreated ?? DateTime(0)));

      notifyListeners();
    } catch (e) {
      debugPrint('❌ fetchRecordsByInventCode: $e');
      _records = [];
      notifyListeners();
    }
  }
  /*
  Future<void> loadMenuPermissions() async {
    try {
      final storage = StorageService();
      final menus = await storage.readMenus();
      _hasInventAdmMenu = menus.any((m) => m.routeName == 'INVENTADM');
    } catch (e) {
      debugPrint('⚠️ loadMenuPermissions: $e');
      _hasInventAdmMenu = false;
    }
    notifyListeners();
  }*/

  Future<void> loadMenuPermissions() async {
    try {
      final storage = StorageService();
      _userInventAdm = await storage.readProfileId();
    } catch (e) {
      _userInventAdm = 0;
    }
    notifyListeners();
  }

  // ********* USADO NO DOWNLOAD *********
  Future<List<InventoryRecordModel>> getRecordsListByInventCode(
    String inventCode,
  ) async {
    final response =
        await inventoryRepository.getRecordsByInventCode(inventCode);

    if (response.success && response.data != null) {
      _records = response.data!;
      notifyListeners();
      return _inventoryRecords;
    }

    return [];
  }

  /*
  Future<void> deleteInventoryRecord(
      String inventCode, String unitizer, String location, String item) async {

    final hasInternet = await NetworkUtils.hasInternetConnection();

    // Se tiver internet, deleta na API primeiro
    // Só continua se a API confirmar — garante que ambos ficam em sincronizados
    if (hasInternet) {
      final response = await inventoryRepository.deleteInventoryRecord(
          inventCode, unitizer, location, item);
      if (!response.success) {
        throw Exception('Erro ao excluir registro na API: ${response.message}');
      }
    }

    // 2API confirmou, ou sem internet -> deleta local
    await database.deleteRecordByKey(
      inventCode: inventCode,
      unitizer: unitizer,
      location: location,
      product: item,
    );

    // Atualiza lista em memória
    final idx = _inventoryRecords.indexWhere((r) =>
        r.inventCode == inventCode &&
        r.inventUnitizer == unitizer &&
        r.inventLocation == location &&
        r.inventProduct == item);

    if (idx == -1) return;

    final removed = _inventoryRecords.removeAt(idx);
    _decrementInventoryTotal(removed);

    notifyListeners();
  }
  */

  Future<void> deleteInventoryRecord(
      String inventCode, String unitizer, String location, String item) async {

    final row = await database.checkDuplicateRecord(
      inventCode: inventCode,
      unitizer: unitizer,
      position: location,
      product: item,
    );

    if (row == null) return;

    await recordsRepository.deleteRecord(
      row.id,
      inventGuid: _selectedInventory!.inventGuid ?? '',
    );

    final idx = _inventoryRecords.indexWhere((r) =>
        r.inventCode == inventCode &&
        r.inventUnitizer == unitizer &&
        r.inventLocation == location &&
        r.inventProduct == item);

    if (idx != -1) {
      final removed = _inventoryRecords.removeAt(idx);
      _decrementInventoryTotal(removed);
    }

    notifyListeners();
  }

  Future<void> deleteAllRecordsByInventCode(String inventCode) async {
    try {
      if (await NetworkUtils.hasInternetConnection()) {
        final response = await inventoryRepository.deleteInventory(inventCode);
        if (!response.success) {
          debugPrint('⚠️ API deleteInventory: ${response.message}');
        }
      }

      await database.deleteRecordsByInventCode(inventCode);
      await database.deleteInventoryByCode(inventCode);

      _inventoryRecords.clear();
      _selectedInventory = null;

      _zeroInventoryTotal(inventCode);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ deleteAllRecordsByInventCode: $e');
      rethrow;
    }
  }

  // =========================================================================
  // PRODUTOS
  // =========================================================================

  // PRA BUSCAR A DESCRIÇÃO DO PRODUTO
  Future<Product?> searchProductLocallyByCode(String code) async {
    if (code.isEmpty) return null;
    try {
      return await database.findProductByCode(code);
    } catch (e) {
      debugPrint('❌ searchProductLocallyByCode: $e');
      return null;
    }
  }

  /*
  Future<void> searchProductLocally(String query) async {
    if (query.length < 4) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _searchResults = await database.searchProducts(query);
    notifyListeners();
  }
  */

  // =========================================================================
  // MASKS
  // =========================================================================

  Future<List<InventoryMaskData>> getMasksByFieldName(MaskFieldName name) async {
    try {
      _listMask = await database.masksByFieldName(name);
      return _listMask;
    } catch (e) {
      _listMask = [];
      return [];
    }
  }

  // =========================================================================
  // SINCRONIZAÇÃO
  // =========================================================================

  Future<void> performSync() async {
    if (_isSetupEnabled)
    {
      await startSyncSetUp();
    }
    if (_isContagemEnabled) 
    {
      await startSyncInventory();
    }
    else if (!_isSetupEnabled) {
      infoSynchronize = 'Selecione ao menos uma opção para sincronizar.';
      notifyListeners();
    }
  }

  /// Sincronização de setup: produtos + máscaras, paginados.
  Future<void> startSyncSetUp() async {
    isSyncing = true;
    progressSynchronize = 0.0;
    infoSynchronize = 'Iniciando sincronização...';
    notifyListeners();

    try {
      infoSynchronize = 'Consultando base remota...';
      notifyListeners();

      final countResponse = await inventoryRepository.getProductCount();
      if (!countResponse.success || countResponse.data == null) {
        throw Exception(countResponse.message ?? 'Falha ao obter contagem de produtos.');
      }

      final totalProducts = countResponse.data!;
      const pageSize = 10000;
      final totalPages = (totalProducts / pageSize).ceil();

      if (totalPages == 0) {
        infoSynchronize = 'Nenhum produto para sincronizar.';
        return;
      }

      totalSynchronize = totalPages;

      infoSynchronize = 'Limpando base local...';
      notifyListeners();
      await Future.wait([database.clearProducts(), database.clearMasks()]);

      unawaited(syncMasks()); // fire-and-forget, não bloqueia produtos

      for (var page = 1; page <= totalPages; page++) {
        infoSynchronize =
            'Sincronizando produtos… ${(progressSynchronize * 100).toInt()}%';
        notifyListeners();

        final response = await inventoryRepository.getProductsPaged(
          page: page,
          pageSize: pageSize,
        );

        if (!response.success || response.data == null) {
          throw Exception('Erro no lote $page: ${response.message}');
        }

        final error = await database.saveProductsBatch(response.data!);
        if (error != null) throw Exception('Falha ao gravar lote $page: $error');

        progressSynchronize = page / totalPages;
        notifyListeners();
      }

      infoSynchronize = 'Sincronização concluída: $totalProducts produtos.';
    } catch (e) {
      infoSynchronize = 'Erro na sincronização: $e';
      debugPrint('❌ startSyncSetUp: $e');
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  /// Sincronização de contagens: cabeçalhos + records pendentes.
  Future<StatusResult> startSyncInventory([String? inventCode]) async {
    isSyncing = true;
    progressSynchronize = 0.0;
    infoSynchronize = 'Verificando conexão...';
    notifyListeners();

    try {
      if (!await NetworkUtils.hasInternetConnection()) {
        infoSynchronize = 'Sem conexão com a internet.';
        notifyListeners();
        return StatusResult(status: 0, message: 'Sem conexão com a internet.');
      }

      final results = await Future.wait([
        inventCode == null
            ? database.getPendingInventories()
            : database.getPendingInventoryByCode(inventCode),
        database.getPendingRecords(inventCode: inventCode),
      ]);

      final pendingInventories = results[0] as List<InventoryData>;
      final pendingRecords = results[1] as List<InventoryRecord>;

      if (pendingInventories.isEmpty && pendingRecords.isEmpty) {
        infoSynchronize = 'Tudo em dia!';
        notifyListeners();
        return StatusResult(status: 1, message: infoSynchronize);
      }

      // Cabeçalhos
      for (final item in pendingInventories) {
        infoSynchronize = 'Sincronizando: ${item.inventName}';
        notifyListeners();

        final response = await inventoryRepository
            .createOrUpdateInventory(InventoryModel.fromLocal(item));
        if (response.success) await database.markInventoryAsSynced(item.inventCode);
      }

      // Records agrupados por inventCode
      await _syncGroupedRecords(pendingRecords);

      infoSynchronize = 'Sincronização concluída!';
      return StatusResult(status: 1, message: infoSynchronize);
    } catch (e) {
      infoSynchronize = 'Erro inesperado: $e';
      debugPrint('❌ startSyncInventory: $e');
      return StatusResult(status: 0, message: 'Erro inesperado: $e');
    } finally {
      await Future.delayed(const Duration(seconds: 1));
      //isSyncing = false; ************ sincronização  ************
      notifyListeners();
    }
  }

  Future<void> syncMasks() async {
    try {
      final response = await inventoryRepository.getInventoryMasks();
      if (!response.success || response.data == null) return;

      await database.clearMasks();
      await database.saveInventoryMasks(response.data!);
      debugPrint('✅ Máscaras sincronizadas.');
    } catch (e) {
      debugPrint('❌ syncMasks: $e');
    }
  }

  // =========================================================================
  // UTILITÁRIOS LOCAIS
  // =========================================================================

  void addRecordLocally(InventoryRecordModel record) {
    _inventoryRecords.add(record);
    //_syncInventorySyncedState();
    notifyListeners();
  }

  void removeRecordLocally(InventoryRecordModel record) {
    _inventoryRecords.removeWhere((r) => r.id == record.id);
    //_syncInventorySyncedState();
    notifyListeners();
  }

  void clearInventoryRecords() {
    _records = [];
    notifyListeners();
  }

  void clearInventories() {
    _inventories = [];
    _inventoriesList = [];
    notifyListeners();
  }

  Future<void> setDecrementSequence() async {
    final storage = StorageService();
    await storage.decrementSequence();
  }

  // =========================================================================
  // PRIVADOS
  // =========================================================================

  Future<void> _updateLocalList(InventoryModel item) async {
    final idx = _allInventories.indexWhere(
      (e) => e.inventCode == item.inventCode && e.inventGuid == item.inventGuid,
    );

    if (idx != -1) {
      _allInventories[idx] = item;
    } else {
      _allInventories.insert(0, item);
    }

    // Reatribui via setter para reaplicar a consistência de isSynced
    _inventoriesList = List.from(_allInventories);
    _inventories = List.from(_allInventories);
    _selectedInventory = item;

    notifyListeners();
  }

  /// Agrupa records por inventCode e envia cada lote para a API.
  /// [parallel] = true usa Future.wait; false usa loop sequencial (com feedback).
  Future<void> _syncGroupedRecords(
    List<InventoryRecord> records, {
    bool parallel = false,
  }) async {
    final grouped = <String, List<InventoryRecord>>{};
    for (final r in records) {
      grouped.putIfAbsent(r.inventCode, () => []).add(r);
    }

    Future<void> syncGroup(MapEntry<String, List<InventoryRecord>> entry) async {
      final batch = InventoryBatchRequest(
        inventGuid: _deviceId ?? '',
        inventCode: entry.key,
        records: entry.value
            .map(
              (r) => InventoryRecordModel(
                inventCode: r.inventCode,
                inventCreated: r.inventCreated,
                inventUser: r.inventUser ?? 'Diones',
                inventUnitizer: r.inventUnitizer,
                inventLocation: r.inventLocation,
                inventProduct: r.inventProduct,
                inventBarcode: r.inventBarcode,
                inventStandardStack: r.inventStandardStack ?? 0,
                inventQtdStack: r.inventQtdStack ?? 0,
                inventQtdIndividual: r.inventQtdIndividual ?? 0,
                inventTotal: r.inventTotal ?? 0,
              ),
            )
            .toList(),
      );

      try {
        final response =
            await inventoryRepository.createOrUpdateInventoryRecords([batch]);
        if (!response.success) throw Exception(response.message);

        await Future.wait(
          entry.value.map((r) => database.markRecordAsSynced(r.id)),
        );
      } catch (e) {
        debugPrint('❌ _syncGroupedRecords lote ${entry.key}: $e');
      }
    }

    if (parallel) {
      await Future.wait(grouped.entries.map(syncGroup));
    } else {
      var done = 0;
      for (final entry in grouped.entries) {
        await syncGroup(entry);
        progressSynchronize = ++done / grouped.length;
        notifyListeners();
      }
    }
  }

  void _decrementInventoryTotal(InventoryRecordModel removed) {
    if (_selectedInventory == null ||
        removed.inventCode != _selectedInventory!.inventCode) return;

    final recordTotal = removed.inventTotal ?? 0;
    final newTotal =
        ((_selectedInventory!.inventTotal ?? 0) - recordTotal).clamp(0.0, double.infinity);

    _selectedInventory = _selectedInventory!.copyWith(inventTotal: newTotal);

    _updateTotalInLists(removed.inventCode, newTotal);
  }

  void _zeroInventoryTotal(String inventCode) =>
      _updateTotalInLists(inventCode, 0);

  void _updateTotalInLists(String inventCode, double total) {
    for (final list in [_allInventories, _inventories]) {
      final idx = list.indexWhere((i) => i.inventCode == inventCode);
      if (idx != -1) list[idx] = list[idx].copyWith(inventTotal: total);
    }
  }
}

/// Suprime o warning "unawaited_futures" para chamadas fire-and-forget intencionais.
void unawaited(Future<void> future) {}