import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/pallet_model.dart';
import 'package:oxdata/app/core/models/pallet_item_model.dart';
import 'package:oxdata/app/core/services/pallet_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:oxdata/app/core/utils/upper_case_text.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/widgets/image_picker.dart';
import 'package:oxdata/app/views/product/search_products_page.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';

class PalletBuilderPage extends StatefulWidget {
  final PalletModel? pallet;

  const PalletBuilderPage({super.key, this.pallet});

  @override
  State<PalletBuilderPage> createState() => _PalletBuilderPageState();
}

class _PalletBuilderPageState extends State<PalletBuilderPage> {
  final TextEditingController _palletIdController = TextEditingController();
  String? _statusController = "N"; // null inicialmente, ou 'I' valor padrão
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _productIdController = TextEditingController();
  final TextEditingController _quantityItemController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Lista de itens local para gerenciar a UI
  List<PalletItemModel> _items = [];
  bool _isLoading = false;
  String productName = "";
  //List<String> _imagePaths = []; 

  List<String> _imagePaths = [
    'PRODUTO_EMBALADO/OXFORD_PORCELANAS/FLAMINGO/FLAMINGO_WHITE/002679/PRODUTO/0001.jpeg',
    'PRODUTO_EMBALADO/OXFORD_PORCELANAS/RYO/MARESIA/103239/PRODUTO/0002.jpeg',
    'PRODUTO_EMBALADO/OXFORD_PORCELANAS/FLAMINGO/FLAMINGO_DIAMOND/002764/PRODUTO/002764.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final userId = await _storage.read(key: 'username');
    if (!mounted) return;

    setState(() {
      if (widget.pallet != null) {
        _palletIdController.text = widget.pallet!.palletId.toString();
        _statusController = widget.pallet!.status;
        _locationController.text = widget.pallet!.location;
        _userController.text = widget.pallet!.createdUser.toUpperCase(); 
        
        _loadPalletItems(); 

      } else {
        _statusController = 'N';
        if (userId != null) {
          _userController.text = userId.toString().toUpperCase();
        }
      }
    });
  }

  // ... (seu _initializeData e outros métodos)
  
  /// Adiciona um novo caminho de imagem à lista.
  void _addImage(String newImagePath) {
    // Nota: Em uma aplicação real, você faria o upload aqui
    // e receberia o URL final para adicionar à lista.
    // Por enquanto, apenas adicionamos o caminho.
    setState(() {
      _imagePaths.add(newImagePath);
      MessageService.showSuccess('Imagem adicionada: ${newImagePath.split('/').last}');
    });
  }

  /// Remove um caminho de imagem da lista.
  void _removeImage(String imagePath) {
    setState(() {
      _imagePaths.remove(imagePath);
      MessageService.showWarning('Imagem removida.');
    });
  }

  /// Carrega os itens do palete a partir do serviço.
  Future<void> _loadPalletItems() async {
    final loadingService = context.read<LoadingService>();
    final palletService = context.read<PalletService>();

    try {
      await CallAction.run(
        action: () async {
          loadingService.show();
          await palletService.fetchPalletItems(widget.pallet!.palletId);
          setState(() {
            _items = palletService.palletItems;
          });
        },
        onFinally: () {
          loadingService.hide();
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar itens do palete: $e')),
      );
    }
  }

  @override
  void dispose() {
    _palletIdController.dispose();
    _statusController = "I";
    _locationController.dispose();
    _productIdController.dispose();
    _quantityItemController.dispose();
    super.dispose();
  }

  /// Adiciona um novo item à lista local do palete.
  Future<void> _addItem() async {
    final username = await _storage.read(key: 'username');
    if (username == null || username.isEmpty) {
      MessageService.showError('Por favor, faça login para adicionar itens.');
      return;
    }
    if (_productIdController.text.isNotEmpty &&
        _quantityItemController.text.isNotEmpty &&
        username != "") {
      final newItem = PalletItemModel(
        palletId    : int.tryParse(_palletIdController.text) ?? 0,
        productId   : _productIdController.text,
        productName : productName,
        quantity    : int.tryParse(_quantityItemController.text) ?? 0,
        quantityReceived : int.tryParse(_quantityItemController.text) ?? 0,
        userId      : username,
        status      : 'PENDING',
      );

      setState(() {
        // Adiciona à lista local, a persistência ocorrerá no botão 'Salvar'
        _items.add(newItem);
      });

      // Limpa os campos após adicionar
      _productIdController.clear();
      _quantityItemController.clear();
      FocusScope.of(context).requestFocus(FocusNode());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos do item e verifique o login.')),
      );
    }
  }

