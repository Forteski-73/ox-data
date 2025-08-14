// -----------------------------------------------------------
// app/views/products/search_products_page.dart (Página de Pesquisa de Produtos)
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/product_service.dart';
import 'package:oxdata/app/core/models/product_model.dart';
import 'package:oxdata/app/views/pages/filter_options_page.dart';
import 'package:flutter/services.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';

class SearchProductsPage extends StatefulWidget {
  const SearchProductsPage({super.key});

  @override
  State<SearchProductsPage> createState() => _SearchProductsPageState();
}

class _SearchProductsPageState extends State<SearchProductsPage> {
  // Controlador para o campo de texto de pesquisa
  final TextEditingController _searchController = TextEditingController();

  // Mapa para armazenar os filtros ativos e seus valores (chave: tipo do filtro, valor: lista de IDs)
  Map<String, dynamic> _activeFilters = {};

  // O filtro que está sendo editado no momento (ex: 'productId', 'brandId')
  String _currentFilterType = 'productId';

  // Mapeia chaves de filtro para nomes de exibição
  final Map<String, String> _filterDisplayNames = {
    'productId': 'CÓDIGO',
    'name': 'DESCRIÇÃO',
    'brandId': 'MARCA',
    'lineId': 'LINHA',
    'familyId': 'FAMÍLIA',
    'decorationId': 'DECORAÇÃO',
    'tag': 'TAGS',
  };

