import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' as excel;
import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/app/core/models/inventory_record_model.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/utils/download_file.dart';

class InventoryAdmRecordsPage extends StatefulWidget {
  final InventoryModel inventory;

  const InventoryAdmRecordsPage({
    super.key,
    required this.inventory,
  });

  @override
  State<InventoryAdmRecordsPage> createState() =>
      _InventoryAdmRecordsPageState();
}

class _InventoryAdmRecordsPageState extends State<InventoryAdmRecordsPage> {
  bool _loading = true;
  List<InventoryRecordModel> _records = [];
  List<InventoryRecordModel> _filteredRecords = [];

  // Conjunto de registros selecionados (aplicável na visualização desktop)
  final Set<InventoryRecordModel> _selectedRecords = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final service = context.read<InventoryService>();

      final result = await service.getRecordsListByInventCode(
        widget.inventory.inventCode ?? '',
      );

      if (!mounted) return;

      setState(() {
        _records = result;
        _filteredRecords = result;
        _selectedRecords.clear();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      MessageService.showError(
        "Erro ao carregar registros do inventário.",
      );
    }
  }

  // Realiza a filtragem em qualquer coluna informada
  void _filterRecords(String query) {
    final lowerQuery = query.toLowerCase().trim();

    setState(() {
      if (lowerQuery.isEmpty) {
        _filteredRecords = _records;
      } else {
        _filteredRecords = _records.where((r) {
          final unitizer = (r.inventUnitizer ?? '').toLowerCase();
          final location = (r.inventLocation ?? '').toLowerCase();
          final barcode = (r.inventBarcode ?? '').toLowerCase();
          final product = r.inventProduct.toLowerCase();
          final description = (r.productDescription ?? '').toLowerCase();

          return unitizer.contains(lowerQuery) ||
              location.contains(lowerQuery) ||
              barcode.contains(lowerQuery) ||
              product.contains(lowerQuery) ||
              description.contains(lowerQuery);
        }).toList();
      }
    });
  }

  // ── Seleção (apenas desktop) ────────────────────────────────────────────

  bool get _allSelected =>
      _filteredRecords.isNotEmpty &&
      _filteredRecords.every(_selectedRecords.contains);

