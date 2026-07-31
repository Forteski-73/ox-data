import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oxdata/app/core/services/ftp_service.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/pallet_model.dart';
import 'package:oxdata/app/core/models/pallet_item_model.dart';
import 'package:oxdata/app/core/services/pallet_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/image_cache_service.dart';
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
import 'package:oxdata/app/views/pallet/pallet_receive_page.dart';
import 'package:oxdata/app/core/widgets/app_confirm_dialog.dart';
import 'package:oxdata/app/core/widgets/delete_confirm_dialog.dart';

// ---------------------------------------------------------------------------
// Constantes de design (mesmo padrão de InventoryItemPage)
// ---------------------------------------------------------------------------

const Color _primaryColor    = Color(0xFF3F51B5);
const Color _defaultBtnColor = Color(0xFFE3F2FD);
const Color _darkBtnColor    = Color.fromARGB(255, 187, 211, 251);
const Color _fieldFillColor  = Color(0xFFF8FAFC);
const Color _fieldBorderColor = Color(0xFFE2E8F0);
const Color _lockedFillColor  = Color(0xFFEEF2FF);

/// Decoração padrão de campo de texto, igual à usada em InventoryItemPage.
InputDecoration buildFieldDecoration(
  String label, {
  bool readOnly = false,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText:  label,
    labelStyle: const TextStyle(fontSize: 14),
    filled:     true,
    fillColor:  readOnly ? _lockedFillColor : _fieldFillColor,
    isDense:    true,
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    suffixIcon: suffixIcon,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide:   BorderSide(color: _fieldBorderColor, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide:   const BorderSide(color: Colors.indigo),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide:   BorderSide.none,
    ),
  );
}

