
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/load_service.dart';
// Certifique-se de que os imports abaixo estão corretos e contêm os modelos!
import 'package:oxdata/app/core/models/pallet_load_item_model.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart'; // Assumindo este import
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Assumindo este import
import 'package:oxdata/app/core/widgets/pulse_icon.dart'; // Assumindo este import

class LoadReceivePage extends StatefulWidget {
  const LoadReceivePage({super.key});

  @override
  State<LoadReceivePage> createState() => _LoadReceivePageState();
}

class _LoadReceivePageState extends State<LoadReceivePage> {
  final TextEditingController _loadSearchController = TextEditingController();
  final TextEditingController _palletSearchController = TextEditingController();
  
  // ESTADOS LOCAIS REDUZIDOS: A lista de itens agora está no Provider.
  int? _selectedLoadId;
  String? _selectedPalletId;
  
  bool _isLoading = false; 
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _loadSearchController.addListener(_onLoadSearchChanged);
      _palletSearchController.addListener(_onPalletSearchChanged);

      final loadService = context.read<LoadService>();
      final preSelectedLoad = loadService.selectedLoadForEdit;

      if (preSelectedLoad != null) {
        final loadIdStr = preSelectedLoad.loadId.toString();
        
        // 1. Define o ID no controlador (para que apareça na caixa de texto caso o campo se torne visível por algum erro)
        _loadSearchController.text = loadIdStr; 
        
        // 2. Chama a função de busca para carregar o ID localmente e no Service.
        // O `_fetchLoad` atualiza _selectedLoadId e exibe a mensagem de sucesso.
        _fetchLoad(loadIdStr);
      }
    });
  }

  @override
  void dispose() {
    _loadSearchController.removeListener(_onLoadSearchChanged);
    _loadSearchController.dispose();
    _palletSearchController.dispose();
    super.dispose();
  }

  // 🎯 NOVO: Método auxiliar para limpar o estado da Carga e do Pallet
  void _clearLoadState() {
      // Usa os métodos existentes no seu LoadService
      context.read<LoadService>().setSelectedLoadForEdit(null);
      context.read<LoadService>().clearPalletItemsState();
  }

  void _onLoadSearchChanged() {
    // Limpa o estado completo da carga e palete no Service
    _clearLoadState(); 
    
    setState(() {
      _selectedPalletId = null;
      if (_loadSearchController.text.isEmpty) {
        _selectedLoadId = null;
      }
    });
  }
  
  void _onPalletSearchChanged() {
      // Limpa o estado de itens do pallet no Service (Provider)
      context.read<LoadService>().clearPalletItemsState();

      setState(() {
        _selectedPalletId = null;
      });
  }

  // 1. Lógica de Busca de Carga (Omitida para brevidade)
  Future<void> _fetchLoad(String loadIdStr) async {
    final loadService = context.read<LoadService>();
    final loadingService = context.read<LoadingService>();
    final loadId = int.tryParse(loadIdStr);

    if (loadId == null) {
      MessageService.showWarning('ID da Carga inválido.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedPalletId = null;
      _palletSearchController.clear();
      _selectedLoadId = null;
    });

    try {
      loadingService.show();
      
      final load = await loadService.fetchLoadById(loadId);
      
      if (load != null) { 
        setState(() {
          _selectedLoadId = load.loadId; 
        });
        MessageService.showSuccess('Carga ${load.loadId} selecionada. Escaneie o palete.');
      } else {
        throw Exception('Carga $loadId não encontrada.');
      }

    } catch (e) {
      _clearLoadState(); 
      setState(() {
        _selectedLoadId = null;
        _errorMessage = 'Erro ao carregar carga $loadId: $e';
      });
      MessageService.showError('Erro ao carregar carga.');
    } finally {
      loadingService.hide();
      setState(() => _isLoading = false);
    }
  }

  // Lógica para salvar os dados do palete no recebimento
  Future<void> _savePalletReception(List<PalletItemModel> items) async {
    if (_selectedLoadId == null || _selectedPalletId == null) {
      MessageService.showError('Erro: Carga ou Palete não selecionado.');
      return;
    }

    final loadService = context.read<LoadService>();
    final loadingService = context.read<LoadingService>();
    
    // 1. Validação básica
    final hasReceivedQuantity = items.any((item) => item.quantityReceived > 0);
    if (!hasReceivedQuantity) {
      MessageService.showWarning('Nenhum item com quantidade recebida preenchida.');
      return;
    }

    setState(() => _isLoading = true);
    loadingService.show();

    try {
      final success = await loadService.savePalletReception(
        loadId: _selectedLoadId!,
        palletId: int.parse(_selectedPalletId!), // Converte de volta para int
        receivedItems: items,
      );
      
      if (success) {
        MessageService.showSuccess('Recebimento do Palete $_selectedPalletId salvo com sucesso!');
        
        // Limpa os estados locais para forçar o escaneamento do próximo palete
        _palletSearchController.clear();
        setState(() {
          _selectedPalletId = null;
        });
        // O LoadService já limpou _currentPalletDetails e _currentPalletItems
      } else {
        // A lógica do Service já lança uma exceção em caso de falha de API
        // O bloco catch tratará isso
      }

    } catch (e) {
      MessageService.showError('Falha ao salvar recebimento: ${e.toString()}');
      setState(() {
        _errorMessage = 'Erro ao salvar: $e';
      });
    } finally {
      loadingService.hide();
      setState(() => _isLoading = false);
    }
  }

  // 2. Lógica de Carregamento dos Itens do Palete (USA O PROVIDER)
  Future<void> _loadPalletItemsFromService(String palletIdStr) async {
    if (_selectedLoadId == null) {
      MessageService.showWarning('Primeiro selecione uma Carga.');
      _palletSearchController.clear();
      return;
    }
    
    final palletId = int.tryParse(palletIdStr);

    if (palletId == null) {
      MessageService.showWarning('ID do Palete inválido.');
      return;
    }

    final loadService = context.read<LoadService>();
    final loadingService = context.read<LoadingService>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedPalletId = null;
    });
    
    try {
      loadingService.show();
      
      final items = await loadService.fetchPalletItems(
          loadId: _selectedLoadId!, 
          palletId: palletId
      );
      
      if (items.isNotEmpty) {
        setState(() {
          _selectedPalletId = palletIdStr; 
        });
        MessageService.showSuccess('Itens do Palete $palletIdStr carregados.');
      } else {
        setState(() {
            _selectedPalletId = null;
        });
        throw Exception('Palete $palletIdStr não encontrado ou sem itens na carga ${_selectedLoadId}.');
      }

    } catch (e) {
      setState(() {
        _selectedPalletId = null;
        _errorMessage = 'Erro ao carregar itens do palete $palletIdStr: $e';
      });
      MessageService.showError('Erro ao carregar palete.');
    } finally {
      loadingService.hide();
      setState(() => _isLoading = false);
    }
  }

  // --- Lógica de Scanner (Omitida para brevidade) ---
  Future<void> _scanBarcode(bool isLoadScan) async {
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      MessageService.showError('Permissão de câmera negada.');
      return;
    }

    final barcodeRead = await Navigator.of(context).push<Barcode?>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (barcodeRead == null) return;

    final scannedRaw = barcodeRead.rawValue ?? "0";
    final scanned = int.tryParse(scannedRaw)?.toString() ?? '';
    
    if (scanned.isEmpty) {
      MessageService.showWarning('Código de barras inválido.');
      return;
    }
    
    if (isLoadScan) {
      _loadSearchController.text = scanned;
      await _fetchLoad(scanned);
    } else if (_selectedLoadId != null) {
      _palletSearchController.text = scanned;
      await _loadPalletItemsFromService(scanned); 
    } else {
      MessageService.showWarning('Primeiro escaneie ou digite o código da Carga.');
    }
  }

  // 1. UI de Resumo da Carga
  Widget _buildLoadSummary() {
    return Consumer<LoadService>(
      builder: (context, loadService, child) {
        final details = loadService.selectedLoadForEdit; 
        
        if (details == null) { 
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8), 
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.blue.shade200),
          ),
          
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 0, 0), 
                child: Row( 
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'CARGA: ${details.loadId} - ${details.name}', 
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18, 
                          color: Colors.blueGrey,
                          height: 1.0, 
                        )
                      ),
                    ),
                    
                    PulseIconButton(
                      icon: Icons.close_fullscreen, 
                      color: Colors.red,
                      size: 32,
                      onPressed: () {
                        _clearLoadState(); 
                        _loadSearchController.clear();
                        _palletSearchController.clear();
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 5),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status: ${details.status}', style: const TextStyle(color: Colors.black87)),
                    Text('Data: ${details.date.day.toString().padLeft(2, '0')}/${details.date.month.toString().padLeft(2, '0')}', 
                        style: const TextStyle(color: Colors.black87)
                    ),
                    Text('Hora: ${details.time}', style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
              
              if (details.createdUser != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0),
                  child: Text('Criado por: ${details.createdUser}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ),
                
            ],
          ),
        );
      },
    );
  }

  // 2. UI de Resumo do Palete (AJUSTADO COM BOTÃO DE FECHAR)
  Widget _buildLoadPalletSummary() {
    return Consumer<LoadService>(
      builder: (context, loadService, child) {
        final details = loadService.currentPalletDetails;
        
        if (details == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8), 
          margin: const EdgeInsets.only(bottom: 8), 
          decoration: BoxDecoration(
            color: Colors.teal.shade50, 
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.teal.shade200),
          ),
          
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 1. Linha Principal (Palete ID e Botão de Limpar Palete)
              Padding(
                // Padding horizontal de 8, superior de 4 para respiro (4/0/8/0 no LoadSummary)
                padding: const EdgeInsets.fromLTRB(8, 4, 0, 0), 
                child: Row( 
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Palete ID (Maior e mais ousado)
                    Expanded( // Usamos Expanded para empurrar o botão para a direita
                      child: Text(
                        'PALETE: ${details.palletId}', 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18, 
                          color: Colors.teal.shade700,
                          height: 1.0, 
                        )
                      ),
                    ),
                    
                    // Botão de Fechar/Limpar APENAS o Palete atual
                    PulseIconButton(
                      icon: Icons.close_fullscreen, // Ícone que sugere fechar a seção
                      color: Colors.red,
                      size: 32,
                      onPressed: () {
                        // Limpa apenas o estado do Palete no Service e o campo de busca
                        context.read<LoadService>().clearPalletItemsState(); 
                        _palletSearchController.clear();
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 5),
              
              // 2. Linha de Detalhes (Local, Status e Total)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Local
                    Text('Local: ${details.location}', style: const TextStyle(color: Colors.black87)),
                    
                    // Status
                    Text('Status: ${details.status}', style: const TextStyle(color: Colors.black87)),
                    
                    // Total
                    Text('Total: ${details.totalQuantity}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              
            ],
          ),
        );
      },
    );
  }

  // --- UI de Detalhes dos Itens (USA O MODELO DO PROVIDER) ---
  Widget _buildPalletItemDetails(List<PalletItemModel> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Nenhum item encontrado no palete.', style: TextStyle(color: Colors.black54)));
    }
    
    return Column(
      children: [
        
        // ⭐️ CHAMADA AO NOVO MÉTODO
        //_buildLoadPalletSummary(),
        // ⭐️ FIM DA CHAMADA
        
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          color: Colors.teal.shade600,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(flex: 7, child: Text('PEÇA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(flex: 3, child: Text('QTD. ENV.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(flex: 3, child: Text('QTD. REC.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: items.length, 
            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.grey),
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(flex: 7, child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productId.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(item.productDescription, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    )),
                    Expanded(
                      flex: 3,
                      child: Text(item.quantity.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22.0,), ),
                    ),
                    // Campo para input da quantidade recebida
                    /*Expanded(flex: 3, child: TextFormField(
                      initialValue: item.quantityReceived.toString(),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28.0,),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        item.quantityReceived = int.tryParse(value) ?? 0;
                      },
                    )),*/
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: item.quantityReceived.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28.0,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: const OutlineInputBorder(),
                          filled: true,
                          // Lógica Condicional para a cor de fundo
                          fillColor: (item.quantityReceived < item.quantity)
                              ? Colors.red.withOpacity(0.3)
                              : Colors.white,
                        ),
                        onChanged: (value) {
                          int received = int.tryParse(value) ?? 0;
                          
                          // ⚠️ Use setState() aqui para reconstruir o widget e atualizar a cor.
                          // setState(() {
                          //   item.quantityReceived = received;
                          // });
                          
                          item.quantityReceived = received;
                        },
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
        // Botão para salvar as quantidades (próximo passo)
        Padding(
          padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _savePalletReception(items),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.save, size: 24),
              label: const Text('SALVAR RECEBIMENTO'),
            ),
          ),
        ),

      ],
    );
  }

  // --- Widget de Campo de Pesquisa Reutilizável (Omitido para brevidade) ---
  Widget _buildSearchField({
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onScan,
    required Future<void> Function(String) onSubmit,
    bool isVisible = true, 
  }) {
    
    // 🎯 Nova Função de Limpeza Condicional
    void onClearField() {
      controller.clear();
      if (hintText.contains('Palete')) {
        _onPalletSearchChanged();
      } else {
        _onLoadSearchChanged(); 
      }
    }

    return Visibility(
      visible: isVisible, 
      replacement: const SizedBox.shrink(), 
      child: TextField(
        controller: controller,
        onChanged: (query) {
          if (hintText.contains('Palete')) {
            _onPalletSearchChanged();
          } else {
            _onLoadSearchChanged();
          }
        },
        onSubmitted: onSubmit,
        enabled: true, 
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade600),
          filled: true,
          fillColor: Colors.white, 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              // Ícone para LIMPAR o campo e o estado
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey, size: 28),
                onPressed: onClearField, // Chama a função de limpeza
              ),
              const SizedBox(width: 4),

              // Ícone do Scanner (existente)
              PulseIconButton(
                icon: Icons.qr_code_scanner_outlined,
                color: Colors.black,
                size: 44,
                onPressed: () async => onScan(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadService = context.watch<LoadService>();
    final currentPalletItems = loadService.currentPalletItems;

    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator(color: Colors.teal));
    } else if (_errorMessage != null) {
      content = Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)));
    } else if (_selectedPalletId != null) {
      // Se o PalletId foi escaneado, usa a lista do Provider
      content = _buildPalletItemDetails(currentPalletItems); 
    } else if (_selectedLoadId != null) {
      // Apenas deixa o Expanded vazio, pois o resumo da carga e o campo do palete estão logo acima
      content = const SizedBox.expand(); 
    } else {
      content = const Center(child: Text('Aguardando a leitura do código da Carga.', style: TextStyle(color: Colors.black54)));
    }
    return Scaffold(
      resizeToAvoidBottomInset: false, 
      backgroundColor: Colors.teal.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0), // Aumentei o padding lateral
          child: Column(
            children: [
              // Título
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory,
                      size: 34,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Recebimento de Paletes',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              // 1. Campo de Pesquisa de Carga
              _buildSearchField(
                controller: _loadSearchController,
                hintText: 'Pesquisar Carga',
                onScan: () => _scanBarcode(true),
                onSubmit: (value) async {
                  if (value.isNotEmpty) await _fetchLoad(value);
                },
                isVisible: _selectedLoadId == null, 
              ),

              if (_selectedLoadId != null) _buildLoadSummary(), // monta o resumo 

              // 2. Campo de Pesquisa de Palete
              if (_selectedLoadId != null) ...[
                _buildSearchField(
                  controller: _palletSearchController,
                  hintText: 'Pesquisar Palete da Carga #${_selectedLoadId}',
                  onScan: () => _scanBarcode(false),
                  onSubmit: (value) async {
                    if (value.isNotEmpty) await _loadPalletItemsFromService(value);
                  },
                  isVisible: _selectedPalletId == null,
                ),

                if (_selectedPalletId != null) _buildLoadPalletSummary(),

                const SizedBox(height: 15),
              ],
              
              // 3. Área de Conteúdo
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [BoxShadow(color: Colors.teal.shade100.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}