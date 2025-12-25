import 'package:flutter/material.dart';

import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/db/app_database.dart';
import 'package:oxdata/app/core/models/dto/inventory_record_input.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/core/widgets/instruction_popup.dart';
import 'package:oxdata/app/core/widgets/product_search_local.dart';
import 'package:oxdata/app/core/utils/mask_validate.dart';
import 'dart:async';

// -------------------------------------------------------------------
// DEFINIÇÕES DE CORES (Constantes)
// -------------------------------------------------------------------
const Color _defaultColor = Color(0xFFE3F2FD);                  // Azul claro (Light Blue 50)
const Color _darkerColor = Color.fromARGB(255, 187, 211, 251);  // Azul mais escuro (Light Blue 100)
const Color _primaryColor = Color(0xFF3F51B5);                  // Indigo 500
const Color _successColor = Color(0xFF4CAF50);                  // Verde sucesso

// -------------------------------------------------------------------
// WIDGET REUTILIZÁVEL: _ColorChangingButton
// Suporte a toque + piscar intermitente opcional
// -------------------------------------------------------------------
class _ColorChangingButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool blink; // 👈 novo parâmetro

  const _ColorChangingButton({
    required this.icon,
    this.onPressed,
    this.blink = false,
  });

  @override
  State<_ColorChangingButton> createState() => __ColorChangingButtonState();
}

class __ColorChangingButtonState extends State<_ColorChangingButton> {
  Color _containerColor = _defaultColor;
  Timer? _blinkTimer;
  bool _blinkOn = false;

  @override
  void initState() {
    super.initState();

    if (widget.blink) {
      _startBlink();
    }
  }

