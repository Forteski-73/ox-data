import 'package:flutter/material.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/pallet_service.dart';
import 'package:oxdata/app/core/models/pallet_item_model.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:provider/provider.dart';

// O widget agora aceita o termo de pesquisa como um parâmetro.
class PalletItemsTab extends StatefulWidget {
  final String searchQuery;

  const PalletItemsTab({
    super.key,
    required this.searchQuery,
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
        _loadAllItems();
      });
    }
  }

  Future<void> _loadAllItems() async {
    final loadingService = context.read<LoadingService>();
    final palletService = context.read<PalletService>();

    final start = DateTime.now();
    const minDuration = Duration(seconds: 1);

    await CallAction.run(
      action: () async {
        loadingService.show();
        await palletService.fetchAllPalletItems();
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
                              Expanded(
                                  child: Text(item.status,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: item.status == 'M'
                                              ? Colors.red.shade700
                                              : Colors.teal.shade700))),
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
}