  // Função para adicionar um filtro
  void _addFilter() {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        if (_currentFilterType == 'name') {
          // Se o filtro atual for 'name', atribua a string diretamente
          _activeFilters[_currentFilterType] = _searchController.text;
        } else {
          // Para os outros filtros, continue atribuindo como uma lista
          _activeFilters[_currentFilterType] = [_searchController.text];
        }
        _searchController.clear();
      });
    }
  }

  // Função para remover um filtro específico
  void _removeFilter(String filterType) {
    setState(() {
      _activeFilters.remove(filterType);
    });
    // Limpa os resultados no ProductService se não houver mais filtros
    /*if (_activeFilters.isEmpty) {
      context.read<ProductService>().clearResults();
    }*/
  }

  // Adicione esta função para navegar para a nova página
  void _navigateToFilterOptionsPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return FilterOptionsPage(
            filterDisplayNames: _filterDisplayNames, // Passe seu mapa de nomes
            currentFilterType: _currentFilterType, // Passe o filtro atual
            onFilterSelected: (selectedFilter) {
              // Este é o callback que a nova página irá chamar
              setState(() {
                _currentFilterType = selectedFilter;
              });
            },
          );
        },
      ),
    );
  }

  /*
  // Diálogo para seleção do filtro
  void _showFilterOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('FILTRAR POR:'),
          children: _filterDisplayNames.keys.map((key) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _currentFilterType = key;
                  });
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.filter_alt),
                label: Text(
                  _filterDisplayNames[key] ?? key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
  */

  /// Retorna o tipo de conteúdo (MIME type) com base na extensão do arquivo.
  String _getContentType(String fileName) {
    if (fileName.endsWith('.png')) {
      return 'image/png';
    } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      return 'image/jpeg';
    } else if (fileName.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'application/octet-stream'; // Tipo padrão para arquivos desconhecidos
  }

  /// Função para buscar a imagem do produto, decodificar o ZIP e extrair as imagens como Data URIs.
  /// Agora recebe o productId e chama o ProductRepository.
  Future<List<String>?> _decodeAndExtractImage(String? imageZipBase64) async {
    // Verifica se a string Base64 é nula ou vazia
    if (imageZipBase64 == null || imageZipBase64.isEmpty) {
      debugPrint('imageZipBase64 é nulo ou vazio, não há imagem para decodificar.');
      return null;
    }

    try {
      // Decodifica a string Base64 para bytes brutos do ZIP
      final Uint8List zipBytes = base64Decode(imageZipBase64);

      // Decodifica os bytes do ZIP
      final Archive archive = ZipDecoder().decodeBytes(zipBytes);
      final List<String> imagesDataUris = [];

      // Itera sobre os arquivos no ZIP
      for (final file in archive) {
        // Verifica se é um arquivo e se é uma imagem suportada
        if (file.isFile && (file.name.endsWith('.png') || file.name.endsWith('.jpg') || file.name.endsWith('.jpeg'))) {
          final Uint8List imageBytes = Uint8List.fromList(file.content as List<int>);
          final String base64Image = base64Encode(imageBytes); // Converte bytes da imagem para Base64
          final String contentType = _getContentType(file.name); // Função auxiliar para determinar o tipo de conteúdo
          final String dataUri = 'data:$contentType;base64,$base64Image'; // Cria a Data URI
          imagesDataUris.add(dataUri);
        }
      }
      // Retorna a lista de Data URIs ou null se nenhuma imagem foi encontrada
      return imagesDataUris.isNotEmpty ? imagesDataUris : null;
    } on FormatException catch (e) {
      debugPrint('Erro de formato ao decodificar Base64 ou ZIP: $e');
      return null;
    } on Exception catch (e) {
      debugPrint('Erro inesperado ao decodificar ou extrair imagem do ZIP: $e');
      return null;
    }
  }

  // Método para chamar o scanner e processar o resultado
  Future<void> _scanBarcode() async {
    var status = await Permission.camera.request();
    
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão da câmera negada.')),
      );
      return;
    }

    // Navega para a tela do scanner, esperando que ela retorne um objeto Barcode
    final barcodeResult = await Navigator.of(context).push<Barcode?>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
    );

    // Se o resultado não for nulo e o valor do código de barras existir
    if (barcodeResult != null && barcodeResult.rawValue != null) {
      String barcodeScanRes = barcodeResult.rawValue!;
      // 1. Atribui o valor do código de barras ao controlador
      _searchController.text = barcodeScanRes;
      // 2. Define o tipo de filtro como 'barcode'
      _currentFilterType = 'barcode';

    } else {
      // Caso nenhum código de barras seja lido (usuário voltou ou erro)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum código de barras lido.')),
      );
    }
  }

  // Função para limpar todos os filtros e os resultados da pesquisa
  void _clearFilters() {
    setState(() {
      _activeFilters = {};
      _searchController.clear();
      _currentFilterType = 'productId';
    });
    // Limpa os resultados da pesquisa no ProductService
    context.read<ProductService>().clearResults();
  }
  
  @override
  Widget build(BuildContext context) {
    final loadingService = context.read<LoadingService>();
    final productService = context.read<ProductService>();
    
    return Scaffold(
      appBar: const AppBarCustom(title: 'Pesquisar Produtos'),
      body: Stack(
        children: [
          // 1. O conteúdo principal da página (lista de resultados)
          Padding(
            // Adiciona um padding no topo para o conteúdo não ficar atrás da barra de pesquisa
            padding: const EdgeInsets.only(top: 136.0, left: 10.0, right: 10.0),
            child: Consumer<ProductService>(
              builder: (context, productService, child) {
                final searchResults = productService.searchResults;
                return searchResults.isEmpty
                    ? Center(child: Text(_activeFilters.isEmpty ? 'Use a barra de pesquisa.' : 'Nenhum produto encontrado com os filtros ativos.'))
                    : ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final ProductModel productData = searchResults[index];
                          return Card(
                            color: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                            margin: const EdgeInsets.only(bottom: 2.0),
                            child: GestureDetector(
                              onTap: () async {
                                loadingService.show();
                                await productService.fetchProductComplete(productData.productId);
                                loadingService.hide();
                                Navigator.of(context).pushNamed(
                                  RouteGenerator.productPage,
                                  arguments: productData.productId,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(0),
                                child: Row(
                                  children: [
                                    FutureBuilder<List<String>?>(
                                      future: _decodeAndExtractImage(productData.imageZipBase64),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const SizedBox(
                                            width: 85,
                                            height: 85,
                                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                          );
                                        } else if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                                          final String dataUri = snapshot.data!.first;
                                          final String base64Image = dataUri.split(',').last;
                                          return Image.memory(
                                            base64Decode(base64Image),
                                            width: 85,
                                            height: 85,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 60),
                                          );
                                        } else {
                                          return const Icon(Icons.broken_image, size: 85);
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Text(
                                              productData.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              softWrap: false, // Impede a quebra de linha
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Cód. Barras: ${productData.barcode}'),
                                              const SizedBox(height: 4),
                                              Text('Código: ${productData.productId}'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
              },
            ),
          ),

          // 2. A barra de pesquisa e filtros, fixada no topo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: const Color.fromARGB(255, 255, 255, 255),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Column(
                children: [
                Row(
                  children: [
                    Expanded(
                      child: IconButton(
                        icon: const Icon(Icons.filter_alt_off_outlined, size: 28),
                        color: Colors.indigo,
                        onPressed: _clearFilters,
                      ),
                    ),
                    Expanded(
                      child: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, size: 28),
                        color: Colors.indigo,
                        onPressed: _scanBarcode,
                      ),
                    ),
                    Expanded(
                      child: IconButton(
                        icon: const Icon(Icons.filter_list, size: 28),
                        color: Colors.indigo,
                        onPressed: () => _navigateToFilterOptionsPage(context),
                      ),
                    ),
                    Expanded(
                      child: IconButton(
                        icon: const Icon(Icons.add, size: 28),
                        color: Colors.indigo,
                        onPressed: _addFilter,
                      ),
                    ),
                    Expanded(
                      child: IconButton(
                        icon: const Icon(Icons.search, size: 30),
                        color: Colors.indigo,
                        onPressed: () async {
                          loadingService.show();
                          await productService.performSearch(_activeFilters);
                          loadingService.hide();
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Pesquisar por ${_filterDisplayNames[_currentFilterType] ?? _currentFilterType}',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onFieldSubmitted: (_) async {
                          _addFilter();
                          loadingService.show();
                          await productService.performSearch(_activeFilters);
                          loadingService.hide();
                        },
                      ),
                    ),
                  ],
                ),
                if (_activeFilters.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 7, left: 2, bottom: 6),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: 8.0, // Espaço horizontal entre os chips
                        children: _activeFilters.entries.map((entry) {
                          final displayValue = entry.value is List<String>
                              ? (entry.value as List<String>).join(', ')
                              : entry.value.toString();
                              
                          final labelText = '${_filterDisplayNames[entry.key] ?? entry.key}: $displayValue';
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.yellowAccent.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            child: Row(
                              children: [
                                Text(
                                  labelText,
                                  style: const TextStyle(height: 0.8),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _removeFilter(entry.key),
                                  child: const Icon(
                                    Icons.close,
                                    size: 15,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 7, left: 2, bottom: 6),
                    child: Text(
                      'Nenhum filtro aplicado..',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}