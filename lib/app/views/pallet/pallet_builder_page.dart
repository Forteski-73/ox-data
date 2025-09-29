import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/pallet_model.dart';
import 'package:oxdata/app/core/models/pallet_item_model.dart';
import 'package:oxdata/app/core/services/pallet_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';

// Este é um mock simples de um UserProvider para demonstração.
/*class UserProvider with ChangeNotifier {
  String? _currentUserId = 'dummy-user-id';
  String? get currentUserId => _currentUserId;
}*/

class PalletBuilderPage extends StatefulWidget {
  final PalletModel? pallet;

  const PalletBuilderPage({super.key, this.pallet});

  @override
  State<PalletBuilderPage> createState() => _PalletBuilderPageState();
}

class _PalletBuilderPageState extends State<PalletBuilderPage> {
  final TextEditingController _palletIdController = TextEditingController();
  String? _statusController = "I"; // null inicialmente, ou 'I' valor padrão
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _productIdController = TextEditingController();
  final TextEditingController _quantityItemController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Lista de itens local para gerenciar a UI
  List<PalletItemModel> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userId = _storage.read(key: 'username');
    // Verifica se um palete foi passado para a página
    if (widget.pallet != null) {
      _palletIdController.text = widget.pallet!.palletId.toString();
      _statusController = widget.pallet!.status;
      _locationController.text = widget.pallet!.location;
      _userController.text = widget.pallet?.createdUser ?? userId.toString();
      // Carrega os itens do palete existente
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadPalletItems();
        });
      }
    } else {
      _statusController = 'I';
    }
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
        palletId: int.tryParse(_palletIdController.text) ?? 0,
        productId: _productIdController.text,
        quantity: int.tryParse(_quantityItemController.text) ?? 0,
        userId: username,
        status: 'PENDING',
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
  
  Future<void> _receivePallet() async {
    final palletService = Provider.of<PalletService>(context, listen: false);
    final userId = await _storage.read(key: 'username');

    if (userId == null) {
      MessageService.showError('Usuário não logado. Impossível receber.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusController = 'R'; // Atualiza o status para 'Recebido'
    });

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

      await palletService.upsertPallets([updatedPallet]);
      MessageService.showSuccess('Palete recebido com sucesso!');
      Navigator.of(context).pop();
    } catch (e) {
      MessageService.showError('Erro ao receber o palete: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Novo método para converter o texto completo de volta para o código
  String _mapStatusToCode(String status) {
    switch (status) {
      case 'Iniciado':
        return 'I';
      case 'Montado':
        return 'M';
      case 'Recebido':
        return 'R';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarCustom(title: 'Montagem de Palete'),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _palletIdController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                labelText: 'Número',
                                contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                suffixIcon: Icon( Icons.qr_code_scanner_outlined, size: 40, color:Colors.indigo),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Quantidade',
                              style: TextStyle(fontSize: 13, height: 2),
                            ),
                            Text(
                              _items.fold<int>(0, (sum, item) => sum + item.quantity).toString(),
                              style: const TextStyle(fontSize: 46, fontWeight: FontWeight.bold, height: 1.0),
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
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: widget.pallet?.imagePath != null
                            ? Image.network(
                                widget.pallet!.imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 162),
                              )
                            : const Icon(Icons.image_search_outlined, size: 162, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _statusController,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'I', child: Text('Iniciado')),
                              DropdownMenuItem(value: 'M', child: Text('Montado')),
                              DropdownMenuItem(value: 'R', child: Text('Recebido')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _statusController = value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Local',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _userController,
                            decoration: const InputDecoration(
                              labelText: 'Usuário',
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
                const SizedBox(height: 4),
                if (_statusController != 'M')
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _productIdController,
                          decoration: const InputDecoration(
                            labelText: 'Cód. produto',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
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
                            labelText: 'Qtd.',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                          ),
                          onSubmitted: (value) => _addItem(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.add_box, color: Colors.indigo, size: 60),
                            onPressed: _addItem,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade200],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'ITENS',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      // Use um Container com decoração para o novo layout
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          //border: Border.all(color: Colors.grey.shade300),
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
                                  // Descrição do produto (mock para demonstração)
                                  const Text(
                                    'DESCRIÇÃO DO PRODUTO COMPLETA',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                    // Código do produto
                                    Text('CÓD: ${item.productId}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                    const SizedBox(width: 10),
                                      const Text('QTD:', style: TextStyle(fontSize: 14)),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 50,
                                        child: TextField(
                                          controller: TextEditingController(text: item.quantity.toString()),
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                            border: InputBorder.none,
                                          ),
                                          onSubmitted: (value) {
                                            _updateQuantity(index, value);
                                            FocusScope.of(context).unfocus(); // Remove o foco do campo
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Botão de exclusão
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 28),
                              onPressed: () => _confirmAndDeleteItem(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
SafeArea(
                  child: Row(
                    children: [
                      if (widget.pallet != null)
                        Expanded(
                          flex: 1,
                          child: ElevatedButton.icon(
                            onPressed: _deletePallet,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            icon: const Icon(Icons.delete, size: 24,),
                            label: const Text('EXCLUIR'),
                          ),
                        ),
                      const SizedBox(width: 16),
                      // 👇 **CORREÇÃO APLICADA AQUI** 👇
                      if (_statusController == 'M')
                        Expanded(
                          flex: 1,
                          child: ElevatedButton.icon(
                            // ❗ FUNÇÃO ANÔNIMA COM LÓGICA DE NAVEGAÇÃO E MODELO ❗
                            onPressed: () async {
                              final loadingService = context.read<LoadingService>();
                              final userId = await _storage.read(key: 'username');
                              
                              if (userId == null || _palletIdController.text.isEmpty) {
                                MessageService.showError('Erro: Usuário ou Palete ID não definidos.');
                                return;
                              }
                              
                              final totalQuantity = _items.fold<int>(0, (sum, item) => sum + item.quantity);
                              final palletId = int.tryParse(_palletIdController.text);
                              
                              if (palletId == null || palletId == 0) {
                                MessageService.showError('ID do Palete inválido.');
                                return;
                              }

                              // Constrói o PalletModel para a próxima tela
                              final palletToReceive = PalletModel(
                                palletId: palletId,
                                totalQuantity: totalQuantity,
                                status: 'R', // Sugere o status de Recebido para a próxima tela
                                location: _locationController.text,
                                createdUser: widget.pallet?.createdUser ?? userId,
                                updatedUser: userId,
                                createdAt: widget.pallet?.createdAt ?? DateTime.now(),
                                imagePath: widget.pallet?.imagePath,
                              );
                              
                              // Navegação para a página de recebimento, passando o modelo
                              Navigator.of(context).pushNamed(
                                'palletReceivePage',
                                arguments: palletToReceive,
                              );
                            },
                            // ⬆️ **FIM DA CORREÇÃO** ⬆️
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            icon: const Icon(Icons.pallet, size: 24,),
                            label: const Text('RECEBER'),
                          ),
                        )
                      else ...[
                        Expanded(
                          flex: 1,
                          child: ElevatedButton.icon(
                            onPressed: _savePallet,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            icon: const Icon(Icons.save, size: 24,),
                            label: const Text('SALVAR'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: ElevatedButton.icon(
                            // Mantive este como _savePallet pois o botão de baixo (Montar)
                            // está sendo usado para SALVAR E MARCAR COMO MONTADO.
                            // Se este botão for para RECEBER, o seu fluxo de app tem que ser revisto.
                            // Por enquanto, ele é redundante com o 'SALVAR'.
                            // Se 'MONTAR' for o mesmo que 'SALVAR' com status 'M', mantenha assim.
                            onPressed: _savePallet, 
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            icon: const Icon(Icons.pallet, size: 24,),
                            label: const Text('MONTAR'),
                          ),
                        )
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
