import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/models/pallet_load_head_model.dart';
import 'package:oxdata/app/core/models/pallet_load_line_model.dart';
import 'package:oxdata/app/core/repositories/pallet_load_repository.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/models/pallet_load_item_model.dart';

/// Serviço responsável por gerenciar a lógica de negócios e o estado 
/// dos cabeçalhos de carga (PalletLoadHead).
class LoadService with ChangeNotifier {
  final LoadRepository loadRepository;

  LoadService({required this.loadRepository});

  // ========================== ESTADO ==========================

  // Lista de cabeçalhos de carga obtidos na última busca.
  List<PalletLoadHeadModel> _loadHeads = [];
  // Lista de linhas(pallets) de carga obtidos na última busca.
  List<PalletLoadLineModel> _loadPallets = [];

  /// Lista de Notas Fiscais associadas ao Pallet atual
  List<String> _currentPalletInvoices = [];
  
  // Getter para acesso externo
  List<PalletLoadHeadModel> get loadHeads => _loadHeads;
  List<PalletLoadLineModel> get loadPallets => _loadPallets;

  // Estado para a carga selecionada para edição
  PalletLoadHeadModel? _selectedLoadForEdit;

  // Estado para o pallet de carga selecionado para edição
  PalletLoadLineModel? _selectedLoadPalletForEdit;
  
  // Getter para a carga selecionada
  PalletLoadHeadModel? get selectedLoadForEdit => _selectedLoadForEdit;
  PalletLoadLineModel? get selectedLoadPalletForEdit => _selectedLoadPalletForEdit;

  List<String> get currentPalletInvoices => _currentPalletInvoices;

  // Paginação
  int _currentPageIndex = 0;
  
  int get currentPageIndex => _currentPageIndex;


  // Objeto completo que armazena os detalhes do pallet
  PalletDetailsModel? _currentPalletDetails;
  // Lista dos itens de linha do pallet (referencia os itens dentro do _currentPalletDetails)
  List<PalletItemModel> _currentPalletItems = [];

  // Getters para acesso externo
  PalletDetailsModel? get currentPalletDetails => _currentPalletDetails;
  List<PalletItemModel> get currentPalletItems => _currentPalletItems;

  // ========================== MÉTODOS DE DADOS ==========================

  /// Altera a página que deve estar mostrando para o usuário
  void setPage(int index) {
      if (_currentPageIndex != index) {
        _currentPageIndex = index;
        notifyListeners(); // Notifica os widgets que estão "escutando"
      }
    }

  /// Realiza a busca de todos os cabeçalhos de carga e atualiza o estado.
  Future<void> fetchAllLoadHeads() async {
    // Retorna uma ApiResponse<List<PalletLoadHeadModel>>
    final ApiResponse<List<PalletLoadHeadModel>> response =
        await loadRepository.getAllLoadHeads();

    if (response.success && response.data != null) {
      _loadHeads = response.data!;
    } else {
      // Se falhar, limpa a lista e lança uma exceção (ou imprime o erro)
      _loadHeads = [];
      debugPrint('Erro ao buscar cabeçalhos de carga: ${response.message}');
      // Opcional: throw Exception(response.message);
    }
    notifyListeners();
  }

  /// Insere ou atualiza uma lista de cabeçalhos de carga na API.
  /// Se `loadId == 0`, é uma inserção; se `loadId > 0`, é uma atualização.
  Future<void> upsertLoadHeads(List<PalletLoadHeadModel> headsToSave) async {
      final ApiResponse<List<int>> response =
          await loadRepository.upsertLoadHeads(headsToSave);

      if (response.success && response.data != null) {
          
          final List<int> returnedLoadIds = response.data!;
          
          if (headsToSave.length == 1 && headsToSave.first.loadId == 0 && returnedLoadIds.isNotEmpty) {
              
              final newId = returnedLoadIds.first;
              final originalHead = headsToSave.first;
              
              originalHead.loadId = newId;

              if (_selectedLoadForEdit != null && _selectedLoadForEdit?.loadId == 0) {
                  _selectedLoadForEdit = originalHead.copyWith(loadId: newId);
              }
          }
          
          await fetchAllLoadHeads();
          
      } else {
          throw Exception('Falha ao salvar cargas: ${response.message}');
      }
  }

