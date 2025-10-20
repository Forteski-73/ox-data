import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/pallet_model.dart';
import 'package:oxdata/app/core/models/pallet_item_model.dart';
import 'package:oxdata/app/core/services/pallet_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart'; 
import 'package:oxdata/app/views/pallet/search_pallet_page.dart';

class PalletReceivePage extends StatefulWidget {
  final PalletModel pallet;

  const PalletReceivePage({super.key, required this.pallet});

  @override
  State<PalletReceivePage> createState() => _PalletReceivePageState();
}

class _PalletReceivePageState extends State<PalletReceivePage> {
  late final PalletService _palletService;
  final TextEditingController _filterController = TextEditingController();

  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, FocusNode> _quantityFocusNodes = {};
  final Map<String, bool> _markedItems = {};

  List<PalletItemModel> _items = [];
  List<PalletItemModel> _filteredItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _palletService = Provider.of<PalletService>(context, listen: false);

    _filterController.addListener(_handleFilterChange); 
    _filterController.addListener(_filterItems);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchPalletItems();
      }
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    _quantityControllers.forEach((key, controller) => controller.dispose());
    _quantityFocusNodes.forEach((key, node) => node.dispose());
    super.dispose();
  }

  TextEditingController _getQuantityController(PalletItemModel item) {
    if (!_quantityControllers.containsKey(item.productId)) {
      _quantityControllers[item.productId] =
          TextEditingController(text: item.quantity.toString());
    } 
    return _quantityControllers[item.productId]!;
  }

  FocusNode _getFocusNode(PalletItemModel item) {
    if (!_quantityFocusNodes.containsKey(item.productId)) {
      final node = FocusNode();
      node.addListener(() {
        if (node.hasFocus) {
          _toggleItemMark(item.productId, true);
        }
      });
      _quantityFocusNodes[item.productId] = node;
    }
    return _quantityFocusNodes[item.productId]!;
  }

  void _handleFilterChange() {
    if (_filterQuery != _filterController.text) {
      setState(() {
        _filterQuery = _filterController.text;
      });
    }
  }

  Future<void> _fetchPalletItems() async {
    final loadingService = context.read<LoadingService>();
    final palletService = context.read<PalletService>();

    try {
      await CallAction.run(
        action: () async {
          loadingService.show();

          await palletService.fetchPalletItems(widget.pallet.palletId);

          setState(() {
            _items = palletService.palletItems;
            _filteredItems = _items;

            _isLoading = false;
            _errorMessage = null;

            // Limpeza e recriação dos controllers
            _quantityControllers.forEach((key, controller) => controller.dispose());
            _quantityControllers.clear();
            _quantityFocusNodes.forEach((key, node) => node.dispose());
            _quantityFocusNodes.clear();

            _markedItems.clear();

            for (var item in _items) {
              _getQuantityController(item);
              _getFocusNode(item); // garante o FocusNode
              _markedItems[item.productId] = false;
            }
          });
        },
        onFinally: () {
          loadingService.hide();
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar itens do palete: ${e.toString()}')),
      );

      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar itens: ${e.toString()}';
        });
      }
    }
  }

  void _filterItems() {
    final filter = _filterController.text.toLowerCase();
    setState(() {
      if (filter.isEmpty) {
        _filteredItems = _items;
      } else {
        _filteredItems = _items.where((item) {
          final description = item.productName ?? 'Sem descrição';
          return item.productId.toLowerCase().contains(filter) ||
                 description.toLowerCase().contains(filter);
        }).toList();
      }
    });
  }

  void _updateQuantity(String productId, String value) {
    final newQuantity = int.tryParse(value) ?? 0;

    final originalItemIndex =
        _items.indexWhere((item) => item.productId == productId);

    if (originalItemIndex != -1) { 
      final oldItem = _items[originalItemIndex]; 

      if (oldItem.quantity != newQuantity) {
        final updatedItem = oldItem.copyWith(quantityReceived: newQuantity);

        setState(() {
          _items[originalItemIndex] = updatedItem;

          final filteredItemIndex =
              _filteredItems.indexWhere((item) => item.productId == productId);
          if (filteredItemIndex != -1) {
            _filteredItems[filteredItemIndex] = updatedItem;
          }
        });
      }
    }
  }

  void _toggleItemMark(String productId, bool? isMarked) {
    if (isMarked == null) return;
    setState(() {
      _markedItems[productId] = isMarked;
    });
  }

  Future<void> _showReceiveConfirmationDialog() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Recebimento'),
          content: Text('Deseja concluir o recebimento do Pallet ${widget.pallet.palletId}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      await _receivePallet();
    }
  }

  Future<void> _receivePallet() async {
    final itemsWithQuantity = _items.where((item) => item.quantity > 0).toList();

    if (itemsWithQuantity.isEmpty) {
      setState(() {
        _errorMessage = 'Nenhum item com quantidade para receber.';
      });
      return;
    }

    final List<PalletItemModel> itemsToUpsert = itemsWithQuantity.map((item) {
      final bool isMarkedForReceipt = _markedItems[item.productId] ?? false;

      if (!isMarkedForReceipt) {
        return item.copyWith(
          quantityReceived: 0,
        );
      }

      return item;
    }).toList();
    
    // ------------------------------------------------------------------------------------

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Envia a lista processada (com quantityReceived = 0 para itens desmarcados)
      await _palletService.upsertPalletItems(itemsToUpsert);
      
      // Calcula a quantidade total APENAS dos itens com quantity > 0
      final totalQuantity = itemsToUpsert.fold<int>(0, (sum, item) => sum + item.quantity);

      final updatedPallet = widget.pallet.copyWith(
        status: 'R',
        totalQuantity: totalQuantity,
      );

      // Salva o status atualizado do Palete
      await _palletService.upsertPallets([updatedPallet], null);
      
      MessageService.showSuccess('Palete recebido com sucesso!');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SearchPalletPage()),
      );

    } catch (e) {
      setState(() {
        MessageService.showError('Falha ao concluir o recebimento: ${e.toString()}');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(title: 'Receber Palete'),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade200],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Text(
                          'PALETE: ',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          widget.pallet.palletId.toString(),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  _buildFilterField(),
                  if (_errorMessage != null) _buildErrorMessage(),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade200],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'ITENS',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.grey.shade200,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredItems.isEmpty
                          ? const Center(child: Text('Nenhum item encontrado.'))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(4, 3, 7, 0),
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                return _buildPalletItemCard(item);
                              },
                            ),
                ),
              ),
            ],
          ),
          _buildReceiveButton(),
        ],
      ),
    );
  }

  Widget _buildFilterField() {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: TextField(
        controller: _filterController,
        decoration: InputDecoration(
          hintText: 'Pesquisar...',
          prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 30),
          suffixIcon: _filterQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.black54),
                  onPressed: () {
                    _filterController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildPalletItemCard(PalletItemModel item) {
    final quantityController = _getQuantityController(item); 
    final isMarked = _markedItems[item.productId] ?? false;

    final cardColor = isMarked ? Colors.green.shade50 : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.10),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
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
                    item.productName ?? 'Produto sem nome',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    softWrap: false,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('CÓD: ${item.productId}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey)),
                    const SizedBox(width: 10),
                    const Text('QTD:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: quantityController,
                        focusNode: _getFocusNode(item), // ✅ aqui
                        onChanged: (value) => _updateQuantity(item.productId, value),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.5, 
            child: Checkbox(
              value: isMarked,
              onChanged: (val) => _toggleItemMark(item.productId, val),
              activeColor: Colors.green.shade700,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
              ),
              side: BorderSide(color: Colors.grey.shade400, width: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveButton() {
    return Positioned(
      left: 4.0,
      right: 8.0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4), 
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _showReceiveConfirmationDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
              ),
              elevation: 4,
            ),
            label: Text(
              _isLoading ? 'Processando...' : 'CONCLUIR RECEBIMENTO',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
