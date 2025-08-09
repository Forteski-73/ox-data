// -----------------------------------------------------------
// app/core/services/product_service.dart (Serviço de Produtos)
// -----------------------------------------------------------
import 'package:flutter/foundation.dart';
import 'package:oxdata/app/core/models/product_model.dart';
import 'package:oxdata/app/core/models/product_complete.dart';
import 'package:oxdata/app/core/repositories/product_repository.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';

/// Ele usa ChangeNotifier para notificar a UI sobre as mudanças.
class ProductService with ChangeNotifier {
  final ProductRepository productRepository; // Adiciona a dependência do repositório

  // Construtor que recebe o repositório
  ProductService({required this.productRepository});

  // Lista para armazenar os resultados da pesquisa da API
  List<ProductModel> _searchResults = [];

  // Variável para armazenar os detalhes completos de um único produto
  ProductComplete? _productComplete;

  // Getter para acessar a lista de resultados de forma segura e pública
  List<ProductModel> get searchResults => _searchResults;

  // Getter para acessar os detalhes completos do produto de forma segura e pública
  ProductComplete? get productComplete => _productComplete;

  // A função de busca agora usa o repositório
  // Ajuste a assinatura para Map<String, dynamic>
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
      // Em um app real, você pode mostrar um SnackBar ou outro feedback ao usuário
    }
    // Notifica todos os widgets que estão "escutando" as mudanças
    notifyListeners();
  }

  /// Busca os detalhes completos de um produto específico e os armazena no serviço.
  /// Notifica os listeners após a conclusão.
  Future<void> fetchProductComplete(String productId) async {
    // Chama o método getAppProduct no repositório
    final ApiResponse<List<ProductComplete>> response =
        await productRepository.getAppProduct(productId); 

    if (response.success && response.data != null && response.data!.isNotEmpty) {
      _productComplete = response.data!.first; // Armazena o produto completo
    } else {
      _productComplete = null; // Limpa se não encontrado ou houver erro
      if (kDebugMode) {
        print('Erro ao buscar detalhes completos do produto $productId: ${response.message}');
      }
    }
    // Notifica todos os widgets que estão "escutando" as mudanças
    notifyListeners();
  }

  // Método para limpar os resultados
  void clearResults() {
    _searchResults = [];
    notifyListeners();
  }

  /// Método para limpar os detalhes do produto completo
  void clearProductCompleteDetails() {
    _productComplete = null;
    notifyListeners();
  }
}