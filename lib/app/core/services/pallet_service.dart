// -----------------------------------------------------------
// app/core/services/pallet_service.dart
// -----------------------------------------------------------
import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/models/pallet_model.dart';
import 'package:oxdata/app/core/models/pallet_item_model.dart';
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

  /// Cria ou atualiza uma lista de paletes (Upsert) e atualiza a lista local.
  Future<void> upsertPallets(List<PalletModel> pallets) async {
    final ApiResponse<String> response = await palletRepository.upsertPallets(pallets);

    if (response.success) {
      // Recarrega todos os paletes após salvar
      await fetchAllPallets();
    } else {
      throw Exception('Erro ao salvar paletes: ${response.message}');
    }
  }

  /// ==================== PALLET ITEM ====================

  /// Cria ou atualiza itens de palete (Upsert)
  Future<void> upsertPalletItems(List<PalletItemModel> items) async {
    final ApiResponse<String> response = await palletRepository.upsertPalletItems(items);

    if (!response.success) {
      throw Exception('Erro ao salvar itens de palete: ${response.message}');
    }
    // Se quiser, pode recarregar o palete específico para atualizar a UI
    notifyListeners();
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

  /// Cria ou atualiza itens de palete (Upsert)
  /*Future<void> upsertPalletItems(List<PalletItemModel> items) async {
    final ApiResponse<String> response = await palletRepository.upsertPalletItems(items);

    if (!response.success) {
      throw Exception('Erro ao salvar itens de palete: ${response.message}');
    }
    // Se quiser, pode recarregar o palete específico para atualizar a UI
    notifyListeners();
  }*/

  /// ==================== UTILITÁRIOS ====================

  /// Limpa a lista de paletes localmente.
  void clearResults() {
    _pallets = [];
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