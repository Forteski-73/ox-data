// -----------------------------------------------------------
// app/views/products/search_products_page.dart (Página de Pesquisa de Produtos)
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/product_service.dart';
import 'package:oxdata/app/core/models/product_model.dart';
import 'package:oxdata/app/views/pages/filter_options_page.dart';
import 'package:flutter/services.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/utils/call_action.dart';

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
    'productId'   : 'CÓDIGO',
    'name'        : 'DESCRIÇÃO',
    'brandId'     : 'MARCA',
    'lineId'      : 'LINHA',
    'familyId'    : 'FAMÍLIA',
    'decorationId': 'DECORAÇÃO',
    'tag'         : 'TAGS',
    'noImage'     : 'SEM IMAGEM',
  };

  void _addFilter() {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        final inputValue = _searchController.text;

        if (_currentFilterType == 'name') {
          // Se o filtro for 'name', atribui a string diretamente.
          _activeFilters[_currentFilterType] = inputValue;
        } else if (_currentFilterType == 'tag') {
          // Se o filtro for 'tag', adicione à lista existente.
          if (_activeFilters.containsKey('tag')) {
            _activeFilters['tag'].add(inputValue);
          } else {
            _activeFilters['tag'] = [inputValue];
          }
        } else {
          // Para os outros filtros de lista
          _activeFilters[_currentFilterType] = [inputValue];
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
  }

  void _navigateToFilterOptionsPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return FilterOptionsPage(
            filterDisplayNames: _filterDisplayNames, // mapa de nomes
            currentFilterType: _currentFilterType, // filtro atual
            onFilterSelected: (selectedFilter) {
              if(selectedFilter == "noImage") // tratamento para o filtro de produtos sem imagem
              {
                setState(() {
                  _activeFilters[selectedFilter] = "SIM";
                });
              }
              else
              {
                setState(() {
                  _currentFilterType = selectedFilter;
                });
              }
            },
          );
        },
      ),
    );
  }

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
  Future<List<String>?> _decodeAndExtractImage(String? imageZipBase64) async {
    // Verifica se a string Base64 é nula ou vazia
    if (imageZipBase64 == null || imageZipBase64.isEmpty) {
      return null;
    }

    try {
      // Decodifica a string Base64 para bytes brutos do ZIP
      final Uint8List zipBytes = base64Decode(imageZipBase64);

      // Decodifica os bytes do ZIP
      final Archive archive = ZipDecoder().decodeBytes(zipBytes);
      final List<String> imagesDataUris = [];

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
      MessageService.showError('Erro ao carregar imagens: $e');
      return null;
    } on Exception catch (e) {
      MessageService.showError('Erro ao carregar imagens: $e');
      return null;
    }
  }

  // Método para chamar o scanner e processar o resultado
  Future<void> _scanBarcode() async {
    var status = await Permission.camera.request();
    
    if (status.isDenied) {
      MessageService.showWarning('Permissão da câmera negada.');
      return;
    }

    // Navega para a tela do scanner
    final barcodeResult = await Navigator.of(context).push<Barcode?>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
    );

    // Se o resultado não for nulo e o valor do código de barras existir
    if (barcodeResult != null && barcodeResult.rawValue != null) {
      String barcodeScanRes = barcodeResult.rawValue!;
      _searchController.text = barcodeScanRes;
      _currentFilterType = 'barcode'; // Define o tipo de filtro como 'barcode'
    } else {
        MessageService.showInfo('Nenhum código de barras lido.');
    }
  }

  // Limpa todos os filtros e os resultados da pesquisa
  void _clearFilters() {
    setState(() {
      _activeFilters = {};
      _searchController.clear();
      _currentFilterType = 'productId';
    });
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
          Padding(
            padding: const EdgeInsets.only(top: 136.0, left: 10.0, right: 10.0), // Para não ficar atrás da barra de pesquisa
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
                          margin: const EdgeInsets.only(bottom: 2.0, top: 3.0),
                          child: InkWell(
                            onTap: () async {
                              await CallAction.run(
                                action: () async {
                                  loadingService.show();

                                  await productService.fetchProductComplete(productData.productId);

                                  Navigator.of(context).pushNamed(
                                    RouteGenerator.productPage,
                                    arguments: productData.productId,
                                  );
                                },
                                onFinally: () {
                                  loadingService.hide();
                                },
                              );
                            },
                            splashColor: const Color.fromARGB(255, 65, 65, 65).withAlpha((255 * 0.2).round()),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
          // Barra de pesquisa e filtros, fixada no topo
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
                          await CallAction.run(
                            action: () async {
                              loadingService.show();
                              FocusScope.of(context).unfocus();

                              await productService.performSearch(_activeFilters);
                            },
                            onFinally: () {
                              loadingService.hide();
                            },
                          );
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
                          labelStyle: const TextStyle(fontSize: 15),
                        ),
                        onFieldSubmitted: (_) async {
                          await CallAction.run(
                            action: () async {
                              _addFilter();
                              loadingService.show();

                              await productService.performSearch(_activeFilters);
                            },
                            onFinally: () {
                              loadingService.hide();
                            },
                          );
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