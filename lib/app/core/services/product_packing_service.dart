import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/models/product_packing_model.dart';
import 'package:oxdata/app/core/models/product_pack_item.dart';
import 'package:oxdata/app/core/models/product_pack_image_base64.dart';
import 'package:oxdata/app/core/repositories/product_packing_repository.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/models/product_packing_bom.dart';

class ProductPackingService with ChangeNotifier {
  final ProductPackingRepository repository;

  ProductPackingService({required this.repository});

  // --- Estado ---
  List<ProductPackingModel> _allPackings = [];
  List<ProductPackingModel> _filteredPackings = [];
  ProductPackingModel? _selectedPacking;

  List<ImagePackBase64> _packImages = [];
  List<ImagePackBase64> get packImages => _packImages;

    // --- Estado do BOM para sequência de embalagem para as TVs ---
  List<ProductPackingBom> _bomItems = [];
  List<ProductPackingBom> get bomItems => _bomItems;

  bool _isLoading = false;

  // --- Getters ---
  List<ProductPackingModel> get packings => _filteredPackings;
  ProductPackingModel? get selectedPacking => _selectedPacking;
  bool get isLoading => _isLoading;

  /// Busca todas as montagens da API
  Future<void> fetchAllPackings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await repository.getAllPackings();
      if (response.success && response.data != null) {
        _allPackings = response.data!;
        _filteredPackings = List.from(_allPackings);
      }
    } catch (e) {
      debugPrint("Erro ao buscar packings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtro local para busca na barra de pesquisa
  void filterPackings(String query) {
    if (query.isEmpty) {
      _filteredPackings = List.from(_allPackings);
    } else {
      _filteredPackings = _allPackings
          .where((p) => p.packName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  /// Remove completamente uma montagem e atualiza a lista local
  Future<ApiResponse<bool>> deletePacking(int packId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await repository.deletePacking(packId);

      if (response.success) {
        // Remove da lista local sem precisar recarregar da API
        _allPackings.removeWhere((p) => p.packId == packId);
        _filteredPackings = List.from(_allPackings);

        // Se a montagem deletada era a selecionada, limpa a seleção
        if (_selectedPacking?.packId == packId) {
          _selectedPacking = null;
          _packImages = [];
        }
      }

      return response;
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erro no service ao deletar: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<ImagePackBase64>> fetchPackImages(int packId) async {
    _isLoading = true;
    notifyListeners();
    
    final response = await repository.getPackImagesBase64(packId);

    List<ImagePackBase64> images = [];

    if (response.success) {
      images = response.data ?? [];
      _packImages = images;
    } else {
      _packImages = [];
    }

    _isLoading = false;
    notifyListeners();

    return images;
  }

  Future<void> addOrUpdatePackImages(List<ImagePackBase64> images, ProductPackingModel pkg,) async {
    _packImages.addAll(images);
    notifyListeners();

    await _savePackImages(pkg);
  }

  Future<void> _savePackImages(ProductPackingModel pkg) async {
    final base64List = _packImages
        .map((e) => e.imagesBase64)
        .whereType<String>()
        .toList();

    final response = await repository.packImagesUpdate(
      pkg.packId,
      base64List,
    );

    if (!response.success) {
      print('Erro ao salvar imagens: ${response.message}');
    }
  }

  // No método setSelectedPacking, chama a busca de imagens
  /*
  void setSelectedPacking(ProductPackingModel pkg) {
    _selectedPacking = pkg;
    fetchPackImages(pkg.packId); // Busca as imagens na API ao selecionar
    notifyListeners();
  }
  */

  Future<void> setSelectedPacking(ProductPackingModel pkg) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Busca os dados necessários
      final images = await fetchPackImages(pkg.packId);
      final items = await fetchSelectedPackItems(pkg.packId);

      // 2. Atualiza o objeto selecionado (clonando ou modificando)
      _selectedPacking = pkg; 
      _selectedPacking!.images = images;
      _selectedPacking!.items = items;

    } catch (e) {
      debugPrint("Erro ao carregar detalhes: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // Notifica a UI que os dados chegaram
    }
  }

  /// Cria uma nova embalagem e atualiza a lista local
  Future<ApiResponse<ProductPackingModel>> createPacking(String name, String user) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await repository.createPacking(name, user);

      if (response.success && response.data != null) {
        // Adiciona o novo item à lista local para atualização imediata na UI
        _allPackings.insert(0, response.data!);
        _filteredPackings = List.from(_allPackings);
        
        // Opcional: Selecionar automaticamente o item recém criado
        _selectedPacking = response.data;
      }
      
      return response;
    } catch (e) {
      return ApiResponse(success: false, message: "Erro no service ao criar: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Remove uma imagem localmente e sincroniza com o servidor
  Future<void> removeImage(int index) async {
    if (_selectedPacking == null || index < 0 || index >= _packImages.length) return;

    // Remove da lista local
    _packImages.removeAt(index);
    notifyListeners(); // Atualiza a UI imediatamente (otimismo)

    // Sincroniza com a API usando o método que você já tem
    await _savePackImages(_selectedPacking!);
  }

  /// Add itens relacionados com a embalagem
  Future<ApiResponse<ProductPackItem>> addItemToSelectedPack(String productId, String username) async {
    if (_selectedPacking == null) {
      return ApiResponse(success: false, message: "Selecione uma embalagem primeiro.");
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await repository.addItemToPack(
        _selectedPacking!.packId,
        productId,
        username,
      );
      
      if (response.success && response.data != null) {
        // Inicializa a lista caso ela esteja nula por segurança
        _selectedPacking!.items ??= []; 
        
        // Adiciona o item no contexto local
        _selectedPacking!.items.add(response.data!);
      }

      return response;
    } finally {
      _isLoading = false;
      notifyListeners(); // Garante que a tela vai se reconstruir com o novo item na lista
    }
  }

  Future<List<ProductPackItem>> fetchSelectedPackItems(int packId) async {
    // Chama o repositório que retorna ApiResponse<List<ProductPackItemModel>>
    debugPrint("packId: $packId");
    final response = await repository.getPackItems(packId);
    
    // Se deu sucesso, retorna os dados (a lista real)
    if (response.success && response.data != null) {
      return response.data!;
    } 
    
    // Se deu erro, retorna lista vazia para não quebrar o contrato do método
    debugPrint("Erro ao carregar itens: ${response.message}");
    return [];
  }

  // Remove itens
  Future<void> removeItem(int index) async {
    if (_selectedPacking == null) return;

    // Pega o item que será removido
    final item = _selectedPacking!.items[index];

    _isLoading = true;
    notifyListeners();

    try {
      final response = await repository.deleteItemFromPack(item.packId, item.packProductId);

      if (response.success) {
        // 1. Remove da lista do objeto selecionado
        _selectedPacking!.items.removeAt(index);


        //_selectedPacking!.items = currentItems;

        // 2. Sincroniza com a lista global (_allPackings)
        _updateLocalListWithSelected();
      } else {
        debugPrint(response.message);
      }

    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Método auxiliar para refletir as mudanças do _selectedPacking na lista principal
  void _updateLocalListWithSelected() {
    if (_selectedPacking == null) return;

    // Encontra o índice do pack na lista principal
    final index = _allPackings.indexWhere((p) => p.packId == _selectedPacking!.packId);
    
    if (index != -1) {
      // Atualiza a referência na lista principal
      _allPackings[index] = _selectedPacking!;
      
      // Se houver um filtro ativo, atualiza a lista filtrada também
      _filteredPackings = List.from(_allPackings); 
      // Nota: Se quiser manter o termo da pesquisa atual, chame filterPackings novamente em vez de redefinir.
    }
  }


  /// Busca o BOM (Bill of Materials) de um produto específico
  Future<List<ProductPackingBom>> fetchPackingBom(String productId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await repository.getPackingBomByProduct(productId);

      if (response.success && response.data != null) {
        _bomItems = response.data!;
      } else {
        _bomItems = [];
        debugPrint("Erro ao buscar BOM: ${response.message}");
      }

      return _bomItems;
    } catch (e) {
      debugPrint("Erro no service ao buscar BOM: $e");
      _bomItems = [];
      return _bomItems;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cria/substitui o BOM de um produto e atualiza o estado local
  Future<ApiResponse<List<ProductPackingBom>>> savePackingBom(
    String productId,
    List<ProductPackingBom> bomItems,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await repository.createPackingBom(productId, bomItems);

      if (response.success) {
        // Se a API retornou a lista atualizada, usa ela; senão mantém o que foi enviado
        _bomItems = (response.data != null && response.data!.isNotEmpty)
            ? response.data!
            : bomItems;
      } else {
        debugPrint("Erro ao salvar BOM: ${response.message}");
      }

      return response;
    } catch (e) {
      _isLoading = false;
      return ApiResponse(
        success: false,
        message: 'Erro no service ao salvar BOM: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}