import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/load_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/core/widgets/pulse_icon.dart';
import 'package:oxdata/app/core/models/pallet_load_head_model.dart';
// Note: PalletLoadItemModel não é mais diretamente necessário aqui

class LoadInvoicePage extends StatefulWidget {
  const LoadInvoicePage({super.key});

  @override
  State<LoadInvoicePage> createState() => _LoadInvoicePageState();
}

class _LoadInvoicePageState extends State<LoadInvoicePage> {
 // 1. Renomeado para focar na Carga
 final TextEditingController _loadSearchController = TextEditingController(); 
 final TextEditingController _invoiceInputController = TextEditingController();

 // 2. Estado para LoadId (usado para controlar a UI, mas o Service gerencia o objeto Load)
 int? _selectedLoadId; 
 bool _isLoading = false;
 String? _errorMessage;

 @override
 void initState() {
  super.initState();
  
  Future.microtask(() async {
  // 1. Ouve o controller da Carga
  _loadSearchController.addListener(_onLoadSearchChanged); 
  
  // 2. Obtém o LoadService
  final loadService = context.read<LoadService>();

  // 3. **LÓGICA: Verifica se já existe uma Carga Selecionada no Service**
  final existingLoad = loadService.selectedLoadForEdit;
  
  if (existingLoad != null) {
   // Se houver, define o estado local e carrega TUDO (Carga + NFs)
   setState(() {
   _selectedLoadId = existingLoad.loadId;
   // Preenche o campo de busca
   _loadSearchController.text = existingLoad.loadId.toString(); 
   });

   // *** CHAMA A FUNÇÃO DE BUSCA COMPLETA PARA GARANTIR PARIDADE DE COMPORTAMENTO ***
   await _fetchInvoicesForExistingLoad(existingLoad.loadId);
  } else {
   // Se não houver, garante que o estado do Service está limpo
   loadService.setSelectedLoadForEdit(null);
  }
  });
 }

 @override
 void dispose() {
  _loadSearchController.removeListener(_onLoadSearchChanged);
  _loadSearchController.dispose();
  _invoiceInputController.dispose();
  super.dispose();
 }

 // Lógica de Estado
 void _clearLoadState() {
  context.read<LoadService>().setSelectedLoadForEdit(null); 
  setState(() {
   _selectedLoadId = null;
   _loadSearchController.clear();
   _invoiceInputController.clear();
   _errorMessage = null;
  });
 }

 // MÉTODO auxiliar que chama o fluxo de pesquisa completo
 Future<void> _fetchInvoicesForExistingLoad(int loadId) async {
  try {
   // Chama a função que replica o fluxo do botão Pesquisar/Escanear.
   await _fetchLoadAndInvoices(loadId.toString());
  } catch (e) {
   debugPrint('Erro fatal ao re-carregar Carga e NFs: $e');
   // O tratamento de erro já deve ter sido feito em _fetchLoadAndInvoices
   // mas garantimos que a flag de loading seja resetada se algo escapar
   context.read<LoadingService>().hide();
   setState(() => _isLoading = false);
  }
 }

 void _onLoadSearchChanged() {
  // Limpa a Carga selecionada e NFs assim que a pesquisa muda
  context.read<LoadService>().setSelectedLoadForEdit(null);
  setState(() {
   _selectedLoadId = null;
  });
 }

 // 3. Busca a Carga e suas Notas Fiscais (FLUXO COMPLETO)
 Future<void> _fetchLoadAndInvoices(String loadIdStr) async {
  final loadService = context.read<LoadService>();
  final loadingService = context.read<LoadingService>();
  final loadId = int.tryParse(loadIdStr);
  
  // Limpa estado anterior antes de iniciar a busca
  _clearLoadState(); 

  if (loadId == null) {
   MessageService.showWarning('ID da Carga inválido.');
   return;
  }

  setState(() {
   _isLoading = true;
   _errorMessage = null;
  });

  try {
   loadingService.show();
   
   // 1. Busca e define a Carga selecionada no Service
   final loadHead = await loadService.fetchLoadById(loadId);
   
   if (loadHead == null) {
    throw Exception('Carga $loadId não encontrada.');
   }
   
   // 2. Busca as Notas Fiscais da Carga
   await loadService.fetchLoadInvoices(loadId); 
   
   setState(() {
    _selectedLoadId = loadId; // Sinaliza que a Carga foi selecionada
   });
   MessageService.showSuccess('Carga $loadId selecionada. Gerencie as NFs.');

  } catch (e) {
   _clearLoadState();
   setState(() {
    _selectedLoadId = null;
    _errorMessage = 'Erro ao carregar Carga $loadId: ${e.toString()}';
   });
   MessageService.showError('Erro ao carregar Carga.');
  } finally {
   loadingService.hide();
   setState(() => _isLoading = false);
  }
 }

