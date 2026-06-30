import 'package:flutter/material.dart';

class DownloadInventoryDialog extends StatefulWidget {
  final String inventoryCode;

  const DownloadInventoryDialog({
    super.key,
    required this.inventoryCode,
  });

  @override
  State<DownloadInventoryDialog> createState() =>
      _DownloadInventoryDialogState();
}

class _DownloadInventoryDialogState extends State<DownloadInventoryDialog> {
  final Map<String, String> columns = const {
    "inventUnitizer":      "Unitizador",
    "inventLocation":      "Localização",
    "inventBarcode":        "Cód. Barras",
    "inventProduct":        "Cód. Produto",
    "productDescription":   "Nome do Produto",
    "inventStandardStack":  "Qtd. por Pilhas",
    "inventQtdStack":       "Qtd. Pilhas",
    "inventQtdIndividual":  "Qtd. Avulsa",
    "inventTotal":          "Total de Itens",
  };

  final Set<String> selectedColumns = {
    "inventUnitizer",
    "inventLocation",
    "inventBarcode",
    "inventTotal"
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        elevation: 12,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              Text(
                "INVENTÁRIO: ${widget.inventoryCode}",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Selecione as colunas para exportação:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: columns.entries.map((entry) {
                      final selected = selectedColumns.contains(entry.key);

                      return FilterChip(
                        label: Text(
                          entry.value,
                          style: TextStyle(
                            color: selected ? Colors.indigo : Colors.black87,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: selected,
                        selectedColor: Colors.indigo.withOpacity(0.1),
                        checkmarkColor: Colors.indigo,
                        backgroundColor: const Color(0xFFF8FAFC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: selected ? Colors.indigo : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              selectedColumns.add(entry.key);
                            } else {
                              selectedColumns.remove(entry.key);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.download_rounded, color: Colors.indigo, size: 28),
        ),
        const SizedBox(width: 12),
        const Text(
          'EXPORTAR INVENTÁRIO',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.indigo),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
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
            onPressed: () {
              final orderedSelection = columns.keys
                  .where((key) => selectedColumns.contains(key))
                  .toList();

              Navigator.pop(context, orderedSelection);
            },
            child: const Text('BAIXAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

/*
import 'package:flutter/material.dart';

class DownloadInventoryDialog extends StatefulWidget {
  final String inventoryCode;

  const DownloadInventoryDialog({
    super.key,
    required this.inventoryCode,
  });

  @override
  State<DownloadInventoryDialog> createState() =>
      _DownloadInventoryDialogState();
}

class _DownloadInventoryDialogState extends State<DownloadInventoryDialog> {
  final Map<String, String> columns = const {
    "inventUnitizer":       "Unitizador",
    "inventLocation":       "Localização",
    "inventBarcode":        "Cód. Barras",
    "inventProduct":        "Cód. Produto",
    "productDescription":   "Nome do Produto",
    "inventStandardStack":  "Qtd. por Pilhas",
    "inventQtdStack":       "Qtd. Pilhas",
    "inventQtdIndividual":  "Qtd. Avulsa",
    "inventTotal":          "Total de Itens",
  };

  final Set<String> selectedColumns = {
    "inventUnitizer",
    "inventLocation",
    "inventBarcode",
    "inventTotal"
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Text("Exportar Inventário"),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Inventário: ${widget.inventoryCode}",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Selecione as colunas para exportação:",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 320,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: columns.entries.map((entry) {
                    final selected =
                        selectedColumns.contains(entry.key);

                    return FilterChip(
                      label: Text(entry.value),
                      selected: selected,
                      selectedColor: Colors.indigo.withOpacity(0.15),
                      checkmarkColor: Colors.indigo,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            selectedColumns.add(entry.key);
                          } else {
                            selectedColumns.remove(entry.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.download_rounded),
          label: const Text("Baixar"),
          onPressed: () {
            // paramanter a ordem de clic do usuário
            // Navigator.pop(context, selectedColumns.toList());

            final orderedSelection = columns.keys
                .where((key) => selectedColumns.contains(key))
                .toList();

            Navigator.pop(context, orderedSelection);
          },
        ),
      ],
    );
  }
}
*/