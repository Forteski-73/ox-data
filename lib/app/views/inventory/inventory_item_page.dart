import 'package:flutter/material.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/dto/inventory_record_input.dart';
import 'package:oxdata/app/core/models/dto/status_result.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:oxdata/app/views/inventory/inventory_info_popup.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/core/widgets/product_search_local.dart';
import 'package:oxdata/app/core/utils/mask_validate.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';
import 'package:oxdata/db/app_database.dart';
import 'package:flutter/services.dart';
import 'dart:async';

const Color _primaryColor = Color(0xFF3F51B5);
const Color _defaultBtnColor = Color(0xFFE3F2FD);
const Color _darkBtnColor = Color.fromARGB(255, 187, 211, 251);

class InventoryItemPage extends StatefulWidget {
  static final GlobalKey<_InventoryItemPageState> inventoryKey = GlobalKey<_InventoryItemPageState>();
  const InventoryItemPage({super.key});

  @override
  State<InventoryItemPage> createState() => _InventoryItemPageState();
}

class _InventoryItemPageState extends State<InventoryItemPage> {
  final Map<String, TextEditingController> _controllers = {
    'unitizer': TextEditingController(),
    'position': TextEditingController(),
    'product': TextEditingController(),
    'qtdPilha': TextEditingController(),
    'numPilhas': TextEditingController(),
    'qtdAvulsa': TextEditingController(),
  };

  final Map<String, FocusNode> _nodes = {
    'unitizer': FocusNode(),
    'position': FocusNode(),
    'product': FocusNode(),
    'qtdPilha': FocusNode(),
    'numPilhas': FocusNode(),
    'qtdAvulsa': FocusNode(),
  };

  bool _isUnitizerBlink = false;
  bool _isPositionBlink = false;
  bool _isProductBlink = false;

  @override
  void initState() {
    super.initState();
    _initListeners();
    _setForEdit();
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    _nodes.values.forEach((n) => n.dispose());
    super.dispose();
  }

  // Dentro da classe _InventoryItemPageState
  // Remova o '_' para tornar o método acessível via GlobalKey
Future<bool> handleConfirmAction() async {
    try {
      final service = context.read<InventoryService>();

      // Pegamos os valores com segurança (evitando o erro Null Check operator)
      final unitizer = _controllers['unitizer']?.text ?? '';
      final position = _controllers['position']?.text ?? '';
      final product = _controllers['product']?.text ?? '';
      final qtdPilha = _controllers['qtdPilha']?.text ?? '0';
      final numPilhas = _controllers['numPilhas']?.text ?? '0';
      final qtdAvulsa = _controllers['qtdAvulsa']?.text ?? '0';

      debugPrint("unitizer*******************: $unitizer");
      debugPrint("position*******************: $position");
      debugPrint("product*******************: $product");
      debugPrint("qtdPilha*******************: $qtdPilha");
      debugPrint("numPilhas*******************: $numPilhas");
      debugPrint("qtdAvulsa*******************: $qtdAvulsa");

      // Validação básica de UI
      if (product.isEmpty) {
        MessageService.showError("Informe o código do produto.");
        FocusScope.of(context).requestFocus(_nodes['product']);
        return false;
      }
      debugPrint("*");
      final StatusResult result = await service.confirmDraft(
        InventoryRecordInput(
          unitizer: unitizer,
          position: position,
          product: product,
          qtdPorPilha: double.tryParse(qtdPilha) ?? 0,
          numPilhas: double.tryParse(numPilhas) ?? 0,
          qtdAvulsa: double.tryParse(qtdAvulsa) ?? 0,
        ),
      );
      debugPrint("***");

      if (result.status == 1) {
        debugPrint("****");
        MessageService.showSuccess(result.message);
        _resetFormAfterSuccess(); // <--- Limpeza automática
        debugPrint("*****");
        return true;
      } else {
        MessageService.showError(result.message);
        return false;
      }
    } catch (e, stack) {
      debugPrint("Erro na confirmação: $e");
      debugPrint(stack.toString());
      return false;
    }
  }

