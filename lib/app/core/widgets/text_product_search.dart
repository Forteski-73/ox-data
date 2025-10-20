import 'package:flutter/material.dart';
import 'package:oxdata/app/core/widgets/pulse_icon.dart';

class ProductTextFieldWithActions extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Future<String> Function()? onScanBarcode;
  final Future<void> Function()? onSearch;

  const ProductTextFieldWithActions({
    super.key,
    required this.controller,
    required this.label,
    this.onScanBarcode,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14),
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[

            // Botão do QR Code
            if (onScanBarcode != null)
              PulseIconButton(
                icon: Icons.qr_code_scanner_outlined,
                color: Colors.indigo,
                size: 32,
                onPressed: () async {
                  String scanned = await onScanBarcode!();
                  if (scanned.isNotEmpty) {
                    controller.text = scanned;
                    (context as Element).markNeedsBuild();
                  }
                },
              ),

            // Botão de Pesquisa
            if (onSearch != null)
              PulseIconButton(
                icon: Icons.search,
                color: Colors.indigo,
                size: 32,
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  await onSearch!();
                },
              ),
          ],
        ),
      ),
    );
  }
}
