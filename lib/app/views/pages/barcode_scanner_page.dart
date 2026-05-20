import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart'; // Importante para o kIsWeb

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  // No Web, o MobileScannerController pode precisar de ajustes de resolução
  final MobileScannerController controller = MobileScannerController(
    // Se for Web, podemos definir parâmetros que facilitam a leitura do ZXing
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    
    // ESSENCIAL PARA WEB: Inicia a câmera após o primeiro frame.
    // No App nativo, o MobileScanner costuma iniciar sozinho, mas o start() não prejudica.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb) {
        controller.start();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose(); 
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
        // O errorBuilder ajuda a identificar se o Safari bloqueou a câmera por falta de HTTPS ou Permissão
        errorBuilder: (context, error, child) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 40),
                const SizedBox(height: 16),
                Text(
                  kIsWeb 
                    ? 'Erro na câmera: Certifique-se de usar HTTPS e permitir o acesso.' 
                    : 'Erro ao iniciar câmera: ${error.errorCode}',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        onDetect: (capture) {
          if (_hasScanned) return;

          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            _hasScanned = true;
            
            // Para garantir que o hardware seja liberado rapidamente
            controller.stop(); 
            
            // Retorna o primeiro código encontrado
            Navigator.of(context).pop(barcodes.first);
          }
        },
      ),
    );
  }
}

/*
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
  void initState() {
    super.initState();
    // ESSENCIAL PARA WEB: Inicia a câmera após o primeiro frame ser desenhado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.start();
    });
  }

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
*/