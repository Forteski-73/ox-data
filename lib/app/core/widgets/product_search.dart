import 'package:flutter/material.dart';
import 'package:oxdata/app/core/widgets/pulse_icon.dart';

class ProductSearch extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Future<String> Function()? onScanBarcode;
  final Future<void> Function()? onSearch;

  const ProductSearch({
    super.key,
    required this.controller,
    required this.label,
    this.onScanBarcode,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return TextField(
          controller: controller,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(
              color: Colors.blueGrey[300],
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.indigo, width: 1),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      controller.clear();
                      (context as Element).markNeedsBuild();
                    },
                  ),
                if (onScanBarcode != null)
                  PulseIconButton(
                    icon: Icons.qr_code_scanner_rounded,
                    color: Colors.indigo,
                    size: 28,
                    onPressed: () async {
                      String scanned = await onScanBarcode!();
                      if (scanned.isNotEmpty) {
                        controller.text = scanned;
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                if (onSearch != null)
                  PulseIconButton(
                    icon: Icons.search,
                    color: Colors.indigo,
                    size: 28,
                    onPressed: () async {
                      FocusScope.of(context).unfocus();
                      await onSearch!();
                    },
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}