  @override
  void didUpdateWidget(covariant _ColorChangingButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.blink && !oldWidget.blink) {
      _startBlink();
    } else if (!widget.blink && oldWidget.blink) {
      _stopBlink();
    }
  }

  void _startBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) {
        if (!mounted) return;
        setState(() {
          _blinkOn = !_blinkOn;
          _containerColor = _blinkOn ? _darkerColor : _defaultColor;
        });
      },
    );
  }

  void _stopBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = null;
    setState(() {
      _containerColor = _defaultColor;
      _blinkOn = false;
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.blink) return;
    setState(() {
      _containerColor = _darkerColor;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.blink) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _containerColor = _defaultColor;
        });
      }
    });
  }

  void _handleTapCancel() {
    if (widget.blink) return;
    setState(() {
      _containerColor = _defaultColor;
    });
  }

  void _handleTap() {
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 54,
        width: 54,
        decoration: BoxDecoration(
          color: _containerColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Icon(
            widget.icon,
            color: _primaryColor,
            size: 36,
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------
// CLASSE PRINCIPAL: InventoryItemPage
// -------------------------------------------------------------------
class InventoryItemPage extends StatefulWidget {
  // Mantenha a chave estática aqui para fácil acesso
  static final GlobalKey<_InventoryItemPageState> inventoryKey = GlobalKey<_InventoryItemPageState>();

  // Altere o construtor para aceitar a key
  const InventoryItemPage({Key? key}) : super(key: key); 

  @override
  State<InventoryItemPage> createState() => _InventoryItemPageState();
}

class _InventoryItemPageState extends State<InventoryItemPage> {


  // SERVICE

  final TextEditingController _unitizerController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _productController = TextEditingController();

  // CONTROLLERS DE QUANTIDADE
  final TextEditingController _qtdPorPilhaController = TextEditingController();
  final TextEditingController _numPilhasController = TextEditingController();
  final TextEditingController _qtdAvulsaController = TextEditingController();

  @override
  void dispose() {
    // Importante: Descartar os controllers para liberar recursos
    _unitizerController.dispose();
    _positionController.dispose();
    _productController.dispose();
    _qtdPorPilhaController.dispose();
    _numPilhasController.dispose();
    _qtdAvulsaController.dispose();
    super.dispose();
  }

    Future<void> _scanBarcode(int _flag) async {
    var status = await Permission.camera.request();
    if (!status.isGranted) return;

    final barcodeRead = await Navigator.of(context).push<Barcode?>(
    MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (barcodeRead == null) return;

    final scanned = barcodeRead.rawValue ?? "";
    if (scanned.isNotEmpty) {
      switch (_flag) {
        case 1:                               // UNITIZADOR

          _unitizerController.text = scanned;
          _syncDraft();
          break;
        
        case 2:                               // POSIÇÃO
          _positionController.text = scanned;
          _syncDraft();
          break;
        
        case 3:                               // PRODUTO
          _productController.text = scanned;

          _syncDraft();
          break;
        
        default:
          _syncDraft();
          break;
      }
    }
  }

  Future<void> _searchProduct() async {
    final product = await showDialog<Product>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ProductSearchLocalDialog(),
    );

    if (product != null) {
      _productController.text = product.barcode;
      // aqui você recebe o produto selecionado
      //debugPrint('Produto selecionado: ${product.productName}');
    }
  }

  Future<void> onSavePressed() async {
    final service = context.read<InventoryService>();

    final input = InventoryRecordInput(
      unitizer: _unitizerController.text,
      position: _positionController.text,
      product: _productController.text,
      qtdPorPilha: double.tryParse(_qtdPorPilhaController.text) ?? 0,
      numPilhas: double.tryParse(_numPilhasController.text) ?? 0,
      qtdAvulsa: double.tryParse(_qtdAvulsaController.text) ?? 0,
    );

    try {
      await service.saveInventoryRecord(input);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro salvo com sucesso ✅')),
      );

      _clearFields();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _syncDraft() {
    final service = context.read<InventoryService>();

    service.updateDraft(
      InventoryRecordInput(
        unitizer: _unitizerController.text,
        position: _positionController.text,
        product: _productController.text,
        qtdPorPilha: double.tryParse(_qtdPorPilhaController.text) ?? 0,
        numPilhas: double.tryParse(_numPilhasController.text) ?? 0,
        qtdAvulsa: double.tryParse(_qtdAvulsaController.text) ?? 0,
      ),
    );
  }

  void _onProductScanned(String code) async {
    final inventoryService = Provider.of<InventoryService>(context, listen: false);
    
    await inventoryService.searchProductLocally(code);
  }


  /*
    // MÉTODO PARA SALVAR
  Future<void> saveInventory() async {
    final inventoryService = Provider.of<InventoryService>(context, listen: false);
    final currentInventory = inventoryService.selectedInventory;

    // 1. Validações básicas
    if (currentInventory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum inventário selecionado! ❌')));
      return;
    }
    if (_productController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o Produto! ⚠️')));
      return;
    }

    try {
      // 2. Cálculos de quantidade
      double perStack = double.tryParse(_qtdPorPilhaController.text.replaceAll(',', '.')) ?? 0;
      double stacks = double.tryParse(_numPilhasController.text.replaceAll(',', '.')) ?? 0;
      double individual = double.tryParse(_qtdAvulsaController.text.replaceAll(',', '.')) ?? 0;
      double total = (perStack * stacks) + individual;

      // 3. Criar o registro individual
      final record = InventoryRecordModel(
        inventCode: currentInventory.inventCode,
        inventUnitizer: _unitizerController.text,
        inventLocation: _positionController.text,
        inventProduct: _productController.text,
        inventStandardStack: perStack.toInt(),
        inventQtdStack: stacks.toInt(),
        inventQtdIndividual: individual,
        inventTotal: total,
        inventCreated: DateTime.now(),
        inventUser: "Diones", // Ou pegue do seu serviço de Auth
      );

      // 4. Montar o Lote (Batch) conforme a API espera (Lista de InventoryBatchRequest)
      final batch = InventoryBatchRequest(
        inventGuid: currentInventory.inventGuid ?? "", // Use o GUID do inventário atual
        inventCode: currentInventory.inventCode,
        records: [record],
      );

      // 5. Enviar para o serviço (ajustado para receber a lista de lotes)
      await inventoryService.createOrUpdateInventoryRecords([batch]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Confirmado! Novo total: ${inventoryService.selectedInventory?.inventTotal} ✅'))
        );
        _clearFields();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e ❌')));
    }
  }

  */

  void _clearFields() {
    setState(() {
      _unitizerController.clear();
      _productController.clear();
      _qtdPorPilhaController.clear();
      _numPilhasController.clear();
      _qtdAvulsaController.clear();
    });
  }

  void showScanInstructions(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return const Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(24),
          child: InstructionPopup(),
        );
      },
    );
  }


  // Métodos de construção do Widget (mantidos no State)
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        const Icon(Icons.dashboard_customize, size: 20, color: _primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildUnitizerTextField() {
    final service = context.read<InventoryService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _unitizerController,
                onSubmitted: (value) async {
                    // 1. Pega as strings das máscaras que já estão no service
                    /*final maskStrings = service.listMask.map((m) => m.fieldMask).toList();*/
                    
                    final masks = await service.getAllMasks();
                    final maskStrings = masks.map((m) => m.fieldMask).toList();

                    // 2. Valida usando o utilitário
                    bool isValid = MaskValidatorService.validateMask(value, maskStrings);

                    if (!isValid) {
                      // Aqui você pode mostrar um SnackBar ou Alerta de erro
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Código do Unitizador inválido!")),
                      );
                      _unitizerController.clear(); // Opcional: limpa o campo se estiver errado
                    } else {
                      // Código válido, pode mover o foco para o próximo campo (ex: Posição)
                      FocusScope.of(context).nextFocus();
                    }
                  },
                style: const TextStyle(fontSize: 18.0), 
                decoration: InputDecoration(
                  labelText: "Unitizador",
                  labelStyle: const TextStyle(fontSize: 16.0), 
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.qr_code_2,
              blink: true,
              onPressed: () {
                _scanBarcode(1);
              },
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.info_outline,
              blink: true,
              onPressed: () {
                showScanInstructions(context);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _productController,
                style: const TextStyle(fontSize: 18), 
                decoration: InputDecoration(
                  labelText: "Produto",
                  labelStyle: const TextStyle(fontSize: 16.0), 
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.qr_code_2,
              blink: true,
              onPressed: () {
                _scanBarcode(3);
              },
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.search,
              blink: true,
              onPressed: () {
                _searchProduct();
              },
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.info_outline,
              blink: true,
              onPressed: () {
                debugPrint("Informação Produto Clicado!");
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPositionTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _positionController,
                style: const TextStyle(fontSize: 18.0), 
                decoration: InputDecoration(
                  labelText: "Posição",
                  labelStyle: const TextStyle(fontSize: 16.0), 
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.qr_code_2,
              blink: true,
              onPressed: () {
                _scanBarcode(2);
              },
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.info_outline,
              blink: true,
              onPressed: () {
                debugPrint("Informação Posição Clicado!");
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityField({
    required String label, 
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        TextField( 
          controller: controller, 
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
          onChanged: (_) => _syncDraft(),
          decoration: const InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(fontSize: 18.0),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Mude para TRUE para o Scaffold redimensionar quando o teclado abrir
      resizeToAvoidBottomInset: true, 
      body: SafeArea( // Recomendado para evitar notch/barras do sistema
        child: SingleChildScrollView(
          // 2. Padding ajustado: remova o 100 exagerado se não houver um botão fixo no rodapé aqui
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- CONTAINER DE TOTAL REATIVO ---
              Consumer<InventoryService>(
                builder: (context, inventoryService, child) {
                  final double totalGeral = inventoryService.selectedInventory?.inventTotal ?? 0.0;
                  return Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "TOTAL DE PEÇAS",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            totalGeral % 1 == 0 
                                ? totalGeral.toInt().toString() 
                                : totalGeral.toStringAsFixed(2),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Campos de Identificação
              _buildSectionTitle("IDENTIFICAÇÃO"),
              const SizedBox(height: 6),
              _buildUnitizerTextField(),
              const SizedBox(height: 6),
              _buildPositionTextField(),
              const SizedBox(height: 6),
              _buildProductTextField(),
              const SizedBox(height: 16),
              
              // Campos de Quantidades
              _buildSectionTitle("QUANTIDADES"),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildQuantityField(label: "QTD por Pilha", controller: _qtdPorPilhaController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildQuantityField(label: "Nº de Pilhas", controller: _numPilhasController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildQuantityField(label: "QTD Avulsa", controller: _qtdAvulsaController)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------
// FUNÇÃO PÚBLICA: buildInventoryBottomBar (Acessível pela classe pai)
// Esta função substitui o método _buildBottomBar na classe State.
// -------------------------------------------------------------------

/*Widget buildInventoryBottomBar(BuildContext context, {required VoidCallback onPressed}) {
  final double bottomPadding = MediaQuery.of(context).padding.bottom;

  return Container(
    // 1. Sombra e Forma Agradável
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 2,
          offset: const Offset(0, -3), // Sombra para cima
        ),
      ],
      // Bordas levemente arredondadas no topo
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(0),
        topRight: Radius.circular(0),
      ),
    ),
    padding: EdgeInsets.fromLTRB(8, 8, 8, bottomPadding), // Padding generoso
    child: Row(
      children: [
        // Botão de Confirmação (Principal)
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              // 2. Usando a cor primária do tema para maior consistência
              backgroundColor: _successColor, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6), // Bordas arredondadas
              ),
              elevation: 4, // Elevação suave
            ),
            icon: const Icon(Icons.check, size: 30),
            label: const Text(
              "CONFIRMAR",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            onPressed: onPressed,
          ),
        ),
      ],
    ),
  );
}*/