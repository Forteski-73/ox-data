import 'package:flutter/material.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/pallet_service.dart';
import 'package:oxdata/app/core/models/pallet_item_model.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:provider/provider.dart';

class PalletItemsTab extends StatefulWidget {
  final String searchQuery;
  final String selectedFilter;

  const PalletItemsTab({
    super.key,
    required this.searchQuery,
    required this.selectedFilter,
  });

  @override
  State<PalletItemsTab> createState() => _PalletItemsTabState();
}

class _PalletItemsTabState extends State<PalletItemsTab> {
  @override
  void initState() {
    super.initState();


    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFilterItems();
      });
    }
  }

  Future<void> _loadFilterItems() async {
    final loadingService = context.read<LoadingService>();
    final palletService = context.read<PalletService>();

    final start = DateTime.now();
    const minDuration = Duration(seconds: 1);

    await CallAction.run(
      action: () async {
        loadingService.show();
        //await palletService.fetchAllPalletItems();
        //await palletService.filterPalletItems(widget.selectedFilter, "");
         palletService.clearPalletsItems();
         palletService.clearPallets();
      },
      onFinally: () async {
        final elapsed = DateTime.now().difference(start);
        if (elapsed < minDuration) {
          await Future.delayed(minDuration - elapsed);
        }
        loadingService.hide();
      },
    );
  }

  List<PalletItemModel> _getFilteredItems(
      List<PalletItemModel> allItems, String query) {
    if (query.isEmpty) return allItems;

    final lowerCaseQuery = query.trim().toLowerCase();
    final upperCaseQuery = query.toUpperCase();

    return allItems.where((item) {
      final matchesProductId =
          item.productId.toLowerCase().contains(lowerCaseQuery);
      final matchesProductName =
          (item.productName ?? '').toUpperCase().contains(upperCaseQuery);
      final matchesPalletId =
          item.palletId.toString().toLowerCase().contains(lowerCaseQuery);
      final matchesQuantity =
          item.quantity.toString().toLowerCase().contains(lowerCaseQuery);

      return matchesProductId ||
          matchesProductName ||
          matchesPalletId ||
          matchesQuantity;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PalletService>(
      builder: (context, palletService, child) {
        final List<PalletItemModel> filteredItems =
            _getFilteredItems(palletService.palletItems, widget.searchQuery);

        if (filteredItems.isEmpty) {
          return Center(
            child: Text(
              'Nenhum item de palete encontrado.',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight,
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                item.productName ?? 'Nome não disponível',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                                softWrap: false,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Palete',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600)),
                                ),
                                Expanded(
                                  child: Text('Código',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade600)),
                                ),
                                Expanded(
                                  child: Text('Quantidade',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600)),
                                ),
                                Expanded(
                                  child: Text('Status',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                    child: Text(item.palletId.toString(),
                                        style: const TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.bold))),
                                Expanded(
                                    child: Text(item.productId,
                                        style: const TextStyle(fontSize: 13))),
                                Expanded(
                                    child: Text(item.quantity.toString(),
                                        style: const TextStyle(fontSize: 13))),
                                
                                /*Expanded(
                                  child: Text(
                                    item.status,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: item.status == 'M' ? Colors.red.shade700 : Colors.teal.shade700
                                    )
                                  )
                                ),*/

                                Expanded(
                                  //flex: 3,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      // Define uma largura MÍNIMA e MÁXIMA fixa (e igual) para uniformizar o chip.
                                      constraints: const BoxConstraints(
                                        minWidth: 90,
                                        maxWidth: 90, 
                                        minHeight: 0, 
                                        maxHeight: 25,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(item.status.toUpperCase()),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: getTextColor(item.status.toUpperCase()).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Center( 
                                        child: Text(
                                          _mapStatus(item.status),
                                          style: TextStyle(
                                            color: getTextColor(item.status.toUpperCase()),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            height: 1, 
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          // ação ao tocar
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

    // Função de ajuda com cores
  Color getStatusColor(String status) {
    switch (status) {
      case 'I':
        return Colors.blue[100]!; // Fundo azul claro e suave
      case 'M':
        return Colors.amber[100]!; // Fundo amarelo claro e suave
      case 'R':
        return Colors.green[100]!; // Fundo verde claro e suave
      default:
        return Colors.grey[200]!;
    }
  }

  // Função para a cor do texto
  Color getTextColor(String status) {
    switch (status) {
      case 'I':
        return Colors.blue[800]!;
      case 'M':
        return Colors.amber[800]!;
      case 'R':
        return Colors.green[800]!;
      default:
        return Colors.grey[700]!;
    }
  }

    // Função para mapear o status de código para o texto completo e definir a cor.
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

}