  /// Limpa o estado atual das cargas.
  void clearLoadHeads() {
    _loadHeads = [];
    notifyListeners();
  }

  Future<void> fetchPalletsByLoadId(int loadId) async {
    final ApiResponse<List<PalletLoadLineModel>> response =
        await loadRepository.getPalletsByLoadId(loadId);

    if (response.success && response.data != null) {
      _loadPallets = response.data!;
    } else {
      _loadPallets = [];
      debugPrint('Erro ao buscar pallets da carga $loadId: ${response.message}');
    }

    notifyListeners(); // Notifica os widgets que dependem da lista de pallets
  }

  Future<ApiResponse<int>> addPalletToLoadLine(int loadId, String palletId, bool carregado) async {
    final pallet = PalletLoadLineModel(
      loadId: loadId,
      palletId: int.parse(palletId),
      carregado: carregado,
      palletLocation: '',
      palletTotalQuantity: 0,
    );

    // Envia o mapa para o repositório
    final response = await loadRepository.addPalletToLoad(pallet);

    if (response.success) {
      if (_selectedLoadForEdit != null) {
        await fetchPalletsByLoadId(_selectedLoadForEdit!.loadId);
      }
    } else {
      throw Exception('Falha ao adicionar pallet à carga: ${response.message}');
    }

    return response;
  }

  /// Atualiza o status de uma carga e retorna sucesso ou erro.
  Future<bool> updateLoadStatus(int loadId, String status) async {
    try {
      // Chama o repositório para atualizar o status na API
      final bool success = await loadRepository.updateLoadStatus(loadId, status);

      if (success) {
        // Se a atualização foi bem-sucedida, atualiza o estado local da carga selecionada
        if (_selectedLoadForEdit != null && _selectedLoadForEdit!.loadId == loadId) {
          _selectedLoadForEdit = _selectedLoadForEdit!.copyWith(status: status);
          notifyListeners();
        }

        // ---------------------------
        // Atualiza _currentPalletItems para refletir todos os pallets
        // ---------------------------

        // Lista temporária para armazenar todos os itens de todos os pallets
        List<PalletItemModel> allItems = [];

        for (final pallet in _loadPallets) {
          final items = await fetchPalletItems(
            loadId: pallet.loadId,
            palletId: pallet.palletId,
          );

          allItems.addAll(items);
        }

        _currentPalletItems = allItems;
        notifyListeners();
        // ---------------------------

      }

      return success;
    } catch (e) {
      debugPrint('Erro ao atualizar status da carga $loadId: $e');
      return false;
    }
  }

  // ========================== MÉTODOS PARA RECEBIMENTO==========================
  
  /// 🆕 Busca uma única carga pelo ID e a define como a carga selecionada.
  Future<PalletLoadHeadModel?> fetchLoadById(int loadId) async {
    final ApiResponse<PalletLoadHeadModel?> response =
        await loadRepository.getLoadHeadById(loadId);

    if (response.success && response.data != null) {
      // Define a carga como a selecionada para uso na página de recebimento
      setSelectedLoadForEdit(response.data); 
      return response.data;
    } else {
      setSelectedLoadForEdit(null);
      debugPrint('Erro ao buscar carga $loadId: ${response.message}');
      return null;
    }
  }

