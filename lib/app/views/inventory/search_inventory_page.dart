import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/services/load_service.dart';
import 'package:oxdata/app/core/widgets/app_confirm_dialog.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

final _dateFormatter = DateFormat('dd/MM/yyyy');

// -------------------------------------------------------------------
// WIDGET REUTILIZÁVEL: _ColorChangingButton
// -------------------------------------------------------------------
class _ColorChangingButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  const _ColorChangingButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 54,
    this.color,
  });

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

  void _handleTap() async {
    if (widget.onPressed == null) return;

    setState(() {
      _containerColor = widget.color != null 
          ? widget.color!.withOpacity(0.7) 
          : _darkerColor;
    });

    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      setState(() {
        _containerColor = widget.color ?? _defaultColor;
      });
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
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
            size: widget.size * 0.7, 
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------
// CARD DE INVENTÁRIO (Componentizado)
// -------------------------------------------------------------------
class _InventoryCard extends StatelessWidget {
  final InventoryModel inventory;

  const _InventoryCard({super.key, required this.inventory});

  @override
  Widget build(BuildContext context) {
    final bool isFinalizado = inventory.inventStatus == InventoryStatus.Finalizado;
    final Color statusColor = isFinalizado ? Colors.green : Colors.orange;

    final String dateText = inventory.inventCreated != null 
        ? _dateFormatter.format(inventory.inventCreated!.toLocal()) 
        : "--/--/----";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          final service = context.read<InventoryService>();
          service.setSelectedInventory(inventory);
          service.fetchRecordsByInventCode(inventory.inventCode);
          if(inventory.inventStatus == InventoryStatus.Iniciado) {
            context.read<LoadService>().setPage(1);
          } else {
            context.read<LoadService>().setPage(2);
          }
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
                              inventory.inventCode,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                            _buildStatusBadge(inventory.inventStatus.name, statusColor),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          inventory.inventName,
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
                                  _buildActionButton(context, isFinalizado),
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
                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600, letterSpacing: 0.5),
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
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool isFinalizado) {
    return _ColorChangingButton(
      size: 50,
      icon: Icons.playlist_add_check,
      color: null,
      onPressed: isFinalizado ? null : () => _showConfirmFinalizeDialog(context),
    );
  }

  Widget _buildSincButton(BuildContext context, bool isFinalizado, bool? isSynced) {
    final bool synced = isSynced ?? false;
    return _ColorChangingButton(
      size: 50,
      icon: synced ? Icons.cloud_sync : Icons.cloud_sync_outlined,
      color: null,
      onPressed: (isFinalizado) 
          ? () => _showConfirmSyncDialog(context) 
          : null,
    );
  }

  void _showConfirmFinalizeDialog(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      message: "Deseja realmente finalizar a contagem #${inventory.inventCode}?",
    );

    if (confirmed) {
      final inventoryService = context.read<InventoryService>();
      final updatedInventory = inventory.copyWith(
        inventStatus: InventoryStatus.Finalizado,
      );
      await inventoryService.createOrUpdateInventory(updatedInventory);
      if (context.mounted) {
        final service = context.read<InventoryService>();
        final loadingService = context.read<LoadingService>();

        loadingService.show();
        await service.fetchAllInventories();
        loadingService.hide();

        MessageService.showSuccess("Inventário #${inventory.inventCode} finalizado com sucesso!");
      }
    }
  }

  void _showConfirmSyncDialog(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      message: "Deseja sincronizar o inventário #${inventory.inventCode} com a nuvem?",
    );

    if (!confirmed) return;

    final inventoryService = context.read<InventoryService>();
    final loadingService = context.read<LoadingService>();

    try {
      loadingService.show();
      await inventoryService.startSyncInventory(inventory.inventCode);
      if (context.mounted) {
        loadingService.hide();
        MessageService.showSuccess("Inventário #${inventory.inventCode} sincronizado!");
      }
    } catch (e) {
      if (context.mounted) {
        loadingService.hide();
        MessageService.showError("Falha na sincronização: ${e.toString()}");
      }
    } finally {
      loadingService.hide();
    }
  }
}