  // 4. Lógica para Adicionar Nota Fiscal (Ajustado para usar _selectedLoadId)
  Future<void> _addInvoice() async {
    final input = _invoiceInputController.text.trim();

    String invoice;
    String invoiceKey;

    // Lógica para extrair número da NF (simplificada, se 44 dígitos)
    if (input.length == 44) {
      // Ajuste o índice se necessário, mas mantendo a lógica anterior
      invoice = input.substring(28, 35); 
      invoiceKey = input;
    } else {
      invoice = input;
      invoiceKey = input;
    }

    final loadService = context.read<LoadService>();
    // Usando o _selectedLoadId (local) ou a Carga selecionada no Service
    final loadId = _selectedLoadId ?? loadService.selectedLoadForEdit?.loadId; 
    
    if (invoice.isEmpty || loadId == null) {
      MessageService.showWarning('Selecione uma Carga e insira um número de NF válido.');
      return;
    }

    final loadingService = context.read<LoadingService>();

    setState(() => _isLoading = true);
    loadingService.show();

    try {
      await loadService.addInvoiceToPallet(
        loadId,
        invoice,
        invoiceKey, 
      );
      
      MessageService.showSuccess('Nota $invoice adicionada com sucesso!');
      _invoiceInputController.clear();
    } catch (e) {
      MessageService.showError('Falha ao adicionar NF: ${e.toString()}');
    } finally {
      loadingService.hide();
      setState(() => _isLoading = false);
    }
  }
  
  // 5. Lógica para Remover Nota Fiscal (Ajustado para usar _selectedLoadId)
  Future<void> _removeInvoice(String invoice) async {
    final loadService = context.read<LoadService>();
    final loadingService = context.read<LoadingService>();

    final loadId = _selectedLoadId ?? loadService.selectedLoadForEdit?.loadId;
    
    if (loadId == null || loadId <= 0 || invoice.isEmpty) return;

    setState(() => _isLoading = true);
    loadingService.show();

    try {
      // Note: O método no Service é delInvoiceFromPallet, mas ele já foi ajustado
      // para usar loadId internamente. O nome deve ser mantido se não foi alterado.
      await loadService.delInvoiceFromPallet(loadId, invoice);
      
      MessageService.showSuccess('Nota $invoice removida com sucesso!');

    } catch (e) {
      MessageService.showError('Falha ao remover NF: ${e.toString()}');
    } finally {
      loadingService.hide();
      setState(() => _isLoading = false);
    }
  }

  // --- Lógica de Scanner (Ajustado para Carga) ---
  Future<void> _scanBarcode() async {
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
    // Tenta obter um ID de carga válido (número inteiro)
    final scanned = int.tryParse(scannedRaw)?.toString() ?? ''; 

    if (scanned.isEmpty) {
      MessageService.showWarning('Código de barras inválido.');
      return;
    }

    _loadSearchController.text = scanned;
    await _fetchLoadAndInvoices(scanned);
  }

