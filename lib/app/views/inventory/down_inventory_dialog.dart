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