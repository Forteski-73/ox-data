import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/pallet_model.dart';
import 'package:oxdata/app/core/models/pallet_item_model.dart';
import 'package:oxdata/app/core/services/pallet_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart'; // Import necessário

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
        super.dispose();
    }

    TextEditingController _getQuantityController(PalletItemModel item) {
        if (!_quantityControllers.containsKey(item.productId)) {
            _quantityControllers[item.productId] =
                TextEditingController(text: item.quantity.toString());
        } 
        return _quantityControllers[item.productId]!;
    }

    void _handleFilterChange() {
        // Isso aciona o setState para reconstruir o _buildFilterField e atualizar o suffixIcon
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

                        _markedItems.clear();

                        for (var item in _items) {
                            _getQuantityController(item); // Garante que os controllers sejam recriados
                            _markedItems[item.productId] = false; // Estado inicial: desmarcado
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
                    final description = item.productName ?? 'Sem descrição'; // Usa productName
                    return item.productId.toLowerCase().contains(filter) ||
                            description.toLowerCase().contains(filter);
                }).toList();
            }
        });
    }

    // =========================================================================
    // CORREÇÃO AQUI: Simplificando a lógica de atualização
    // =========================================================================
    void _updateQuantity(String productId, String value) {
        final newQuantity = int.tryParse(value) ?? 0;

        final originalItemIndex =
            _items.indexWhere((item) => item.productId == productId);

        if (originalItemIndex != -1) {
            final oldItem = _items[originalItemIndex];

            if (oldItem.quantity != newQuantity) {
                final updatedItem = oldItem.copyWith(quantity: newQuantity);

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
    // =========================================================================
    // FIM DA CORREÇÃO DE ATUALIZAÇÃO
    // =========================================================================


    // ✅ Mantido o check independente
    void _toggleItemMark(String productId, bool? isMarked) {
        if (isMarked == null) return;
        setState(() {
            _markedItems[productId] = isMarked;
        });
    }

// MÉTODO DE DIÁLOGO DE CONFIRMAÇÃO
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
            // 1. Atualiza/insere os itens do palete
            await _palletService.upsertPalletItems(itemsToUpsert);
            
            // 2. Atualiza o status do Pallet para 'R' (Recebido)
            final updatedPallet = widget.pallet.copyWith(
                status: 'R',
                totalQuantity: itemsToUpsert.fold<int>(0, (sum, item) => sum + item.quantity),
            );
            await _palletService.upsertPallets([updatedPallet]);
            
            MessageService.showSuccess('Palete recebido com sucesso!');
            Navigator.of(context).pop();

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

// ---------------------------------------------------------------------
// LAYOUT DA PÁGINA (ESTRUTURA)
// ---------------------------------------------------------------------

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
                                padding: const EdgeInsets.symmetric(horizontal: 0), // Adicionei padding horizontal para as bordas
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
                                            Padding(
                                                padding: const EdgeInsets.only(left: 6),
                                                child: Text(
                                                    'PALETE: ',
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                    ),
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
                                                        color: Colors.indigo,
                                                    ),
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
                            // Lista de Itens (rolável, ocupando o restante do espaço)
                            Expanded(
                                child: Container(
                                    color: Colors.grey.shade200, // Cor de fundo do ListView
                                    child: _isLoading
                                            ? const Center(child: CircularProgressIndicator())
                                            : _filteredItems.isEmpty
                                                    ? const Center(child: Text('Nenhum item encontrado.'))
                                                    : ListView.builder(
                                                            padding: const EdgeInsets.fromLTRB(4, 3, 7, 0), // Ajuste o padding
                                                            itemCount: _filteredItems.length,
                                                            itemBuilder: (context, index) {
                                                                final item = _filteredItems[index];
                                                                return _buildPalletItemCard(item); // Usa o novo layout aqui
                                                            },
                                                        ),
                                ),
                            ),
                            // Espaçamento para o botão flutuante
                            //const SizedBox(height: 100),
                        ],
                    ),
                    // Botão flutuante (Rodapé)
                    _buildReceiveButton(),
                ],
            ),
        );
    }
    
    // DENTRO DA CLASSE _PalletReceivePageState
    Widget _buildFilterField() {
        return Padding(
            padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 0),
            child: TextField(
                controller: _filterController,
                decoration: InputDecoration(
                    hintText: 'Pesquisar...',
                    prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 30),
                    // Usa _filterQuery para mostrar/ocultar o ícone de limpar
                    suffixIcon: _filterQuery.isNotEmpty
                        ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.black54),
                                onPressed: () {
                                    _filterController.clear();
                                    // O listener _handleFilterChange fará o setState e atualizará _filterQuery.
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

// WIDGET DE CARTÃO DE ITEM (AGORA COM O CAMPO FUNCIONANDO)
    Widget _buildPalletItemCard(PalletItemModel item) {
        // Garante que o controller seja obtido/criado SEM o listener de onChanged
        final quantityController = _getQuantityController(item); 
        final isMarked = _markedItems[item.productId] ?? false;

        // Define a cor do cartão aqui
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
                                      item.productName ?? 'Produto sem nome', // Usa productName ou fallback
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
                                      // Usa o controller obtido
                                      controller: quantityController, 
                                      // O onChanged é o ÚNICO responsável por atualizar o modelo
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
                        /*icon: _isLoading
                                ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                                color: Colors.white, strokeWidth: 2),
                                    )
                                : const Icon(Icons.check_circle, size: 24),*/
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