  // 6. UI de Resumo da Carga (Ajustado para LoadHeadModel)
  Widget _buildLoadSummary(PalletLoadHeadModel loadHead) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Usando o ID da Carga
                  'CARGA: ${loadHead.loadId}', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.teal.shade700,
                  ),
                ),
                // Exibe o Status da Carga
                Text('Status: ${loadHead.status}',
                    style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
          PulseIconButton(
            icon: Icons.close_fullscreen,
            color: Colors.red,
            size: 32,
            onPressed: _clearLoadState, // Limpa o estado da Carga
          ),
        ],
      ),
    );
  }
  
  // 7. UI de Campo de Pesquisa Reutilizável (Ajustado para Carga)
  Widget _buildSearchField({
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onScan,
    required Future<void> Function(String) onSubmit,
    bool isVisible = true,
  }) {
    void onClearField() {
      controller.clear();
      _onLoadSearchChanged(); // Usa a nova lógica
    }

    return Visibility(
      visible: isVisible,
      replacement: const SizedBox.shrink(),
      child: TextField(
        controller: controller,
        // Usando o controller da Carga
        onChanged: (query) { 
          _onLoadSearchChanged();
        },
        onSubmitted: onSubmit,
        enabled: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          // Texto de dica alterado para Carga
          hintText: 'Pesquisar Carga (ID)', 
          hintStyle: TextStyle(color: Colors.grey.shade600),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey, size: 28),
                onPressed: onClearField,
              ),
              const SizedBox(width: 4),
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

  // 8. UI de Gerenciamento de Notas Fiscais (Mantido, mas agora usa NFs da Carga)
  Widget _buildInvoiceManager(List<String> invoices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input para Nova Nota Fiscal
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 10.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _invoiceInputController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addInvoice(),
                  decoration: InputDecoration(
                    labelText: 'Número da Nota Fiscal',
                    hintText: 'Digite ou escaneie o número da NF',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _addInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                ),
                child: const Text('ADICIONAR'),
              ),
            ],
          ),
        ),

        // Chips das Notas Fiscais Vinculadas
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0, top: 8.0),
          child: Text('Notas Fiscais Vinculadas:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        
        if (invoices.isEmpty)
          const Text('Nenhuma Nota Fiscal associada a esta Carga.', style: TextStyle(color: Colors.black54)),

        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 6.0,
              runSpacing: 4.0,
              children: invoices.map((invoice) {
                return Chip(
                  label: Text(invoice, style: const TextStyle(fontWeight: FontWeight.bold)),
                  deleteIcon: const Icon(Icons.cancel, size: 18),
                  onDeleted: _isLoading ? null : () => _removeInvoice(invoice),
                  backgroundColor: Colors.teal.shade100,
                  side: BorderSide(color: Colors.teal.shade300),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadService = context.watch<LoadService>();
    // Usando a Carga selecionada
    final selectedLoadHead = loadService.selectedLoadForEdit; 
    // Usando a lista de NFs da Carga
    final loadInvoices = loadService.currentPalletInvoices; 

    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator(color: Colors.teal));
    } else if (_errorMessage != null) {
      content = Center(
          child:
              Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)));
    } else if (_selectedLoadId != null && selectedLoadHead != null) { 
      // Se a Carga foi selecionada/encontrada, exibe o gerenciador de NFs
      content = _buildInvoiceManager(loadInvoices);
    } else {
      content = const Center(
          child: Text('Aguardando a leitura do código da Carga.',
              style: TextStyle(color: Colors.black54)));
    }

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER ---------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_rounded,
                      size: 34,
                      color: Colors.teal.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Associação de Notas Fiscais',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 1. Campo de Pesquisa da Carga
              _buildSearchField(
                controller: _loadSearchController,
                hintText: 'Pesquisar Carga',
                onScan: _scanBarcode,
                onSubmit: (value) async {
                  if (value.isNotEmpty) {
                    await _fetchLoadAndInvoices(value);
                  }
                },
                // Visível apenas se nenhuma carga estiver selecionada
                isVisible: _selectedLoadId == null, 
              ),

              const SizedBox(height: 12),

              // 2. Resumo da Carga
              // Usando selectedLoadHead (do Service)
              if (selectedLoadHead != null) _buildLoadSummary(selectedLoadHead), 

              // 3. Conteúdo Principal
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.shade100.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
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

/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/load_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/core/widgets/pulse_icon.dart';
import 'package:oxdata/app/core/models/pallet_load_item_model.dart';


