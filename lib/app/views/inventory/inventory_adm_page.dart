import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/services/load_service.dart';
import 'package:oxdata/app/views/inventory/inventory_adm_records_page.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/utils/download_file.dart';
import 'package:oxdata/app/views/inventory/down_inventory_dialog.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class InventoryAdmPage extends StatefulWidget {
  const InventoryAdmPage({super.key});

  @override
  State<InventoryAdmPage> createState() => _InventoryAdmPageState();
}

class _InventoryAdmPageState extends State<InventoryAdmPage> {
  bool _isLoading = true;
  List<InventoryModel> _allInventories = [];

  final TextEditingController _searchController = TextEditingController();
  String          _searchQuery = "";
  String?         _selectedStatus;
  DateTimeRange?  _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInventories();
    });
  }

  Future<void> _fetchInventories() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final inventoryService = context.read<InventoryService>();
      await inventoryService.fetchAllInventoriesFromApiOnly();
      
      if (mounted) {
        setState(() {
          _allInventories = inventoryService.inventories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao buscar inventários: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        MessageService.showError("Erro ao carregar a lista de inventários.");
      }
    }
  }

  Future<void> _downloadInventoryTxt(InventoryModel inventory) async {
    try {
      final selectedColumns = await showDialog<List<String>>(
        context: context,
        builder: (_) => DownloadInventoryDialog(
          inventoryCode: inventory.inventCode ?? '',
        ),
      );

      if (selectedColumns == null || selectedColumns.isEmpty) {
        MessageService.showError("Selecione pelo menos uma coluna.");
        return;
      }

      final records = await context
          .read<InventoryService>()
          .getRecordsListByInventCode(inventory.inventCode ?? '');

      if (records.isEmpty) {
        MessageService.showError("Nenhum registro encontrado.");
        return;
      }

      final buffer = StringBuffer();

      for (final r in records) {
        // Devolve o Map de forma limpa sem serializar devarde
        final Map<String, dynamic> jsonMap = r.toMap();

        final line = selectedColumns.map((col) {
          final value = jsonMap[col];
          if (value == null) return "";
          
          String strValue = value.toString();
          
          // Remove o zero à esquerda apenas na penúltima coluna
          final colIndex = selectedColumns.indexOf(col);
          if (colIndex == selectedColumns.length - 2) {
            strValue = strValue.replaceFirst(RegExp(r'^0+'), '');
          }
          
          return strValue;
        }).join(";");

        buffer.write(line);
        buffer.write('\r\n');
      }

      final txtContent = buffer.toString();

      await DownloadFile.saveTxt(
        txtContent,
        "${inventory.inventCode}.txt",
      );

      MessageService.showSuccess(
        "Download do inventário ${inventory.inventCode} concluído!",
      );
    } catch (e) {
      MessageService.showError("Falha ao gerar arquivo de download.");
    }
  }

  Future<void> _confirmDelete(InventoryModel inventory) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Exclusão"),
        content: Text("Deseja realmente excluir o inventário '${inventory.inventName}'? Esta ação não pode ser desfeita."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final inventoryService = context.read<InventoryService>();

        await inventoryService.deleteAllRecordsByInventCode(inventory.inventCode);
        await inventoryService.refreshSelectedInventoryState(inventory.inventCode);

        if (mounted) {
          await _fetchInventories(); // Atualiza a lista da página
          MessageService.showSuccess("Inventário '${inventory.inventName}' excluído com sucesso!");
        }
      } catch (e) {
        debugPrint("Erro ao excluir inventário: $e");
        if (mounted) {
          MessageService.showError("Erro ao excluir o inventário.");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredInventories = _allInventories.where((item) {
      final searchLower = _searchQuery.toLowerCase();
      final name = item.inventName?.toLowerCase() ?? "";
      final code = item.inventCode?.toLowerCase() ?? "";
      final sector = item.inventSector?.toLowerCase() ?? "";
      final user = item.inventUser?.toLowerCase() ?? "";
      
      final bool isFinalizado = item.inventStatus.toString().toLowerCase().contains('finalizado');
      final String statusText = isFinalizado ? "Concluído" : "Em andamento";
      
      final matchesSearch = name.contains(searchLower) || code.contains(searchLower) || sector.contains(searchLower) || user.contains(searchLower);
      final matchesStatus = _selectedStatus == null || statusText == _selectedStatus;
      final matchesDate = _selectedDateRange == null || (item.inventCreated != null && 
          item.inventCreated!.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
          item.inventCreated!.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();

    final int totalFiles = filteredInventories.length;
    final double totalItemsCounted = filteredInventories.fold(0.0, (sum, item) => sum + (item.inventTotal ?? 0));
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppBarCustom(title: 'Apuração do Inventário'),
      body: Column(
        children: [
          _buildSearchField(isDesktop),
          _buildTotalizersCards(totalFiles, totalItemsCounted, isDesktop),
          Expanded(
            child: _isLoading
                ? const Center(child: SpinKitThreeBounce(color: Colors.white, size: 30.0))
                : RefreshIndicator(
                    onRefresh: _fetchInventories,
                    color: Colors.indigo,
                    child: filteredInventories.isEmpty
                        ? _buildEmptyState()
                        : Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1400),
                              child: isDesktop
                                  ? _buildWebGridTable(filteredInventories)
                                  : _buildMobileCardsList(filteredInventories),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16.0 : 10.0, vertical: 14.0),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Filtrar inventários..',
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
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                        color: Colors.indigo,
                        width: 1,
                      ),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.filter_list_rounded, color: _selectedStatus != null ? Colors.indigo : Colors.grey),
                onPressed: () async {
                  final String? result = await showModalBottomSheet<String>(
                    context: context,
                    builder: (ctx) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(title: const Text("Todos"), onTap: () => Navigator.pop(ctx, null)),
                        ListTile(title: const Text("Concluído"), onTap: () => Navigator.pop(ctx, "Concluído")),
                        ListTile(title: const Text("Em andamento"), onTap: () => Navigator.pop(ctx, "Em andamento")),
                      ],
                    ),
                  );
                  setState(() => _selectedStatus = result);
                },
              ),
              IconButton(
                icon: Icon(Icons.calendar_today_rounded, color: _selectedDateRange != null ? Colors.indigo : Colors.grey),
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                    initialDateRange: _selectedDateRange,
                  );
                  if (range != null) setState(() => _selectedDateRange = range);
                },
              ),
              if (_selectedStatus != null || _selectedDateRange != null)
                IconButton(
                  icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.red),
                  onPressed: () => setState(() {
                    _selectedStatus = null;
                    _selectedDateRange = null;
                  }),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.indigo),
                tooltip: 'Atualizar Lista',
                onPressed: _isLoading ? null : () => _fetchInventories(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalizersCards(int files, double items, bool isDesktop) {
    final formatter = NumberFormat.decimalPattern('pt_BR');

    final cards = [
      _buildKPIItem("Total Contagens", files.toDouble(), Icons.folder_open_rounded, Colors.indigo,),
      _buildKPIItem("Total Itens", items.toDouble(), Icons.playlist_add_check_rounded, Colors.teal, 2,),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 6.0 : 1.0,
        vertical: isDesktop ? 4.0 : 1.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: isDesktop
              ? Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 16),
                    Expanded(child: cards[1]),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 8),
                    Expanded(child: cards[1]),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildKPIItem(String title, double? value, IconData icon, Color color, [int decimalDigits = 0,]) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                NumberFormat.decimalPatternDigits(
                  locale: 'pt_BR',
                  decimalDigits: decimalDigits,
                ).format(value ?? 0.0),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }


  Widget _buildWebGridTable(List<InventoryModel> list) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            color: const Color(0xFFF1F5F9), // 🎨 Adicionado o padrão de cor de fundo aqui
            child: const Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    "USUÁRIO",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "CÓDIGO",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "NOME",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "SETOR",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "QUANTIDADE",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "SITUAÇÃO",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Text(
                    "AÇÕES",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = list[index];

                final isFinalizado = item.inventStatus
                    .toString()
                    .toLowerCase()
                    .contains('finalizado');

                final statusColor =
                    isFinalizado ? Colors.green : Colors.orange;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0,),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          item.inventUser ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.inventCode ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.inventName ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.inventSector ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2).format(item.inventTotal ?? 0.0),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isFinalizado
                                  ? "CONCLUÍDO"
                                  : "EM ANDAMENTO",
                              style: TextStyle(
                                color: statusColor.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              iconSize: 18,
                              icon: const Icon(
                                Icons.file_download_rounded,
                              ),
                              tooltip: 'Baixar TXT',
                              onPressed: isFinalizado
                                  ? () => _downloadInventoryTxt(item)
                                  : null,
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              iconSize: 18,
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                              ),
                              tooltip: 'Excluir',
                              onPressed: () => _confirmDelete(item),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              iconSize: 18,
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.indigo,
                              ),
                              tooltip: 'Abrir',
                              onPressed: () => _selectInventoryRow(item),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCardsList(List<InventoryModel> list) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];

          final isFinalizado =
              item.inventStatus.toString().toLowerCase().contains('finalizado');

          final statusColor = isFinalizado ? Colors.green : Colors.orange;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10), 
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _selectInventoryRow(item),
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
                          // Padding interno mais compacto (10 horizontal, 8 vertical)
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.inventCode ?? '',
                                      style: const TextStyle(
                                        color: Colors.indigo,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2, // Tag de status mais fininha
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isFinalizado ? 'CONCLUÍDO' : 'EM ANDAMENTO',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4), // Reduzido de 6 para 4

                              Text(
                                item.inventName ?? '',
                                style: const TextStyle(
                                  fontSize: 15, // Reduzido de 17 para 15
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D3142),
                                ),
                              ),

                              // Linha combinada: Setor na esquerda e Botões na direita
                              Row(
                                children: [
                                  const Icon(
                                    Icons.factory_rounded,
                                    size: 16, // Reduzido de 16
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.inventSector ?? 'Geral',
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1, // Previne quebra de linha indesejada
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Usando constraints para remover o padding gigante do IconButton
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 32, minHeight: 32),
                                    icon: const Icon(Icons.file_download_rounded, size: 22),
                                    onPressed: isFinalizado
                                        ? () => _downloadInventoryTxt(item)
                                        : null,
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 32, minHeight: 32),
                                    icon: const Icon(Icons.delete_outline_rounded,
                                        color: Colors.red, size: 22),
                                    onPressed: () => _confirmDelete(item),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 32, minHeight: 32),
                                    icon: const Icon(Icons.arrow_forward_rounded,
                                        color: Colors.indigo, size: 22),
                                    onPressed: () => _selectInventoryRow(item),
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
        },
      );
    }

  
  /*void _selectInventoryRow(InventoryModel inventory) {
    context.read<InventoryService>().setSelectedInventory(inventory);
    context.read<InventoryService>().fetchRecordsByInventCode(inventory.inventCode);
    context.read<LoadService>().setPage(0);
  }*/

  void _selectInventoryRow(InventoryModel inventory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryAdmRecordsPage(
          inventory: inventory,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("Nenhum inventário encontrado."));
  }

  String _formatDateTime(DateTime? dateTime) => dateTime == null ? '--' : DateFormat('dd/MM/yyyy').format(dateTime);
  String _formatQty(double? value) => value?.toString() ?? "0";
}
