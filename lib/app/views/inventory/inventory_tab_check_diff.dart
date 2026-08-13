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
                    hintText: 'Depósito (ex: 101-101)',
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