  /// Busca a lista de itens detalhados de um palete específico em uma carga.
  Future<List<PalletItemModel>> fetchPalletItems({
    required int loadId, 
    required int palletId 
  }) async {
    // O Repositório retorna um PalletDetailsModel (o objeto completo)
    final ApiResponse<PalletDetailsModel> response = 
        await loadRepository.getPalletItemsByPalletId(loadId, palletId);

    if (response.success && response.data != null) {
      // 1. ATUALIZA O ESTADO DO DETALHE COMPLETO
      _currentPalletDetails = response.data;
      
      // 2. ATUALIZA O ESTADO DA LISTA DE ITENS
      _currentPalletItems = response.data!.items;
      
      // Notifica quem está ouvindo o estado
      notifyListeners(); 

      // Retorna a lista de itens (mantendo a assinatura original, se for usada em ViewModels)
      return _currentPalletItems; 
    } else {
      // Em caso de falha, limpa os estados relacionados ao pallet
      _currentPalletDetails = null;
      _currentPalletItems = [];
      notifyListeners();

      debugPrint('Erro ao buscar itens do palete $palletId: ${response.message}');
      return []; 
    }
  }

  Future<bool> savePalletReception({
    required int loadId,
    required int palletId,
    required List<PalletItemModel> receivedItems,
  }) async {
    // Cria o DTO (Data Transfer Object) para enviar ao repositório
    // O Repositório deve saber como mapear PalletItemModel para o formato da API.
    final ApiResponse<bool> response = await loadRepository.savePalletReception(
      loadId: loadId,
      palletId: palletId,
      items: receivedItems,
    );

    if (response.success && response.data == true) {
      // Se for bem-sucedido, limpamos o estado do pallet, forçando o usuário a escanear
      // o próximo palete ou a buscar a carga novamente.
      clearPalletItemsState();
      return true;
    } else {
      debugPrint('Falha ao salvar recebimento do pallet $palletId: ${response.message}');
      throw Exception(response.message ?? 'Falha desconhecida ao salvar o recebimento.');
    }
  }

  // ========================== MÉTODOS DE EXCLUSÃO ==========================

  /// 🆕 Exclui o cabeçalho da carga (PalletLoadHead) e atualiza o estado local.
  Future<bool> deleteLoadHead(int loadId) async {
    // 1. Chama o repositório para realizar a exclusão na API.
    final ApiResponse<bool> response =
        await loadRepository.deleteLoadHead(loadId); // <-- REQUER IMPLEMENTAÇÃO NO REPOSITÓRIO

    if (response.success && response.data == true) {
      // 2. A exclusão foi bem-sucedida na API.

      // 3. Atualiza o estado local: remove o cabeçalho da lista _loadHeads.
      _loadHeads.removeWhere((head) => head.loadId == loadId);

      // Opcional: Limpa o estado selecionado se a carga excluída for a atual.
      if (_selectedLoadForEdit?.loadId == loadId) {
        _selectedLoadForEdit = null;
      }

      // 4. Notifica os ouvintes sobre a alteração.
      notifyListeners();

      debugPrint('Carga $loadId excluída com sucesso.');
      
      // 🎯 Retorna TRUE em caso de SUCESSO.
      return true;
    } else {
      // A exclusão falhou na API ou por conexão.
      debugPrint('Falha ao excluir carga $loadId: ${response.message}');
      
      // 🎯 Retorna FALSE em caso de FALHA, sem lançar exceção.
      return false;
    }
  }

  /// Exclui um pallet da carga (PalletLoadLine) e atualiza o estado local.
  Future<void> deletePallet(int loadId, int palletId) async {
    // Chama o repositório para realizar a exclusão na API
    final ApiResponse<bool> response =
        await loadRepository.deletePalletFromLoad(loadId, palletId);

    if (response.success && response.data == true) {
      // 1. A exclusão foi bem-sucedida na API.
      
      // 2. Atualiza o estado local: remove o pallet da lista _loadPallets
      _loadPallets.removeWhere(
        (pallet) => pallet.loadId == loadId && pallet.palletId == palletId,
      );
      
      // 3. Notifica os ouvintes sobre a alteração
      notifyListeners();
      
      debugPrint('Palete $palletId da carga $loadId excluído com sucesso.');
      
    } else {
      // A exclusão falhou na API ou por conexão.
      debugPrint('Falha ao excluir palete $palletId: ${response.message}');
      throw Exception(response.message ?? 'Falha desconhecida ao excluir o palete.');
    }
  }

  // ========================== MÉTODOS PARA NOTAS FISCAIS ==========================

