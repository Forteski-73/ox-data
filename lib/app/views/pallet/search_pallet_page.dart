import 'package:flutter/material.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/pallet_service.dart';
import 'package:oxdata/app/core/models/pallet_model.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:provider/provider.dart';
import 'pallet_builder_page.dart';

class SearchPalletPage extends StatefulWidget {
  const SearchPalletPage({super.key});

  @override
  State<SearchPalletPage> createState() => _SearchPalletPageState();
}

class _SearchPalletPageState extends State<SearchPalletPage> {
  @override
  void initState() {
    super.initState();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPallets();
      });
    }
  }

  // Método para carregar todos os paletes ao iniciar a página
  Future<void> _loadPallets() async {
    final loadingService = context.read<LoadingService>();
    final palletService = context.read<PalletService>();

    await CallAction.run(
      action: () async {
        loadingService.show();
        await palletService.fetchAllPallets();
      },
      onFinally: () {
        loadingService.hide();
      },
    );
  }
  
  // Limpa todos os paletes e os resultados da pesquisa
  void _clearPallets() {
    context.read<PalletService>().clearResults();
  }


  // Função para mapear o status de código para o texto completo.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer<PalletService>(
          builder: (context, palletService, child) {
            final int totalCount = palletService.pallets.length;
            final String title = 'Paletes: $totalCount';
            return AppBarCustom(title: title);
          },
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
            child: Consumer<PalletService>(
              builder: (context, palletService, child) {
                final pallets = palletService.pallets;
                return pallets.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum palete encontrado.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: pallets.length,
                        itemBuilder: (context, index) {
                          final PalletModel palletData = pallets[index];
                          return Card(
                            color: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                            margin: const EdgeInsets.only(bottom: 2.0, top: 3.0),
                            child: InkWell(
                              onTap: () {
                                // Navega para a PalletBuilderPage, passando o palete selecionado.
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PalletBuilderPage(pallet: palletData),
                                  ),
                                ).then((value) {
                                  // Recarrega a lista de paletes após voltar para a página
                                  _loadPallets();
                                });
                              },
                              splashColor: const Color.fromARGB(255, 65, 65, 65).withAlpha((255 * 0.2).round()),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.pallet, size: 85, color: Colors.indigo),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Text(
                                              'Número: ${palletData.palletId}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              softWrap: false,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Localização: ${palletData.location}'),
                                              const SizedBox(height: 4),
                                              Text('Status: ${_mapStatus(palletData.status)}'),
                                              const SizedBox(height: 4),
                                              Text('Total de Itens: ${palletData.totalQuantity}'),
                                            ],
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
              },
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _loadPallets,
              label: const Text('NOVO'),
              icon: const Icon(Icons.add_outlined),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4), // borda arredondada em 4
              ),
            ),
          ),
        ],
      ),
    );
  }
}
