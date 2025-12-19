import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/services/load_service.dart';
import 'package:intl/intl.dart';


// CLASSE _InventoryCard (Mantida inalterada)
class _InventoryCard extends StatelessWidget {
  final InventoryModel inventory; 

  const _InventoryCard({required this.inventory});

  @override
  Widget build(BuildContext context) {
    String statusText = inventory.inventStatus.name;
    final Color statusColor = statusText == 'Finalizado' ? Colors.grey : Colors.green;
    final String dateText = inventory.inventCreated != null
        ? DateFormat('dd/MM/yyyy').format(inventory.inventCreated!.toLocal())
        : "Data Desconhecida";

    return InkWell(
      onTap: () {

        context.read<InventoryService>().setSelectedInventory(inventory);
        context.read<InventoryService>().fetchRecordsByInventCode(inventory.inventCode);
        context.read<LoadService>().setPage(1);
        
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0), 
        ),
        
        margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    inventory.inventCode ?? "Sem Código", 
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                dateText, 
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Rótulo "Total:"
                  Text(
                    'Total: ', // Adicione os dois pontos e um espaço
                    style: TextStyle(
                    fontSize: 16, 
                    color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    inventory.inventTotal.toString(),
                    style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CLASSE PRINCIPAL (SearchInventoryPage)
class SearchInventoryPage extends StatefulWidget {
  const SearchInventoryPage({super.key});

  @override
  State<SearchInventoryPage> createState() => _SearchInventoryPageState();
}

class _SearchInventoryPageState extends State<SearchInventoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Adiciona listener para monitorar a mudança no campo de pesquisa
    _searchController.addListener(_onSearchChanged);

    // CHAMA A BUSCA INICIAL. O fetchAllInventories DEVE CARREGAR A LISTA COMPLETA 
    // E SALVÁ-LA EM UMA VARIÁVEL INTERNA NO InventoryService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryService>(context, listen: false).fetchAllInventories();
    });
  }

  // 🔑 AJUSTE APLICADO: O método é SÍNCRONO e chama diretamente o método de filtro no Service.
  void _onSearchChanged() {
    final inventoryService = context.read<InventoryService>();
    final search = _searchController.text.trim();
    
    // Chama o método no Service. O Service DEVE agora filtrar a lista _allInventories
    // em memória (localmente) e atualizar a lista 'inventories'.
    inventoryService.filterInventoryByGuid(search);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Acessa a lista de inventários usando context.watch
    final inventories = context.watch<InventoryService>().inventories;
    
    return Scaffold(
      backgroundColor: Colors.transparent, 
      
      // Floating Action Button
      /*floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicionar novo inventário pressionado!')),
          );
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),*/
      
      // Corpo Principal da Lista
      body: Column(
        children: [
          // Barra de Pesquisa
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Pesquisar por Inventário GUID ou Código...',
                filled: true,
                fillColor: Colors.white,
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 15,
                ),
                prefixIcon: const Icon(Icons.search, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),
          
          // Lista de Inventários (Usando a lista observada via context.watch)
          Expanded(
            child: inventories.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Nenhum inventário encontrado. Tente buscar por GUID ou Código.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    itemCount: inventories.length,
                    itemBuilder: (context, index) {
                      return _InventoryCard(inventory: inventories[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}