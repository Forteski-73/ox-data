import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/pallet_load_head_model.dart';
import 'package:oxdata/app/core/services/load_service.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/widgets/pulse_icon.dart';

// NOVAS IMPORTAÇÕES PARA EMAIL/EXCEL/ARQUIVO
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel;
import 'package:oxdata/app/core/utils/email_sender.dart'; 
import 'package:oxdata/app/core/services/message_service.dart'; 
import 'dart:io';
// FIM NOVAS IMPORTAÇÕES

class SearchLoadPage extends StatefulWidget {
 /// Callback chamado quando uma carga é selecionada
 final void Function(PalletLoadHeadModel load)? onEditLoad;

 const SearchLoadPage({super.key, this.onEditLoad});

 @override
 State<SearchLoadPage> createState() => _SearchLoadPageState();
}

class _SearchLoadPageState extends State<SearchLoadPage> {
 final TextEditingController _searchController = TextEditingController();
 List<PalletLoadHeadModel> _filteredCargas = [];
 bool _isLoading = true;
 String? _errorMessage;

 @override
 void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
   _fetchInitialData();
  });
 }

 Future<void> _fetchInitialData() async {
  final loadService = context.read<LoadService>();
  final loadingService = context.read<LoadingService>();

  try {
   loadingService.show();
   await loadService.fetchAllLoadHeads();
   loadingService.hide();

   _filterCargas(_searchController.text);

   setState(() {
    _isLoading = false;
    _errorMessage = null;
   });
  } catch (e) {
   /*setState(() {
    _isLoading = false;
    _errorMessage = 'Erro ao carregar dados: $e';
   });*/
  }
 }

 void _filterCargas(String query) {
  final allCargas = context.read<LoadService>().loadHeads;

  setState(() {
   if (query.isEmpty) {
    _filteredCargas = allCargas;
   } else {
    _filteredCargas = allCargas
      .where((c) =>
        (c.loadId?.toString() ?? '').contains(query) ||
        (c.name?.toLowerCase() ?? '')
          .contains(query.toLowerCase()))
      .toList();
   }
  });
 }

 Future<void> _scanBarcode() async {
  var status = await Permission.camera.request();
  if (!status.isGranted) return;

  final barcodeRead = await Navigator.of(context).push<Barcode?>(
   MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
  );

  if (barcodeRead == null) return;

  final scanned = barcodeRead.rawValue ?? "";
  if (scanned.isNotEmpty) {
   _searchController.text = scanned;
   _filterCargas(scanned);
  }
 }

 void _performSearch() {
  _filterCargas(_searchController.text);
  FocusScope.of(context).unfocus();
 }

 Future<void> _sendFileEmail({
  required BuildContext context,
  required List<int> fileBytes,
  required String fileName,
  required List<String> recipients,
  required String subject,
  required String body,
 }) async {
  final loadingService = context.read<LoadingService>();
  loadingService.show();
  try {
   //final tempDir = await getTemporaryDirectory();
   //final tempDir = await getExternalStoragePublicDirectory();
   final tempDir = await getExternalStorageDirectory();
   final filePath = "${tempDir!.path}/$fileName";
   final tempFile = File(filePath);
   await tempFile.writeAsBytes(fileBytes);

   final success = await EmailSenderUtility.sendEmail(
    context: context,
    recipients: recipients,
    subject: subject,
    body: body,
    attachmentPaths: [tempFile.path],
   );

   if (success) {

    //await tempFile.delete();
   }

  } catch (e) {
   debugPrint('Erro ao preparar ou enviar email: $e');
   MessageService.showError('Falha ao gerar ou preparar o e-mail: $e');
  } finally {
   loadingService.hide();
  }
 }

