import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/load_service.dart';
import 'package:oxdata/app/core/models/pallet_load_line_model.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/core/widgets/pulse_icon.dart';
import 'package:oxdata/app/core/widgets/app_confirm_dialog.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel;
import 'package:oxdata/app/core/models/pallet_load_item_model.dart' as LoadItemModel;
import 'package:oxdata/app/core/utils/email_sender.dart';
import 'dart:io';

class SearchReadyPalletsPage extends StatefulWidget {
  const SearchReadyPalletsPage({super.key});

  @override
  State<SearchReadyPalletsPage> createState() => _SearchReadyPalletsPageState();
}

class _SearchReadyPalletsPageState extends State<SearchReadyPalletsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<PalletLoadLineModel> _filteredPallets = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    //_searchController.addListener(_onSearchQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  @override
  void dispose() {
    //_searchController.removeListener(_onSearchQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchQueryChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
      _filterPallets(_searchQuery);
    });
  }

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

  Future<void> _fetchInitialData() async {
    final loadService = context.read<LoadService>();
    final loadingService = context.read<LoadingService>();
    const minDuration = Duration(milliseconds: 700);
    final start = DateTime.now();

    try {
      loadingService.show();

      // Usando LoadService para buscar pallets pelo loadId
      final selectedLoad = loadService.selectedLoadForEdit;
      if (selectedLoad != null) {
        await loadService.fetchPalletsByLoadId(selectedLoad.loadId);
      }

      _filterPallets(_searchController.text);

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      /*setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar paletes: $e';
      });*/
    } finally {
      final elapsed = DateTime.now().difference(start);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
      loadingService.hide();
    }
  }

  void _filterPallets(String query) {
    final loadService = context.read<LoadService>();
    final allPallets = loadService.loadPallets;
    final normalizedQuery = query.toLowerCase().trim();

    setState(() {
      if (normalizedQuery.isEmpty) {
        _filteredPallets = allPallets;
      } else {
        _filteredPallets = allPallets.where((pallet) {
          final matchesId = pallet.palletId.toString().toLowerCase().contains(normalizedQuery);
          final matchesLocation = pallet.palletLocation.toLowerCase().contains(normalizedQuery);
          final matchesStatus = _mapStatus(pallet.carregado ? 'M' : 'I').toLowerCase().contains(normalizedQuery);
          return matchesId || matchesLocation || matchesStatus;
        }).toList();
      }
    });
  }

  Future<int> _handlePalletAddition({
    int? pallet,
  }) async {
    final loadService = context.read<LoadService>();
    final selectedLoad = loadService.selectedLoadForEdit;

    int ret = 0;

    try {
      bool carregado = false;

      if (selectedLoad?.status == "Carga Finalizada")
      {
        carregado = true;
      }

      final response = await loadService.addPalletToLoadLine(
        selectedLoad!.loadId,
        pallet.toString(),
        carregado,
      );

      // Limpa o campo de busca
      _searchController.clear();
      
      ret = response.data ?? 0;
      // Trata o status retornado
      switch (response.data) {
        case 0:
          // Erro
          MessageService.showError('Falha ao adicionar pallet.');
          break;
        case 1:
          // Sucesso
          MessageService.showSuccess('Pallet adicionado com sucesso.');
          break;
        case 2:
          // Sucesso + todos os pallets carregados
          MessageService.showSuccess('Todos os paletes estão prontos');
          final confirmed = await showConfirmDialog(
            context: context,
            message: 'Todos os Paletes foram carregados. Deseja finalizar a Carga?',
          );

          if (confirmed) {

            bool sucesso = await loadService.updateLoadStatus(selectedLoad.loadId, "Carga Finalizada");

            if (sucesso) {
              MessageService.showSuccess('A carga foi finalizada.');

              final confirmedEmal = await showConfirmDialog(
                context: context,
                message: 'Deseja enviar e-mail com a lista de produtos da carga?',
              );

              if (confirmedEmal) {
                final loadService = context.read<LoadService>();
                //final selectedLoad = loadService.selectedLoadForEdit;

                //if (selectedLoad != null) {
                  try {
                    // Cria um Excel único
                    var excelInstance = excel.Excel.createExcel();

                    // Pega a aba default criada automaticamente
                    final sheet = excelInstance['Sheet1'];

                    // Cabeçalho
                    sheet.appendRow(['Carga', 'Palete', 'Produto', 'Quantidade']);

                    // Adiciona todos os itens de todos os pallets em sequência
                    for (final pallet in loadService.loadPallets) {
                      // Filtra os itens correspondentes ao pallet
                      final items = loadService.currentPalletItems
                          .where((i) => i.palletId == pallet.palletId)
                          .toList();

                      for (final item in items) {
                        sheet.appendRow([
                          pallet.loadId,
                          pallet.palletId,
                          item.productId,
                          item.quantity,
                        ]);
                      }
                    }

                    // Codifica o Excel em bytes
                    final bytes = excelInstance.encode() ?? [];

                    // Envia o e-mail
                    await _sendFileEmail(
                      context: context,
                      fileBytes: bytes,
                      fileName: 'Carga_${selectedLoad.loadId}.xlsx',
                      recipients: [],
                      subject: 'Lista de Produtos da Carga ${selectedLoad.loadId}',
                      body: 'Segue em anexo a lista de produtos da carga.',
                    );

                    MessageService.showSuccess('Email enviado com sucesso!');

                  } catch (e) {
                    MessageService.showError('Erro ao enviar email: $e');
                  }
                //} else {
                //  MessageService.showError('Carga não encontrada para envio de email.');
                //}
              }


            } else {
              MessageService.showError('Erro ao atualizar a carga.');
            }
                        
          }

          break;
        default:
          // Valor inesperado
          MessageService.showWarning('Status desconhecido ao adicionar pallet.');
      }

    } catch (_) {
      ret = 0;
    }
    return ret;
  }

  ///******************************ENVIAR E-MAIL********************************** */

  Future<List<int>> _generateExampleExcelBytes({
    required PalletLoadLineModel palletLine, // renomeado
    required LoadService loadService,
  }) async {
    var excelInstance = excel.Excel.createExcel();

    String sheetName = 'Palete_${palletLine.palletId}';
    final sheet = excelInstance[sheetName];

    // Cabeçalho
    sheet.appendRow(['Carga', 'Palete', 'Produto', 'Quantidade']);

    // Usa os itens já carregados no serviço
    List<LoadItemModel.PalletItemModel> items = loadService.currentPalletItems;

    for (final item in items) {
      sheet.appendRow([
        palletLine.loadId,
        palletLine.palletId,
        item.productId,
        item.quantity,
      ]);
    }

    return excelInstance.encode() ?? [];
  }

  Future<void> _sendFileEmail({
    required BuildContext context,
    required List<int> fileBytes,
    required String fileName,
    required List<String> recipients,
    required String subject,
    required String body,
  }) async {
    try {
      // 1️⃣ Cria arquivo temporário
      final tempDir = await getTemporaryDirectory();
      final filePath = "${tempDir.path}/$fileName";
      final tempFile = File(filePath);
      await tempFile.writeAsBytes(fileBytes);

      // 2️⃣ Usa a classe EmailSenderUtility para enviar
      final success = await EmailSenderUtility.sendEmail(
        context: context,
        recipients: recipients,
        subject: subject,
        body: body,
        attachmentPaths: [tempFile.path],
      );

      // 3️⃣ Limpa arquivo temporário
      if (success) {
        await tempFile.delete();
      }

    } catch (e) {
      debugPrint('Erro ao preparar ou enviar email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar email: $e')),
      );
    }
  }

  ///******************************ENVIAR E-MAIL********************************** */

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
      //_filterPallets(scanned);
      _handlePalletAddition(pallet:int.parse(scanned));
    }
  }

  /// Lida com a exclusão de um pallet da carga.
  Future<void> _deletePallet(int loadId, int palletId) async {
    final confirmed = await showConfirmDialog(
      context: context,
      message: 'Tem certeza que deseja remover o Palete $palletId desta carga?',
    );

    if (!confirmed) return; // Se o usuário cancelar, não faz nada

    final loadService = context.read<LoadService>();
    final loadingService = context.read<LoadingService>();

    loadingService.show();
    try {
      // Chama o método do Service para realizar a exclusão
      await loadService.deletePallet(loadId, palletId);
      
      // Se o serviço não lançar exceção, significa que foi sucesso
      MessageService.showSuccess('Palete $palletId removido com sucesso!');

      // Atualiza a lista filtrada no State após a exclusão do estado global
      _filterPallets(_searchController.text);
      
    } catch (e) {
      
      // O LoadService lança uma Exception em caso de falha (erro na API ou conexão)
      MessageService.showError(e.toString().replaceFirst('Exception: ', ''));
      debugPrint('Erro ao deletar palete: $e');

    } finally {
      loadingService.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loadService = context.watch<LoadService>();
    final loadingService = context.read<LoadingService>();
    
    if (_isLoading) {
      _filteredPallets = loadService.loadPallets;
    } else {
      _filterPallets(_searchController.text);
    }

    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator(color: Colors.teal));
    } else if (_errorMessage != null) {
      content = Center(
          child: Text(_errorMessage!, style: const TextStyle(color: Colors.teal, fontSize: 16)));
    } else if (_filteredPallets.isEmpty && _searchController.text.isEmpty) {
      content = const Center(child: Text('Nenhum palete carregado.', style: TextStyle(color: Colors.black54)));
    } else if (_filteredPallets.isEmpty && _searchController.text.isNotEmpty) {
      content = const Center(child: Text('Nenhum palete encontrado com o filtro atual.', style: TextStyle(color: Colors.black54)));
    } else {
      content = ListView.separated(
        padding: const EdgeInsets.all(5),
        itemCount: _filteredPallets.length + 1,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.grey),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: Colors.teal.shade600,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(flex: 4, child: Text('N° PALETE',  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(flex: 3, child: Text('LOCAL',      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(flex: 2, child: Text('QTD.',       style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(flex: 4, child: Text('CARREGADO?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(flex: 2, child: Text(' ',          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                ],
              ),
            );
          }

          final palletData = _filteredPallets[index - 1];
          return Material(
            color: Colors.white,
            child: InkWell(
              onTap: () async {},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(flex: 4, child: Text('${palletData.palletId}', style: const TextStyle(color: Colors.black))),
                    Expanded(flex: 3, child: Text(palletData.palletLocation, style: const TextStyle(color: Colors.black))),
                    Expanded(flex: 2, child: Text(palletData.palletTotalQuantity.toString(), style: const TextStyle(color: Colors.black))),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        crossAxisAlignment: CrossAxisAlignment.center, 
                        children: [
                          Transform.scale(
                            scale: 1.8,
                            child: Checkbox(
                              value: palletData.carregado,
                              activeColor: Colors.teal,
                              checkColor: Colors.white,
                              side: const BorderSide(color: Colors.teal, width: 1.5),
                              fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                                if (states.contains(MaterialState.selected)) {
                                  return Colors.teal.shade600;
                                }
                                return Colors.teal.shade50;
                              }),
                              onChanged: null,
                              /*onChanged: (value) {
                                
                                setState(() {
                                  palletData.carregado = value ?? false;
                                });

                                loadingService.show();
                                _handlePalletAddition(carregado: palletData.carregado,pallet:palletData.palletId);
                                loadingService.hide();

                              },*/
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align( 
                        alignment: Alignment.centerLeft, // Alinha à esquerda e no centro vertical
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.redAccent,
                            size: 30,
                          ),
                          onPressed: () async {
                            final selectedLoadId = loadService.selectedLoadForEdit?.loadId;
                            if (selectedLoadId != null) {
                              await _deletePallet(selectedLoadId, palletData.palletId);
                            } else {
                              MessageService.showError('Erro: Carga selecionada não encontrada.');
                            }
                          },
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
    }

    final loadTitle;
    var titleColor = Colors.teal;
    final selectedLoad = loadService.selectedLoadForEdit;
    if (selectedLoad?.status == "Carga Finalizada")
    {
      loadTitle = 'Conferindo a Carga ${selectedLoad?.loadId}';
    }
    else if (selectedLoad?.status == "Carregando")
    {
      loadTitle = 'Montando a Carga ${selectedLoad?.loadId}';
    }
    else
    {
      loadTitle = '*Sem Carga Selecionada*';
      titleColor = Colors.red;
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
                      Icons.pallet,
                      size: 34,
                      color: titleColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loadTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                //onChanged: _filterPallets,
                onSubmitted: (value) {
                    FocusScope.of(context).unfocus();
                    if (value.isNotEmpty) {
                      try {
                        final palletNumber = int.parse(value);
                        _handlePalletAddition(pallet: palletNumber); 
                      } catch (e) {
                        MessageService.showError('Falha ao adicionar pallet.');
                      }
                    }
                  },
                decoration: InputDecoration(
                  hintText: 'Pesquisar',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PulseIconButton(
                        icon: Icons.qr_code_scanner_outlined,
                        color: Colors.black,
                        size: 44,
                        onPressed: () async => _scanBarcode(),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
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


/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/pallet_service.dart';
import 'package:oxdata/app/core/models/pallet_model.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/core/widgets/pulse_icon.dart';

class SearchReadyPalletsPage extends StatefulWidget {
  const SearchReadyPalletsPage({super.key});

  @override
  State<SearchReadyPalletsPage> createState() => _SearchAllPalletsPageState();
}

class _SearchAllPalletsPageState extends State<SearchReadyPalletsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<PalletModel> _filteredPallets = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchQueryChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
      _filterPallets(_searchQuery);
    });
  }

  // Função para mapear o status de código para o texto completo (Reutilizado da SearchPalletPage)
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

  // Função para carregar todos os pallets
  Future<void> _fetchInitialData() async {
    final palletService = context.read<PalletService>();
    final loadingService = context.read<LoadingService>();
    
    // Define uma duração mínima para o loading (como no seu código de exemplo)
    final start = DateTime.now();
    const minDuration = Duration(milliseconds: 700); 

    try {
      loadingService.show();
      
      // Chamada para buscar todos os pallets. 
      // Se não houver um método específico 'fetchAllPallets', usamos 'filtersPallets' com filtros nulos.
      // Assumindo que PalletService.filtersPallets com ambos parâmetros nulos/vazios retorna TUDO.
      await palletService.filtersPallets("MONTADO", "");
      loadingService.hide();

      _filterPallets(_searchController.text); // Filtra com texto vazio para carregar a lista completa

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
    
        _isLoading = false;
        _errorMessage = 'Erro ao carregar paletes: $e';
     
    } finally {
      final elapsed = DateTime.now().difference(start);
      if (elapsed < minDuration) {
        final remaining = minDuration - elapsed;
        await Future.delayed(remaining);
      }
      
    }
  }

  // Função para filtrar a lista na memória (similar a _getFilteredPallets)
  void _filterPallets(String query) {
    final allPallets = context.read<PalletService>().pallets;
    final normalizedQuery = query.toLowerCase().trim();

    setState(() {
      if (normalizedQuery.isEmpty) {
        _filteredPallets = allPallets;
      } else {
        _filteredPallets = allPallets.where((pallet) {
          final matchesId = pallet.palletId.toString().toLowerCase().contains(normalizedQuery);
          final matchesLocation = pallet.location.toLowerCase().contains(normalizedQuery);
          final matchesStatus = pallet.status.toLowerCase().contains(normalizedQuery) || 
                                _mapStatus(pallet.status).toLowerCase().contains(normalizedQuery);
          return matchesId || matchesLocation || matchesStatus;
        }).toList();
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
      _filterPallets(scanned);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palletService = context.watch<PalletService>();
    if (_isLoading) {
      _filteredPallets = palletService.pallets;
    } else {
      // Garantir que a lista filtrada reflita as últimas mudanças do service ao recarregar a tela
      _filterPallets(_searchController.text);
    }

    Widget content;

    if (_isLoading) {
      // COR: Substituída de redAccent para teal
      content = const Center(child: CircularProgressIndicator(color: Colors.teal));
    } else if (_errorMessage != null) {
      // COR: Substituída de redAccent para teal
      content = Center(
          child: Text(_errorMessage!,
              style: const TextStyle(color: Colors.teal, fontSize: 16)));
    } else if (_filteredPallets.isEmpty && _searchController.text.isEmpty) {
      content = const Center(
          child:
              Text('Nenhum palete carregado.', style: TextStyle(color: Colors.black54)));
    } else if (_filteredPallets.isEmpty && _searchController.text.isNotEmpty) {
      content = const Center(
          child: Text('Nenhum palete encontrado com o filtro atual.',
              style: TextStyle(color: Colors.black54)));
    } else {
      // Reutiliza a lógica de lista da SearchPalletPage
      content = ListView.separated(
        padding: const EdgeInsets.all(5),
        itemCount: _filteredPallets.length + 1, // +1 para o cabeçalho
        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.grey),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              // COR: Substituída de Colors.red.shade600 para Colors.teal.shade600
              color: Colors.teal.shade600, // Cor de destaque para o cabeçalho
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(flex: 2, child: Text('N° PALETE',  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(flex: 2, child: Text('LOCAL',      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(flex: 1, child: Text('QTD.',       style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(flex: 2, child: Text('CARREGADO?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                ],
              ),
            );
          }

          final palletData = _filteredPallets[index - 1];
          //final mappedStatus = _mapStatus(palletData.status);
          bool isCarregado = false;
          return Material(
            color: Colors.white,
            child: InkWell(
              onTap: () async {
                await Future.delayed(const Duration(milliseconds: 200));
                //Navigator.of(context).push(
                  //MaterialPageRoute(
                    //builder: (context) => PalletBuilderPage(pallet: palletData),
                  //),
                //).then((_) => _fetchInitialData()); // Recarrega os dados ao voltar
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text('${palletData.palletId}', style: const TextStyle(color: Colors.black)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(palletData.location, style: const TextStyle(color: Colors.black)),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(palletData.totalQuantity.toString(), style: const TextStyle(color: Colors.black)),
                    ),
                    // Novo item: checkbox "Carregado"
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Checkbox "Carregado"
                          Transform.scale (
                            scale: 1.5,
                            child: Checkbox(
                              value: palletData.carregado == 1,
                              onChanged: (value) {
                                setState(() {
                                  palletData.carregado = (value ?? false) ? 1 : 0;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 22,
                            ),
                            tooltip: 'Excluir palete',
                            onPressed: () {
                              // exclusão:
                              // _filteredPallets.remove(palletData);
                              // setState(() {});
                            },
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
    }

    return Scaffold(
      // COR: Substituída de Colors.red.shade50 para Colors.teal.shade50
      backgroundColor: Colors.teal.shade50, // Cor de fundo suave do tema
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  // ÍCONE: Ícone de inventário mantido, mas a cor de destaque alterada
                  Icon(Icons.pallet, size: 36, color: Colors.teal),
                  SizedBox(width: 15),
                  Text(
                    'Paletes Montados',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      // COR: Substituída de Colors.redAccent para Colors.teal
                      color: Colors.teal, 
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                // O filtro em tempo real (_onSearchQueryChanged) já está no listener
                // Mas a função de onChanged no TextField também chama _filterPallets no seu original.
                // Para manter a funcionalidade original (que já estava correta), usamos onChanged.
                onChanged: _filterPallets, 
                onSubmitted: (_) => FocusScope.of(context).unfocus(), // O filtro já é em tempo real, mas esconde o teclado
                decoration: InputDecoration(
                  hintText: 'Pesquisar',
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
                      // ÍCONE: Ícone de scanner de código de barras
                      PulseIconButton(
                        icon: Icons.qr_code_scanner_outlined,
                        color: Colors.black,
                        size: 44,
                        onPressed: () async {
                          await _scanBarcode();
                        },
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
                        // COR: Substituída de Colors.red.shade100.withOpacity(0.5) para Colors.teal.shade100.withOpacity(0.5)
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