  bool get _someSelected =>
      _selectedRecords.isNotEmpty && !_allSelected;

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedRecords.removeWhere(_filteredRecords.contains);
      } else {
        _selectedRecords.addAll(_filteredRecords);
      }
    });
  }

  void _toggleSelectOne(InventoryRecordModel r, bool? value) {
    setState(() {
      if (value == true) {
        _selectedRecords.add(r);
      } else {
        _selectedRecords.remove(r);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedRecords.clear());
  }

  // ── Exportação para Excel (Ajustado para excel v2.0.0) ───────────────────

  Future<void> _exportToExcel() async {
    final recordsToExport = _selectedRecords.isNotEmpty
        ? _filteredRecords.where(_selectedRecords.contains).toList()
        : _filteredRecords;

    if (recordsToExport.isEmpty) {
      MessageService.showError("Nenhum registro para exportar.");
      return;
    }

    try {
      final workbook = excel.Excel.createExcel();
      const sheetName = 'Itens';
      final sheet = workbook[sheetName];
      workbook.setDefaultSheet(sheetName);

      const headers = [
        'Unitizador',
        'Localização',
        'Código de Barras',
        'Produto',
        'Descrição',
        'Padrão Pilha',
        'Qtd Pilhas',
        'Qtd Avulsa',
        'Total',
      ];
      // Na v2.0.0 passamos a lista de tipos dinâmicos primitivos diretamente
      sheet.appendRow(headers);

      for (final r in recordsToExport) {
        sheet.appendRow([
          r.inventUnitizer ?? '-',
          r.inventLocation ?? '-',
          r.inventBarcode ?? '-',
          r.inventProduct,
          r.productDescription ?? '-',
          r.inventStandardStack ?? 0,
          r.inventQtdStack ?? 0,
          (r.inventQtdIndividual ?? 0).toDouble(),
          (r.inventTotal ?? 0).toDouble(),
        ]);
      }

      final bytes = workbook.encode();
      if (bytes == null) throw Exception('Falha ao gerar o arquivo.');

      await DownloadFile.saveBytes(
        Uint8List.fromList(bytes),
        "${widget.inventory.inventCode}_itens.xlsx",
      );

      MessageService.showSuccess(
        "Exportação concluída! (${recordsToExport.length} ${recordsToExport.length == 1 ? 'item' : 'itens'})",
      );
    } catch (e) {
      MessageService.showError("Falha ao exportar para Excel: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBarCustom(
        title: widget.inventory.inventName ?? '',
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Column(
                  children: [
                    // Campo de Pesquisa no Topo
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: _buildSearchField(),
                    ),

                    if (isDesktop && _selectedRecords.isNotEmpty)
                      _buildSelectionBar(),

                    // Conteúdo da Listagem / Tabela
                    Expanded(
                      child: _filteredRecords.isEmpty
                          ? const Center(
                              child: Text(
                                "Nenhum registro encontrado.",
                              ),
                            )
                          : isDesktop
                              ? _desktopTable()
                              : _mobileList(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Barra que indica quantos itens estão selecionados (desktop)
  Widget _buildSelectionBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.indigo, size: 18),
          const SizedBox(width: 8),
          Text(
            "${_selectedRecords.length} ${_selectedRecords.length == 1 ? 'item selecionado' : 'itens selecionados'}",
            style: const TextStyle(
              color: Colors.indigo,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _exportToExcel,
            icon: const Icon(Icons.file_download_rounded, size: 18),
            label: const Text("Exportar seleção"),
          ),
          TextButton(
            onPressed: _clearSelection,
            child: const Text("Limpar"),
          ),
        ],
      ),
    );
  }

  // Campo de Pesquisa reaproveitando o layout desejado
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _filterRecords,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Pesquisar..',
        hintStyle: TextStyle(
          color: Colors.blueGrey[300],
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.indigo, size: 22),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _filterRecords("");
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.indigo, width: 1),
        ),
      ),
    );
  }

  // Layout em formato de TABELA para WEB / DESKTOP
  Widget _desktopTable() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Cabeçalho da Tabela
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: const Color(0xFFF1F5F9),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Checkbox(
                    tristate: true,
                    value: _allSelected ? true : (_someSelected ? null : false),
                    activeColor: Colors.indigo,
                    onChanged: (_) => _toggleSelectAll(),
                  ),
                ),
                const Expanded(flex: 2, child: Text("UNITIZADOR",       style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 14))),
                const Expanded(flex: 2, child: Text("LOCALIZAÇÃO",      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 14))),
                const Expanded(flex: 2, child: Text("CÓDIGO DE BARRAS", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 14))),
                const Expanded(flex: 6, child: Text("NOME PRODUTO",     style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 14))),
                const Expanded(flex: 2, child: Text("TOTAL DE ITENS",   textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 14))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Lista de Registros usando a lista filtrada
          Expanded(
            child: ListView.separated(
              itemCount: _filteredRecords.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (_, index) {
                final r = _filteredRecords[index];
                final isSelected = _selectedRecords.contains(r);

                return Container(
                  color: isSelected ? Colors.indigo.withOpacity(0.05) : null,
                  child: InkWell(
                    onTap: () => _toggleSelectOne(r, !isSelected),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Checkbox(
                              value: isSelected,
                              activeColor: Colors.indigo,
                              onChanged: (value) => _toggleSelectOne(r, value),
                            ),
                          ),
                          // Unitizador
                          Expanded(
                            flex: 2,
                            child: Text(
                              r.inventUnitizer ?? '-',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                          // Localização
                          Expanded(
                            flex: 2,
                            child: Text(
                              r.inventLocation ?? '-',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                          // Código de Barras
                          Expanded(
                            flex: 2,
                            child: Text(
                              r.inventBarcode ?? '-',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                          // Nome Produto / Descrição
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.inventProduct,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo,
                                  ),
                                ),
                                if (r.productDescription != null)
                                  Text(
                                    r.productDescription!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          // Total de Itens
                          Expanded(
                            flex: 2,
                            child: Text(
                              r.inventTotal == null
                                  ? '0'
                                  : (r.inventTotal! % 1 == 0
                                      ? r.inventTotal!.toInt().toString()
                                      : r.inventTotal!.toStringAsFixed(2)),
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Layout compacto e simplificado para MOBILE
  Widget _mobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredRecords.length,
      itemBuilder: (_, index) {
        final r = _filteredRecords[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        r.inventProduct,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Qtd: ${r.inventTotal?.toStringAsFixed(2) ?? '0.00'}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (r.productDescription != null) ...[
                  Text(
                    r.productDescription!,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  "Loc: ${r.inventLocation ?? '-'} | Unit: ${r.inventUnitizer ?? '-'}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:oxdata/app/core/models/inventory_model.dart';
import 'package:oxdata/app/core/models/inventory_record_model.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';

class InventoryAdmRecordsPage extends StatefulWidget {
  final InventoryModel inventory;

  const InventoryAdmRecordsPage({
    super.key,
    required this.inventory,
  });

  @override
  State<InventoryAdmRecordsPage> createState() =>
      _InventoryAdmRecordsPageState();
}

class _InventoryAdmRecordsPageState extends State<InventoryAdmRecordsPage> {
  bool _loading = true;
  List<InventoryRecordModel> _records = [];
  List<InventoryRecordModel> _filteredRecords = [];
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final service = context.read<InventoryService>();

      final result = await service.getRecordsListByInventCode(
        widget.inventory.inventCode ?? '',
      );

      if (!mounted) return;

      setState(() {
        _records = result;
        _filteredRecords = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      MessageService.showError(
        "Erro ao carregar registros do inventário.",
      );
    }
  }

  // Realiza a filtragem em qualquer coluna informada
  void _filterRecords(String query) {
    final lowerQuery = query.toLowerCase().trim();
    
    setState(() {
      if (lowerQuery.isEmpty) {
        _filteredRecords = _records;
      } else {
        _filteredRecords = _records.where((r) {
          final unitizer = (r.inventUnitizer ?? '').toLowerCase();
          final location = (r.inventLocation ?? '').toLowerCase();
          final barcode = (r.inventBarcode ?? '').toLowerCase();
          final product = r.inventProduct.toLowerCase();
          final description = (r.productDescription ?? '').toLowerCase();

          return unitizer.contains(lowerQuery) ||
              location.contains(lowerQuery) ||
              barcode.contains(lowerQuery) ||
              product.contains(lowerQuery) ||
              description.contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBarCustom(
        title: widget.inventory.inventName ?? '',
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Column(
                  children: [
                    // Campo de Pesquisa no Topo
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: _buildSearchField(),
                    ),
                    
                    // Conteúdo da Listagem / Tabela
                    Expanded(
                      child: _filteredRecords.isEmpty
                          ? const Center(
                              child: Text(
                                "Nenhum registro encontrado.",
                              ),
                            )
                          : isDesktop 
                              ? _desktopTable() 
                              : _mobileList(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Campo de Pesquisa reaproveitando o layout desejado
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _filterRecords,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Pesquisar por produto, unitizador, localização...',
        hintStyle: TextStyle(
          color: Colors.blueGrey[300],
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.indigo, size: 22),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _filterRecords("");
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.indigo, width: 1),
        ),
      ),
    );
  }

  // Layout em formato de TABELA (Linhas uma abaixo da outra) para WEB / DESKTOP
  Widget _desktopTable() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Cabeçalho da Tabela
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: const Color(0xFFF1F5F9),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text("UNITIZADOR",       style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 14))),
                Expanded(flex: 2, child: Text("LOCALIZAÇÃO",      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 14))),
                Expanded(flex: 2, child: Text("CÓDIGO DE BARRAS", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 14))),
                Expanded(flex: 6, child: Text("NOME PRODUTO",     style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 14))),
                Expanded(flex: 2, child: Text("TOTAL DE ITENS",   textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 14))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          
          // Lista de Registros (Linhas horizontais) usando a lista filtrada
          Expanded(
            child: ListView.separated(
              itemCount: _filteredRecords.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (_, index) {
                final r = _filteredRecords[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      // Unitizador
                      Expanded(
                        flex: 2,
                        child: Text(
                          r.inventUnitizer ?? '-',
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      // Localização
                      Expanded(
                        flex: 2,
                        child: Text(
                          r.inventLocation ?? '-',
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      // Código de Barras
                      Expanded(
                        flex: 2,
                        child: Text(
                          r.inventBarcode ?? '-',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      // Nome Produto / Descrição
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.inventProduct,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo,
                              ),
                            ),
                            if (r.productDescription != null)
                              Text(
                                r.productDescription!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      // Total de Itens (Valor Total)
                      Expanded(
                        flex: 2,
                        child: Text(
                          r.inventTotal == null
                              ? '0'
                              : (r.inventTotal! % 1 == 0 
                                  ? r.inventTotal!.toInt().toString() 
                                  : r.inventTotal!.toStringAsFixed(2)),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 15,
                          ),
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

  // Layout compacto e simplificado para MOBILE
  Widget _mobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredRecords.length,
      itemBuilder: (_, index) {
        final r = _filteredRecords[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        r.inventProduct,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Qtd: ${r.inventTotal?.toStringAsFixed(2) ?? '0.00'}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (r.productDescription != null) ...[
                  Text(
                    r.productDescription!,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                ],
                // Informações adicionais mais compactas no Mobile
                Text(
                  "Loc: ${r.inventLocation ?? '-'} | Unit: ${r.inventUnitizer ?? '-'}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
*/