  void _resetFormAfterSuccess() {
    setState(() {
      // Limpa dados do produto e quantidades
      _controllers['product']?.clear();
      _controllers['qtdPilha']?.clear();
      _controllers['numPilhas']?.clear();
      _controllers['qtdAvulsa']?.clear();
      
      _isProductBlink = false;

      // Retorna o foco para o produto para a próxima contagem
      FocusScope.of(context).requestFocus(_nodes['product']);
    });
  }

  void _setForEdit() {
    final service = context.read<InventoryService>();
    final draft = service.draft;

    if (draft != null) {
      setState(() {
        _controllers['unitizer']?.text = draft.unitizer;
        _controllers['position']?.text = draft.position;
        _controllers['product']?.text = draft.product;
        
        _controllers['qtdPilha']?.text = (draft.qtdPorPilha != null && draft.qtdPorPilha! > 0) 
            ? draft.qtdPorPilha!.toInt().toString() : '';
            
        _controllers['numPilhas']?.text = (draft.numPilhas != null && draft.numPilhas! > 0) 
            ? draft.numPilhas!.toInt().toString() : '';
            
        _controllers['qtdAvulsa']?.text = (draft.qtdAvulsa != null && draft.qtdAvulsa! > 0) 
            ? (draft.qtdAvulsa! % 1 == 0 ? draft.qtdAvulsa!.toInt().toString() : draft.qtdAvulsa!.toString()) 
            : '';
      });

      /*_validateField('unitizer', MaskFieldName.Unitizador);
      _validateField('position', MaskFieldName.Posicao);
      _handleProductBlur();
      */
    }
  }

  void _initListeners() {
    // Adicionamos a lógica de verificar duplicidade apenas no "Blur" (perda de foco)
    _nodes['unitizer']!.addListener(() {
      if (!_nodes['unitizer']!.hasFocus) {
        _contagemJaExiste();
        _validateField('unitizer', MaskFieldName.Unitizador);
      }
    });
    _nodes['position']!.addListener(() {
      if (!_nodes['position']!.hasFocus) {
        _contagemJaExiste();
        _validateField('position', MaskFieldName.Posicao);
      }
    });
    _nodes['product']!.addListener(() {
      if (!_nodes['product']!.hasFocus) {
        _contagemJaExiste();
        _validateField('product', MaskFieldName.Codigo);
      }
    });
  }

  Future<void> _contagemJaExiste() async {
    debugPrint("-->");
    final unitizer = _controllers['unitizer']?.text ?? '';
    final position = _controllers['position']?.text ?? '';
    final product = _controllers['product']?.text ?? '';
    debugPrint("--->");
    if (unitizer.isEmpty || position.isEmpty || product.isEmpty) return;
    
    debugPrint("---->$unitizer, $position, $product");
    final service = context.read<InventoryService>();
    final existingRecord = await service.checkExistingRecord(unitizer, position, product);
    debugPrint("----->");
    if (existingRecord != null) {
      debugPrint("------>");
      setState(() {
        _controllers['qtdPilha']!.text = existingRecord.inventStandardStack.toString();
        _controllers['numPilhas']!.text = existingRecord.inventQtdStack.toString();
        _controllers['qtdAvulsa']!.text = existingRecord.inventQtdIndividual.toString();
        debugPrint("-->");
      });
      debugPrint("-------->");
      // Opcional: Avisar o usuário que carregou dados existentes
      MessageService.showInfo("Contagem anterior carregada para este item.");
    }
  }

  // --- AÇÕES DE CAMPOS ---

  Future<void> _handleProductBlur() async {
    final code = _controllers['product']!.text;
    if (code.isEmpty) return;

    final product = await context.read<InventoryService>().searchProductLocallyByCode(code);
    
    setState(() {
      if (product != null) {
        _controllers['product']!.text = product.barcode;
        _isProductBlink = false;
      } else {
        _isProductBlink = true;
      }
    });

    //await _syncAndRefresh();
    if (product != null) FocusScope.of(context).requestFocus(_nodes['qtdPilha']);
  }

