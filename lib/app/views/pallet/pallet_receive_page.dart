import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/pallet_model.dart';
import 'package:oxdata/app/core/models/pallet_item_model.dart';
import 'package:oxdata/app/core/services/pallet_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';

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
  final Map<String, bool> _markedItems = {};

  List<PalletItemModel> _items = [];
  List<PalletItemModel> _filteredItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _palletService = Provider.of<PalletService>(context, listen: false);

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
    super.dispose();
  }

  TextEditingController _getQuantityController(PalletItemModel item) {
    if (!_quantityControllers.containsKey(item.productId)) {
      _quantityControllers[item.productId] =
          TextEditingController(text: item.quantity.toString());
    } else {
      final controller = _quantityControllers[item.productId]!;
      if (controller.text != item.quantity.toString()) {
        controller.text = item.quantity.toString();
      }
    }
    return _quantityControllers[item.productId]!;
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

            _quantityControllers.forEach((key, controller) => controller.dispose());
            _quantityControllers.clear();

            _markedItems.clear();

            for (var item in _items) {
              _getQuantityController(item);
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
          final descriptionMock =
              'DESCRIÇÃO DO PRODUTO COMPLETA PARA ${item.productId}';
          return item.productId.toLowerCase().contains(filter) ||
              descriptionMock.toLowerCase().contains(filter);
        }).toList();
      }
    });
  }

  void _updateQuantity(String productId, String value) {
    try {
      final newQuantity = int.tryParse(value);

      if (newQuantity != null && newQuantity >= 0) {
        final originalItemIndex =
            _items.indexWhere((item) => item.productId == productId);

        if (originalItemIndex != -1) {
          final oldItem = _items[originalItemIndex];
          final updatedItem = oldItem.copyWith(quantity: newQuantity);

          setState(() {
            _items[originalItemIndex] = updatedItem;

            final filteredItemIndex =
                _filteredItems.indexWhere((item) => item.productId == productId);
            if (filteredItemIndex != -1) {
              _filteredItems[filteredItemIndex] = updatedItem;
            }

            _quantityControllers[productId]?.text = newQuantity.toString();
          });
        }
      } else {
        final originalItem =
            _items.firstWhere((item) => item.productId == productId);
        _quantityControllers[productId]?.text =
            originalItem.quantity.toString();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Quantidade inválida. Insira um número inteiro não negativo.')),
        );
      }
    } catch (e) {
      print('Erro ao atualizar quantidade: $e');
    }
  }

  // ✅ Agora cada check é independente
  void _toggleItemMark(String productId, bool? isMarked) {
    if (isMarked == null) return;
    setState(() {
      _markedItems[productId] = isMarked;
    });
  }

  Future<void> _receivePallet() async {
    final itemsToUpsert = _items.where((item) => item.quantity > 0).toList();

    if (itemsToUpsert.isEmpty) {
      setState(() {
        _errorMessage = 'Nenhum item com quantidade para receber.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _palletService.upsertPalletItems(itemsToUpsert);
      MessageService.showSuccess('Palete recebido com sucesso!');
    } catch (e) {
      setState(() {
        MessageService.showError('Falha ao concluir o recebimento.');
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
      appBar: AppBar(
        title: Text('Receber Palete - ID ${widget.pallet.palletId}'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildFilterField(),
                const SizedBox(height: 16),
                if (_errorMessage != null) _buildErrorMessage(),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredItems.isEmpty
                          ? const Center(child: Text('Nenhum item encontrado.'))
                          : ListView.builder(
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                return _buildPalletItemCard(item);
                              },
                            ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          _buildReceiveButton(),
        ],
      ),
    );
  }

  Widget _buildFilterField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _filterController,
        decoration: const InputDecoration(
          hintText: 'Filtrar itens (código/descrição)...',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.indigo),
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isMarked ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Text(
          'Produto ${item.productId.substring(item.productId.length - 4)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            children: [
              Text('CÓD: ${item.productId}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(width: 12),
              const Text('QTD:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(width: 6),
              SizedBox(
                width: 55,
                child: TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onChanged: (value) => _updateQuantity(item.productId, value),
                ),
              ),
            ],
          ),
        ),
        trailing: Checkbox(
          value: isMarked,
          onChanged: (val) => _toggleItemMark(item.productId, val),
          activeColor: Colors.green.shade700,
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiveButton() {
    return Positioned(
      bottom: 16.0,
      left: 16.0,
      right: 16.0,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _receivePallet,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.check_circle, size: 24),
        label: Text(
          _isLoading ? 'Processando...' : 'CONCLUIR RECEBIMENTO',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}