/// Cabeçalho de seção padronizado (ícone + título em indigo).
Widget buildSectionHeader(String title) {
  return Row(
    children: [
      const Icon(Icons.dashboard_customize, size: 20, color: _primaryColor),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// PalletBuilderPage
// ---------------------------------------------------------------------------

class PalletBuilderPage extends StatefulWidget {
  final PalletModel? pallet;

  const PalletBuilderPage({super.key, this.pallet});

  @override
  State<PalletBuilderPage> createState() => _PalletBuilderPageState();
}

class _PalletBuilderPageState extends State<PalletBuilderPage> {
  final TextEditingController _palletIdController     = TextEditingController();
  final TextEditingController _itemSearchController   = TextEditingController();
  String?                     _statusController       = "N"; 
  final TextEditingController _locationController     = TextEditingController();
  final TextEditingController _userController         = TextEditingController();
  final TextEditingController _productIdController    = TextEditingController();
  final TextEditingController _palletDestController   = TextEditingController();
  final TextEditingController _quantityItemController = TextEditingController();
  final FlutterSecureStorage  _storage                = const FlutterSecureStorage();

  // Lista de itens local para gerenciar a UI
  //List<PalletItemModel> _items = [];
  String productName = "";
  //bool _isLoading = false;
  int? _activePalletId;
  late PalletService _palletService; 

  @override
  void initState() {
    super.initState();
    
    // Pega o serviço apenas uma vez
    _palletService = context.read<PalletService>();

    // Inicializa os dados depois que o frame estiver pronto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final userId = await _storage.read(key: 'username');
    if (!mounted) return;

    setState(() {
      if (widget.pallet != null) {
        _palletIdController.text    = widget.pallet!.palletId.toString();
        _palletDestController.text  = widget.pallet!.palletDestination.toString();
        _statusController           = widget.pallet!.status;
        _locationController.text    = widget.pallet!.location;
        _userController.text        = widget.pallet!.createdUser.toUpperCase(); 
        _activePalletId             = widget.pallet!.palletId;

        _loadPalletItems(); 

      } else {
        _palletService.clearPallets();
        _palletService.clearPalletsItems();
        _statusController = 'N';
        if (userId != null) {
          _userController.text = userId.toString().toUpperCase();
        }
      }
    });
  }

  /// Remove um caminho de imagem da lista, via Provider.
  void _removeImage(String imagePath) {
    final imageCacheService = context.read<ImageCacheService>();
    imageCacheService.removeImageByPath(imagePath);
    MessageService.showWarning('Imagem removida.');
  }

  /// Carrega os itens do palete a partir do serviço.
  Future<void> _loadPalletItems() async {
    final loadingService = context.read<LoadingService>();
    //final palletService = context.read<PalletService>();
    
    try {
      await CallAction.run(
        action: () async {
          loadingService.show();
          await _palletService.fetchPalletItems(widget.pallet!.palletId);
          /*setState(() {
            _items = palletService.palletItems;
          });*/
          
          //await _getPalletImages(widget.pallet!.palletId);

        },
        onFinally: () {
          loadingService.hide();
        },
      );
    } catch (e) {
      MessageService.showError('Erro ao carregar itens do palete: $e');
    }
  }

  @override
  void dispose() {
    _palletIdController.dispose();
    _statusController = "I";
    _locationController.dispose();
    _productIdController.dispose();
    _palletDestController.dispose();
    _quantityItemController.dispose();
    super.dispose();
  }

  void _setPalletIdFromInput(String? value) {
    if (!mounted) return;

    // Remove tudo que não for número
    final numericString = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';

    // Limita a 10 caracteres
    final limitedNumericString = numericString.length > 8
        ? numericString.substring(0, 8)
        : numericString;

    final id = int.tryParse(limitedNumericString);

    _palletIdController.text = limitedNumericString.toString();
    if (id != null && id > 0 && id != _activePalletId) {
      setState(() {
        _activePalletId = id;
      });
    } else if ((id == null || numericString!.isEmpty) && _activePalletId != null) {
      setState(() {
        _activePalletId = null;
      });
    }
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
        _palletDestController.text.isNotEmpty &&
        username != "") {
      final newItem = PalletItemModel(
        palletId          : int.tryParse(_palletIdController.text) ?? 0,
        productId         : _productIdController.text,
        productName       : productName,
        quantity          : int.tryParse(_quantityItemController.text) ?? 0,
        quantityReceived  : int.tryParse(_quantityItemController.text) ?? 0,
        userId            : username,
        status            : 'I',
      );
      
      _palletService.addItemLocally(newItem);

      // Limpa os campos após adicionar
      _productIdController.clear();
      _quantityItemController.clear();
      FocusScope.of(context).requestFocus(FocusNode());
    } else {
      MessageService.showWarning('Por favor, preencha todos os campos do item.');
    }
  }

  /// Salva o palete e seus itens.
  Future<void> _savePallet() async {
    //final palletService = Provider.of<PalletService>(context, listen: false);
    final userId = await _storage.read(key: 'username');

    if (_palletIdController.text.isEmpty) {
      MessageService.showWarning('Informe o número do palete.');
      return;
    }

    if (_palletDestController.text.isEmpty) {
      MessageService.showWarning('Informe o destino do palete.');
      return;
    }

    if (userId == null) {
      MessageService.showError('Usuário não logado. Impossível salvar.');
      return;
    }

    try {

      final List<PalletItemModel> _items = _palletService.palletItems; 
      final totalQuantity = _items.fold<int>(0, (sum, item) => sum + item.quantity);
      final palletId = int.parse(_palletIdController.text);

      final newPallet = PalletModel (
        palletId:           palletId,
        palletDestination:  _palletDestController.text,
        totalQuantity:      totalQuantity,
        status:             _mapStatusToCode(_statusController.toString()),
        location:           _locationController.text,
        createdUser:        widget.pallet?.createdUser ?? userId,
        updatedUser:        userId,
        createdAt:          widget.pallet?.createdAt ?? DateTime.now(),
      );

      final imageCacheService = context.read<ImageCacheService>();
      final loadingService = context.read<LoadingService>();
      loadingService.show();
      // Salva o palete e seus itens
      await _palletService.upsertPallets([newPallet], imageCacheService.imagePaths);

      if (_items.isNotEmpty) {
        // Envia todos os itens de uma vez para o serviço
        final itemsToSave = _items.map((item) => item.copyWith(palletId: palletId)).toList();
        await _palletService.upsertPalletItems(itemsToSave);
      }

      final FtpService ftpService = context.read<FtpService>();

      if (imageCacheService.cachedImages.isNotEmpty) {
        final response = await ftpService.setImagesBase64(imageCacheService.cachedImages);
        if (response.success && response.data != null) {
          MessageService.showSuccess('Palete salvo com sucesso!');
        }
        else
        {
          MessageService.showError('Erro ao salvar o palete: ${response.message}}');
        }
      }
      loadingService.hide();
      
      MessageService.showSuccess('Palete salvo com sucesso!');

      Navigator.of(context).pop(true);

    } catch (e) {
      MessageService.showError('Erro ao salvar o palete: $e');
    } finally {
      /*setState(() {
        _isLoading = false;
      });*/
    }
  }


  /// Exibe o diálogo de confirmação antes de excluir o palete.
  Future<void> _showConfirmDeletePallet() async {
    final palletId = widget.pallet?.palletId;
    await showConfirmDelete(
      context: context,
      title: 'Excluir Palete',
      message: 'Tem certeza que deseja excluir o palete $palletId?',
      onConfirm: _deletePallet,
    );
  }

  /// Exclui o palete.
  Future<void> _deletePallet() async {
    if (widget.pallet == null) {
      MessageService.showWarning('Não é possível excluir um palete que ainda não foi salvo.');
      return;
    }

    try {
      /*setState(() {
        _isLoading = true;
      });*/
      //final palletService = Provider.of<PalletService>(context, listen: false);
      await _palletService.deletePallet(widget.pallet!.palletId);

      MessageService.showSuccess('Palete excluído com sucesso!');

      Navigator.of(context).pop();
    } catch (e) {
      MessageService.showError('Erro ao excluir o palete: $e');
    } finally {

    }
  }


  /// Exibe o diálogo de confirmação antes de excluir o item do palete.
  Future<void> _showConfirmDeletePalletItem(int index) async {
    final List<PalletItemModel> items = _palletService.palletItems;

    await showConfirmDelete(
      context: context,
      title: 'Excluir Item do Palete',
      message: 'Tem certeza que deseja remover ${items[index].productId} deste palete?',
      onConfirm: () => _deletePalletItem(items[index]),
    );
  }

  /// Exclui um item da lista após confirmação.
  Future<void> _deletePalletItem(PalletItemModel itemToRemove) async {
    final List<PalletItemModel> items = _palletService.palletItems;

    try {
      // Se o item tem um ID, remove do backend. Se não, é um item novo e só remove localmente.
      if (itemToRemove.productId != "") {
        await _palletService.deletePalletItem(itemToRemove.palletId, itemToRemove.productId!);
      }

      setState(() {
        items.remove(itemToRemove);
      });

      MessageService.showSuccess('Item removido com sucesso!');
    } catch (e) {
      MessageService.showError('Erro ao remover o item: $e');
    }
  }

  /*

  void _updateQuantity(int index, String newValue) {
    final List<PalletItemModel> _items = _palletService.palletItems; 
    setState(() {
      int quantity = int.tryParse(newValue) ?? 0;
      _items[index] = _items[index].copyWith(quantity: quantity);
    });
  }

  */
  
  // Converter o texto completo de volta para o código
  String _mapStatusToCode(String status) {
    switch (status) {
      case ('I' || 'N'):
        return 'I';
      default:
        return status;
    }
  }

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

  // Define as cores de fundo do Chip
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

  // Define as cores do texto (e da borda) do Chip
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
    if (selectedProductData != null && selectedProductData is Map<String, dynamic>) {
      final productId = selectedProductData['productId'] as String?;
      productName = selectedProductData['productName']; 
      if (productId != null) {
        //setState(() {
          _productIdController.text = productId;
        //});
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

  /// Altera o status do Pallet para 'M' (Montado) e salva.
  Future<void> _buildPallet() async {
    final imageCacheService = context.read<ImageCacheService>();
    //final palletService = Provider.of<PalletService>(context, listen: false);
    final userId = await _storage.read(key: 'username');
    final List<PalletItemModel> _items = _palletService.palletItems; 

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
      //_isLoading = true;
      _statusController = 'M';
    });

    try {
      final totalQuantity = _items.fold<int>(0, (sum, item) => sum + item.quantity);
      final palletId = int.parse(palletIdText);

      final updatedPallet = PalletModel(
        palletId: palletId,
        palletDestination: _palletDestController.text,
        totalQuantity: totalQuantity,
        status: 'M', // Status Montado
        location: _locationController.text,
        createdUser: widget.pallet?.createdUser ?? userId,
        updatedUser: userId,
        createdAt: widget.pallet?.createdAt ?? DateTime.now(),
      );

      // Chama o serviço para salvar (atualizar) o Pallet
      await _palletService.upsertPallets([updatedPallet], imageCacheService.imagePaths);
      
      // Salva os itens também, caso haja alterações locais pendentes
      if (_items.isNotEmpty) {
        final itemsToSave = _items.map((item) => item.copyWith(palletId: palletId)).toList();
        await _palletService.upsertPalletItems(itemsToSave);
      }
      
      MessageService.showSuccess('Montagem do Pallet concluída com sucesso!');

      //final imageCacheService = context.read<ImageCacheService>();
      final FtpService ftpService = context.read<FtpService>();

      if (imageCacheService.cachedImages.isNotEmpty) {
        //loadingService.show();

        await _palletService.upsertPalletImages(widget.pallet!.palletId,imageCacheService.imagePaths);

        final response = await ftpService.setImagesBase64(imageCacheService.cachedImages);
        //loadingService.hide();
        if (response.success && response.data != null) {
        }
        else
        {
          MessageService.showError('Erro ao salvar: ${response.message}}');
        }
      }

      Navigator.of(context).pop();
    } catch (e) {
      MessageService.showError('Erro ao concluir a montagem do palete: $e');
    } finally {
      /*setState(() {
        _isLoading = false;
      });*/
    }
  }
  
    /// Altera o status do Pallet para 'I' (Inicializado) e salva.
  Future<void> _editPallet() async {
    //final palletService = Provider.of<PalletService>(context, listen: false);
    final userId = await _storage.read(key: 'username');
    final List<PalletItemModel> _items = _palletService.palletItems;  

    if (userId == null) {
      MessageService.showError('Usuário não logado. Impossível concluir ação.');
      return;
    }

    setState(() {
      //_isLoading = true;
      _statusController = 'I';
    });

    try {

      final int? palletId = widget.pallet?.palletId;

      if (palletId != null) {
        // Chama o serviço para salvar (atualizar) o Pallet
        await _palletService.updatePalletStatus(palletId, "I");
        
        // Salva os itens também, caso haja alterações locais pendentes
        if (_items.isNotEmpty) {
          final itemsToSave = _items.map((item) => item.copyWith(palletId: widget.pallet?.palletId)).toList();
          await _palletService.upsertPalletItems(itemsToSave);
        }
        
        MessageService.showSuccess('Pallet reaberto com sucesso!');
      }

      Navigator.of(context).pop();

    } catch (e) {
      MessageService.showError('Erro ao reabrir o palete: $e');
    } finally {
      /*setState(() {
        _isLoading = false;
      });*/
    }
  }

  /// Exibe o diálogo de confirmação de montagem.
  Future<void> _showBuildConfirmationDialog() async {
    final confirm = await showConfirmDialog(
      context: context,
      message: 'Concluir a montagem do Pallet. Deseja continuar?',
    );

    if (confirm) {
      await _buildPallet();
    }
  }

    /// Exibe o diálogo de confirmação de montagem.
  Future<void> _showEditConfirmationDialog() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          title: const Text('Editar Palete', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
          content: const Text('O Palete será reaberto para edição. Deseja continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim', style: TextStyle(color: _primaryColor)),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      await _editPallet();
    }
  }

  Future<void> _receivePallet() async {
    final userId = await _storage.read(key: 'username');
    final List<PalletItemModel> _items = _palletService.palletItems;  
    if (userId == null) {
      MessageService.showError('Usuário não logado. Impossível receber.');
      return;
    }

    try {
      final totalQuantity = _items.fold<int>(0, (sum, item) => sum + item.quantity);
      final palletId = int.parse(_palletIdController.text);

      final updatedPallet = PalletModel(
        palletId: palletId,
        palletDestination: _palletDestController.text,
        totalQuantity: totalQuantity,
        status: 'R',
        location: _locationController.text,
        createdUser: widget.pallet?.createdUser ?? userId,
        updatedUser: userId,
        createdAt: widget.pallet?.createdAt ?? DateTime.now(),
      );

      final loadingService = context.read<LoadingService>();

      final imageCacheService = context.read<ImageCacheService>();
      final FtpService ftpService = context.read<FtpService>();

      if (imageCacheService.cachedImages.isNotEmpty) {
        loadingService.show();

        await _palletService.upsertPalletImages(palletId,imageCacheService.imagePaths);

        final response = await ftpService.setImagesBase64(imageCacheService.cachedImages);
        loadingService.hide();
        if (response.success && response.data != null) {
          _navigateToPalletReceivePage(updatedPallet);
        }
        else
        {
          MessageService.showError('Erro ao atualizar o palete: ${response.message}}');
        }
      }

    } catch (e) {
      MessageService.showError('Erro ao receber o palete: $e');
    } finally {
      /*setState(() {
        _isLoading = false;
      });*/
    }
  }

  void _navigateToPalletReceivePage(PalletModel pallet) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PalletReceivePage(pallet: pallet),
      ),
    );
    
  }

  // Constrói o Widget do Chip com largura e estilo fixos
  Widget _buildStatusChip(String statusCode) {
    // Mapeia o código ('I', 'M', 'R') para o texto completo
    final mappedStatus = _mapCodeToStatus(statusCode);
    
    // Obtém as cores baseadas no status completo
    final chipColor = _getStatusColor(mappedStatus);
    final textColor = _getTextColor(mappedStatus);

    return Container(
      // Define a largura MÍNIMA e MÁXIMA fixa (e igual) para uniformizar o chip.
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 130,
        minHeight: 0,
        maxHeight: 25,
      ),
      
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 1), 
      
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          mappedStatus,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //final palletService = context.watch<PalletService>();

    return Scaffold(
      appBar: const AppBarCustom(title: 'Montagem do Palete'),
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ================= CONTEÚDO FIXO DO TOPO =================
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    buildSectionHeader("DESTINO DO PALETE"),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _palletDestController,
                            inputFormatters: [UpperCaseTextFormatter()],
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            decoration: buildFieldDecoration('Destino'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    buildSectionHeader("IDENTIFICAÇÃO"),
                    const SizedBox(height: 6),

                    // Linha de Pallet ID + Quantidade (banner indigo)
                    PalletIdAndQuantity(
                      palletIdController: _palletIdController,
                      scanBarcode: _scanBarcode,
                      onPalletIdChanged: _setPalletIdFromInput,
                    ),

                    const SizedBox(height: 10),

                    // Linha de imagens do pallet + status/local/usuário
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_activePalletId != null)
                          Expanded(
                            child: _PalletImagesSection(
                              palletId: widget.pallet?.palletId,
                              onImageRemoved: _removeImage,
                            ),
                          )
                        else
                          Expanded(
                            child: Container(
                              height: 170,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: _fieldBorderColor, width: 1.5),
                                borderRadius: BorderRadius.circular(4),
                                color: _fieldFillColor,
                              ),
                              child: Icon(
                                Icons.camera_alt_outlined,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            children: [
                              // Status
                              Column(
                               crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Status',
                                    style: TextStyle(fontSize: 14, color: Colors.black38),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: _statusController != null
                                        ? _buildStatusChip(_statusController!)
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Local
                              TextField(
                                controller: _locationController,
                                textCapitalization: TextCapitalization.characters,
                                inputFormatters: [UpperCaseTextFormatter()],
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                decoration: buildFieldDecoration('Local'),
                              ),
                              const SizedBox(height: 8),

                              // Usuário
                              TextField(
                                controller: _userController,
                                readOnly: true,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.indigo.shade700,
                                ),
                                decoration: buildFieldDecoration('Usuário', readOnly: true),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Linha de adicionar item (produto + qtd + botão)
                    if (_statusController != 'M' && _statusController != 'R') ...[
                      const SizedBox(height: 10),
                      buildSectionHeader("ADICIONAR ITEM"),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _productIdController,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              decoration: buildFieldDecoration('Produto'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ColorChangingButton(
                            icon: Icons.qr_code_scanner_outlined,
                            onPressed: () async {
                              final scanned = await _scanBarcode();
                              if (scanned.isNotEmpty) {
                                setState(() => _productIdController.text = scanned);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _ColorChangingButton(
                            icon: Icons.search,
                            onPressed: () async {
                              await _openProductSearch(context);
                              if (mounted) setState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _quantityItemController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              decoration: buildFieldDecoration('Quantidade'),
                              onSubmitted: (value) => _addItem(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ColorChangingButton(
                            icon: Icons.add_outlined,
                            disabled: _palletIdController.text.trim().isEmpty,
                            onPressed: () {
                              if (_palletIdController.text.trim().isNotEmpty) {
                                _addItem();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // ================= CAMPO DE PESQUISA =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildSectionHeader('ITENS'),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: TextField(
                          controller: _itemSearchController,
                          style: const TextStyle(fontSize: 14),
                          decoration: buildFieldDecoration('Pesquisar').copyWith(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            suffixIcon: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.qr_code_scanner_outlined, size: 22, color: _primaryColor),
                              onPressed: () async {
                                String scanned = await _scanBarcode();
                                if (scanned.isNotEmpty) {
                                  _itemSearchController.text = scanned;
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ================= LISTA DE ITENS FILTRADOS =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ValueListenableBuilder(
                  valueListenable: _itemSearchController,
                  builder: (context, _, __) => ItemList(
                    searchController: _itemSearchController,
                    onDeleteItem: (item) async {
                      final index = _palletService.palletItems.indexOf(item);
                      if (index != -1) {
                        await _showConfirmDeletePalletItem(index);
                      }
                    },
                    onUpdateQuantity: (item, newQuantity) {
                      final index = _palletService.palletItems.indexOf(item);
                      if (index != -1) {
                        _palletService.updateItemQuantity(index, newQuantity);
                        //_updateQuantity(index, newQuantity.toString());
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -1),
            ),
          ],
          border: const Border(
            top: BorderSide(color: _fieldBorderColor),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (widget.pallet != null)
              _toolbarButton(
                label: 'Excluir',
                icon: Icons.delete_forever_rounded,
                color: Colors.red.shade600,
                onPressed: _showConfirmDeletePallet,
              ),

            if (_statusController == 'M') ...[
              _toolbarButton(
                label: 'Editar',
                icon: Icons.edit_note_rounded,
                color: _primaryColor,
                onPressed: _showEditConfirmationDialog,
              ),
              _toolbarButton(
                label: 'Receber',
                icon: Icons.inventory_2_rounded,
                color: Colors.green.shade700,
                onPressed: _receivePallet,
              ),
            ] else if (_statusController != 'R') ...[
              _toolbarButton(
                label: 'Salvar',
                icon: Icons.save_rounded,
                color: _primaryColor,
                onPressed: _palletIdController.text.trim().isNotEmpty
                    ? _savePallet
                    : null,
              ),
              _toolbarButton(
                label: 'Montar',
                icon: Icons.pallet,
                color: Colors.green.shade700,
                onPressed: _palletIdController.text.trim().isNotEmpty
                  ? () {
                      if (widget.pallet != null) {
                        _showBuildConfirmationDialog();
                      } else {
                        _statusController = "M";
                        _savePallet();
                      }
                    }
                  : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Botão estilizado para toolbar (mesmo raio de borda / paleta do padrão indigo)
  Widget _toolbarButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final isDisabled = onPressed == null;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: isDisabled ? Colors.grey.shade300 : color,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          ),
          icon: Icon(icon, size: 22),
          label: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }


}

// ---------------------------------------------------------------------------
// ItemList
// ---------------------------------------------------------------------------

class ItemList extends StatelessWidget {
  final TextEditingController searchController;
  final void Function(PalletItemModel item) onDeleteItem;
  final void Function(PalletItemModel item, int newQuantity) onUpdateQuantity;

  const ItemList({
    super.key,
    required this.searchController,
    required this.onDeleteItem,
    required this.onUpdateQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final palletService = context.watch<PalletService>();

    final items = searchController.text.isEmpty
        ? palletService.palletItems
        : palletService.palletItems.where((item) {
            final query = searchController.text.toLowerCase();
            final nameMatch = item.productName!.toLowerCase().contains(query);
            final idMatch = item.productId.toLowerCase().contains(query);
            return nameMatch || idMatch;
          }).toList();

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Text(
          'Nenhum item adicionado.',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final quantityController = TextEditingController(text: item.quantity.toString());

        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _fieldBorderColor),
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
                        item.productName ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        softWrap: false,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('CÓD: ${item.productId}',
                            style: const TextStyle(fontSize: 13, color: _primaryColor, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 10),
                        const Text('QTD:', style: TextStyle(fontSize: 13, color: Colors.black87)),
                        const SizedBox(width: 6),
                        Container(
                          width: 54,
                          decoration: BoxDecoration(
                            color: _fieldFillColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _fieldBorderColor),
                          ),
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (value) => onUpdateQuantity(item, int.tryParse(value) ?? 0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: Colors.red.shade400, size: 26),
                onPressed: () => onDeleteItem(item),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// PalletIdAndQuantity — banner indigo, mesmo padrão de _buildTotalHeader
// ---------------------------------------------------------------------------

class PalletIdAndQuantity extends StatelessWidget {
  final TextEditingController palletIdController;
  final Future<String> Function() scanBarcode;
  final void Function(String) onPalletIdChanged;

  const PalletIdAndQuantity({
    super.key,
    required this.palletIdController,
    required this.scanBarcode,
    required this.onPalletIdChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Usa o Provider para ler os itens e calcular o total
    final palletService = context.watch<PalletService>();
    final totalQuantity = palletService.palletItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: TextField(
            controller: palletIdController,
            keyboardType: TextInputType.number,
            onChanged: onPalletIdChanged,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: buildFieldDecoration('Número'),
          ),
        ),
        const SizedBox(width: 8),
        _ColorChangingButton(
          icon: Icons.qr_code_scanner_outlined,
          onPressed: () async {
            String scanned = await scanBarcode();
            if (scanned.isNotEmpty) {
              palletIdController.text = scanned;
              onPalletIdChanged(scanned);
            }
          },
        ),
        const SizedBox(width: 8),
        // Banner indigo com o total, no mesmo padrão de _buildTotalHeader (InventoryItemPage)
        Expanded(
          flex: 4,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'QUANTIDADE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  totalQuantity.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Separado para não depender do setState do pai
/// ai não fica piscando atoa quando adiciona itens
class _PalletImagesSection extends StatelessWidget {
  final int? palletId;
  final Function(String) onImageRemoved;

  const _PalletImagesSection({
    required this.palletId,
    required this.onImageRemoved,
  });

  @override
  Widget build(BuildContext context) {
    // Apenas este widget observa (watch) do ImageCacheService.
    final imageCacheService = context.watch<ImageCacheService>();
    final List<String> currentImagePaths = imageCacheService.imagePaths;

    return ImagesPicker(
      imagePaths: currentImagePaths,
      baseImagePath: "MONTAGEM_PALETE/",
      codePallet: palletId,
      onImageRemoved: onImageRemoved,
      onImagesChanged: (newPaths) {
        // A lógica de setState aqui não afeta a tela Pai
      },
      itemHeight: 174,
      itemWidth: 178,
      iconSize: 28,
    );
  }
}

// ---------------------------------------------------------------------------
// _ColorChangingButton — mesmo componente de ação usado em InventoryItemPage
// ---------------------------------------------------------------------------

class _ColorChangingButton extends StatefulWidget {
  final IconData       icon;
  final VoidCallback?  onPressed;
  final bool           blink;
  final bool           disabled;

  const _ColorChangingButton({
    required this.icon,
    this.onPressed,
    this.blink = false,
    this.disabled = false,
  });

  @override
  State<_ColorChangingButton> createState() => _ColorChangingButtonState();
}

class _ColorChangingButtonState extends State<_ColorChangingButton> {
  Color  _bgColor    = _defaultBtnColor;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.disabled || widget.onPressed == null;
    return GestureDetector(
      onTap:     disabled ? null : widget.onPressed,
      onTapDown: disabled ? null : (_) => setState(() => _bgColor = _darkBtnColor),
      onTapUp:   disabled ? null : (_) => setState(() => _bgColor = _defaultBtnColor),
      onTapCancel: disabled ? null : () => setState(() => _bgColor = _defaultBtnColor),
      child: AnimatedContainer(
        duration:  const Duration(milliseconds: 200),
        height:    52,
        width:     52,
        decoration: BoxDecoration(
          color:        disabled ? Colors.grey.shade200 : _bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          widget.icon,
          color: disabled ? Colors.grey : _primaryColor,
          size:  30,
        ),
      ),
    );
  }
}


/*

import 'package:flutter/material.dart';
import 'package:oxdata/app/core/services/ftp_service.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/pallet_model.dart';
import 'package:oxdata/app/core/models/pallet_item_model.dart';
import 'package:oxdata/app/core/services/pallet_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/image_cache_service.dart';
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
import 'package:oxdata/app/views/pallet/pallet_receive_page.dart';
import 'package:oxdata/app/core/widgets/text_product_search.dart';
import 'package:oxdata/app/core/widgets/pulse_icon.dart';

class PalletBuilderPage extends StatefulWidget {
  final PalletModel? pallet;

  const PalletBuilderPage({super.key, this.pallet});

  @override
  State<PalletBuilderPage> createState() => _PalletBuilderPageState();
}

class _PalletBuilderPageState extends State<PalletBuilderPage> {
  final TextEditingController _palletIdController = TextEditingController();
  final TextEditingController _itemSearchController = TextEditingController();
  String? _statusController = "N";
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _productIdController = TextEditingController();
  final TextEditingController _quantityItemController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Lista de itens local para gerenciar a UI
  //List<PalletItemModel> _items = [];
  String productName = "";
  //bool _isLoading = false;
  int? _activePalletId;
  late PalletService _palletService; 

  @override
  void initState() {
    super.initState();
    
    // Pega o serviço apenas uma vez
    _palletService = context.read<PalletService>();

    // Inicializa os dados depois que o frame estiver pronto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final userId = await _storage.read(key: 'username');
    if (!mounted) return;

    setState(() {
      if (widget.pallet != null) {
        _palletIdController.text  = widget.pallet!.palletId.toString();
        _statusController         = widget.pallet!.status;
        _locationController.text  = widget.pallet!.location;
        _userController.text      = widget.pallet!.createdUser.toUpperCase(); 
        _activePalletId           = widget.pallet!.palletId;

        _loadPalletItems(); 

      } else {
        _palletService.clearPallets();
        _palletService.clearPalletsItems();
        _statusController = 'N';
        if (userId != null) {
          _userController.text = userId.toString().toUpperCase();
        }
      }
    });
  }

  /// Remove um caminho de imagem da lista, via Provider.
  void _removeImage(String imagePath) {
    final imageCacheService = context.read<ImageCacheService>();
    imageCacheService.removeImageByPath(imagePath);
    MessageService.showWarning('Imagem removida.');
  }

  /// Carrega os itens do palete a partir do serviço.
  Future<void> _loadPalletItems() async {
    final loadingService = context.read<LoadingService>();
    //final palletService = context.read<PalletService>();
    
    try {
      await CallAction.run(
        action: () async {
          loadingService.show();
          await _palletService.fetchPalletItems(widget.pallet!.palletId);
          /*setState(() {
            _items = palletService.palletItems;
          });*/
          
          //await _getPalletImages(widget.pallet!.palletId);

        },
        onFinally: () {
          loadingService.hide();
        },
      );
    } catch (e) {
      MessageService.showError('Erro ao carregar itens do palete: $e');
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

  void _setPalletIdFromInput(String? value) {
    if (!mounted) return;

    // Remove tudo que não for número
    final numericString = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';

    // Limita a 10 caracteres
    final limitedNumericString = numericString.length > 8
        ? numericString.substring(0, 8)
        : numericString;

    final id = int.tryParse(limitedNumericString);

    _palletIdController.text = limitedNumericString.toString();
    if (id != null && id > 0 && id != _activePalletId) {
      setState(() {
        _activePalletId = id;
      });
    } else if ((id == null || numericString!.isEmpty) && _activePalletId != null) {
      setState(() {
        _activePalletId = null;
      });
    }
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
        status      : 'I',
      );
      
      _palletService.addItemLocally(newItem);

      // Limpa os campos após adicionar
      _productIdController.clear();
      _quantityItemController.clear();
      FocusScope.of(context).requestFocus(FocusNode());
    } else {
      MessageService.showWarning('Por favor, preencha todos os campos do item.');
    }
  }

  /// Salva o palete e seus itens.
  Future<void> _savePallet() async {
    //final palletService = Provider.of<PalletService>(context, listen: false);
    final userId = await _storage.read(key: 'username');

    if (_palletIdController.text.isEmpty) {
      MessageService.showWarning('Informe o número do palete.');
      return;
    }

    if (userId == null) {
      MessageService.showError('Usuário não logado. Impossível salvar.');
      return;
    }

    try {
      /*setState(() {
        _isLoading = true;
      });*/
      final List<PalletItemModel> _items = _palletService.palletItems; 
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

      final imageCacheService = context.read<ImageCacheService>();
      final loadingService = context.read<LoadingService>();
      loadingService.show();
      // Salva o palete e seus itens
      await _palletService.upsertPallets([newPallet], imageCacheService.imagePaths);

      if (_items.isNotEmpty) {
        // Envia todos os itens de uma vez para o serviço
        final itemsToSave = _items.map((item) => item.copyWith(palletId: palletId)).toList();
        await _palletService.upsertPalletItems(itemsToSave);
      }

      final FtpService ftpService = context.read<FtpService>();

      if (imageCacheService.cachedImages.isNotEmpty) {
        final response = await ftpService.setImagesBase64(imageCacheService.cachedImages);
        if (response.success && response.data != null) {
          MessageService.showSuccess('Palete salvo com sucesso!');
        }
        else
        {
          MessageService.showError('Erro ao salvar o palete: ${response.message}}');
        }
      }
      loadingService.hide();
      
      MessageService.showSuccess('Palete salvo com sucesso!');

      Navigator.of(context).pop(true);

    } catch (e) {
      MessageService.showError('Erro ao salvar o palete: $e');
    } finally {
      /*setState(() {
        _isLoading = false;
      });*/
    }
  }

  /// Exclui o palete.
  Future<void> _deletePallet() async {
    if (widget.pallet == null) {
      MessageService.showWarning('Não é possível excluir um palete que ainda não foi salvo.');
      return;
    }

    try {
      /*setState(() {
        _isLoading = true;
      });*/
      //final palletService = Provider.of<PalletService>(context, listen: false);
      await _palletService.deletePallet(widget.pallet!.palletId);

      MessageService.showSuccess('Palete excluído com sucesso!');

      Navigator.of(context).pop();
    } catch (e) {
      MessageService.showError('Erro ao excluir o palete: $e');
    } finally {
      /*setState(() {
        _isLoading = false;
      });*/
    }
  }


  /// Exclui um item da lista após confirmação.
  Future<void> _confirmAndDeleteItem(int index) async {
    final List<PalletItemModel> _items = _palletService.palletItems; 
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
        //final palletService = Provider.of<PalletService>(context, listen: false);
        final itemToRemove = _items[index];

        // Se o item tem um ID, remove do backend. Se não, é um item novo e só remove localmente.
        if (itemToRemove.productId != "") {
          await _palletService.deletePalletItem(itemToRemove.palletId, itemToRemove.productId!);
        }

        setState(() {
          _items.removeAt(index);
        });
        
        MessageService.showError('Item removido com sucesso!');

      } catch (e) {
        MessageService.showError('Erro ao remover o item: $e');
      }
    }
  }

  void _updateQuantity(int index, String newValue) {
    final List<PalletItemModel> _items = _palletService.palletItems; 
    setState(() {
      int quantity = int.tryParse(newValue) ?? 0;
      _items[index] = _items[index].copyWith(quantity: quantity);
    });
  }
  
  // Converter o texto completo de volta para o código
  String _mapStatusToCode(String status) {
    switch (status) {
      case ('I' || 'N'):
        return 'I';
      default:
        return status;
    }
  }

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

  // Define as cores de fundo do Chip
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

  // Define as cores do texto (e da borda) do Chip
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
    if (selectedProductData != null && selectedProductData is Map<String, dynamic>) {
      final productId = selectedProductData['productId'] as String?;
      productName = selectedProductData['productName']; 
      if (productId != null) {
        //setState(() {
          _productIdController.text = productId;
        //});
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

  /// Altera o status do Pallet para 'M' (Montado) e salva.
  Future<void> _buildPallet() async {
    final imageCacheService = context.read<ImageCacheService>();
    //final palletService = Provider.of<PalletService>(context, listen: false);
    final userId = await _storage.read(key: 'username');
    final List<PalletItemModel> _items = _palletService.palletItems; 

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
      //_isLoading = true;
      _statusController = 'M';
    });

    try {
      final totalQuantity = _items.fold<int>(0, (sum, item) => sum + item.quantity);
      final palletId = int.parse(palletIdText);

      final updatedPallet = PalletModel(
        palletId: palletId,
        totalQuantity: totalQuantity,
        status: 'M', // Status Montado
        location: _locationController.text,
        createdUser: widget.pallet?.createdUser ?? userId,
        updatedUser: userId,
        createdAt: widget.pallet?.createdAt ?? DateTime.now(),
      );

      // Chama o serviço para salvar (atualizar) o Pallet
      await _palletService.upsertPallets([updatedPallet], imageCacheService.imagePaths);
      
      // Salva os itens também, caso haja alterações locais pendentes
      if (_items.isNotEmpty) {
        final itemsToSave = _items.map((item) => item.copyWith(palletId: palletId)).toList();
        await _palletService.upsertPalletItems(itemsToSave);
      }
      
      MessageService.showSuccess('Montagem do Pallet concluída com sucesso!');

      //final imageCacheService = context.read<ImageCacheService>();
      final FtpService ftpService = context.read<FtpService>();

      if (imageCacheService.cachedImages.isNotEmpty) {
        //loadingService.show();

        await _palletService.upsertPalletImages(widget.pallet!.palletId,imageCacheService.imagePaths);

        final response = await ftpService.setImagesBase64(imageCacheService.cachedImages);
        //loadingService.hide();
        if (response.success && response.data != null) {
        }
        else
        {
          MessageService.showError('Erro ao salvar: ${response.message}}');
        }
      }

      Navigator.of(context).pop();
    } catch (e) {
      MessageService.showError('Erro ao concluir a montagem do palete: $e');
    } finally {
      /*setState(() {
        _isLoading = false;
      });*/
    }
  }
  
    /// Altera o status do Pallet para 'I' (Inicializado) e salva.
  Future<void> _editPallet() async {
    //final palletService = Provider.of<PalletService>(context, listen: false);
    final userId = await _storage.read(key: 'username');
    final List<PalletItemModel> _items = _palletService.palletItems;  

    if (userId == null) {
      MessageService.showError('Usuário não logado. Impossível concluir ação.');
      return;
    }

    setState(() {
      //_isLoading = true;
      _statusController = 'I';
    });

    try {

      final int? palletId = widget.pallet?.palletId;

      if (palletId != null) {
        // Chama o serviço para salvar (atualizar) o Pallet
        await _palletService.updatePalletStatus(palletId, "I");
        
        // Salva os itens também, caso haja alterações locais pendentes
        if (_items.isNotEmpty) {
          final itemsToSave = _items.map((item) => item.copyWith(palletId: widget.pallet?.palletId)).toList();
          await _palletService.upsertPalletItems(itemsToSave);
        }
        
        MessageService.showSuccess('Pallet reaberto com sucesso!');
      }

      Navigator.of(context).pop();

    } catch (e) {
      MessageService.showError('Erro ao reabrir o palete: $e');
    } finally {
      /*setState(() {
        _isLoading = false;
      });*/
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
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {

    //final loadingService = context.read<LoadingService>();

      await _buildPallet();
    }
  }

    /// Exibe o diálogo de confirmação de montagem.
  Future<void> _showEditConfirmationDialog() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Palete'),
          content: const Text('O Palete será reaberto para edição. Deseja continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      await _editPallet();
    }
  }

  Future<void> _receivePallet() async {
    final userId = await _storage.read(key: 'username');
    final List<PalletItemModel> _items = _palletService.palletItems;  
    if (userId == null) {
      MessageService.showError('Usuário não logado. Impossível receber.');
      return;
    }

    try {
      final totalQuantity = _items.fold<int>(0, (sum, item) => sum + item.quantity);
      final palletId = int.parse(_palletIdController.text);

      final updatedPallet = PalletModel(
        palletId: palletId,
        totalQuantity: totalQuantity,
        status: 'R',
        location: _locationController.text,
        createdUser: widget.pallet?.createdUser ?? userId,
        updatedUser: userId,
        createdAt: widget.pallet?.createdAt ?? DateTime.now(),
      );

      final loadingService = context.read<LoadingService>();

      final imageCacheService = context.read<ImageCacheService>();
      final FtpService ftpService = context.read<FtpService>();

      if (imageCacheService.cachedImages.isNotEmpty) {
        loadingService.show();

        await _palletService.upsertPalletImages(palletId,imageCacheService.imagePaths);

        final response = await ftpService.setImagesBase64(imageCacheService.cachedImages);
        loadingService.hide();
        if (response.success && response.data != null) {
          _navigateToPalletReceivePage(updatedPallet);
        }
        else
        {
          MessageService.showError('Erro ao atualizar o palete: ${response.message}}');
        }
      }

    } catch (e) {
      MessageService.showError('Erro ao receber o palete: $e');
    } finally {
      /*setState(() {
        _isLoading = false;
      });*/
    }
  }

  void _navigateToPalletReceivePage(PalletModel pallet) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PalletReceivePage(pallet: pallet),
      ),
    );
    
  }

  // Constrói o Widget do Chip com largura e estilo fixos
  Widget _buildStatusChip(String statusCode) {
    // Mapeia o código ('I', 'M', 'R') para o texto completo
    final mappedStatus = _mapCodeToStatus(statusCode);
    
    // Obtém as cores baseadas no status completo
    final chipColor = _getStatusColor(mappedStatus);
    final textColor = _getTextColor(mappedStatus);

    return Container(
      // Define a largura MÍNIMA e MÁXIMA fixa (e igual) para uniformizar o chip.
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 130,
        minHeight: 0,
        maxHeight: 25,
      ),
      
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4), 
      
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          mappedStatus,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //final palletService = context.watch<PalletService>();

    return Scaffold(
      appBar: const AppBarCustom(title: 'Montagem do Palete'),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ================= CONTEÚDO FIXO DO TOPO =================
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Linha de Pallet ID + Quantidade
                    PalletIdAndQuantity(
                      palletIdController: _palletIdController,
                      //totalQuantity: palletService.palletItems.fold<int>(0, (sum, item) => sum + item.quantity),
                      scanBarcode: _scanBarcode,
                      onPalletIdChanged: _setPalletIdFromInput,
                    ),

                    const SizedBox(height: 4),

                    // Linha de imagens do pallet + status/local/usuário
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_activePalletId != null)
                          Expanded(
                            child: _PalletImagesSection(
                              palletId: widget.pallet?.palletId,
                              onImageRemoved: _removeImage,
                            ),
                          )
                        else
                          Expanded(
                            child: Container(
                              height: 170,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.grey.shade100,
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            children: [
                              // Status
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Status',
                                    style: TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 0),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: _statusController != null
                                        ? _buildStatusChip(_statusController!)
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Local
                              TextField(
                                controller: _locationController,
                                textCapitalization: TextCapitalization.characters,
                                inputFormatters: [UpperCaseTextFormatter()],
                                decoration: const InputDecoration(
                                  labelText: 'Local',
                                  labelStyle: TextStyle(fontSize: 14),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Usuário
                              TextField(
                                controller: _userController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Usuário',
                                  labelStyle: TextStyle(fontSize: 14),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Linha de adicionar item (produto + qtd + botão)
                    if (_statusController != 'M' && _statusController != 'R')
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ProductTextFieldWithActions(
                              controller: _productIdController,
                              label: 'Produto',
                              onScanBarcode: _scanBarcode,
                              onSearch: () async {
                                await _openProductSearch(context);
                              },
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
                                contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                              ),
                              onSubmitted: (value) => _addItem(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PulseIconButton(
                            icon: Icons.add_box_rounded ,
                            color: _palletIdController.text.trim().isNotEmpty
                                ? Colors.indigo
                                : Colors.grey.shade400,
                            size: 60,
                            onPressed: () {
                              if (_palletIdController.text.trim().isNotEmpty) {
                                _addItem(); // aqui pode ser async, sem await
                              }
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // ================= CAMPO DE PESQUISA =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade200],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Center(
                          child: Text(
                            'ITENS',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 30,
                          child: TextField(
                            controller: _itemSearchController,
                            decoration: InputDecoration(
                              hintText: 'Pesquisar..',
                              hintStyle: const TextStyle(fontSize: 14),
                              suffixIcon: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.qr_code_scanner_outlined, size: 28, color: Colors.black,),
                                onPressed: () async {
                                  String scanned = await _scanBarcode();
                                  if (scanned.isNotEmpty) {
                                    _itemSearchController.text = scanned;
                                  }
                                },
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 0),
                              fillColor: Colors.white,
                              filled: true,
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ================= LISTA DE ITENS FILTRADOS =================
              ValueListenableBuilder(
                valueListenable: _itemSearchController,
                builder: (context, _, __) => ItemList(
                  searchController: _itemSearchController,
                  onDeleteItem: (item) async {
                    final index = _palletService.palletItems.indexOf(item);
                    if (index != -1) {
                      await _confirmAndDeleteItem(index);
                    }
                  },
                  onUpdateQuantity: (item, newQuantity) {
                    final index = _palletService.palletItems.indexOf(item);
                    if (index != -1) {
                      _palletService.updateItemQuantity(index, newQuantity);
                      //_updateQuantity(index, newQuantity.toString());
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -1),
            ),
          ],
          border: const Border(
            top: BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (widget.pallet != null)
              _toolbarButton(
                label: 'Excluir',
                icon: Icons.delete_forever_rounded,
                color: Colors.red.shade600,
                onPressed: _deletePallet,
              ),

            if (_statusController == 'M') ...[
              _toolbarButton(
                label: 'Editar',
                icon: Icons.edit_note_rounded,
                color: Colors.indigo,
                onPressed: _showEditConfirmationDialog,
              ),
              _toolbarButton(
                label: 'Receber',
                icon: Icons.inventory_2_rounded,
                color: Colors.green.shade700,
                onPressed: _receivePallet,
              ),
            ] else if (_statusController != 'R') ...[
              _toolbarButton(
                label: 'Salvar',
                icon: Icons.save_rounded,
                color: Colors.indigo,
                onPressed: _palletIdController.text.trim().isNotEmpty
                    ? _savePallet
                    : null,
              ),
              _toolbarButton(
                label: 'Montar',
                icon: Icons.pallet,
                color: Colors.green.shade700,
                onPressed: _palletIdController.text.trim().isNotEmpty
                  ? () {
                      if (widget.pallet != null) {
                        _showBuildConfirmationDialog();
                      } else {
                        _statusController = "M";
                        _savePallet();
                      }
                    }
                  : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Botão estilizado para toolbar
  Widget _toolbarButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final isDisabled = onPressed == null;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: isDisabled ? Colors.grey.shade300 : color,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          ),
          icon: Icon(icon, size: 22),
          label: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }


}

class ItemList extends StatelessWidget {
  final TextEditingController searchController;
  final void Function(PalletItemModel item) onDeleteItem;
  final void Function(PalletItemModel item, int newQuantity) onUpdateQuantity;

  const ItemList({
    super.key,
    required this.searchController,
    required this.onDeleteItem,
    required this.onUpdateQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final palletService = context.watch<PalletService>();

    final items = searchController.text.isEmpty
        ? palletService.palletItems
        : palletService.palletItems.where((item) {
            final query = searchController.text.toLowerCase();
            final nameMatch = item.productName!.toLowerCase().contains(query);
            final idMatch = item.productId.toLowerCase().contains(query);
            return nameMatch || idMatch;
          }).toList();

    return Container(
      color: Colors.grey.shade200,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final quantityController = TextEditingController(text: item.quantity.toString());

          return Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            padding: const EdgeInsets.fromLTRB(0, 2, 0, 4),
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
                          item.productName ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          softWrap: false,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('CÓD: ${item.productId}',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF1565C0))),
                          const SizedBox(width: 10),
                          const Text('QTD:', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 50,
                            child: TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                              onSubmitted: (value) => onUpdateQuantity(item, int.tryParse(value) ?? 0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 30),
                  onPressed: () => onDeleteItem(item),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


class PalletIdAndQuantity extends StatelessWidget {
  final TextEditingController palletIdController;
  final Future<String> Function() scanBarcode;
  final void Function(String) onPalletIdChanged;

  const PalletIdAndQuantity({
    super.key,
    required this.palletIdController,
    required this.scanBarcode,
    required this.onPalletIdChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Usa o Provider para ler os itens e calcular o total
    final palletService = context.watch<PalletService>();
    final totalQuantity = palletService.palletItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: TextField(
            controller: palletIdController,
            keyboardType: TextInputType.number,
            onChanged: onPalletIdChanged,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              labelText: 'Número',
              labelStyle: const TextStyle(fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              /*suffixIcon: IconButton(
                icon: const Icon(
                  Icons.qr_code_scanner_outlined,
                  size: 38,
                  color: Colors.indigo,
                ),
                onPressed: () async {
                  String scanned = await scanBarcode();
                  if (scanned.isNotEmpty) {
                    palletIdController.text = scanned;
                    onPalletIdChanged(scanned);
                  }
                },
              ),*/
              suffixIcon: PulseIconButton(
                icon: Icons.qr_code_scanner_outlined,
                color: Colors.indigo,
                size: 38,
                onPressed: () {
                  // pode ser async dentro da função
                  () async {
                    String scanned = await scanBarcode();
                    if (scanned.isNotEmpty) {
                      palletIdController.text = scanned;
                      onPalletIdChanged(scanned);
                    }
                  }();
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
                const Text('Quantidade', style: TextStyle(fontSize: 13, height: 2)),
                Text(
                  totalQuantity.toString(),
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
    );
  }
}

/// Separado para não depender do setState do pai
/// ai não fica piscando atoa quando adiciona itens
class _PalletImagesSection extends StatelessWidget {
  final int? palletId;
  final Function(String) onImageRemoved;

  const _PalletImagesSection({
    required this.palletId,
    required this.onImageRemoved,
  });

  @override
  Widget build(BuildContext context) {
    // Apenas este widget observa (watch) do ImageCacheService.
    final imageCacheService = context.watch<ImageCacheService>();
    final List<String> currentImagePaths = imageCacheService.imagePaths;

    return ImagesPicker(
      imagePaths: currentImagePaths,
      baseImagePath: "MONTAGEM_PALETE/",
      codePallet: palletId,
      onImageRemoved: onImageRemoved,
      onImagesChanged: (newPaths) {
        // A lógica de setState aqui não afeta a tela Pai
      },
      itemHeight: 174,
      itemWidth: 178,
      iconSize: 28,
    );
  }
}

*/