class LoadInvoicePage extends StatefulWidget {
  const LoadInvoicePage({super.key});

  @override
  State<LoadInvoicePage> createState() => _LoadInvoicePageState();
}

class _LoadInvoicePageState extends State<LoadInvoicePage> {
  final TextEditingController _palletSearchController = TextEditingController();
  final TextEditingController _invoiceInputController = TextEditingController();

  int? _selectedPalletId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _palletSearchController.addListener(_onPalletSearchChanged);
    });
  }

  @override
  void dispose() {
    _palletSearchController.removeListener(_onPalletSearchChanged);
    _palletSearchController.dispose();
    _invoiceInputController.dispose();
    super.dispose();
  }

  // Lógica de Estado
  void _clearPalletState() {
    context.read<LoadService>().clearPalletItemsState(); 
    setState(() {
      _selectedPalletId = null;
      _palletSearchController.clear();
      _invoiceInputController.clear();
      _errorMessage = null;
    });
  }

  void _onPalletSearchChanged() {
    // Limpa apenas o Pallet selecionado e as NFs, mantendo a busca de carga ativa
    context.read<LoadService>().clearPalletItemsState();
    setState(() {
      _selectedPalletId = null;
    });
  }

  // Busca as notas do palete
  Future<void> _fetchPalletDetailsAndInvoices(String palletIdStr) async {
    final loadService = context.read<LoadService>();
    final loadingService = context.read<LoadingService>();
    final palletId = int.tryParse(palletIdStr);
    

    if (palletId == null) {
      MessageService.showWarning('ID do Palete inválido.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedPalletId = null;
    });

    try {
      loadingService.show();
      
      // Busca as notas fiscais
      await loadService.fetchLoadInvoices(palletId); 
      
      setState(() {
        _selectedPalletId = palletId;
      });
      //MessageService.showSuccess('Palete $palletId selecionado. Gerencie as NFs.');

    } catch (e) {
      _clearPalletState();
      setState(() {
        _selectedPalletId = null;
        _errorMessage = 'Erro ao carregar Palete $palletId: $e';
      });
      MessageService.showError('Erro ao carregar Palete.');
    } finally {
      loadingService.hide();
      setState(() => _isLoading = false);
    }
  }

  // 2. Lógica para Adicionar Nota Fiscal
  Future<void> _addInvoice() async {
    final input = _invoiceInputController.text.trim();

    String invoice;
    String invoiceKey;

    if (input.length == 44) {
      invoice = input.substring(28, 35); 
      invoiceKey = input;
    } else {
      invoice = input;
      invoiceKey = input;
    }

    // Usando _selectedLoadId, conforme ajustes anteriores.
    final loadService = context.read<LoadService>();
    final loadId = loadService.selectedLoadForEdit?.loadId;
    
    if (invoice.isEmpty || loadId == null) return;

    final loadingService = context.read<LoadingService>();

    setState(() => _isLoading = true);
    loadingService.show();

    try {
      await loadService.addInvoiceToPallet(
        loadId,
        invoice,
        invoiceKey, 
      );
      
      MessageService.showSuccess('Nota $invoice adicionada com sucesso!');
      _invoiceInputController.clear();
    } catch (e) {
      MessageService.showError('Falha ao adicionar NF: ${e.toString()}');
    } finally {
      loadingService.hide();
      setState(() => _isLoading = false);
    }
  }
  
  // 3. Lógica para Remover Nota Fiscal
  Future<void> _removeInvoice(String invoice) async {
    final loadService = context.read<LoadService>();
    final loadingService = context.read<LoadingService>();

    final loadId = loadService.selectedLoadForEdit?.loadId;
    
    if (loadId == null || loadId <= 0 || invoice.isEmpty) return;

    setState(() => _isLoading = true);
    loadingService.show();

    try {
      await loadService.delInvoiceFromPallet(loadId, invoice);
      
      MessageService.showSuccess('Nota $invoice removida com sucesso!');

    } catch (e) {
      MessageService.showError('Falha ao remover NF: ${e.toString()}');
    } finally {
      loadingService.hide();
      setState(() => _isLoading = false);
    }
  }

  // --- Lógica de Scanner (Simplificada) ---
  Future<void> _scanBarcode() async {
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

    _palletSearchController.text = scanned;
    await _fetchPalletDetailsAndInvoices(scanned);
  }

  // 4. UI de Resumo do Palete (usando PalletDetailsModel)
  Widget _buildPalletSummary(PalletDetailsModel details) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PALETE: ${details.palletId}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.teal.shade700,
                  ),
                ),
                // ⚠️ AJUSTE: PalletDetailsModel não tem 'location' ou 'status' na definição que você forneceu.
                // Vou usar um valor de exemplo ou o ID:
                Text('Total de Itens: ${details.items.length}',
                    style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
          PulseIconButton(
            icon: Icons.close_fullscreen,
            color: Colors.red,
            size: 32,
            onPressed: _clearPalletState,
          ),
        ],
      ),
    );
  }
  
  // 5. UI de Campo de Pesquisa Reutilizável (Adaptado da LoadReceivePage)
  Widget _buildSearchField({
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onScan,
    required Future<void> Function(String) onSubmit,
    bool isVisible = true,
  }) {
    void onClearField() {
      controller.clear();
      _onPalletSearchChanged();
    }

    return Visibility(
      visible: isVisible,
      replacement: const SizedBox.shrink(),
      child: TextField(
        controller: controller,
        onChanged: (query) {
          _onPalletSearchChanged();
        },
        onSubmitted: onSubmit,
        enabled: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade600),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey, size: 28),
                onPressed: onClearField,
              ),
              const SizedBox(width: 4),
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

  // 6. UI de Gerenciamento de Notas Fiscais
  Widget _buildInvoiceManager(List<String> invoices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input para Nova Nota Fiscal
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 10.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _invoiceInputController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addInvoice(),
                  decoration: InputDecoration(
                    labelText: 'Número da Nota Fiscal',
                    hintText: 'Digite ou escaneie o número da NF',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _addInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                ),
                child: const Text('ADICIONAR'),
              ),
            ],
          ),
        ),

        // Chips das Notas Fiscais Vinculadas
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0, top: 8.0),
          child: Text('Notas Fiscais Vinculadas:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        
        if (invoices.isEmpty)
          const Text('Nenhuma Nota Fiscal associada a este palete.', style: TextStyle(color: Colors.black54)),

        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 6.0,
              runSpacing: 4.0,
              children: invoices.map((invoice) {
                return Chip(
                  label: Text(invoice, style: const TextStyle(fontWeight: FontWeight.bold)),
                  deleteIcon: const Icon(Icons.cancel, size: 18),
                  onDeleted: _isLoading ? null : () => _removeInvoice(invoice),
                  backgroundColor: Colors.teal.shade100,
                  side: BorderSide(color: Colors.teal.shade300),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadService = context.watch<LoadService>();
    final palletDetails = loadService.currentPalletDetails;
    final palletInvoices = loadService.currentPalletInvoices;

    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator(color: Colors.teal));
    } else if (_errorMessage != null) {
      content = Center(
          child:
              Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)));
    } else if (_selectedPalletId != null) {
      // Se o Palete foi selecionado/encontrado, exibe o gerenciador de NFs
      content = _buildInvoiceManager(palletInvoices);
    } else {
      content = const Center(
          child: Text('Aguardando a leitura do código do Palete.',
              style: TextStyle(color: Colors.black54)));
    }

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER ---------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_rounded,
                      size: 34,
                      color: Colors.teal.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Associação de Notas Fiscais',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 1. Campo de Pesquisa do Palete
              _buildSearchField(
                controller: _palletSearchController,
                hintText: 'Pesquisar Palete',
                onScan: _scanBarcode,
                onSubmit: (value) async {
                  if (value.isNotEmpty) {
                    await _fetchPalletDetailsAndInvoices(value);
                  }
                },
                isVisible: _selectedPalletId == null,
              ),

              const SizedBox(height: 12),

              // 2. Resumo do Palete
              if (palletDetails != null) _buildPalletSummary(palletDetails),

              // 3. Conteúdo Principal
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.shade100.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
*/