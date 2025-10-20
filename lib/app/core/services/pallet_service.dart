// -----------------------------------------------------------
// app/core/services/pallet_service.dart
// -----------------------------------------------------------
import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/models/pallet_model.dart';
import 'package:oxdata/app/core/models/pallet_item_model.dart';
import 'package:oxdata/app/core/models/ftp_image_response.dart';
import 'package:oxdata/app/core/repositories/pallet_repository.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';

class PalletService with ChangeNotifier {
  final PalletRepository palletRepository;

  PalletService({required this.palletRepository});

  List<PalletModel> _pallets = [];
  List<PalletItemModel> _palletItems = []; 

  List<PalletModel> get pallets => _pallets;
  List<PalletItemModel> get palletItems => _palletItems;

  /// ==================== PALLET ====================

  /// Busca todos os paletes da API e atualiza a lista.
  Future<void> fetchAllPallets() async {
      
    final ApiResponse<List<PalletModel>> response = await palletRepository.getAllPallets();

    if (response.success && response.data != null) {
      _pallets = response.data!;
    } else {
      _pallets = [];
      debugPrint('Erro ao buscar paletes: ${response.message}');
    }

    notifyListeners();
  }


    /// Busca paletes a partir dos filtros escolhidos na tela d epesquisa.
  Future<void> filtersPallets(String? status, String txtFilter) async {
      
    final ApiResponse<List<PalletModel>> response = await palletRepository.getFiltersPallets(status, txtFilter);

    if (response.success && response.data != null) {
      _pallets = response.data!;
    } else {
      _pallets = [];
      debugPrint('Erro ao buscar paletes: ${response.message}');
    }

    notifyListeners();
  }

  /// Cria ou atualiza uma lista de paletes (Upsert) e atualiza a lista local.
  Future<void> upsertPallets(List<PalletModel> pallets, List<String>? imagePaths) async {

    final ApiResponse<String> response = await palletRepository.upsertPallets(pallets, imagePaths);

    if (response.success) {
      // Recarrega todos os paletes após salvar
      await fetchAllPallets();
    } else {
      throw Exception('Erro ao salvar paletes: ${response.message}');
    }
    notifyListeners();
  }

  /// Cria ou atualiza uma lista de paletes (Upsert) e atualiza a lista local.
  Future<void> upsertPalletImages(int pallet, List<String> imagePaths) async {

    final ApiResponse<String> response = await palletRepository.upsertPalletImages(pallet, imagePaths);

    if (response.success) {
      // Recarrega todos os paletes após salvar
      //await fetchAllPallets();
    } else {
      throw Exception('Erro ao salvar imagens: ${response.message}');
    }
    notifyListeners();
  }

    /// Altera o status do pallet.
  Future<void> updatePalletStatus(int pallet, String status) async {

    final ApiResponse<String> response = await palletRepository.updatePalletStatus(pallet, status);

    if (response.success) {
      // Recarrega todos os paletes após salvar
      await fetchAllPallets();
    } else {
      throw Exception('Erro: ${response.message}');
    }
  }

  /// ==================== PALLET ITEM ====================

  /// Cria ou atualiza itens de palete (Upsert)
  Future<void> upsertPalletItems(List<PalletItemModel> items) async {
    final ApiResponse<String> response = await palletRepository.upsertPalletItems(items);

    if (!response.success) {
      throw Exception('Erro ao salvar itens de palete: ${response.message}');
    }

    notifyListeners();
  }

  /// Adiciona um novo PalletItemModel à lista local temporária
  /// e notifica os listeners.
  void addItemLocally(PalletItemModel item) {
    _palletItems.add(item);
    notifyListeners();
  }

  /// Remove um PalletItemModel específico da lista local temporária
  /// e notifica os listeners.
  void removeItemLocally(PalletItemModel item) {
    final removed = _palletItems.remove(item);
    // Se a remoção for bem-sucedida, notifica os listeners.
    if (removed) {
      notifyListeners();
    }
  }

