import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  // O controlador permite parar a câmera manualmente
  final MobileScannerController controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    controller.dispose(); // Importante liberar a câmera
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('Scanner'),
            SizedBox(width: 8),
            Icon(Icons.qr_code_scanner),
          ],
        ),
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          if (_hasScanned) return; // Trava imediata para nã oenfileirar as leituras

          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            _hasScanned = true;
            controller.stop(); 
            // Retorna o código
            Navigator.of(context).pop(barcodes.first);
          }
        },
      ),
    );
  }
}