import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/services/load_service.dart';
import 'package:oxdata/app/core/widgets/app_confirm_dialog.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// -------------------------------------------------------------------
// WIDGET REUTILIZÁVEL: _ColorChangingButton
// -------------------------------------------------------------------
class _ColorChangingButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  const _ColorChangingButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.size = 54,
    this.color,
  }) : super(key: key);

  @override
  State<_ColorChangingButton> createState() => __ColorChangingButtonState();
}

class __ColorChangingButtonState extends State<_ColorChangingButton> {
  late Color _containerColor;

  final Color _defaultColor = const Color(0xFFE3F2FD);
  final Color _darkerColor = const Color.fromARGB(255, 187, 211, 251);
  final Color _primaryIconColor = const Color(0xFF3F51B5);

  @override
  void initState() {
    super.initState();
    _containerColor = widget.color ?? _defaultColor;
  }

  // Função que faz a "piscadinha"
  void _handleTap() async {
    if (widget.onPressed == null) return;

    setState(() {
      // Escurece a cor ao tocar
      _containerColor = widget.color != null 
          ? widget.color!.withOpacity(0.7) 
          : _darkerColor;
    });

    // Pequeno delay para o olho humano perceber a mudança
    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      setState(() {
        _containerColor = widget.color ?? _defaultColor;
      });
    }

    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100), // Transição rápida
        height: widget.size,
        width: widget.size,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[200] : _containerColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            widget.icon,
            color: isDisabled 
                ? Colors.grey[400] 
                : (widget.color != null ? Colors.white : _primaryIconColor),
            // Aumentado de 0.55 para 0.7 para o ícone ficar maior
            size: widget.size * 0.7, 
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------
// CARD DE INVENTÁRIO
// -------------------------------------------------------------------
class _InventoryCard extends StatelessWidget {
  final InventoryModel inventory;

  const _InventoryCard({required this.inventory});

  @override
  Widget build(BuildContext context) {
    final bool isFinalizado = inventory.inventStatus.name == 'Finalizado';
    final Color statusColor = isFinalizado ? Colors.green : Colors.orange;

    final String dateText = inventory.inventCreated != null
        ? DateFormat('dd/MM/yyyy').format(inventory.inventCreated!.toLocal())
        : "--/--/----";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          context.read<InventoryService>().setSelectedInventory(inventory);
          context.read<InventoryService>().fetchRecordsByInventCode(inventory.inventCode);
          context.read<LoadService>().setPage(1);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "#${inventory.inventCode ?? "---"}",
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                            _buildStatusBadge(inventory.inventStatus.name, statusColor),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          inventory.inventName ?? "Inventário sem título",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2D3142)),
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFF1F1F1)),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 15,
                                runSpacing: 15,
                                children: [
                                  _buildInfoItem(Icons.business_rounded, "Setor", inventory.inventSector ?? "Geral"),
                                  _buildInfoItem(Icons.person_outline_rounded, "Usuário", inventory.inventUser ?? "N/D"),
                                  _buildInfoItem(Icons.calendar_today_rounded, "Data", dateText),
                                  _buildInfoItem(Icons.inventory_2_outlined, "Total Peças", inventory.inventTotal?.toString() ?? "0", isBold: true),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Column(
                                children: [
                                  _buildActionButton(context, isFinalizado,),
                                  const SizedBox(height: 10),
                                  _buildSincButton(context, isFinalizado, inventory.isSynced),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {bool isBold = false}) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: isBold ? Colors.indigo[900] : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool isFinalizado) {
    return _ColorChangingButton(
      size: 50,
      icon: Icons.playlist_add_check,
      color: isFinalizado ? const Color(0xFFE3F2FD) : null,
      onPressed: isFinalizado ? null : () => _showConfirmFinalizeDialog(context),
    );
  }

  Widget _buildSincButton(BuildContext context, bool isFinalizado, bool? isSynced) {
    final bool synced = isSynced ?? false;
    return _ColorChangingButton(
      size: 50,
      icon: synced ? Icons.cloud_sync : Icons.cloud_sync_outlined,
      color: isFinalizado ? const Color(0xFFE3F2FD) : null,
      onPressed: (isFinalizado && !synced) 
          ? () => _showConfirmSyncDialog(context) 
          : null,
    );
  }

  /// MÉTODO PARA FINALIZAR
  void _showConfirmFinalizeDialog(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      message: "Deseja realmente finalizar a contagem #${inventory.inventCode}?",
    );

    if (confirmed) {
      final inventoryService = context.read<InventoryService>();
      
      // Criamos uma nova instância com o status atualizado
      // Se o seu model não tiver copyWith, você pode instanciar um novo InventoryModel
      // passando os campos do 'inventory' atual.
      final updatedInventory = inventory.copyWith(
        inventStatus: InventoryStatus.Finalizado,
      );

      // Chama o serviço para persistir no Banco de Dados
      await inventoryService.createOrUpdateInventory(updatedInventory);
      
      if (context.mounted) {
        MessageService.showSuccess("Inventário #${inventory.inventCode} finalizado com sucesso!");
      }
    }
  }

  /// MÉTODO PARA SINCRONIZAR
  void _showConfirmSyncDialog(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      message: "Deseja sincronizar o inventário #${inventory.inventCode} com a nuvem?",
    );

    if (confirmed) {
      debugPrint("Iniciando upload para a nuvem...");

    }
  } 

}

// ---------------------------------------------------------------------------------------------------
// PÁGINA PRINCIPAL
// ---------------------------------------------------------------------------------------------------
class SearchInventoryPage extends StatefulWidget {
  static final GlobalKey<_SearchInventoryPageState> inventoryKey = GlobalKey<_SearchInventoryPageState>();
  const SearchInventoryPage({super.key});

  @override
  State<SearchInventoryPage> createState() => _SearchInventoryPageState();
}

class _SearchInventoryPageState extends State<SearchInventoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final service = Provider.of<InventoryService>(context, listen: false);
      await service.initializeDeviceId();
      await service.fetchAllInventories();
    });
  }

  void _onSearchChanged() {
    context.read<InventoryService>().filterInventoryByGuid(_searchController.text.trim());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventories = context.watch<InventoryService>().inventories;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
              },
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Pesquisar..',
                hintStyle: TextStyle(
                  color: Colors.blueGrey[300],
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.indigo,
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                
                // ESTA É A PARTE QUE VOCÊ PRECISAVA:
                // O 'border' padrão garante que o preenchimento (fillColor) seja arredondado
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Colors.indigo, width: 1),
                ),
              ),
            ),
          ),
          Expanded(
            child: inventories.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(10.0),
                    itemCount: inventories.length,
                    itemBuilder: (context, index) => _InventoryCard(inventory: inventories[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Nenhum inventário encontrado',
            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/*import 'package:flutter/material.dart';
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
  static final GlobalKey<_SearchInventoryPageState> inventoryKey = GlobalKey<_SearchInventoryPageState>();
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final service = Provider.of<InventoryService>(context, listen: false);

      await service.initializeDeviceId(); // AGUARDA (*********** ISSO DEVE SER INICIADO NO SERVIÇO DE CONTROLE DE PERMISSÃO NO FUTURO ***********)
      await service.fetchAllInventories();
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

      // MÉTODO PARA SALVAR
  Future<void> saveNewInventory() async {
    final inventoryService = Provider.of<InventoryService>(context, listen: false);
    final currentInventory = inventoryService.selectedInventory;
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
*/