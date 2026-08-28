import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:oxdata/app/core/models/dto/inventory_audit_model.dart';
import 'package:oxdata/app/core/models/invent_location_model.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Aba "Conferência de Divergência" da InventoryAdmPage.
///
/// Busca no endpoint `AuditResult` os itens de um ou mais depósitos,
/// comparando o total contado (`totalInvent`) com o saldo do sistema
/// (`availPhysical`), e lista o resultado em formato de grid
/// (tabela no desktop / cards no mobile), seguindo o mesmo padrão
/// visual da InventoryTabLista.
class InventoryTabChkDiff extends StatefulWidget {
  const InventoryTabChkDiff({super.key});

  @override
  State<InventoryTabChkDiff> createState() => _InventoryTabChkDiffState();
}

class _InventoryTabChkDiffState extends State<InventoryTabChkDiff> {
  bool _isLoading = false;
  bool _hasSearched = false;
  List<InventoryAuditModel> _results = [];

  bool _loadingLocations = false;
  List<InventorLocationModel> _availableLocations = [];
  List<InventorLocationModel> _selectedLocations = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocations();
    });
  }

  Future<void> _loadLocations() async {
    if (!mounted) return;
    setState(() => _loadingLocations = true);

    try {
      final inventoryService = context.read<InventoryService>();
      final locations = await inventoryService.getActiveLocations();

      if (mounted) {
        setState(() {
          _availableLocations = locations;
          _loadingLocations = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao buscar depósitos: $e");
      if (mounted) {
        setState(() => _loadingLocations = false);
        MessageService.showError("Erro ao carregar a lista de depósitos.");
      }
    }
  }

  Future<void> _fetchAuditResult() async {
    if (_selectedLocations.isEmpty) {
      MessageService.showError("Selecione ao menos um depósito para buscar.");
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final inventoryService = context.read<InventoryService>();
      final combined = <InventoryAuditModel>[];

      // Busca sequencialmente cada depósito selecionado e agrega os resultados.
      for (final location in _selectedLocations) {
        final results = await inventoryService.getInventoryAuditResult(
          location.inventLocationId,
        );
        combined.addAll(results);
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _results = combined;
      });

      if (combined.isEmpty) {
        MessageService.showError("Nenhum registro encontrado para os depósitos selecionados.");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MessageService.showError("Erro ao buscar resultado da conferência.");
      }
    }
  }

  /// Abre o popup "Selecione os Depósitos", no mesmo padrão visual dos
  /// demais popups da página (ícone circular + título em caixa alta,
  /// cartões com borda para cada opção, botões Cancelar/Aplicar).
  Future<void> _openLocationPicker() async {
    // Trabalha com uma cópia temporária para só aplicar ao confirmar.
    final tempSelected = List<InventorLocationModel>.from(_selectedLocations);

    final result = await showDialog<List<InventorLocationModel>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Material(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                elevation: 12,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLocationPickerTitle(),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Selecione um ou mais depósitos:",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton(
                              onPressed: () => setModalState(() => tempSelected.clear()),
                              child: const Text('Limpar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 320),
                            child: _loadingLocations
                                ? const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(child: CircularProgressIndicator(color: Colors.indigo)),
                                  )
                                : _availableLocations.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text('Nenhum depósito disponível.'),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        itemCount: _availableLocations.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final location = _availableLocations[index];
                                          final isChecked = tempSelected.any(
                                            (l) => l.inventLocationId == location.inventLocationId,
                                          );

                                          return _buildLocationOptionTile(
                                            location: location,
                                            isSelected: isChecked,
                                            onTap: () {
                                              setModalState(() {
                                                if (isChecked) {
                                                  tempSelected.removeWhere(
                                                    (l) => l.inventLocationId == location.inventLocationId,
                                                  );
                                                } else {
                                                  tempSelected.add(location);
                                                }
                                              });
                                            },
                                          );
                                        },
                                      ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: Colors.indigo),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('CANCELAR', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => Navigator.pop(dialogContext, tempSelected),
                                child: Text(
                                  'APLICAR (${tempSelected.length})',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _selectedLocations = result);
    }
  }

  /// Cabeçalho do popup de depósitos, no mesmo padrão visual dos demais
  /// popups da página (ícone circular + título em caixa alta).
  Widget _buildLocationPickerTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warehouse_rounded, color: Colors.indigo, size: 28),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'SELECIONE OS DEPÓSITOS',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// Uma opção de depósito no seletor (`_openLocationPicker`), no mesmo
  /// estilo de "cartão" com borda usado nos demais popups da página.
  Widget _buildLocationOptionTile({
    required InventorLocationModel location,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.withOpacity(0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.indigo : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: isSelected ? Colors.indigo : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 60,
              child: Text(
                location.inventLocationId,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.indigo : const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                location.inventLocationName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.indigo : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalProdutos = _results.length;
    final int totalDivergencias = _results.where((r) => r.hasDivergence).length;
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Column(
      children: [
        _buildSearchField(isDesktop),
        if (_hasSearched) _buildTotalizersCards(totalProdutos, totalDivergencias, isDesktop),
        Expanded(
          child: _isLoading
              ? const Center(child: SpinKitThreeBounce(color: Colors.indigo, size: 30.0))
              : !_hasSearched
                  ? _buildInitialState()
                  : _results.isEmpty
                      ? _buildEmptyState()
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1400),
                            child: isDesktop
                                ? _buildWebGridTable(_results)
                                : _buildMobileCardsList(_results),
                          ),
                        ),
        ),
      ],
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
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildLocationSelector()),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.indigo),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(50, double.infinity),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  tooltip: 'Buscar',
                  onPressed: _isLoading ? null : _fetchAuditResult,
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.indigo),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(50, double.infinity),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  tooltip: 'Atualizar',
                  onPressed: (_isLoading || !_hasSearched) ? null : _fetchAuditResult,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Campo estilo combobox: abre um seletor múltiplo de depósitos.
  Widget _buildLocationSelector() {
    final hasSelection = _selectedLocations.isNotEmpty;
    final label = !hasSelection
        ? 'Depósitos'
        : _selectedLocations.map((l) => l.inventLocationId).join(', ');

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: _loadingLocations ? null : _openLocationPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.warehouse_outlined, color: Colors.indigo, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: hasSelection ? const Color(0xFF0F172A) : Colors.blueGrey[300],
                ),
              ),
            ),
            if (hasSelection)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _selectedLocations = [];
                    _hasSearched = false;
                    _results = [];
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded, size: 20),
                ),
              ),
            if (hasSelection) const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalizersCards(int totalProdutos, int totalDivergencias, bool isDesktop) {
    final cards = [
      _buildKPIItem("Total Produtos", totalProdutos.toDouble(), Icons.inventory_2_outlined, Colors.indigo),
      _buildKPIItem("Divergências", totalDivergencias.toDouble(), Icons.report_gmailerrorred_outlined, Colors.red),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
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

  Widget _buildKPIItem(String title, double value, IconData icon, Color color) {
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
              borderRadius: BorderRadius.circular(10),
            ),
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
                NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 0).format(value),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebGridTable(List<InventoryAuditModel> list) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF1F5F9),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "PRODUTO",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "CÓD. BARRAS",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "CONTADO",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "SISTEMA",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "DIFERENÇA",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
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
                final diffColor = !item.hasDivergence
                    ? Colors.grey.shade700
                    : (item.difference > 0 ? Colors.green.shade700 : Colors.red.shade700);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.inventProduct,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.inventBarcode ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2).format(item.totalInvent),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2).format(item.availPhysical),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2).format(item.difference),
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.w700, color: diffColor),
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

  Widget _buildMobileCardsList(List<InventoryAuditModel> list) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final diffColor = !item.hasDivergence
            ? Colors.grey.shade700
            : (item.difference > 0 ? Colors.green : Colors.red);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
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
                      color: diffColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.inventProduct,
                                  style: const TextStyle(
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: diffColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2).format(item.difference),
                                  style: TextStyle(color: diffColor, fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.inventBarcode ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Contado: ${NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2).format(item.totalInvent)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Sistema: ${NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2).format(item.availPhysical)}',
                                  style: const TextStyle(fontSize: 12),
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
        );
      },
    );
  }

  Widget _buildInitialState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warehouse_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Selecione o(s) depósito(s) e toque em buscar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("Nenhum registro encontrado para os depósitos selecionados."));
  }
}


