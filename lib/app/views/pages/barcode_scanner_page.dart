import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatelessWidget {
  const BarcodeScannerPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    bool read = false;
    return Scaffold(
      appBar: AppBar(title: const Text('Mobile Scanner')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && read == false) {
            read = true;
            // Retorna o primeiro código de barras detectado para a tela anterior
            Navigator.of(context).pop(barcodes.first);
          }
        },
      ),
    );
  }
}