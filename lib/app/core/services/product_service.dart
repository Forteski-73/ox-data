// -----------------------------------------------------------
// app/core/services/product_service.dart (Serviço de Produtos)
// -----------------------------------------------------------
import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/models/product_model.dart';
import 'package:oxdata/app/core/models/product_complete.dart';
import 'package:oxdata/app/core/repositories/product_repository.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:oxdata/app/core/utils/logger.dart';

class ProductService with ChangeNotifier {
  final ProductRepository productRepository;

  ProductService({required this.productRepository});

  List<ProductModel> _searchResults = [];
  ProductComplete? _productComplete;

  List<ProductModel> get searchResults => _searchResults;
  ProductComplete? get productComplete => _productComplete;

  Future<void> performSearch(Map<String, dynamic> activeFilters) async {
    final ApiResponse<List<ProductModel>> response =
        await productRepository.searchProducts(activeFilters);

    if (response.success && response.data != null) {
      _searchResults = response.data!;
    } else {
      _searchResults = [];
      if (kDebugMode) {
        print('Erro no ProductService: ${response.message}');
      }
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
      if (kDebugMode) {
        print('Erro ao buscar detalhes completos do produto $productId: ${response.message}');
      }
    }
    notifyListeners();
  }


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

  Future<bool> uploadProductImagesBase64(
      String productId, String finalidade, List<String> base64Images) async {
    
    if (base64Images.isEmpty) return false;

    try {
      // A lista de Base64 já está pronta, então podemos passá-la diretamente
      final ApiResponse<bool> response = await productRepository.updateProductImagesBase64(
        productId: productId,
        finalidade: finalidade,
        base64Images: base64Images,
      );

      // Trata a resposta da API
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
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao processar e enviar imagens: $e');
      }
      return false;
    }
  }

  /// Isso prepara a lista para que a UI seja atualizada instantaneamente.
  void addProductImageLocal(String finalidade, String base64Image) {
    if (_productComplete == null) return;

    // Cria o objeto ImageBase64 com os dados da nova imagem
    final newImage = ImageBase64(
      // Você pode gerar um ID temporário ou usar a lógica que preferir
      imagePath: 'temp_path_${const Uuid().v4()}', 
      imagesBase64: base64Image,
      finalidade: finalidade,
    );
    
    // Inicializa a lista de imagens se ela for nula
    _productComplete!.images ??= []; 
    _productComplete!.images!.add(newImage);

    // Notifica os listeners para que a UI seja reconstruída
    notifyListeners();
  }

  Future<bool> deleteProductImage(
      String productId, String imagePath, String finalidade) async {
    // TODO: Chamar o repositório para excluir a imagem na API
    // Exemplo:
    // final response = await productRepository.deleteImage(productId, imagePath, finalidade);
    // if (response.success) {
    //   await fetchProductComplete(productId);
    //   return true;
    // }
    // return false;

    // Lógica simulada:
    if (_productComplete != null) {
      _productComplete!.images!.removeWhere((img) => img.imagePath == imagePath);
      _productComplete!.images!.asMap().forEach((index, img) => img.sequence = index + 1);
      notifyListeners();
    }
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  void clearResults() {
    _searchResults = [];
    notifyListeners();
  }

  void clearProductCompleteDetails() {
    _productComplete = null;
    notifyListeners();
  }

  Future<void> addTag(String productId, String valueTag) async {
    await fetchProductComplete(productId);
  }

  Future<void> deleteTag(String productId, int tagId) async {
    await fetchProductComplete(productId);
  }
}

extension on List<int> {
  int? get lastOption => isNotEmpty ? last : null;
}