/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:oxdata/app/core/models/dto/inventory_audit_model.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Aba "Conferência de Divergência" da InventoryAdmPage.
///
/// Busca no endpoint `AuditResult` os itens de um depósito, comparando
/// o total contado (`totalInvent`) com o saldo do sistema
/// (`availPhysical`), e lista o resultado em formato de grid
/// (tabela no desktop / cards no mobile), seguindo o mesmo padrão
/// visual da InventoryTabLista.
class InventoryTabChkDiff extends StatefulWidget {
  const InventoryTabChkDiff({super.key});

  @override
  State<InventoryTabChkDiff> createState() => _InventoryTabChkDiffState();
}

class _InventoryTabChkDiffState extends State<InventoryTabChkDiff> {
  bool _isLoading = false;
  bool _hasSearched = false;
  List<InventoryAuditModel> _results = [];

  final TextEditingController _locationController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAuditResult() async {
    final location = _locationController.text.trim();

    if (location.isEmpty) {
      MessageService.showError("Informe o depósito para buscar.");
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final inventoryService = context.read<InventoryService>();
      final results = await inventoryService.getInventoryAuditResult(location);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _results = results;
      });

      if (results.isEmpty) {
        MessageService.showError("Nenhum registro encontrado para esse depósito.");
      }
    } catch (e) {
      debugPrint("Erro ao buscar auditoria: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        MessageService.showError("Erro ao buscar resultado da conferência.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalProdutos = _results.length;
    final int totalDivergencias = _results.where((r) => r.hasDivergence).length;
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Column(
      children: [
        _buildSearchField(isDesktop),
        if (_hasSearched) _buildTotalizersCards(totalProdutos, totalDivergencias, isDesktop),
        Expanded(
          child: _isLoading
              ? const Center(child: SpinKitThreeBounce(color: Colors.indigo, size: 30.0))
              : !_hasSearched
                  ? _buildInitialState()
                  : _results.isEmpty
                      ? _buildEmptyState()
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1400),
                            child: isDesktop
                                ? _buildWebGridTable(_results)
                                : _buildMobileCardsList(_results),
                          ),
                        ),
        ),
      ],
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
                  controller: _locationController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _fetchAuditResult(),
                  decoration: InputDecoration(
                    hintText: 'Depósitos',
                    hintStyle: TextStyle(
                      color: Colors.blueGrey[300],
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(
                      Icons.warehouse_outlined,
                      color: Colors.indigo,
                      size: 22,
                    ),
                    suffixIcon: _locationController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            style: IconButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _locationController.clear();
                                _hasSearched = false;
                                _results = [];
                              });
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
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                tooltip: 'Buscar',
                onPressed: _isLoading ? null : _fetchAuditResult,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.indigo),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                tooltip: 'Atualizar',
                onPressed: (_isLoading || !_hasSearched) ? null : _fetchAuditResult,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalizersCards(int totalProdutos, int totalDivergencias, bool isDesktop) {
    final cards = [
      _buildKPIItem("Total Produtos", totalProdutos.toDouble(), Icons.inventory_2_outlined, Colors.indigo),
      _buildKPIItem("Divergências", totalDivergencias.toDouble(), Icons.report_gmailerrorred_outlined, Colors.red),
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

  Widget _buildKPIItem(String title, double value, IconData icon, Color color) {
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
              borderRadius: BorderRadius.circular(10),
            ),
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
                NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 0).format(value),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebGridTable(List<InventoryAuditModel> list) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF1F5F9),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "PRODUTO",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "CÓD. BARRAS",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "CONTADO",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "SISTEMA",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "DIFERENÇA",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
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
                final diffColor = !item.hasDivergence
                    ? Colors.grey.shade700
                    : (item.difference > 0 ? Colors.green.shade700 : Colors.red.shade700);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.inventProduct,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.inventBarcode ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2).format(item.totalInvent),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2).format(item.availPhysical),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2).format(item.difference),
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.w700, color: diffColor),
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

  Widget _buildMobileCardsList(List<InventoryAuditModel> list) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final diffColor = !item.hasDivergence
            ? Colors.grey.shade700
            : (item.difference > 0 ? Colors.green : Colors.red);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
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
                      color: diffColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.inventProduct,
                                  style: const TextStyle(
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: diffColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2).format(item.difference),
                                  style: TextStyle(color: diffColor, fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.inventBarcode ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Contado: ${NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2).format(item.totalInvent)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Sistema: ${NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2).format(item.availPhysical)}',
                                  style: const TextStyle(fontSize: 12),
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
        );
      },
    );
  }

  Widget _buildInitialState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warehouse_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Informe o depósito e toque em buscar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("Nenhum registro encontrado para esse depósito."));
  }
}
*/