  Future<void> _validateField(String key, MaskFieldName field) async {
    final text = _controllers[key]!.text;
    if (text.isEmpty) {
      _setBlink(key, false);
      //await _syncAndRefresh();
      return;
    }

    final masks = await context.read<InventoryService>().getMasksByFieldName(field);
    final isValid = MaskValidatorService.validateMask(text, masks.map((m) => m.fieldMask).toList());

    _setBlink(key, !isValid);
    //await _syncAndRefresh();
  }

  void _setBlink(String key, bool value) {
    setState(() {
      if (key == 'unitizer') {
        _isUnitizerBlink = value;
        if(_isUnitizerBlink == true)
          _openInfoPopup('unitizer', MaskFieldName.Unitizador, "Código Unitizador");
      }
      if (key == 'position') {
        _isPositionBlink = value;
        if(_isPositionBlink == true)
          _openInfoPopup('position', MaskFieldName.Posicao, "Código Posição");
      }
      if (key == 'product') {
        _isProductBlink = value;
        if(_isProductBlink == true)
          _openInfoPopup('product', MaskFieldName.Codigo, "Código Produto");
      }
    });
  }

  // --- INTERFACE ---

  @override
  Widget build(BuildContext context) {
    final totalGeral = context.watch<InventoryService>().selectedInventory?.inventTotal ?? 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTotalHeader(totalGeral),
              const SizedBox(height: 16),
              _buildSectionHeader("IDENTIFICAÇÃO"),
              const SizedBox(height: 6),
              _InventoryField(
                label: "Unitizador",
                controller: _controllers['unitizer']!,
                focusNode: _nodes['unitizer']!,
                isBlinking: _isUnitizerBlink,
                onScan: () => _scanBarcode(1),
                onClear: () => _clearField('unitizer'),
                onSubmitted: (_) => _validateField('unitizer', MaskFieldName.Unitizador),
                onInfo: () => _openInfoPopup('unitizer', MaskFieldName.Unitizador, "Código Unitizador"),
              ),
              _InventoryField(
                label: "Posição",
                controller: _controllers['position']!,
                focusNode: _nodes['position']!,
                isBlinking: _isPositionBlink,
                onScan: () => _scanBarcode(2),
                onClear: () => _clearField('position'),
                onSubmitted: (_) => _validateField('position', MaskFieldName.Posicao),
                onInfo: () => _openInfoPopup('position', MaskFieldName.Posicao, "Código Posição"),
              ),
              _InventoryField(
                label: "Produto",
                controller: _controllers['product']!,
                focusNode: _nodes['product']!,
                isBlinking: _isProductBlink,
                onScan: () => _scanBarcode(3),
                onClear: () => _clearField('product'),
                extraIcon: Icons.search,
                onExtra: _searchProduct,
                onSubmitted: (_) => _handleProductBlur(),
                onInfo: () => _openInfoPopup('product', MaskFieldName.Codigo, "Código Produto"),
              ),
              const SizedBox(height: 14),
              _buildSectionHeader("QUANTIDADES"),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildQtyBox("QTD por Pilha", _controllers['qtdPilha']!, _nodes['qtdPilha']!, true),
                  const SizedBox(width: 10),
                  _buildQtyBox("Nº de Pilhas", _controllers['numPilhas']!, _nodes['numPilhas']!, true),
                  const SizedBox(width: 10),
                  _buildQtyBox("QTD Avulsa", _controllers['qtdAvulsa']!, _nodes['qtdAvulsa']!, false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQtyBox(String label, TextEditingController ctrl, FocusNode node, bool isInt) {
    return Expanded(
      child: TextField(
        controller: ctrl,
        focusNode: node,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
        // Ajustado para 17 para bater com o seu campo de referência
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        onTapOutside: (_) => node.unfocus(),
        inputFormatters: [
          isInt 
            ? FilteringTextInputFormatter.digitsOnly 
            : FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
        ],
        decoration: InputDecoration(
          labelText: label, // O label agora fica dentro do campo
          floatingLabelAlignment: FloatingLabelAlignment.center, // Centraliza o label ao subir
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          // Padding vertical 14 para manter a mesma altura de 54px dos botões
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          
          // Bordas idênticas ao seu exemplo
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
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
      ),
    );
  }

  // --- MÉTODOS AUXILIARES ---

  Widget _buildTotalHeader(double total) {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(4)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("TOTAL DE PEÇAS", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(total % 1 == 0 ? total.toInt().toString() : total.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        const Icon(Icons.dashboard_customize, size: 20, color: _primaryColor),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor)),
      ],
    );
  }

  Future<void> _scanBarcode(int flag) async {
    if (!(await Permission.camera.request().isGranted)) return;
    final res = await Navigator.of(context).push<Barcode?>(MaterialPageRoute(builder: (_) => const BarcodeScannerPage()));
    if (res?.rawValue == null) return;
    
    final val = res!.rawValue!;
    _controllers[flag == 1 ? 'unitizer' : flag == 2 ? 'position' : 'product']!.text = val;

    if (flag == 1) _validateField('unitizer', MaskFieldName.Unitizador);
    else if (flag == 2) _validateField('position', MaskFieldName.Posicao);
    else _handleProductBlur();
  }

  void _clearField(String key) {
    _controllers[key]!.clear();
    _setBlink(key, false);
    //_syncAndRefresh();
  }

  void _openInfoPopup(String key, MaskFieldName field, String title) {
    showDialog(
      context: context,
      builder: (context) => FieldInfoPopup(
        value: _controllers[key]!.text,
        field: field,
        title: title,
        icon: Icons.qr_code_2,
      ),
    );
  }

  Future<void> _searchProduct() async {
    final product = await showDialog<Product>(context: context, builder: (_) => const ProductSearchLocalDialog());
    if (product != null) {
      _controllers['product']!.text = product.barcode;
      _handleProductBlur();
    }
  }
}

class _InventoryField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBlinking;
  final VoidCallback onScan;
  final VoidCallback onInfo;
  final VoidCallback onClear;
  final Function(String)? onSubmitted;
  final IconData? extraIcon;
  final VoidCallback? onExtra;

