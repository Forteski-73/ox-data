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
import 'package:oxdata/app/core/utils/network_status.dart';
import 'package:oxdata/db/app_database.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class InventoryService with ChangeNotifier {
  InventoryService({
    required this.inventoryRepository,
    required this.database,
  });

  final InventoryRepository inventoryRepository;
  final AppDatabase database;

  // ── Estado ────────────────────────────────────────────────────────────────

  String? _deviceId;
  String? get deviceId => _deviceId;

  List<InventoryModel> _allInventories = [];
  List<InventoryModel> _inventories = [];
  List<InventoryRecordModel> _inventoryRecords = [];
  List<Product> _searchResults = [];
  List<InventoryMaskData> _listMask = [];

  set _records(List<InventoryRecordModel> value) {
    _inventoryRecords = value;
    _syncInventorySyncedState();
  }

  set _inventoriesList(List<InventoryModel> value) {
    _allInventories = value;
    _syncInventorySyncedState();
  }

  /// Marca isSynced = false em todo inventário pai que tenha ao menos
  /// um record filho pendente em _inventoryRecords.
  void _syncInventorySyncedState() {
    if (_allInventories.isEmpty || _inventoryRecords.isEmpty) return;

    final unsyncedCodes = _inventoryRecords
        .where((r) => r.isSynced == false)
        .map((r) => r.inventCode)
        .toSet();

    if (unsyncedCodes.isEmpty) return;

    var changed = false;

    _allInventories = _allInventories.map((inv) {
      if (unsyncedCodes.contains(inv.inventCode) && (inv.isSynced ?? true)) {
        changed = true;
        return inv.copyWith(isSynced: false);
      }
      return inv;
    }).toList();

    if (changed) {
      _inventories = List.from(_allInventories);

      if (_selectedInventory != null &&
          unsyncedCodes.contains(_selectedInventory!.inventCode)) {
        _selectedInventory = _selectedInventory!.copyWith(isSynced: false);
      }
    }
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

  /// Fluxo: salva localmente → tenta sync se houver internet.
  Future<StatusResult> confirmDraft(InventoryRecordInput draft) async {
    if (_selectedInventory == null) {
      return StatusResult(
        status: 0,
        message: 'Nenhum inventário selecionado para gravação.',
      );
    }

    // 1. Sempre salva local primeiro (offline-first)
    final localResult = await database.insertOrUpdateInventoryRecordOffline(
      _selectedInventory!,
      draft,
      synced: false,
    );

    if (localResult.status == 0) return localResult;

    await refreshSelectedInventoryState(_selectedInventory!.inventCode);

    _draft = null;
    notifyListeners();

    // 2. Sem internet → retorna sucesso local
    if (!await NetworkUtils.hasInternetConnection()) {
      await fetchRecordsByInventCode(_selectedInventory!.inventCode);
      return StatusResult(status: 1, message: 'Registro salvo localmente.');
    }

    // 3. Com internet → sincroniza pendentes em lote
    final syncResult = await syncInventoryBatch(_selectedInventory!.inventCode);

    if (syncResult.status == 1) {
      await fetchRecordsByInventCode(_selectedInventory!.inventCode);
    }

    return syncResult;
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

  Future<InventoryRecordModel?> checkExistingRecordRemote(
    String unitizer,
    String position,
    String product,
  ) async {
    if (_selectedInventory == null) return null;
    if (!await NetworkUtils.hasInternetConnection()) return null;

    final response = await inventoryRepository
        .getRecordsByInventCode(_selectedInventory!.inventCode);

    if (!response.success || response.data == null) return null;

    return response.data!.cast<InventoryRecordModel?>().firstWhere(
          (r) =>
              r!.inventUnitizer == unitizer &&
              r.inventLocation == position &&
              r.inventBarcode == product,
          orElse: () => null,
        );
  }

  // =========================================================================
  // INVENTÁRIOS
  // =========================================================================

  /// Merge local-first: banco local tem prioridade quando não sincronizado.
  Future<void> fetchAllInventories() async {
    if (_deviceId == null) {
      debugPrint('⚠️ fetchAllInventories: deviceId nulo');
      _inventories = _allInventories = [];
      notifyListeners();
      return;
    }

    final localRows = await database.getLocalInventories();

    // Mapa inicial com os dados locais
    final merged = <String, InventoryModel>{
      for (final row in localRows)
        row.inventCode: InventoryModel.fromLocal(row),
    };

    // Sobrescreve apenas registros já sincronizados com a versão remota
    final remote = await inventoryRepository.getRecentInventoriesByGuid(_deviceId!);
    if (remote.success && remote.data != null) {
      for (final r in remote.data!) {
        final local = merged[r.inventCode];
        if (local == null || local.isSynced == true) {
          merged[r.inventCode] = r;
          await database.insertOrUpdateInventoryOffline(r, synced: true);
        }
      }
    } else {
      debugPrint('⚠️ Inventários remotos indisponíveis: ${remote.message}');
    }

    _inventoriesList = merged.values.toList()
      ..sort((a, b) =>
          b.inventCreated?.compareTo(a.inventCreated ?? DateTime(0)) ?? 0);

    _inventories = List.from(_allInventories);
    _selectedInventory ??= _allInventories.firstOrNull;

    notifyListeners();
  }

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

  /*
  Future<StatusResult> createOrUpdateInventoryCurr(InventoryModel inventory) async {

    // Inventários Iniciados são persistidos localmente imediatamente
    if (inventory.inventStatus == InventoryStatus.Iniciado) {
      await database.insertOrUpdateInventoryOffline(inventory, synced: false);
      await _updateLocalList(inventory);

      if (!await NetworkUtils.hasInternetConnection()) {
        return StatusResult(
          status: 1,
          message: 'Sem conexão. Trabalhando offline.',
        );
      }
      else {
        final response = await inventoryRepository.createOrUpdateInventory(inventory);
        if (!response.success) {
          return StatusResult(status: 0, message: response.message ?? 'Erro ao salvar inventário.',);
        }
      }

    } else { // Quando finaliza o inventário

      if (!await NetworkUtils.hasInternetConnection()) {
        return StatusResult(
          status: 1,
          message: 'Sem conexão com Internet.',
        );
      }

      final response = await inventoryRepository.createOrUpdateInventory(inventory);
      if (!response.success) {
        return StatusResult(status: 0, message: response.message ?? 'Erro ao salvar inventário.',);
      }
      else
      {
        ///final recordResponse = await inventoryRepository.createOrUpdateInventoryRecords(records);
        /// enviar todos os records do inventário
        
        

          await database.insertOrUpdateInventoryOffline(response.data ?? inventory, synced: true,);
          await _updateLocalList(inventory);
      }
    }
    return StatusResult(status: 1, message: 'Inventário salvo com sucesso.');
  }
  */

  Future<StatusResult> createOrUpdateInventoryCurr(InventoryModel inventory) async {

    if (inventory.inventStatus == InventoryStatus.Iniciado) {
      await database.insertOrUpdateInventoryOffline(inventory, synced: false);
      await _updateLocalList(inventory);

      if (!await NetworkUtils.hasInternetConnection()) {
        return StatusResult(status: 1, message: 'Sem conexão. Trabalhando offline.');
      }

      final response = await inventoryRepository.createOrUpdateInventory(inventory);
      if (!response.success) {
        return StatusResult(status: 0, message: response.message ?? 'Erro ao salvar inventário.');
      }

    } else {

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

        final recordsResponse = await inventoryRepository.createOrUpdateInventoryRecords([batch]);

        if (!recordsResponse.success) {
          debugPrint('⚠️ Erro ao enviar records na finalização: ${recordsResponse.message}');
          return StatusResult(status: 0, message: response.message ?? 'Erro ao salvar inventário.');
        } else {
            // Marca todos os records como sincronizados
            await database.insertOrUpdateInventoryOffline(response.data ?? inventory, synced: true,);
            await _updateLocalList(inventory);
          }
      }

    }

    return StatusResult(status: 1, message: 'Inventário salvo com sucesso.');
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

  // =========================================================================
  // RECORDS
  // =========================================================================

  Future<StatusResult> saveInventoryRecord(InventoryRecordInput input) async {
    if (_selectedInventory == null) {
      return StatusResult(status: 0, message: 'Nenhum inventário selecionado.');
    }
    if (input.product.isEmpty) {
      return StatusResult(status: 0, message: 'Produto obrigatório.');
    }

    final product = await searchProductLocallyByCode(input.product);
    if (product == null) {
      return StatusResult(status: 0, message: 'Produto não encontrado.');
    }

    final total =
        ((input.qtdPorPilha ?? 0) * (input.numPilhas ?? 0)) + (input.qtdAvulsa ?? 0);

    final record = InventoryRecordModel(
      inventCode: _selectedInventory!.inventCode,
      inventUnitizer: input.unitizer,
      inventLocation: input.position,
      inventProduct: product.productId,
      inventBarcode: product.barcode,
      inventStandardStack: (input.qtdPorPilha ?? 0).toInt(),
      inventQtdStack: (input.numPilhas ?? 0).toInt(),
      inventQtdIndividual: input.qtdAvulsa,
      inventTotal: total,
      inventCreated: DateTime.now(),
      inventUser: 'Diones',
    );

    final batch = InventoryBatchRequest(
      inventGuid: _selectedInventory!.inventGuid ?? '',
      inventCode: _selectedInventory!.inventCode,
      records: [record],
    );

    return createOrUpdateInventoryRecords([batch]);
  }

  Future<StatusResult> createOrUpdateInventoryRecords(
    List<InventoryBatchRequest> batches,
  ) async {
    final response =
        await inventoryRepository.createOrUpdateInventoryRecords(batches);

    if (!response.success) {
      return StatusResult(
        status: 0,
        message: response.message ?? 'Erro ao salvar registros.',
      );
    }

    // Atualiza o total do inventário selecionado com o valor retornado pela API
    final raw = response.rawJson;
    if (raw != null && _selectedInventory != null) {
      final returnedCode =
          (raw['InventCode'] ?? raw['inventCode']) as String?;
      final newTotal =
          (raw['InventTotal'] ?? raw['inventTotal'] as num?)?.toDouble();

      if (_selectedInventory!.inventCode == returnedCode && newTotal != null) {
        _selectedInventory = _selectedInventory!.copyWith(inventTotal: newTotal);
        await _updateLocalList(_selectedInventory!);
      }
    }

    return StatusResult(
      status: 1,
      message: (raw?['Message'] ?? raw?['message'] as String?) ??
          response.data ??
          'Registros salvos com sucesso.',
    );
  }

  /// Merge local-first: registros da API são base; pendentes locais sobrescrevem.
  /*
  Future<void> fetchRecordsByInventCode(String inventCode) async {
    try {
      List<InventoryRecordModel> apiRecords = [];

      if (await NetworkUtils.hasInternetConnection()) {
        final response =
            await inventoryRepository.getRecordsByInventCode(inventCode);
        if (response.success && response.data != null) {
          apiRecords = response.data!;
        }
      }

      final localData = await database.getPendingRecordsWithDescription(
        inventCode: inventCode,
      );

      final localModels = localData
          .map(
            (item) => InventoryRecordModel.fromLocal(item.record).copyWith(
              productDescription: item.productName,
              isSynced: false,
            ),
          )
          .toList();

      // Constrói mapa com API como base e pendentes locais sobrescrevendo
      final merged = <String, InventoryRecordModel>{
        for (final r in apiRecords) r.id.toString(): r,
        for (final r in localModels) r.id.toString(): r,
      };

      _records = merged.values.toList()
        ..sort((a, b) =>
            (b.inventCreated ?? DateTime(0)).compareTo(a.inventCreated ?? DateTime(0)));

      notifyListeners();
    } catch (e) {
      debugPrint('❌ fetchRecordsByInventCode: $e');

      // Fallback seguro: apenas locais
      final localData = await database.getPendingRecordsWithDescription(
        inventCode: inventCode,
      );
      _records = localData
          .map(
            (item) => InventoryRecordModel.fromLocal(item.record).copyWith(
              productDescription: item.productName,
            ),
          )
          .toList();

      notifyListeners();
    }
  }
  */

  /// Merge local-first: registros da API são base; pendentes locais sobrescrevem.
  Future<void> fetchRecordsByInventCode(String inventCode) async {
    try {
      List<InventoryRecordModel> apiRecords = [];

      if (await NetworkUtils.hasInternetConnection()) {
        final response =
            await inventoryRepository.getRecordsByInventCode(inventCode);
        if (response.success && response.data != null) {
          apiRecords = response.data!;
        }
      }

      final localData = await database.getPendingRecordsWithDescription(
        inventCode: inventCode,
      );

      final localModels = localData
          .map(
            (item) => InventoryRecordModel.fromLocal(item.record).copyWith(
              productDescription: item.productName,
              isSynced: false,
            ),
          )
          .toList();

      // 💡 CORREÇÃO AQUI: Usando uma chave composta de negócio para unificar os registros
      final merged = <String, InventoryRecordModel>{};

      // 1. Adiciona os registros vindos da API
      for (final r in apiRecords) {
        final businessKey = '${r.inventUnitizer}_${r.inventLocation}_${r.inventBarcode}';
        merged[businessKey] = r;
      }

      // 2. Adiciona/Sobrescreve com os locais pendentes (se houver correspondência, o local substitui o da API)
      for (final r in localModels) {
        final businessKey = '${r.inventUnitizer}_${r.inventLocation}_${r.inventBarcode}';
        merged[businessKey] = r;
      }

      _records = merged.values.toList()
        ..sort((a, b) =>
            (b.inventCreated ?? DateTime(0)).compareTo(a.inventCreated ?? DateTime(0)));

      notifyListeners();
    } catch (e) {
      debugPrint('❌ fetchRecordsByInventCode: $e');

      // Fallback seguro: apenas locais
      final localData = await database.getPendingRecordsWithDescription(
        inventCode: inventCode,
      );
      _records = localData
          .map(
            (item) => InventoryRecordModel.fromLocal(item.record).copyWith(
              productDescription: item.productName,
            ),
          )
          .toList();

      notifyListeners();
    }
  }

  Future<InventoryRecordModel?> getRecordById(int id) async {
    final response = await inventoryRepository.getRecordById(id);
    return response.success ? response.data : null;
  }

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

  Future<void> deleteInventoryRecord(int id) async {
    final response = await inventoryRepository.deleteInventoryRecord(id);
    if (!response.success) {
      throw Exception('Erro ao excluir registro: ${response.message}');
    }

    final idx = _inventoryRecords.indexWhere((r) => r.id == id);
    if (idx == -1) return;

    final removed = _inventoryRecords.removeAt(idx);
    _decrementInventoryTotal(removed);

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

  Future<Product?> searchProductLocallyByCode(String code) async {
    if (code.isEmpty) return null;
    try {
      return await database.findProductByCode(code);
    } catch (e) {
      debugPrint('❌ searchProductLocallyByCode: $e');
      return null;
    }
  }

  Future<void> searchProductLocally(String query) async {
    if (query.length < 4) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _searchResults = await database.searchProducts(query);
    notifyListeners();
  }

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
    if (_isSetupEnabled) await startSyncSetUp();
    if (_isContagemEnabled) {
      await startSyncInventory();
    } else if (!_isSetupEnabled) {
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
      isSyncing = false;
      notifyListeners();
    }
  }

  /// Sync em paralelo (cabeçalhos + records), sem feedback de progresso.
  /// Usado internamente após confirmDraft().
  Future<StatusResult> syncInventoryBatch([String? inventCode]) async {
    try {
      final results = await Future.wait([
        inventCode == null
            ? database.getPendingInventories()
            : database.getPendingInventoryByCode(inventCode),
        database.getPendingRecords(inventCode: inventCode),
      ]);

      final pendingInventories = results[0] as List<InventoryData>;
      final pendingRecords = results[1] as List<InventoryRecord>;

      if (pendingInventories.isEmpty && pendingRecords.isEmpty) {
        return StatusResult(status: 1, message: 'Tudo em dia!');
      }

      // Cabeçalhos em paralelo
      await Future.wait(
        pendingInventories.map((item) async {
          final response = await inventoryRepository
              .createOrUpdateInventory(InventoryModel.fromLocal(item));
          if (response.success) await database.markInventoryAsSynced(item.inventCode);
        }),
      );

      // Records em paralelo por grupo
      await _syncGroupedRecords(pendingRecords, parallel: true);

      return StatusResult(status: 1, message: 'Sincronização concluída!');
    } catch (e) {
      debugPrint('❌ syncInventoryBatch: $e');
      return StatusResult(status: 0, message: 'Erro: $e');
    } finally {
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
    _syncInventorySyncedState();
    notifyListeners();
  }

  void removeRecordLocally(InventoryRecordModel record) {
    _inventoryRecords.removeWhere((r) => r.id == record.id);
    _syncInventorySyncedState();
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