  /// 🆕 Busca as Notas Fiscais de um Palete específico.
  /*Future<void> fetchPalletInvoices(int palletId) async {
    final ApiResponse<List<String>> response =
        await loadRepository.getPalletInvoices(palletId);

    if (response.success && response.data != null) {
      _currentPalletInvoices = response.data!;
    } else {
      _currentPalletInvoices = [];
      debugPrint('Erro ao buscar NFs do palete $palletId: ${response.message}');
      throw Exception(response.message ?? 'Falha ao buscar NFs.');
    }
    notifyListeners();
  }
  */

  /*Future<void> fetchLoadInvoices(int palletId) async {
    // 💡 Mudar o tipo de retorno esperado do Repositório para List<String> (lista de NFs)
    final ApiResponse<List<String>> response =
        await loadRepository.getLoadInvoices(palletId);

    // O mapeamento complexo para extrair o número da NF não é mais necessário,
    // pois a API já retorna apenas os números das NFs como strings.
    if (response.success && response.data != null) {
      _currentPalletInvoices = response.data!; 
    } else {
      _currentPalletInvoices = [];
      debugPrint('Erro ao buscar NFs do palete $palletId: ${response.message}');
      throw Exception(response.message ?? 'Falha ao buscar NFs.');
    }
    notifyListeners();
  }*/

  /// Adiciona uma Nota Fiscal a um Palete.
  Future<bool> addInvoiceToPallet(int loadId, String invoiceNumber, String invoiceKey) async {
    final ApiResponse<bool> response =
        await loadRepository.addInvoiceToPallet(loadId, invoiceNumber, invoiceKey);

    if (response.success && response.data == true)
    {
      if (!_currentPalletInvoices.contains(invoiceNumber))
      {
        _currentPalletInvoices.add(invoiceNumber);
        notifyListeners();
      }
      return true;
    }
    else
    {
      debugPrint('Falha ao adicionar NF $invoiceNumber: ${response.message}');
      throw Exception(response.message ?? 'Falha desconhecida ao adicionar NF.');
    }
  }

  /// 🆕 Remove uma Nota Fiscal de um Palete.
  Future<void> delInvoiceFromPallet(int loadId, String invoiceNumber) async {
    final ApiResponse<bool> response =
        await loadRepository.removeInvoiceFromPallet(loadId, invoiceNumber);

    if (response.success && response.data == true) {
      // Atualiza o estado local e notifica
      _currentPalletInvoices.remove(invoiceNumber);
      notifyListeners();
    } else {
      debugPrint('Falha ao remover NF $invoiceNumber: ${response.message}');
      throw Exception(response.message ?? 'Falha desconhecida ao remover NF.');
    }
  }

Future<void> fetchLoadInvoices(int loadId) async {

  // 💡 O repositório deve ser ajustado para usar loadId. Assumindo que você tem:
  final ApiResponse<List<String>> response = await loadRepository.getLoadInvoices(loadId); // <-- Novo método necessário no Repositório

  if (response.success && response.data != null) {
    _currentPalletInvoices = response.data!; 
  } else {
    _currentPalletInvoices = [];
    debugPrint('Erro ao buscar NFs da carga $loadId: ${response.message}');
    throw Exception(response.message ?? 'Falha ao buscar NFs da carga.');
  }
  notifyListeners();
  
}

  // ========================================== MÉTODOS DE ESTADO SELECIONADO ==========================================

  /// Define a carga selecionada.
  void setSelectedLoadForEdit(PalletLoadHeadModel? load) {
    _selectedLoadForEdit = load;
      
      _loadPallets = [];
      _selectedLoadPalletForEdit = null;
      _currentPalletInvoices = [];
      _currentPalletDetails = null;
      _currentPalletItems = [];

      notifyListeners();
  }
  
  /// 🆕 Limpa o estado de detalhes e itens do pallet atual.
  void clearPalletItemsState() {
    _currentPalletDetails = null;
    _currentPalletItems = [];
    _currentPalletInvoices = [];
    notifyListeners();
  }

}