  const _InventoryField({
    required this.label, required this.controller, required this.focusNode,
    required this.isBlinking, required this.onScan, required this.onInfo,
    required this.onClear, this.onSubmitted, this.extraIcon, this.onExtra,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        //padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onSubmitted: onSubmitted,
                onTapOutside: (_) => focusNode.unfocus(),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  //isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),

                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) =>
                      value.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: onClear,
                            )
                          : const SizedBox.shrink(),
                    ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
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
              ),
            ),

            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.qr_code_2,
              onPressed: onScan,
            ),

            if (extraIcon != null) ...[
              const SizedBox(width: 8),
              _ColorChangingButton(
                icon: extraIcon!,
                onPressed: onExtra,
              ),
            ],

            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.info_outline,
              blink: isBlinking,
              onPressed: onInfo,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChangingButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool blink;
  const _ColorChangingButton({required this.icon, this.onPressed, this.blink = false});
  @override
  State<_ColorChangingButton> createState() => _ColorChangingButtonState();
}

class _ColorChangingButtonState extends State<_ColorChangingButton> {
  Color _bgColor = _defaultBtnColor;
  Timer? _timer;
  bool _blinkState = false;

  @override
  void initState() {
    super.initState();
    if (widget.blink) _startBlink();
  }

  @override
  void didUpdateWidget(covariant _ColorChangingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blink != oldWidget.blink) widget.blink ? _startBlink() : _stopBlink();
  }

  void _startBlink() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (mounted) setState(() { _blinkState = !_blinkState; _bgColor = _blinkState ? _darkBtnColor : _defaultBtnColor; });
    });
  }

  void _stopBlink() { _timer?.cancel(); if (mounted) setState(() => _bgColor = _defaultBtnColor); }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => setState(() => _bgColor = _darkBtnColor),
      onTapUp: (_) => setState(() => _bgColor = _defaultBtnColor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54, width: 54,
        decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(4)),
        child: Icon(widget.icon, color: _primaryColor, size: 36),
      ),
    );
  }
}