import 'package:flutter/material.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/pallet_service.dart';
import 'package:oxdata/app/core/services/image_cache_service.dart';
import 'package:oxdata/app/core/models/pallet_model.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:provider/provider.dart';
import 'pallet_builder_page.dart';
import 'pallet_items_tab.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/core/widgets/pulse_icon.dart';

class SearchPalletPage extends StatefulWidget {
  const SearchPalletPage({super.key});

  @override
  State<SearchPalletPage> createState() => _SearchPalletPageState();
}

class _SearchPalletPageState extends State<SearchPalletPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFilter;
  String _searchQuery = '';
  late PalletService _palletService; 

  @override
  void initState() {
    _palletService = context.read<PalletService>();
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _tabController.addListener(() {

      // Só executa quando a aba realmente mudou
      if (!_tabController.indexIsChanging) {
        // Limpa a pesquisa ao trocar de aba
        _searchController.clear();
        _searchQuery = '';

        //setState(() {});

        //if (_tabController.index == 0) {
          //_loadPallets();
         _palletService.clearPallets();
        //}
        
      }
    });

    _searchController.addListener(() {
      // Filtra a lista sempre que o texto muda
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPallets(); 
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPallets() async {
    final loadingService = context.read<LoadingService>();

    final imageCacheService = context.read<ImageCacheService>(); 

    imageCacheService.clearAllImages();

    // Marca o início
    final start = DateTime.now();
    const minDuration = Duration(seconds: 1); // 1 SEGUNDO PARA EVITAR QUE A TELA FIQUE PISCANDO

    await CallAction.run(
      action: () async {
        loadingService.show();
        await _handleFilterTap("INICIADO");
        await _palletService.filtersPallets("INICIADO", "");
      },
      onFinally: () async {
        final elapsed = DateTime.now().difference(start);

        if (elapsed < minDuration) {
          final remaining = minDuration - elapsed;
          await Future.delayed(remaining);
        }

        loadingService.hide();
      },
    );
  }

  // Função para mapear o status de código para o texto completo e definir a cor.
  String _mapStatus(String status) {
    switch (status) {
      case 'I':
        return 'Iniciado';
      case 'M':
        return 'Montado';
      case 'R':
        return 'Recebido';
      default:
        return status;
    }
  }

  List<PalletModel> _getFilteredPallets(List<PalletModel> allPallets) {
    if (_searchQuery.isEmpty) {
      return allPallets;
    }

    final query = _searchQuery.trim();
    return allPallets.where((pallet) {
      final matchesId = pallet.palletId.toString().toLowerCase().contains(query);
      final matchesLocation = pallet.location.toLowerCase().contains(query);
      final matchesStatus = pallet.status.toLowerCase().contains(query) || _mapStatus(pallet.status).toLowerCase().contains(query);

      return matchesId || matchesLocation || matchesStatus;
    }).toList();
  }

  // Função de ajuda com cores
  Color getStatusColor(String status) {
    switch (status) {
      case 'INICIADO':
        return Colors.blue[100]!; // Fundo azul claro e suave
      case 'MONTADO':
        return Colors.amber[100]!; // Fundo amarelo claro e suave
      case 'RECEBIDO':
        return Colors.green[100]!; // Fundo verde claro e suave
      default:
        return Colors.grey[200]!;
    }
  }

  // Função para a cor do texto
  Color getTextColor(String status) {
    switch (status) {
      case 'INICIADO':
        return Colors.blue[800]!;
      case 'MONTADO':
        return Colors.amber[800]!;
      case 'RECEBIDO':
        return Colors.green[800]!;
      default:
        return Colors.grey[700]!;
    }
  }

  // --- WIDGET PARA A BARRA DE PESQUISA  ---
  _handleFilterTap(String filter) async {
      setState(() {
        _selectedFilter = (_selectedFilter == filter) ? null : filter;
      });

      _palletService.clearPallets();
      
      //await _palletService.filtersPallets(_selectedFilter, "");
  }

  Widget _buildSearchBar() {
    final loadingService = context.read<LoadingService>();
    final String hintText = 'Pesquisar...';
    
    const List<String> filters = ['INICIADO', 'MONTADO', 'RECEBIDO'];

    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 6, right: 6, bottom: 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch, // Garante que ocupem a largura máxima
        children: <Widget>[
          
          // --- 1. Botões de Filtro Rápido (INICIADO, MONTADO, RECEBIDO) ---
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: filters.map((filter) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: ElevatedButton(
                      onPressed: () => _handleFilterTap(filter),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedFilter == filter ? Colors.indigo : Colors.grey[300],
                        foregroundColor: _selectedFilter == filter ? Colors.white : Colors.black87,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // --- 2. Campo de Pesquisa (TextField) ---
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: hintText,
              
              // Ícone de prefixo (não definido no seu código, mantive comentado)
              // prefixIcon: const Icon(Icons.search, color: Colors.black54),
              
              // SuffixIcon com Ícone de Limpar, QR Code e Pesquisa (agora com PulseIconButton)
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Botão de Limpar (Mantido como IconButton)
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.black54),
                      onPressed: () {
                        _searchController.clear();
                        // Chame setState()
                      },
                    ),
                  
                  // Botão do QR Code Scanner (AGORA COMO PulseIconButton)
                  PulseIconButton(
                    icon: Icons.qr_code_scanner_outlined,
                    color: Colors.indigo,
                    // size: 34, // Removido, o PulseIconButton pode ter seu próprio tamanho padrão
                    onPressed: () async {
                      await CallAction.run(
                        action: () async {
                          // CHAMADA DA FUNÇÃO DE SCANNER INTEGRADA AQUI
                          String scanned = await _scanBarcode();
                          if (scanned.isNotEmpty) {
                            _searchController.text = scanned;
                          }
                        },
                        // onFinally opcional aqui, a menos que você precise de lógica após o scan
                      );
                    },
                  ),
                  
                  // Botão Pesquisar (AGORA COMO PulseIconButton)
                  PulseIconButton(
                    icon: Icons.search, // Ícone de pesquisa
                    color: Colors.indigo,
                    // size: 34, // Removido, o PulseIconButton pode ter seu próprio tamanho padrão
                    onPressed: () async {
                      await CallAction.run(
                        action: () async {
                          // Lógica de pesquisa: mostrar loading, tirar o foco e buscar
                          loadingService.show();
                          FocusScope.of(context).unfocus();
                          
                          if (_tabController.index == 0) {
                            await _palletService.filtersPallets(_selectedFilter, _searchController.text);
                            await _palletService.filterPalletItems(_selectedFilter, "");
                          }
                          else {
                            //await _palletService.filtersPallets(_selectedFilter, "");
                            await _palletService.filterPalletItems(_selectedFilter, _searchController.text);
                          }
                          // Você precisa passar os filtros ativos (incluindo o texto do campo)
                          //await productService.performSearch(_activeFilters); 
                          // Note: Assumindo que performSearch usa _searchController.text e _activeFilters
                        },
                        onFinally: () {
                          loadingService.hide();
                        },
                      );
                    },
                  ),
                ],
              ),
              
              // Estilo do campo de texto
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _scanBarcode() async {
    var status = await Permission.camera.request();

    if (status.isDenied) {
      return "";
    }

    final barcodeRead = await Navigator.of(context).push<Barcode?>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
    );

    if (barcodeRead == null) {
      return "";
    }

    return barcodeRead.rawValue ?? "";
  }

  Widget _buildPalletTabContent(List<PalletModel> pallets) {
    if (pallets.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty
              ? 'Nenhum palete corresponde à pesquisa.'
              : 'Nenhum palete encontrado.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(6, 5, 7, 5),
      itemCount: pallets.length + 1, // +1 para incluir o cabeçalho
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.grey),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            color: Colors.blueGrey.shade600,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(flex: 4, child: Text('N° PALETE',  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                Expanded(flex: 3, child: Text('LOCAL',      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                Expanded(flex: 3, child: Text('SITUAÇÃO',     style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              ],
            ),
          );
        }

        final palletData = pallets[index - 1]; // -1 por causa do cabeçalho
        final mappedStatus = _mapStatus(palletData.status);

        return StatefulBuilder(
          builder: (context, setInnerState) {
            bool isHighlighted = false;

            return Material(
              color: isHighlighted ? Colors.indigo : Colors.white,
              borderRadius: BorderRadius.circular(4),
              child: InkWell(
                borderRadius: BorderRadius.circular(1),
                highlightColor: Colors.grey,
                splashColor: Colors.grey.shade300,
                onHighlightChanged: (value) {
                  setInnerState(() => isHighlighted = value);
                },
                onTap: () async {
                  await Future.delayed(const Duration(milliseconds: 200));
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PalletBuilderPage(pallet: palletData),
                    ),
                  ).then((_) => _loadPallets());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          '${palletData.palletId}',
                          style: TextStyle(color: isHighlighted ? Colors.white : Colors.black),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          palletData.location,
                          style: TextStyle(color: isHighlighted ? Colors.white : Colors.black),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            // Define uma largura MÍNIMA e MÁXIMA fixa (e igual) para uniformizar o chip.
                            constraints: const BoxConstraints(
                              minWidth: 90,
                              maxWidth: 90, 
                              minHeight: 0, 
                              maxHeight: 25,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                            decoration: BoxDecoration(
                              color: getStatusColor(mappedStatus.toUpperCase()),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: getTextColor(mappedStatus.toUpperCase()).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Center( 
                              child: Text(
                                mappedStatus,
                                style: TextStyle(
                                  color: getTextColor(mappedStatus.toUpperCase()),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  height: 1, 
                                ),
                              ),
                            ),
                          ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        title: _tabController.index == 0 ? 'PALETES' : 'PEÇAS',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'PALETES', icon: Icon(Icons.pallet)),
              Tab(text: 'PEÇAS', icon: Icon(Icons.local_cafe)),
            ],
          ),
        ),
      ),
      floatingActionButton: _tabController.index == 0
        ? FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PalletBuilderPage(pallet: null),
                ),
              );

              if (result == true) {
                setState(() {
                  _loadPallets();
                });
              }
            },
            label: const Text('NOVO'),
            icon: const Icon(Icons.add_outlined),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          )
        : null,
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Consumer<PalletService>(
                  builder: (context, palletService, child) {
                    final filteredPallets = _getFilteredPallets(palletService.pallets);
                    return _buildPalletTabContent(filteredPallets);
                  },
                ),
                PalletItemsTab(searchQuery: _searchQuery, selectedFilter: _selectedFilter ?? ""),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