  /// Salva o palete e seus itens.
  Future<void> _savePallet() async {
    final palletService = Provider.of<PalletService>(context, listen: false);
    //final userId = Provider.of<UserProvider>(context, listen: false).currentUserId;
    final userId = await _storage.read(key: 'username');

    if (_palletIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o número do palete.')),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não logado. Impossível salvar.')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final totalQuantity = _items.fold<int>(0, (sum, item) => sum + item.quantity);
      final palletId = int.parse(_palletIdController.text);

      final newPallet = PalletModel(
        palletId: palletId,
        totalQuantity: totalQuantity,
        status: _mapStatusToCode(_statusController.toString()),
        location: _locationController.text,
        createdUser: widget.pallet?.createdUser ?? userId,
        updatedUser: userId,
        createdAt: widget.pallet?.createdAt ?? DateTime.now(),
      );

      // Salva o palete e seus itens de uma vez
      await palletService.upsertPallets([newPallet]);
      if (_items.isNotEmpty) {
        // Envia todos os itens de uma vez para o serviço
        final itemsToSave = _items.map((item) => item.copyWith(palletId: palletId)).toList();
        await palletService.upsertPalletItems(itemsToSave);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Palete salvo com sucesso!')),
      );

      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar o palete: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Exclui o palete.
  Future<void> _deletePallet() async {
    if (widget.pallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não é possível excluir um palete que ainda não foi salvo.')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });
      final palletService = Provider.of<PalletService>(context, listen: false);
      await palletService.deletePallet(widget.pallet!.palletId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Palete excluído com sucesso!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir o palete: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Exclui um item da lista após confirmação.
  Future<void> _confirmAndDeleteItem(int index) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja remover este item?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        final palletService = Provider.of<PalletService>(context, listen: false);
        final itemToRemove = _items[index];

        // Se o item tem um ID, remove do backend. Se não, é um item novo e só remove localmente.
        if (itemToRemove.productId != null) {
          await palletService.deletePalletItem(itemToRemove.palletId, itemToRemove.productId!);
        }

        setState(() {
          _items.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removido com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover o item: $e')),
        );
      }
    }
  }

  void _updateQuantity(int index, String newValue) {
    setState(() {
      int quantity = int.tryParse(newValue) ?? 0;
      _items[index] = _items[index].copyWith(quantity: quantity);
    });
  }
  
  // Novo método para converter o texto completo de volta para o código
  String _mapStatusToCode(String status) {
    switch (status) {
      case ('I' || 'N'):
        return 'I';
      default:
        return status;
    }
  }

    // 1. Mapeia o código ('I', 'M', 'R') para o texto de exibição
  String _mapCodeToStatus(String code) {
    switch (code.toUpperCase()) {
      case 'I':
        return 'INICIADO';
      case 'M':
        return 'MONTADO';
      case 'R':
        return 'RECEBIDO';
      default:
        return 'NENHUM';
    }
  }

  // 2. Define as cores de fundo do Chip
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'INICIADO':
        return Colors.blue[100]!;
      case 'MONTADO':
        return Colors.amber[100]!;
      case 'RECEBIDO':
        return Colors.green[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  // 3. Define as cores do texto (e da borda) do Chip
  Color _getTextColor(String status) {
    switch (status.toUpperCase()) {
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

  Future<void> _openProductSearch(BuildContext context) async {
    final selectedProductData = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SearchProductsPage(shouldNavigate: false),
      ),
    );
    // Processa o retorno
    if (selectedProductData != null && selectedProductData is Map<String, dynamic>) {
      final productId = selectedProductData['productId'] as String?;
      productName = selectedProductData['productName']; 
      if (productId != null) {
        setState(() {
          _productIdController.text = productId;
        });
      }
    }
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

// ... (após _receivePallet)

  /// Altera o status do Pallet para 'M' (Montado) e salva.
  Future<void> _buildPallet() async {
    final palletService = Provider.of<PalletService>(context, listen: false);
    final userId = await _storage.read(key: 'username');

    if (userId == null) {
      MessageService.showError('Usuário não logado. Impossível concluir montagem.');
      return;
    }

    // Verifica se o Pallet tem um ID válido para ser "montado"
    final palletIdText = _palletIdController.text;
    if (palletIdText.isEmpty || int.tryParse(palletIdText) == 0) {
      MessageService.showError('O Pallet deve ser salvo antes de ser montado.');
      return;
    }
    
    if (_items.isEmpty) {
      MessageService.showWarning('O Pallet não tem itens. Adicione itens antes de concluir a montagem.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusController = 'M'; // Atualiza o status localmente para 'Montado'
    });

    try {
      final totalQuantity = _items.fold<int>(0, (sum, item) => sum + item.quantity);
      final palletId = int.parse(palletIdText);

      // 1. Cria o objeto Pallet com o novo status 'M'
      final updatedPallet = PalletModel(
        palletId: palletId,
        totalQuantity: totalQuantity,
        status: 'M', // Status Montado
        location: _locationController.text,
        createdUser: widget.pallet?.createdUser ?? userId,
        updatedUser: userId,
        createdAt: widget.pallet?.createdAt ?? DateTime.now(),
      );

      // 2. Chama o serviço para salvar (atualizar) o Pallet
      await palletService.upsertPallets([updatedPallet]);
      
      // 3. Opcional: Salva os itens também, caso haja alterações locais pendentes
      if (_items.isNotEmpty) {
        final itemsToSave = _items.map((item) => item.copyWith(palletId: palletId)).toList();
        await palletService.upsertPalletItems(itemsToSave);
      }
      
      MessageService.showSuccess('Montagem do Pallet concluída com sucesso!');
      // Volta para a tela anterior
      Navigator.of(context).pop();
    } catch (e) {
      MessageService.showError('Erro ao concluir a montagem do palete: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Exibe o diálogo de confirmação de montagem.
  Future<void> _showBuildConfirmationDialog() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Concluir Montagem'),
          content: const Text('Concluir a montagem do Pallet. Deseja continuar?'),
          actions: [
            TextButton(
              // Opção "Não"
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            TextButton(
              // Opção "Sim"
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim'),
            ),
          ],
        );
      },
    ) ?? false;

    // Se o usuário confirmar, chama o método para alterar o status
    if (confirm) {
      await _buildPallet();
    }
  }

  Future<void> _receivePallet() async {
    //final palletService = Provider.of<PalletService>(context, listen: false);
    final userId = await _storage.read(key: 'username');

    if (userId == null) {
      MessageService.showError('Usuário não logado. Impossível receber.');
      return;
    }

    /*setState(() {
      _isLoading = true;
      _statusController = 'R'; // Atualiza o status para 'Recebido'
    });*/

    try {
      final totalQuantity = _items.fold<int>(0, (sum, item) => sum + item.quantity);
      final palletId = int.parse(_palletIdController.text);

      final updatedPallet = PalletModel(
        palletId: palletId,
        totalQuantity: totalQuantity,
        status: 'R', // O status já foi atualizado localmente
        location: _locationController.text,
        createdUser: widget.pallet?.createdUser ?? userId,
        updatedUser: userId,
        createdAt: widget.pallet?.createdAt ?? DateTime.now(),
      );

      _navigateToPalletReceivePage(updatedPallet);
      //await palletService.upsertPallets([updatedPallet]);
      //MessageService.showSuccess('Palete recebido com sucesso!');
      //Navigator.of(context).pop();
    } catch (e) {
      MessageService.showError('Erro ao receber o palete: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToPalletReceivePage(PalletModel pallet) {
    // Navega para a página de recebimento, passando o PalletModel como argumento.
    Navigator.of(context).pushNamed(
      RouteGenerator.palletReceivePage,
      arguments: pallet,
    );
  }

  // 4. Constrói o Widget do Chip com largura e estilo fixos
  Widget _buildStatusChip(String statusCode) {
    // Mapeia o código ('I', 'M', 'R') para o texto completo (ex: INICIADO)
    final mappedStatus = _mapCodeToStatus(statusCode);
    
    // Obtém as cores baseadas no status completo
    final chipColor = _getStatusColor(mappedStatus);
    final textColor = _getTextColor(mappedStatus);

    return Container(
      // Define a largura MÍNIMA e MÁXIMA fixa (e igual) para uniformizar o chip.
      // O valor 90 é baseado no tamanho do texto "INICIADO" ou "RECEBIDO" com font size 14, mais o padding.
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 130,
        minHeight: 0,
        maxHeight: 25, // Limita a altura para um visual compacto
      ),
      
      // Remove o padding horizontal para que o Center use a largura fixa
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4), 
      
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center( // Centraliza o texto horizontalmente dentro do container de largura 90
        child: Text(
          mappedStatus,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1, // Ajuda a centralizar verticalmente
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // O conteúdo principal é um Column que divide o espaço verticalmente:
    // 1. Conteúdo Fixo do Topo (Pallet, Qtd, Imagem, Status, Campos, Formulário de Adição)
    // 2. Lista Rolável (ITENS)
    // 3. Conteúdo Fixo do Rodapé (Botões)
    return Scaffold(
      appBar: const AppBarCustom(title: 'Montagem do Palete'),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Column(
            // mainAxisSize.max garante que a coluna ocupe todo o espaço do body
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =========================================================
              // 1. CONTEÚDO FIXO DO TOPO (Informações e Formulário de Adição)
              // Foi removido o Expanded/ListView desnecessário para fixar esta parte.
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 3, 10, 5), // Ajuste de padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: _palletIdController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              isDense: true,
                              labelText: 'Número',
                              labelStyle: const TextStyle(fontSize: 14),
                              contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.qr_code_scanner_outlined,
                                  size: 38,
                                  color: Colors.indigo,
                                ),
                                onPressed: () async {
                                  String scanned = await _scanBarcode();
                                  if (scanned.isNotEmpty) {
                                    _palletIdController.text = scanned;
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Quantidade',
                                    style: TextStyle(fontSize: 13, height: 2)),
                                Text(
                                  _items.fold<int>(0, (sum, item) => sum + item.quantity).toString(),
                                  style: const TextStyle(
                                    fontSize: 46,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
/*
Expanded(
  child: Stack(
    children: [
      Container(
        width: double.infinity,
        height: 162,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1.0),
        ),
        child: widget.pallet?.imagePath != null
            ? Image.network(
                widget.pallet!.imagePath!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 162),
              )
            : const Icon(Icons.image_search_outlined,
                size: 162, color: Colors.grey),
      ),
      Positioned(
        top: 3,
        left: 3,
        child: GestureDetector(
          onTap: () {
            // Lógica para excluir nova foto
          },
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white70,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 28,
              color: Colors.red,
            ),
          ),
        ),
      ),
      Positioned(
        top: 3,
        right: 3,
        child: GestureDetector(
          onTap: () {
            // Lógica para adicionar foto
          },
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white70,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_a_photo,
              size: 28,
              color: Color.fromRGBO(56, 142, 60, 1),
            ),
          ),
        ),
      ),
    ],
  ),
),
*/
                        Expanded(
                          // Envolve o ImagesPicker em um Expanded se for parte de um Row com outros widgets 
                          // que precisam de largura definida (como o Container ao lado).
                          child: ImagesPicker(
                            imagePaths: _imagePaths,
                            onImageAdded: _addImage,
                            onImageRemoved: _removeImage,
                            itemHeight: 170,
                            itemWidth: 174,
                            iconSize: 28,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Label que simula o InputDecoration
                                  const Text(
                                    'Status',
                                    style: TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 0),
                                  Container(
                                  // Adiciona a borda do campo para manter o visual uniforme
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                  decoration: BoxDecoration(
                                    // border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: _statusController != null
                                    // Usa o seu chip de largura fixa e centralizado
                                      ? _buildStatusChip(_statusController!)
                                      : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _locationController,
                              // Adiciona a formatação para forçar maiúsculas
                                textCapitalization: TextCapitalization.characters,
                                inputFormatters: [
                                  UpperCaseTextFormatter(),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Local',
                                  labelStyle: TextStyle(fontSize: 14),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _userController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Usuário',
                                  labelStyle: TextStyle(fontSize: 14),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (_statusController != 'M' && _statusController != 'R')
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _productIdController,
                              decoration: InputDecoration(
                                labelText: 'Produto',
                                labelStyle: const TextStyle(fontSize: 14),
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.search,
                                      size: 32, color: Colors.indigo),
                                  onPressed: () async {
                                    // Lógica para abrir a página de pesquisa e esperar o resultado
                                    await _openProductSearch(context); 
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _quantityItemController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Quantidade',
                                labelStyle: TextStyle(fontSize: 14),
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                              ),
                              onSubmitted: (value) => _addItem(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_box,
                                color: Colors.indigo, size: 60),
                            onPressed: _addItem,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              // Título ITENS (também Fixo)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0),
                    ),
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade200],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'ITENS',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              // =========================================================
              // 2. LISTA DE ITENS (CONTEÚDO ROLANTE)
              // O Expanded garante que esta seção use o espaço restante.
              Expanded(
                child: Container(
                  color: Colors.grey.shade200, // <- cor de fundo do ListView
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(3, 3, 6, 0),
                    children: [
                      ..._items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.20),
                                spreadRadius: 2,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Text(
                                        '${item.productName}',
                                        style: const TextStyle( // Use 'const' se o item.productName for estático
                                            fontWeight: FontWeight.bold, fontSize: 16),
                                        softWrap: false, // Força o texto a ficar em uma única linha
                                      ),
                                    ),
                                    const SizedBox(height: 4),
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    // Este Text é exibido SEMPRE, pois está fora da condição 'if'.
    Text(
      'CÓD: ${item.productId}',
      style: const TextStyle(
          fontSize: 14, color: Colors.grey),
    ),
        
    // O bloco a seguir (QTD e TextField) só é exibido se a condição for verdadeira.
    if (_statusController == "R") ...[
      const SizedBox(width: 10), 
      const Text(
        'Qtd.:',
        style: TextStyle(fontSize: 14),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 50,
        child: TextField(
          readOnly: true,
          controller: TextEditingController(
              text: item.quantity.toString()),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
          ),
        ),
      ),
      const SizedBox(width: 10), 
      const Text(
        'QTD Recebida:',
        style: TextStyle(fontSize: 14),
      ),
      const SizedBox(width: 8),
  Container(
    width: 50,
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Espaçamento para o estilo chip
    decoration: BoxDecoration(
      // Se as quantidades forem diferentes, usa vermelho claro; senão, usa transparente.
      color: item.quantity != item.quantityReceived
          ? Colors.red.withOpacity(0.15) // Vermelho claro (estilo chip)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(4), // Bordas arredondadas (estilo chip)
    ),
    child: SizedBox(
      width: 50, // O widget filho do Container deve ter o mesmo width
      child: TextField(
        readOnly: true,
        controller: TextEditingController(
            text: item.quantityReceived.toString()),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        // É bom garantir que o texto dentro do TextField não tenha a cor do fundo:
        style: TextStyle(
          color: item.quantity != item.quantityReceived
              ? Colors.red.shade900 // Texto um pouco mais escuro para destaque
              : null, // Cor padrão
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
        ),
      ),
    ),
  ),
    ] else ...[
      const SizedBox(width: 10), 
      const Text(
        'QTD:',
        style: TextStyle(fontSize: 14),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 50,
        child: TextField(
          controller: TextEditingController(
              text: item.quantity.toString()),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
          ),
          onSubmitted: (value) {
            _updateQuantity(index, value);
            FocusScope.of(context).unfocus();
          },
        ),
      ),
    ],
  ],
)
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.red, size: 30),
                                onPressed: () => _confirmAndDeleteItem(index),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              
              // =========================================================
              // 3. CONTEÚDO FIXO DO RODAPÉ (Botões)
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(8, 0, 10, 1),
                  child: Row(
                    children: [
                      if (widget.pallet != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _deletePallet,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                            icon: const Icon(Icons.delete, size: 24),
                            label: const Text('EXCLUIR'),
                          ),
                        ),
                      if (widget.pallet != null) const SizedBox(width: 16),
                      if (_statusController == 'M')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _receivePallet,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                            icon: const Icon(Icons.pallet, size: 24),
                            label: const Text('RECEBER'),
                          ),
                        )
                      else if (_statusController != 'R')...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _savePallet,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                            icon: const Icon(Icons.save, size: 24),
                            label: const Text('SALVAR'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showBuildConfirmationDialog,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                              ),
                              icon: const Icon(Icons.pallet, size: 24),
                              label: const Text('MONTAR'),
                            ),
                        ),
                        
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          /*if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),*/
        ],
      ),
    );
  }

}