// ---------------------------------------------------------------------------------------------------
// PÁGINA PRINCIPAL
// ---------------------------------------------------------------------------------------------------
class SearchInventoryPage extends StatefulWidget {
  const SearchInventoryPage({super.key});

  @override
  State<SearchInventoryPage> createState() => _SearchInventoryPageState();
}

class _SearchInventoryPageState extends State<SearchInventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final service = context.read<InventoryService>();
      final loadingService = context.read<LoadingService>();
      
      try {
        loadingService.show();
        await service.initializeDeviceId();
        await service.fetchAllInventories();
        loadingService.hide();
      } catch (e) {
        MessageService.showError('Erro interno: $e');
      } finally {
        if (mounted) {
          loadingService.hide();
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<InventoryService>().filterInventoryByGuid(value.trim());
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
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
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildSearchField(),
          ),
          Expanded(
            child: Consumer<InventoryService>(
              builder: (context, service, _) {
                final inventories = service.inventories;

                if (inventories.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10.0),
                  itemCount: inventories.length,
                  cacheExtent: 100,
                  itemBuilder: (context, index) {
                    final item = inventories[index];
                    return _InventoryCard(
                      inventory: item,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
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
                  _onSearchChanged("");
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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



/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/services/load_service.dart';
import 'package:oxdata/app/core/widgets/app_confirm_dialog.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

final _dateFormatter = DateFormat('dd/MM/yyyy');

// -------------------------------------------------------------------
// WIDGET REUTILIZÁVEL: _ColorChangingButton
// -------------------------------------------------------------------
class _ColorChangingButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  const _ColorChangingButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 54,
    this.color,
  });

  @override
  State<_ColorChangingButton> createState() => __ColorChangingButtonState();
}

class __ColorChangingButtonState extends State<_ColorChangingButton> {
  late Color _containerColor;

  final Color _defaultColor =     const Color(0xFFE3F2FD);
  final Color _darkerColor =      const Color.fromARGB(255, 187, 211, 251);
  final Color _primaryIconColor = const Color(0xFF3F51B5);

  @override
  void initState() {
    super.initState();
    _containerColor = widget.color ?? _defaultColor;
  }

  void _handleTap() async {
    if (widget.onPressed == null) return;

    setState(() {
      _containerColor = widget.color != null 
          ? widget.color!.withOpacity(0.7) 
          : _darkerColor;
    });

    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      setState(() {
        _containerColor = widget.color ?? _defaultColor;
      });
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
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
            size: widget.size * 0.7, 
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------
// CARD DE INVENTÁRIO (Componentizado)
// -------------------------------------------------------------------
class _InventoryCard extends StatelessWidget {
  final InventoryModel inventory;

  const _InventoryCard({super.key, required this.inventory});

  
  @override
  Widget build(BuildContext context) {
    final bool isFinalizado = inventory.inventStatus == InventoryStatus.Finalizado;
    final Color statusColor = isFinalizado ? Colors.green : Colors.orange;

    final String dateText = inventory.inventCreated != null ? _dateFormatter.format(inventory.inventCreated!.toLocal()) : "--/--/----";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          final service = context.read<InventoryService>();
          service.setSelectedInventory(inventory);
          service.fetchRecordsByInventCode(inventory.inventCode);
          if(inventory.inventStatus == InventoryStatus.Iniciado)
          {
            context.read<LoadService>().setPage(1);
          }
          else
          {
            context.read<LoadService>().setPage(2);
          }
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
                              inventory.inventCode,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                            _buildStatusBadge(inventory.inventStatus.name, statusColor),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          inventory.inventName,
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
                                  _buildActionButton(context, isFinalizado),
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
                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600, letterSpacing: 0.5),
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
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool isFinalizado) {
    return _ColorChangingButton(
      size: 50,
      icon: Icons.playlist_add_check,
      color: null,
      onPressed: isFinalizado ? null : () => _showConfirmFinalizeDialog(context),
    );
  }

  Widget _buildSincButton(BuildContext context, bool isFinalizado, bool? isSynced) {
    final bool synced = isSynced ?? false;
    return _ColorChangingButton(
      size: 50,
      icon: synced ? Icons.cloud_sync : Icons.cloud_sync_outlined,
      color: null,
      onPressed: (isFinalizado) 
          ? () => _showConfirmSyncDialog(context) 
          : null,
    );
  }

  void _showConfirmFinalizeDialog(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      message: "Deseja realmente finalizar a contagem #${inventory.inventCode}?",
    );

    if (confirmed) {
      final inventoryService = context.read<InventoryService>();
      final updatedInventory = inventory.copyWith(
        inventStatus: InventoryStatus.Finalizado,
      );
      await inventoryService.createOrUpdateInventory(updatedInventory);
      if (context.mounted) {
        final service = context.read<InventoryService>();
        final loadingService = context.read<LoadingService>();

        loadingService.show();

        await service.fetchAllInventories();

        loadingService.hide();

        MessageService.showSuccess("Inventário #${inventory.inventCode} finalizado com sucesso!");
        
      }
    }
  }

  void _showConfirmSyncDialog(BuildContext context) async {
    // 1. Confirmação prévia
    final confirmed = await showConfirmDialog(
      context: context,
      message: "Deseja sincronizar o inventário #${inventory.inventCode} com a nuvem?",
    );

    if (!confirmed) return;

    final inventoryService = context.read<InventoryService>();
    final loadingService = context.read<LoadingService>();

    try {
      loadingService.show();
      await inventoryService.startSyncInventory(inventory.inventCode);
      if (context.mounted) {
        loadingService.hide();
        MessageService.showSuccess("Inventário #${inventory.inventCode} sincronizado!");
      }
    } catch (e) {
      if (context.mounted) {
        loadingService.hide();
        MessageService.showError("Falha na sincronização: ${e.toString()}");
      }
    } finally {
        loadingService.hide();
    }
  }

}

// ---------------------------------------------------------------------------------------------------
// PÁGINA PRINCIPAL
// ---------------------------------------------------------------------------------------------------
class SearchInventoryPage extends StatefulWidget {
  const SearchInventoryPage({super.key});

  @override
  State<SearchInventoryPage> createState() => _SearchInventoryPageState();
}

class _SearchInventoryPageState extends State<SearchInventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce; // Controle de Debounce

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final service = context.read<InventoryService>();
      final loadingService = context.read<LoadingService>();
      
      try {

        loadingService.show();

        await service.initializeDeviceId();
        await service.fetchAllInventories();

        loadingService.hide();

      } catch (e) {
        MessageService.showError('Erro interno: $e');

      } finally {
        if (mounted) {
          loadingService.hide();
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Lógica de busca com Debounce (evita processamento excessivo ao digitar)
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Atualiza apenas o ícone de limpar instantaneamente
    setState(() {});

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<InventoryService>().filterInventoryByGuid(value.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildSearchField(),
          ),
          Expanded(
            // Selector reconstrói APENAS esta parte quando a lista 'inventories' muda no Service
            child: Selector<InventoryService, List<InventoryModel>>(
              selector: (_, service) => service.inventories,
              builder: (context, inventories, child) {
                if (inventories.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(10.0),
                  itemCount: inventories.length,
                  cacheExtent: 100, // Melhora performance de scroll
                  itemBuilder: (context, index) {
                    final item = inventories[index];
                    return _InventoryCard(
                      key: ValueKey(item.inventCode), // Performance de reciclagem
                      inventory: item,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
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
                  _onSearchChanged("");
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

*/