import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/models/product_packing_model.dart';
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

  // No método setSelectedPacking, chama a busca de imagens
  void setSelectedPacking(ProductPackingModel pkg) {
    _selectedPacking = pkg;
    fetchPackImages(pkg.packId); // Busca as imagens na API ao selecionar
    notifyListeners();
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

}