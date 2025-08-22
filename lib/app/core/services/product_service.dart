// -----------------------------------------------------------
// app/core/services/product_service.dart (Serviço de Produtos)
// -----------------------------------------------------------
import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/models/product_model.dart';
import 'package:oxdata/app/core/models/product_complete.dart';
import 'package:oxdata/app/core/models/product_tag_model.dart'; 
import 'package:oxdata/app/core/repositories/product_repository.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
//import 'package:uuid/uuid.dart';

class ProductService with ChangeNotifier {
  final ProductRepository productRepository;

  ProductService({required this.productRepository});

  List<ProductModel> _searchResults = [];
  ProductComplete? _productComplete;
  int? _totalProducts = 0;

  List<ProductModel> get searchResults => _searchResults;
  ProductComplete? get productComplete => _productComplete;
  int? get totalProducts => _totalProducts;

  Future<void> performSearch(Map<String, dynamic> activeFilters) async {
    final ApiProductResponse<List<ProductModel>> response =
        await productRepository.searchProducts(activeFilters);

    if (response.success && response.data != null) {
      _searchResults = response.data!;
      _totalProducts = response.totalCount;
    } else {
      _searchResults = [];
      _totalProducts = 0;
    }
    notifyListeners();
  }

  Future<void> fetchProductComplete(String productId) async {
    final ApiResponse<List<ProductComplete>> response =
        await productRepository.getAppProduct(productId);

    if (response.success && response.data != null && response.data!.isNotEmpty) {
      _productComplete = response.data!.first;
    } else {
      _productComplete = null;
      throw Exception('Erro ao buscar detalhes do produto $productId: ${response.message}');
    }
    notifyListeners();
  }

  /*
  Future<bool> uploadProductImages(
      String productId, String finalidade, List<XFile> files) async {
    if (files.isEmpty) return false;

    // Chama o repositório para enviar as imagens
    final ApiResponse<bool> response = await productRepository.updateProductImages(
      productId: productId,
      finalidade: finalidade,
      images: files,
    );

    if (response.success && response.data == true) {
      // Atualiza os detalhes do produto após o upload
      await fetchProductComplete(productId);
      return true;
    } else {
      if (kDebugMode) {
        print('Falha ao enviar imagens do produto $productId: ${response.message}');
      }
      return false;
    }
  }
  */

  Future<bool> uploadProductImagesBase64(
      String productId, String finalidade, List<String> base64Images) async {
    
    if (base64Images.isEmpty) return false;
    
    // A lista de Base64 já pronta, passado diretamente
    final ApiResponse<bool> response = await productRepository.updateProductImagesBase64(
      productId: productId,
      finalidade: finalidade,
      base64Images: base64Images,
    );

    if (response.success && response.data == true) {
      // Atualiza os detalhes do produto após o upload
      await fetchProductComplete(productId);
      return true;

    } else {
      throw Exception('Falha ao enviar imagens do produto $productId: ${response.message}');
    }
  }

  /// Prepara a lista para que a UI seja atualizada instantaneamente.
  /*
  void addProductImageLocal(String finalidade, String base64Image) {
    if (_productComplete == null) return;

    // Cria o objeto ImageBase64 com os dados da nova imagem
    final newImage = ImageBase64(
      // gera um ID temporário
      imagePath: 'temp_path_${const Uuid().v4()}', 
      imagesBase64: base64Image,
      finalidade: finalidade,
    );
    
    // Inicializa a lista de imagens se ela for nula
    _productComplete!.images ??= []; 
    _productComplete!.images!.add(newImage);

    notifyListeners();
  }
  */
  /*
  Future<bool> deleteProductImage(
      String productId, String imagePath, String finalidade) async {

    if (_productComplete != null) {
      _productComplete!.images!.removeWhere((img) => img.imagePath == imagePath);
      _productComplete!.images!.asMap().forEach((index, img) => img.sequence = index + 1);
      notifyListeners();
    }
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
  */

  void clearResults() {
    _searchResults = [];
    notifyListeners();
  }

  void clearProductCompleteDetails() {
    _productComplete = null;
    notifyListeners();
  }

  /// Método para enviar a lista completa de tags para a API.
  Future<void> updateTags(List<ProductTagModel> tags) async {
    final ApiResponse<bool> response = await productRepository.updateTags(tags);

    if (response.success) {
      // Se a API atualizou com sucesso, recarrega os dados completos do produto
      // para garantir que a UI reflita o estado atual do banco de dados.
      final productId = tags.isNotEmpty ? tags.first.productId : '';
      await fetchProductComplete(productId);
    } else {
      throw Exception('Erro ao atualizar tags: ${response.message}');
    }
  }

}