  /// Atualiza a quantidade de um item existente na lista local e notifica.
  void updateItemQuantityLocally(PalletItemModel item, int newQuantity) {
    final index = _palletItems.indexWhere((i) => 
        i.palletId == item.palletId && i.productId == item.productId
    );
    
    if (index != -1) {
      // Cria uma nova instância com a quantidade atualizada
      _palletItems[index] = item.copyWith(
        quantity: newQuantity, 
        quantityReceived: newQuantity, // Assumindo que a quantidade recebida também é atualizada, se necessário
      );
      notifyListeners();
    }
  }

  /// ==================== DELETE ====================

  /// Exclui um palete e seus itens da API e atualiza a lista local.
  Future<void> deletePallet(int palletId) async {
    final ApiResponse<String> response = await palletRepository.deletePallet(palletId);

    if (response.success) {
      _pallets.removeWhere((pallet) => pallet.palletId == palletId);
      notifyListeners();
    } else {
      throw Exception('Erro ao excluir palete: ${response.message}');
    }
  }

  /// Exclui um item específico de um palete na API.
  Future<void> deletePalletItem(int palletId, String productId) async {
    final ApiResponse<String> response = await palletRepository.deletePalletItem(palletId, productId);

    if (!response.success) {
      throw Exception('Erro ao excluir item do palete: ${response.message}');
    }
    // Se quiser, recarregue o palete específico
    notifyListeners();
  }

  /// ==================== PALLET ITEM ====================

  /// Busca todos os itens de um palete específico e atualiza a lista local.
  Future<void> fetchPalletItems(int palletId) async {
    final ApiResponse<List<PalletItemModel>> response = await palletRepository.getPalletItems(palletId);

    if (response.success && response.data != null) {
      _palletItems = response.data!;
    } else {
      _palletItems = [];
      debugPrint('Erro ao buscar itens do palete: ${response.message}');
    }
    notifyListeners();
  }

    /// Busca TODOS os itens de TODOS os paletes.
  Future<void> fetchAllPalletItems() async {
    final ApiResponse<List<PalletItemModel>> response = await palletRepository.getAllPalletItems();

    if (response.success && response.data != null) {
      _palletItems = response.data!;
    } else {
      _palletItems = [];
      debugPrint('Erro ao buscar TODOS os itens de palete: ${response.message}');
    }
    notifyListeners();
  }

  /// Busca os itens filtrados
  Future<void> filterPalletItems(String? status, String txtFilter) async {
      
    final ApiResponse<List<PalletItemModel>> response = await palletRepository.getFilterPalletItems(status, txtFilter);

    if (response.success && response.data != null) {
      _palletItems = response.data!;
    } else {
      _palletItems = [];
      debugPrint('Erro ao buscar os itens de palete: ${response.message}');
    }
    notifyListeners();
  }

  /// Atualiza a quantidade de um item específico de um pallet.
  Future<void> updateItemQuantity(int index, int newQuantity) async {
    try {

      if (index >= 0 && index < _palletItems.length) {

        final updatedItem = _palletItems[index].copyWith(
          quantity: newQuantity,
          quantityReceived: newQuantity,
        );

        _palletItems[index] = updatedItem;
        notifyListeners();

      }

    } catch (e) {
      debugPrint('Erro em updateItemQuantity: $e');
      rethrow;
    }
  }

  /// ========================== IMAGENS ==========================
  Future<List<dynamic>> getPalletImages(int palletId) async {

    final ApiResponse<List<dynamic>> response =
      await palletRepository.getPalletImagesPath(palletId);

    if (response.success && response.data != null) {
      return response.data!; // retorna todas
    } else {
      debugPrint('Erro ao buscar imagens do palete: ${response.message}');
      return []; // lista vazia em caso de erro
    }
  }

  /// ==================== UTILITÁRIOS ====================

  void clearPallets() {
    _pallets = [];
    notifyListeners();
  }

  void clearPalletsItems() {
    _palletItems = [];
    notifyListeners();
  }

  /// Busca um palete específico na lista local (sem chamar a API)
  PalletModel? getPalletById(int palletId) {
    try {
      return _pallets.firstWhere((p) => p.palletId == palletId);
    } catch (e) {
      return null;
    }
  }
}