Future<void> _generateAndSendEmail(PalletLoadHeadModel load) async {
    final loadService = context.read<LoadService>();
    final loadingService = context.read<LoadingService>();
    final loadId = load.loadId;

    if (loadId == null) {
        MessageService.showError('ID da Carga inválido.');
        return;
    }

    loadingService.show();
    try {
        // 1. GARANTIR QUE A LISTA DE PALETES ESTÁ CARREGADA (popula loadService.loadPallets)
        await loadService.fetchPalletsByLoadId(loadId);

        // 2. GARANTIR QUE OS ITENS DE TODOS OS PALETES ESTÃO CARREGADOS (popula loadService.currentPalletItems)
        // O método updateLoadStatus contém a lógica de iterar sobre os Paletes e buscar 
        // todos os seus itens, salvando-os em _currentPalletItems. Usamos o status atual da 
        // carga para evitar uma alteração de status indesejada.
        await loadService.updateLoadStatus(loadId, load.status ?? 'Carregando');


        final allPallets = loadService.loadPallets;
        final allItems = loadService.currentPalletItems;

        if (allPallets.isEmpty) {
            MessageService.showError('Nenhum Palete encontrado para esta Carga. Não é possível gerar o Excel.');
            return;
        }

        var excelInstance = excel.Excel.createExcel();
        //final sheet = excelInstance['Carga_${loadId}'];
        final sheet = excelInstance['Sheet1'];

        sheet.appendRow(['Carga', 'Palete', 'Produto', 'Quantidade', 'Localização']);

        for (final pallet in allPallets) {
            // Filtra APENAS os itens que pertencem ao Palete atual
            final items = allItems.where((i) => i.palletId == pallet.palletId).toList();

            if (items.isEmpty) {
                sheet.appendRow([
                    pallet.loadId,
                    pallet.palletId,
                    'N/A',
                    0,
                    pallet.palletLocation,
                ]);
            } else {
                for (final item in items) {
                    sheet.appendRow([
                        pallet.loadId,
                        pallet.palletId,
                        item.productId,
                        item.quantity,
                        pallet.palletLocation,
                    ]);
                }
            }
        }

        final bytes = excelInstance.encode() ?? [];

        await _sendFileEmail(
            context: context,
            fileBytes: bytes,
            fileName: 'Carga_${loadId}.xlsx',
            recipients: [],
            subject: 'Lista de Produtos da Carga $loadId',
            body: 'Segue em anexo a lista de produtos e pallets da carga ${load.loadId} - ${load.name}.',
        );
    } catch (e) {
        debugPrint('Erro no processo de envio de e-mail: $e');
        MessageService.showError('Erro ao processar o e-mail da carga: $e');
    } finally {
        loadingService.hide();
    }
}

  @override
  Widget build(BuildContext context) {
      final loadService = context.watch<LoadService>();
      if (_isLoading) _filteredCargas = loadService.loadHeads;

      Widget content;

      if (_isLoading) {
          content = const Center(child: CircularProgressIndicator(color: Colors.white));
      } else if (_errorMessage != null) {
          content = Center(
              child: Text(_errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16)));
      } else if (_filteredCargas.isEmpty && _searchController.text.isEmpty) {
          content = const Center(
              child:
                  Text('Nenhuma carga carregada.', style: TextStyle(color: Colors.black54)));
      } else if (_filteredCargas.isEmpty && _searchController.text.isNotEmpty) {
          content = const Center(
              child: Text('Nenhuma carga encontrada com o filtro atual.',
                  style: TextStyle(color: Colors.black54)));
      } else {
          content = ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.builder(
                  itemCount: _filteredCargas.length,
                  itemBuilder: (context, index) {
                      final load = _filteredCargas[index];
                      final displayTitle = 'CARGA ${load.loadId} - ${load.name}';

                      return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                              // 💡 ALTERAÇÃO PRINCIPAL: Uso de InkWell customizado
                              InkWell(
                                  onTap: () {
                                      context.read<LoadService>().setSelectedLoadForEdit(load); 
                                      context.read<LoadService>().setPage(0);
                                  },
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                                      child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                              // 1. Ícone Leading (Status da Carga)
                                              Icon(
                                                  load.status == 'Carregando' 
                                                      ? Icons.local_shipping_outlined 
                                                      : Icons.local_shipping,
                                                  color: Colors.teal,
                                                  size: 28,
                                              ),
                                              const SizedBox(width: 16),

                                              // 2. Título (Permite Scroll Horizontal) e Subtítulo
                                              Expanded(
                                                  child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                          // TÍTULO COM SCROLL HORIZONTAL
                                                          SingleChildScrollView(
                                                              scrollDirection: Axis.horizontal,
                                                              child: Text(
                                                                  displayTitle,
                                                                  style: const TextStyle(
                                                                      fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.visible, // Garante que não quebre linha
                                                              ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                              'ID: ${load.loadId ?? 'N/A'} | Status: ${load.status ?? 'N/A'}',
                                                              style: const TextStyle(color: Colors.black54, fontSize: 16),
                                                          ),
                                                      ],
                                                  ),
                                              ),

                                              // 3. Ícone de E-mail (Compacto)
                                              const SizedBox(width: 6),
                                              InkWell(
                                                  //onTap: () => _generateAndSendEmail(load),
                                                  child: Padding(
                                                      padding: EdgeInsets.all(2.0), // Padding mínimo para o toque
                                                      child: PulseIconButton(
                                                        icon: Icons.email_rounded,
                                                        color: Colors.indigo,
                                                        size: 30,
                                                        onPressed: () { _generateAndSendEmail(load); }
                                                      ),
                                                  ),
                                              ),
                                          ],
                                      ),
                                  ),
                              ),
                              if (index < _filteredCargas.length - 1)
                                  const Divider(height: 0, indent: 20, endIndent: 20),
                          ],
                      );
                  },
              ),
          );
      }

      return Scaffold(
          backgroundColor: Colors.teal.shade50,
          body: SafeArea(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                  child: Column(
                      children: [
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
                                Icons.search_rounded,
                                size: 34,
                                color: Colors.teal.shade700,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Pesquisar Cargas',
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
                          TextField(
                              controller: _searchController,
                              onChanged: _filterCargas,
                              decoration: InputDecoration(
                                  hintText: 'Digite ou escaneie o número/cidade da carga...',
                                  hintStyle: TextStyle(color: Colors.grey.shade600),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                          IconButton(
                                              icon: const Icon(Icons.search, size: 28, color: Colors.teal),
                                              onPressed: _performSearch,
                                              tooltip: 'Pesquisar Carga',
                                          ),
                                          IconButton(
                                              icon: const Icon(Icons.qr_code_scanner, size: 30, color: Colors.teal),
                                              onPressed: _scanBarcode,
                                              tooltip: 'Ler código de barras',
                                          ),
                                          const SizedBox(width: 8),
                                      ],
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
                              ),
                          ),
                          const SizedBox(height: 15),
                          Expanded(
                              child: Container(
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
import 'package:oxdata/app/core/models/pallet_load_head_model.dart';
import 'package:oxdata/app/core/services/load_service.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/core/services/loading_service.dart';

class SearchLoadPage extends StatefulWidget {
  /// Callback chamado quando uma carga é selecionada
  final void Function(PalletLoadHeadModel load)? onEditLoad;

  const SearchLoadPage({super.key, this.onEditLoad});

  @override
  State<SearchLoadPage> createState() => _SearchLoadPageState();
}

class _SearchLoadPageState extends State<SearchLoadPage> {
  final TextEditingController _searchController = TextEditingController();
  List<PalletLoadHeadModel> _filteredCargas = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    final loadService = context.read<LoadService>();
    final loadingService = context.read<LoadingService>();

    try {
      loadingService.show();
      await loadService.fetchAllLoadHeads();
      loadingService.hide();

      _filterCargas(_searchController.text);

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      /*setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar dados: $e';
      });*/
    }
  }

  void _filterCargas(String query) {
    final allCargas = context.read<LoadService>().loadHeads;

    setState(() {
      if (query.isEmpty) {
        _filteredCargas = allCargas;
      } else {
        _filteredCargas = allCargas
            .where((c) =>
                (c.loadId?.toString() ?? '').contains(query) ||
                (c.name?.toLowerCase() ?? '')
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _scanBarcode() async {
    var status = await Permission.camera.request();
    if (!status.isGranted) return;

    final barcodeRead = await Navigator.of(context).push<Barcode?>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (barcodeRead == null) return;

    final scanned = barcodeRead.rawValue ?? "";
    if (scanned.isNotEmpty) {
      _searchController.text = scanned;
      _filterCargas(scanned);
    }
  }

  void _performSearch() {
    _filterCargas(_searchController.text);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final loadService = context.watch<LoadService>();
    if (_isLoading) _filteredCargas = loadService.loadHeads;

    Widget content;

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator(color: Colors.white));
    } else if (_errorMessage != null) {
      content = Center(
          child: Text(_errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 16)));
    } else if (_filteredCargas.isEmpty && _searchController.text.isEmpty) {
      content = const Center(
          child:
              Text('Nenhuma carga carregada.', style: TextStyle(color: Colors.black54)));
    } else if (_filteredCargas.isEmpty && _searchController.text.isNotEmpty) {
      content = const Center(
          child: Text('Nenhuma carga encontrada com o filtro atual.',
              style: TextStyle(color: Colors.black54)));
    } else {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.builder(
          itemCount: _filteredCargas.length,
          itemBuilder: (context, index) {
            final load = _filteredCargas[index];
            final displayTitle = 'CARGA ${load.loadId} - ${load.name}';

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              ListTile(
                leading: Icon(
                  load.status == 'Carregando' 
                      ? Icons.local_shipping_outlined 
                      : Icons.local_shipping,
                  color: Colors.teal,
                ),
                title: Text(displayTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.black87)),
                subtitle: Text(
                  'ID: ${load.loadId ?? 'N/A'} | Status: ${load.status ?? 'N/A'}'),
                onTap: () {
                  // 1. Define qual carga está sendo editada no Service
                  context.read<LoadService>().setSelectedLoadForEdit(load); 
                  
                  // 2. Chama o método de navegação para a página de destino (ex: índice 0 para LoadNewPage)
                  // O LoadService irá atualizar o _currentPageIndex e notificar o PageView.
                  context.read<LoadService>().setPage(0); // <<<<<< ADICIONE ESTA LINHA
                  
                  /*if (widget.onEditLoad != null) {
                    widget.onEditLoad!(load);
                  }*/
                },
              ),
                if (index < _filteredCargas.length - 1)
                  const Divider(height: 0, indent: 20, endIndent: 20),
              ],
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.teal.shade50, // mesma cor de fundo que LoadNewPage
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.search_rounded, size: 36, color: Colors.teal),
                  SizedBox(width: 15),
                  Text(
                    'Pesquisar Cargas',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal, // mesma tonalidade de destaque
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                onChanged: _filterCargas,
                decoration: InputDecoration(
                  hintText: 'Digite ou escaneie o número/cidade da carga...',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.teal),
                        onPressed: _performSearch,
                        tooltip: 'Pesquisar Carga',
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.teal),
                        onPressed: _scanBarcode,
                        tooltip: 'Ler código de barras',
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // fundo branco consistente
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
