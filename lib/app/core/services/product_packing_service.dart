import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/models/product_packing_model.dart';
import 'package:oxdata/app/core/models/product_pack_item.dart';
import 'package:oxdata/app/core/models/product_pack_image_base64.dart';
import 'package:oxdata/app/core/repositories/product_packing_repository.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';

class ProductPackingService with ChangeNotifier {
  final ProductPackingRepository repository;

  ProductPackingService({required this.repository});

  // --- Estado ---
  List<ProductPackingModel> _allPackings = [];
  List<ProductPackingModel> _filteredPackings = [];
  ProductPackingModel? _selectedPacking;

  List<ImagePackBase64> _packImages = [];
  List<ImagePackBase64> get packImages => _packImages;

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

  /*
  Future<void> fetchPackImages(int packId) async {
    _isLoading = true;
    notifyListeners();
    
    final response = await repository.getPackImagesBase64(packId);
    if (response.success) {
      _packImages = response.data ?? [];
    } else {
      _packImages = [];
    }
    
    _isLoading = false;
    notifyListeners();
  }
  */

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
  Future<ApiResponse<bool>> addItemToSelectedPack(String productId, String username) async {
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
      
      return response;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<ProductPackItem>> fetchSelectedPackItems(int packId) async {
    // 1. Chama o repositório que retorna ApiResponse<List<ProductPackItemModel>>
    final response = await repository.getPackItems(packId);
    
    // 2. Se deu sucesso, retorna os dados (a lista real)
    if (response.success && response.data != null) {
      return response.data!;
    } 
    
    // 3. Se deu erro, retorna lista vazia para não quebrar o contrato do método
    debugPrint("Erro ao carregar itens: ${response.message}");
    return [];
  }

  /// Quando adicionar um novo item com sucesso, você também pode atualizar localmente
  Future<ApiResponse<bool>> addItem(String productId, String username) async {
    if (_selectedPacking == null) return ApiResponse(success: false);

    _isLoading = true;
    notifyListeners();

    final response = await repository.addItemToPack(
      _selectedPacking!.packId,
      productId,
      username,
    );

    if (response.success) {
      // Em vez de recarregar tudo da API, você pode adicionar o item 
      // manualmente na lista local para uma UI mais rápida
      /*
      _selectedPacking!.items.add(ProductPackItemModel(
        packId: _selectedPacking!.packId,
        packProductId: productId,
        packUser: username,
      ));
      */
      
      // Ou, para garantir integridade, recarrega da API:
      await fetchSelectedPackItems(_selectedPacking!.packId);
    }

    _isLoading = false;
    notifyListeners();
    return response;
  }

}