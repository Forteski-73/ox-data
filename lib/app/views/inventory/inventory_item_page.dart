import 'package:flutter/material.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/db/app_database.dart';
import 'package:oxdata/app/core/models/dto/inventory_record_input.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:oxdata/app/views/inventory/inventory_info_popup.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/core/widgets/product_search_local.dart';
import 'package:oxdata/app/core/utils/mask_validate.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// -------------------------------------------------------------------
// CONSTANTES DE ESTILO
// -------------------------------------------------------------------
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
    
    // Sincroniza os controllers com o rascunho inicial do serviço
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToServiceChanges();
      context.read<InventoryService>().addListener(_listenToServiceChanges);
    });
  }

  @override
  void dispose() {
    // É vital remover o listener para evitar vazamento de memória
    context.read<InventoryService>().removeListener(_listenToServiceChanges);
    for (var c in _controllers.values) c.dispose();
    for (var n in _nodes.values) n.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // LISTENERS E LÓGICA DE SINCRONIZAÇÃO
  // -------------------------------------------------------------------

  // Escuta mudanças no serviço (ex: rascunho limpo ou carregado)
  void _listenToServiceChanges() {
    if (!mounted) return;
    final draft = context.read<InventoryService>().draft;
    
    setState(() {
      if (draft == null) {
        for (var c in _controllers.values) c.clear();
        _isUnitizerBlink = _isPositionBlink = _isProductBlink = false;
      } else {
        _updateControllerIfChanged(_controllers['unitizer']!, draft.unitizer);
        _updateControllerIfChanged(_controllers['position']!, draft.position);
        _updateControllerIfChanged(_controllers['product']!, draft.product);
        _updateControllerIfChanged(_controllers['qtdPilha']!, draft.qtdPorPilha!.toInt().toString());
        _updateControllerIfChanged(_controllers['numPilhas']!, draft.numPilhas!.toInt().toString());
        _updateControllerIfChanged(_controllers['qtdAvulsa']!, draft.qtdAvulsa.toString());
      }
    });
  }

  void _updateControllerIfChanged(TextEditingController controller, String newValue) {
    // Só atualiza se o valor for diferente para não perder a posição do cursor/foco
    if (controller.text != newValue) {
      controller.text = newValue;
    }
  }

  void _initListeners() {
    _nodes['unitizer']!.addListener(() => _validateFieldOnBlur('unitizer', MaskFieldName.Unitizador));
    _nodes['position']!.addListener(() => _validateFieldOnBlur('position', MaskFieldName.Posicao));
    _nodes['product']!.addListener(() => _handleProductBlur());

  //_nodes['qtdPilha']!.addListener(() => _autoNextFocus('qtdPilha', 'numPilhas'));
  //_nodes['numPilhas']!.addListener(() => _autoNextFocus('numPilhas', 'qtdAvulsa'));
  //_nodes['qtdAvulsa']!.addListener(() => _autoNextFocus('qtdAvulsa', null));

    _nodes['qtdPilha']!.addListener(() { if (!_nodes['qtdPilha']!.hasFocus) _syncDraft(); });
    _nodes['numPilhas']!.addListener(() { if (!_nodes['numPilhas']!.hasFocus) _syncDraft(); });
    _nodes['qtdAvulsa']!.addListener(() { if (!_nodes['qtdAvulsa']!.hasFocus) _syncDraft(); }); 
  }

  // -------------------------------------------------------------------
  // VALIDAÇÕES E EVENTOS
  // -------------------------------------------------------------------

  Future<void> _validateFieldOnBlur(String key, MaskFieldName field) async {
    if (_nodes[key]!.hasFocus) return;

    final service = context.read<InventoryService>();
    final text = _controllers[key]!.text;

    if (text.isEmpty) {
      _setBlink(key, false);
      _syncDraft();
      return;
    }

    final masks = await service.getMasksByFieldName(field);
    final isValid = MaskValidatorService.validateMask(text, masks.map((m) => m.fieldMask).toList());

    _setBlink(key, !isValid);
    _syncDraft();
  }

  Future<void> _handleProductBlur() async {
    if (_nodes['product']!.hasFocus || _controllers['product']!.text.isEmpty) return;

    final service = context.read<InventoryService>();
    final product = await service.searchProductLocallyByCode(_controllers['product']!.text);

    setState(() {
      if (product != null) {
        _controllers['product']!.text = product.barcode;
        _isProductBlink = false;
        FocusScope.of(context).requestFocus(_nodes['qtdPilha']);
      } else {
        _isProductBlink = true;
      }
    });
    _syncDraft();
  }
  
  /*
  void _autoNextFocus(String current, String? next) {
    if (!_nodes[current]!.hasFocus) {
      _syncDraft();
      if (next != null) FocusScope.of(context).requestFocus(_nodes[next]);
    }
  }*/

  void _setBlink(String key, bool value) {
    if (!mounted) return;
    setState(() {
      if (key == 'unitizer') _isUnitizerBlink = value;
      if (key == 'position') _isPositionBlink = value;
      if (key == 'product') _isProductBlink = value;
    });
  }

  void _syncDraft() {
    context.read<InventoryService>().updateDraft(
          InventoryRecordInput(
            unitizer: _controllers['unitizer']!.text,
            position: _controllers['position']!.text,
            product: _controllers['product']!.text,
            qtdPorPilha: double.tryParse(_controllers['qtdPilha']!.text) ?? 0,
            numPilhas: double.tryParse(_controllers['numPilhas']!.text) ?? 0,
            qtdAvulsa: double.tryParse(_controllers['qtdAvulsa']!.text) ?? 0,
          ),
        );
  }

  // -------------------------------------------------------------------
  // AÇÕES DE SCAN E LIMPEZA
  // -------------------------------------------------------------------

  Future<void> _scanBarcode(int flag) async {
    if (!(await Permission.camera.request().isGranted)) return;

    final barcodeRead = await Navigator.of(context).push<Barcode?>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (barcodeRead?.rawValue == null) return;
    final value = barcodeRead!.rawValue!;

    setState(() {
      if (flag == 1) _controllers['unitizer']!.text = value;
      if (flag == 2) _controllers['position']!.text = value;
      if (flag == 3) _controllers['product']!.text = value;
    });

    if (flag == 1) {
      _validateFieldOnBlur('unitizer', MaskFieldName.Unitizador);
      FocusScope.of(context).requestFocus(_nodes['position']);
    } else if (flag == 2) {
      _validateFieldOnBlur('position', MaskFieldName.Posicao);
      FocusScope.of(context).requestFocus(_nodes['product']);
    } else {
      _handleProductBlur();
    }
  }

  void _clearField(String key) {
    setState(() {
      _controllers[key]!.clear();
      _setBlink(key, false);
    });
    _syncDraft();
    FocusScope.of(context).requestFocus(_nodes[key]);
  }

  // -------------------------------------------------------------------
  // CONSTRUÇÃO DA PÁGINA
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final service = context.watch<InventoryService>();
    final totalGeral = service.selectedInventory?.inventTotal ?? 0.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
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
                onInfo: () => _openInfoPopup('unitizer', MaskFieldName.Unitizador, "Código Unitizador"),
              ),
              
              _InventoryField(
                label: "Posição",
                controller: _controllers['position']!,
                focusNode: _nodes['position']!,
                isBlinking: _isPositionBlink,
                onScan: () => _scanBarcode(2),
                onClear: () => _clearField('position'),
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
                onInfo: () => _openInfoPopup('product', MaskFieldName.Codigo, "Código Produto"),
              ),

              const SizedBox(height: 16),
              _buildSectionHeader("QUANTIDADES"),
              const SizedBox(height: 8),

              Row(
                children: [
                  _buildQtyBox("QTD por Pilha", _controllers['qtdPilha']!, _nodes['qtdPilha']!, true, "0"),
                  const SizedBox(width: 10),
                  _buildQtyBox("Nº de Pilhas", _controllers['numPilhas']!, _nodes['numPilhas']!, true, "0"),
                  const SizedBox(width: 10),
                  _buildQtyBox("QTD Avulsa", _controllers['qtdAvulsa']!, _nodes['qtdAvulsa']!, false, "0.0"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SUB-WIDGETS ---

  Widget _buildTotalHeader(double total) {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(4)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("TOTAL DE PEÇAS", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            total % 1 == 0 ? total.toInt().toString() : total.toStringAsFixed(2),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
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

  Widget _buildQtyBox(String label, TextEditingController ctrl, FocusNode node, bool isInt, String? hint,) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            focusNode: node,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
            style: const TextStyle(fontSize: 20),
            //onChanged: (_) => _syncDraft(), // Sincroniza enquanto digita números
            inputFormatters: [
              isInt ? FilteringTextInputFormatter.digitsOnly : FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            decoration: InputDecoration(
              isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(vertical: 10), hintText: hint,
             ),
          ),
        ],
      ),
    );
  }

  void _openInfoPopup(String key, MaskFieldName field, String title) {
    showDialog(
      context: context,
      builder: (context) => FieldInfoPopup(
        value: _controllers[key]!.text,
        field: field,
        title: title,
        icon: Icons.qr_code_2,
        description: 'Verifique se o formato do código lido está de acordo com os padrões aceitos.',
      ),
    );
  }

  Future<void> _searchProduct() async {
    final product = await showDialog<Product>(
      context: context,
      builder: (_) => const ProductSearchLocalDialog(),
    );
    if (product != null) {
      _controllers['product']!.text = product.barcode;
      _handleProductBlur();
    }
  }
}

// -------------------------------------------------------------------
// COMPONENTE DE CAMPO DE ENTRADA CUSTOMIZADO
// -------------------------------------------------------------------
class _InventoryField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBlinking;
  final VoidCallback onScan;
  final VoidCallback onInfo;
  final VoidCallback onClear;
  final IconData? extraIcon;
  final VoidCallback? onExtra;

  const _InventoryField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.isBlinking,
    required this.onScan,
    required this.onInfo,
    required this.onClear,
    this.extraIcon,
    this.onExtra,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                labelText: label,
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIconConstraints: const BoxConstraints(minHeight: 24, minWidth: 32),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    return value.text.isNotEmpty 
                      ? InkWell(
                          onTap: onClear,
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.only(right: 10.0, left: 4.0),
                            child: Icon(Icons.clear, size: 20, color: Colors.grey),
                          ),
                        )
                      : const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ColorChangingButton(icon: Icons.qr_code_2, onPressed: onScan),
          if (extraIcon != null) ...[
            const SizedBox(width: 8),
            _ColorChangingButton(icon: extraIcon!, onPressed: onExtra),
          ],
          const SizedBox(width: 8),
          _ColorChangingButton(icon: Icons.info_outline, blink: isBlinking, onPressed: onInfo),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// BOTÃO COM FEEDBACK VISUAL E BLINK
// -------------------------------------------------------------------
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
    if (widget.blink != oldWidget.blink) {
      widget.blink ? _startBlink() : _stopBlink();
    }
  }

  void _startBlink() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      setState(() {
        _blinkState = !_blinkState;
        _bgColor = _blinkState ? _darkBtnColor : _defaultBtnColor;
      });
    });
  }

  void _stopBlink() {
    _timer?.cancel();
    setState(() => _bgColor = _defaultBtnColor);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => setState(() => _bgColor = _darkBtnColor),
      onTapUp: (_) => setState(() => _bgColor = _defaultBtnColor),
      onTapCancel: () => setState(() => _bgColor = _defaultBtnColor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54, width: 54,
        decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(4)),
        child: Icon(widget.icon, color: _primaryColor, size: 36),
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';

import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/db/app_database.dart';
import 'package:oxdata/app/core/models/dto/inventory_record_input.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:oxdata/app/views/inventory/inventory_info_popup.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/core/widgets/product_search_local.dart';
import 'package:oxdata/app/core/utils/mask_validate.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// -------------------------------------------------------------------
// CONSTANTES DE ESTILO
// -------------------------------------------------------------------
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
  // Gerenciamento de Controllers e Nodes via Maps para escalabilidade
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

  // Estados de Blink
  bool _isUnitizerBlink = false;
  bool _isPositionBlink = false;
  bool _isProductBlink = false;

  @override
  void initState() {
    super.initState();
    _initListeners();
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    for (var n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  // -------------------------------------------------------------------
  // LISTENERS E LÓGICA
  // -------------------------------------------------------------------

  void _initListeners() {
    // Validação Automática ao perder o foco
    _nodes['unitizer']!.addListener(() => _validateFieldOnBlur('unitizer', MaskFieldName.Unitizador));
    _nodes['position']!.addListener(() => _validateFieldOnBlur('position', MaskFieldName.Posicao));
    _nodes['product']!.addListener(() => _handleProductBlur());

    // Navegação automática entre quantidades
    _nodes['qtdPilha']!.addListener(() => _autoNextFocus('qtdPilha', 'numPilhas'));
    _nodes['numPilhas']!.addListener(() => _autoNextFocus('numPilhas', 'qtdAvulsa'));
    _nodes['qtdAvulsa']!.addListener(() => _autoNextFocus('qtdAvulsa', null));
  }

  Future<void> _validateFieldOnBlur(String key, MaskFieldName field) async {
    if (_nodes[key]!.hasFocus) return;

    final service = context.read<InventoryService>();
    final text = _controllers[key]!.text;

    if (text.isEmpty) {
      _setBlink(key, false);
      _syncDraft();
      return;
    }

    final masks = await service.getMasksByFieldName(field);
    final isValid = MaskValidatorService.validateMask(text, masks.map((m) => m.fieldMask).toList());

    _setBlink(key, !isValid);
    _syncDraft();
  }

  Future<void> _handleProductBlur() async {
    if (_nodes['product']!.hasFocus || _controllers['product']!.text.isEmpty) return;

    final service = context.read<InventoryService>();
    final product = await service.searchProductLocallyByCode(_controllers['product']!.text);

    setState(() {
      if (product != null) {
        _controllers['product']!.text = product.barcode;
        _isProductBlink = false;
        FocusScope.of(context).requestFocus(_nodes['qtdPilha']);
      } else {
        _isProductBlink = true;
      }
    });
    _syncDraft();
  }

  void _autoNextFocus(String current, String? next) {
    if (!_nodes[current]!.hasFocus) {
      _syncDraft();
      if (next != null) FocusScope.of(context).requestFocus(_nodes[next]);
    }
  }

  void _setBlink(String key, bool value) {
    if (!mounted) return;
    setState(() {
      if (key == 'unitizer') _isUnitizerBlink = value;
      if (key == 'position') _isPositionBlink = value;
      if (key == 'product') _isProductBlink = value;
    });
  }

  void _syncDraft() {
    context.read<InventoryService>().updateDraft(
          InventoryRecordInput(
            unitizer: _controllers['unitizer']!.text,
            position: _controllers['position']!.text,
            product: _controllers['product']!.text,
            qtdPorPilha: double.tryParse(_controllers['qtdPilha']!.text),
            numPilhas: double.tryParse(_controllers['numPilhas']!.text) ?? 0,
            qtdAvulsa: double.tryParse(_controllers['qtdAvulsa']!.text) ?? 0,
          ),
        );
  }

  // -------------------------------------------------------------------
  // AÇÕES
  // -------------------------------------------------------------------

  Future<void> _scanBarcode(int flag) async {
    if (!(await Permission.camera.request().isGranted)) return;

    final barcodeRead = await Navigator.of(context).push<Barcode?>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (barcodeRead?.rawValue == null) return;
    final value = barcodeRead!.rawValue!;

    setState(() {
      if (flag == 1) _controllers['unitizer']!.text = value;
      if (flag == 2) _controllers['position']!.text = value;
      if (flag == 3) _controllers['product']!.text = value;
    });

    if (flag == 1) {
      _validateFieldOnBlur('unitizer', MaskFieldName.Unitizador);
      FocusScope.of(context).requestFocus(_nodes['position']);
    } else if (flag == 2) {
      _validateFieldOnBlur('position', MaskFieldName.Posicao);
      FocusScope.of(context).requestFocus(_nodes['product']);
    } else {
      _handleProductBlur();
    }
  }

  void _clearField(String key) {
    setState(() {
      _controllers[key]!.clear();
      _setBlink(key, false);
    });
    _syncDraft();
    FocusScope.of(context).requestFocus(_nodes[key]);
  }

  // -------------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final service = context.watch<InventoryService>();
    final totalGeral = service.selectedInventory?.inventTotal ?? 0.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTotalHeader(totalGeral),
              const SizedBox(height: 16),
              _buildSectionHeader("IDENTIFICAÇÃO"),
              const SizedBox(height: 6),
              
              // Campo Unitizador
              _InventoryField(
                label: "Unitizador",
                controller: _controllers['unitizer']!,
                focusNode: _nodes['unitizer']!,
                isBlinking: _isUnitizerBlink,
                onScan: () => _scanBarcode(1),
                onClear: () => _clearField('unitizer'),
                onInfo: () => _openInfoPopup('unitizer', MaskFieldName.Unitizador, "Código Unitizador"),
              ),
              
              // Campo Posição
              _InventoryField(
                label: "Posição",
                controller: _controllers['position']!,
                focusNode: _nodes['position']!,
                isBlinking: _isPositionBlink,
                onScan: () => _scanBarcode(2),
                onClear: () => _clearField('position'),
                onInfo: () => _openInfoPopup('position', MaskFieldName.Posicao, "Código Posição"),
              ),

              // Campo Produto
              _InventoryField(
                label: "Produto",
                controller: _controllers['product']!.text == "" ? _controllers['product']! : _controllers['product']!,
                focusNode: _nodes['product']!,
                isBlinking: _isProductBlink,
                onScan: () => _scanBarcode(3),
                onClear: () => _clearField('product'),
                extraIcon: Icons.search,
                onExtra: _searchProduct,
                onInfo: () => _openInfoPopup('product', MaskFieldName.Codigo, "Código Produto"),
              ),

              const SizedBox(height: 16),
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

  // --- SUB-WIDGETS ---

  Widget _buildTotalHeader(double total) {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(4)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("TOTAL DE PEÇAS", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            total % 1 == 0 ? total.toInt().toString() : total.toStringAsFixed(2),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
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

  Widget _buildQtyBox(String label, TextEditingController ctrl, FocusNode node, bool isInt) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            focusNode: node,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
            style: const TextStyle(fontSize: 20),
            inputFormatters: [
              isInt ? FilteringTextInputFormatter.digitsOnly : FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(vertical: 10)),
          ),
        ],
      ),
    );
  }

  // --- MÉTODOS DE DIALOGS ---

  void _openInfoPopup(String key, MaskFieldName field, String title) {
    showDialog(
      context: context,
      builder: (context) => FieldInfoPopup(
        value: _controllers[key]!.text,
        field: field,
        title: title,
        icon: Icons.qr_code_2,
        description: 'Verifique se o formato do código lido está de acordo com os padrões aceitos.',
      ),
    );
  }

  Future<void> _searchProduct() async {
    final product = await showDialog<Product>(
      context: context,
      builder: (_) => const ProductSearchLocalDialog(),
    );
    if (product != null) {
      _controllers['product']!.text = product.barcode;
      _handleProductBlur();
    }
  }
}

// -------------------------------------------------------------------
// COMPONENTE DE CAMPO DE ENTRADA CUSTOMIZADO
// -------------------------------------------------------------------
class _InventoryField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBlinking;
  final VoidCallback onScan;
  final VoidCallback onInfo;
  final VoidCallback onClear;
  final IconData? extraIcon;
  final VoidCallback? onExtra;

  const _InventoryField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.isBlinking,
    required this.onScan,
    required this.onInfo,
    required this.onClear,
    this.extraIcon,
    this.onExtra,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                labelText: label,
                isDense: true,
                border: const OutlineInputBorder(),
                // AJUSTE DO BOTÃO LIMPAR:
                suffixIconConstraints: const BoxConstraints(
                  minHeight: 24,
                  minWidth: 32, // Largura total reservada para o ícone
                ),
                suffixIcon: controller.text.isNotEmpty 
                  ? InkWell(
                      onTap: onClear,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 10.0, left: 4.0), // Ajuste fino aqui
                        child: Icon(Icons.clear, size: 20, color: Colors.grey),
                      ),
                    )
                  : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ColorChangingButton(icon: Icons.qr_code_2, onPressed: onScan),
          if (extraIcon != null) ...[
            const SizedBox(width: 8),
            _ColorChangingButton(icon: extraIcon!, onPressed: onExtra),
          ],
          const SizedBox(width: 8),
          _ColorChangingButton(icon: Icons.info_outline, blink: isBlinking, onPressed: onInfo),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// BOTÃO COM FEEDBACK VISUAL E BLINK
// -------------------------------------------------------------------
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
    if (widget.blink != oldWidget.blink) {
      widget.blink ? _startBlink() : _stopBlink();
    }
  }

  void _startBlink() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      setState(() {
        _blinkState = !_blinkState;
        _bgColor = _blinkState ? _darkBtnColor : _defaultBtnColor;
      });
    });
  }

  void _stopBlink() {
    _timer?.cancel();
    setState(() => _bgColor = _defaultBtnColor);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => setState(() => _bgColor = _darkBtnColor),
      onTapUp: (_) => setState(() => _bgColor = _defaultBtnColor),
      onTapCancel: () => setState(() => _bgColor = _defaultBtnColor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54, width: 54,
        decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(4)),
        child: Icon(widget.icon, color: _primaryColor, size: 36),
      ),
    );
  }
}
*/

/*
import 'package:flutter/material.dart';

import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/db/app_database.dart';
import 'package:oxdata/app/core/models/dto/inventory_record_input.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:oxdata/app/views/inventory/inventory_info_popup.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/core/widgets/instruction_popup.dart';
import 'package:oxdata/app/core/widgets/product_search_local.dart';
import 'package:oxdata/app/core/utils/mask_validate.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';
import 'package:flutter/services.dart';
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
  
  late final FocusNode _unitizerFocusNode;
  late final FocusNode _positionFocusNode;
  late final FocusNode _productFocusNode;
  late final FocusNode _qtdPorPilhaFocusNode;
  late final FocusNode _numPilhasFocusNode;
  late final FocusNode _qtdAvulsaFocusNode;

  bool _isUnitizerBlink = false;
  bool _isPositionBlink = false;
  bool _isProductBlink  = false;

  /*
  @override
  void initState() {
    super.initState();
  
    _unitizerFocusNode    = FocusNode();
    _positionFocusNode    = FocusNode();
    _productFocusNode     = FocusNode();
    _qtdPorPilhaFocusNode = FocusNode();
    _numPilhasFocusNode   = FocusNode();
    _qtdAvulsaFocusNode   = FocusNode();
    
  }*/

  @override
  void initState() {
    super.initState();
    
    final service = context.read<InventoryService>();
    _unitizerFocusNode    = FocusNode();
    _positionFocusNode    = FocusNode();
    _productFocusNode     = FocusNode();
    _qtdPorPilhaFocusNode = FocusNode();
    _numPilhasFocusNode   = FocusNode();
    _qtdAvulsaFocusNode   = FocusNode();
    
    _unitizerFocusNode.addListener(() async { // 1. Adicionado async
      if (!_unitizerFocusNode.hasFocus) {
        // 2. Buscando as máscaras no serviço
        final masks = await service.getMasksByFieldName(MaskFieldName.Unitizador);
        final maskStrings = masks.map((m) => m.fieldMask).toList();

        // 3. Valida usando o texto do CONTROLLER (ex: _unitizerController)
        // Se o valor for 0, você pode tratar aqui ou no validator
        bool isValid = MaskValidatorService.validateMask(_unitizerController.text, maskStrings,);

        if (!isValid && _unitizerController.text != "") {
          //_unitizerController.text = "";
          _isUnitizerBlink = true;
        }
        else
        {
          _isUnitizerBlink = false;
        }
        _syncDraft();
      }
    });

    _positionFocusNode.addListener(() async {
      if (!_positionFocusNode.hasFocus) {
        // 2. Buscando as máscaras no serviço
        final masks = await service.getMasksByFieldName(MaskFieldName.Posicao);
        final maskStrings = masks.map((m) => m.fieldMask).toList();

        // 3. Valida usando o texto do CONTROLLER (ex: _unitizerController)
        // Se o valor for 0, você pode tratar aqui ou no validator
        bool isValid = MaskValidatorService.validateMask(_positionController.text, maskStrings,);

        if (!isValid && _positionController.text != "") {
          //_positionController.text = "";
          _isPositionBlink = true;
        }
        else
        {
          _isPositionBlink = false;
        }
        _syncDraft();
      }
    });

    _productFocusNode.addListener(() {
      if (!_productFocusNode.hasFocus) {
        // Usuário saiu do campo
        _productChanged();
      }
    });
    
    _qtdPorPilhaFocusNode.addListener(() {
      if (!_qtdPorPilhaFocusNode.hasFocus) {
        // Usuário saiu do campo
        _syncDraft();
        FocusScope.of(context).requestFocus(_numPilhasFocusNode);
      }
    });
    
    _numPilhasFocusNode.addListener(() {
      if (!_numPilhasFocusNode.hasFocus) {
        // Usuário saiu do campo
        _syncDraft();
        FocusScope.of(context).requestFocus(_qtdAvulsaFocusNode);
      }
    });
    
    _qtdAvulsaFocusNode.addListener(() {
      if (!_qtdAvulsaFocusNode.hasFocus) {
        // Usuário saiu do campo
        _syncDraft();
      }
    });
  }

  @override
  void dispose() {
    // Importante: Descartar os controllers para liberar recursos
    _unitizerController.dispose();
    _positionController.dispose();
    _productController.dispose();
    _qtdPorPilhaController.dispose();
    _numPilhasController.dispose();
    _qtdAvulsaController.dispose();

    _unitizerFocusNode.dispose();
    _positionFocusNode.dispose();
    _productFocusNode.dispose();
    _qtdPorPilhaFocusNode.dispose();
    _numPilhasFocusNode.dispose();
    _qtdAvulsaFocusNode.dispose();

    _isUnitizerBlink = false;
    _isPositionBlink = false;
    _isProductBlink = false;

    super.dispose();
  }

  void _productChanged() async {
    if (_productController.text != "")
    {
      final service = context.read<InventoryService>();
      final productLocal = await service.searchProductLocallyByCode(_productController.text);
      if (productLocal != null) {
          _productController.text = productLocal.barcode;
          _isProductBlink = false;
          FocusScope.of(context).requestFocus(_qtdPorPilhaFocusNode);
        } else {
          //_productController.text = "";
          _isProductBlink = true;
          FocusScope.of(context).requestFocus(_productFocusNode);
        }
    }
    _syncDraft();
  }

  Future<void> _scanBarcode(int flag) async { // Remova o _ do parâmetro para padronizar
    var status = await Permission.camera.request();
    if (!status.isGranted) return;

    setState(() { // pra não lokiar a leitura com a cãmera
      if (flag == 1) _unitizerController.clear();
      if (flag == 2) _positionController.clear();
      if (flag == 3) _productController.clear();
    });

  // 3. Pequeno delay para garantir que o teclado abaixou e o estado limpou
  await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() async {
        // 1. Abra o scanner e aguarde o resultado
        final barcodeRead = await Navigator.of(context).push<Barcode?>(
          MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
        );

        // 2. Se o usuário cancelou ou voltou sem ler nada, pare aqui
        if (barcodeRead == null || barcodeRead.rawValue == null || barcodeRead.rawValue!.isEmpty) {
          return;
        }

        // 3. Pegue o valor e use localmente apenas UMA vez
        final String currentValue = barcodeRead.rawValue!;

        setState(() {
          if (flag == 1) _unitizerController.text = currentValue;
          if (flag == 2) _positionController.text = currentValue;
          if (flag == 3) _productController.text = currentValue;
        });

        //_showQuickConferencePopup(currentValue);  
        // 4. Ações pós-atribuição (fora do setState para melhor performance)
        if (flag == 1) {
          await _validateUnitizer();
          FocusScope.of(context).requestFocus(_positionFocusNode);
        } else if (flag == 2) {
          _syncDraft(); // Garante que salvou a posição
          FocusScope.of(context).requestFocus(_productFocusNode);
        } else if (flag == 3) {
          _productChanged();
        }
      });
    }
  }

  void _showQuickConferencePopup(String value) {
    // Extração segura (usando a lógica anterior)
    String safeExtract(String str, int start, int end) {
      if (str.length <= start) return "";
      return str.substring(start, str.length < end ? str.length : end).trim();
    }

    final data = {
      "Depósito": safeExtract(value, 0, 2),
      "Bloco":    safeExtract(value, 2, 4),
      "Quadra":   safeExtract(value, 4, 5),
      "Lote":     safeExtract(value, 5, 7),
      "Andar":    safeExtract(value, 7, 8),
    };

    showDialog(
      context: context,
      barrierDismissible: false, // Usuário não fecha clicando fora
      builder: (BuildContext context) {
        // Agenda o fechamento para 1 segundo
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Conferência de Posição",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Divider(),
                const SizedBox(height: 10),
                ...data.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${e.key}:", style: const TextStyle(fontSize: 16)),
                      Row(
                        children: [
                          Text(
                            e.value.isEmpty ? "--" : e.value,
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                              color: e.value.isEmpty ? Colors.red : Colors.black
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            e.value.isEmpty ? Icons.error_outline : Icons.check_circle_outline,
                            color: e.value.isEmpty ? Colors.red : Colors.green,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        );
      },
    );
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

  void _openInfoPopup({
    required String value,
    required MaskFieldName field,
    required String title,
    required IconData icon,
    required String description,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FieldInfoPopup(
        value: value,
        field: field,
        title: title,
        icon: icon,
        description: description,
      ),
    );
  }

  void _syncDraft() {
    final service = context.read<InventoryService>();

    service.updateDraft(
      InventoryRecordInput(
        unitizer: _unitizerController.text,
        position: _positionController.text,
        product: _productController.text,
      qtdPorPilha: _qtdPorPilhaController.text.isEmpty
          ? null
          : double.tryParse(_qtdPorPilhaController.text),
        numPilhas: double.tryParse(_numPilhasController.text) ?? 0,
        qtdAvulsa: double.tryParse(_qtdAvulsaController.text) ?? 0,
      ),
    );
  }

  Future<void> _validateUnitizer() async {
    final service = context.read<InventoryService>();

    final masks =
        await service.getMasksByFieldName(MaskFieldName.Unitizador);

    final maskStrings = masks.map((m) => m.fieldMask).toList();

    final isValid = MaskValidatorService.validateMask(
      _unitizerController.text,
      maskStrings,
    );

    setState(() {
      _isUnitizerBlink =
          !isValid && _unitizerController.text.isNotEmpty;
    });

    _syncDraft();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _unitizerController,
                focusNode: _unitizerFocusNode,
                style: const TextStyle(fontSize: 18.0), 
                decoration: InputDecoration(
                  labelText: "Unitizador",
                  labelStyle: const TextStyle(fontSize: 16.0), 
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _unitizerController.clear();
                        _isUnitizerBlink = false;
                        _syncDraft();
                        FocusScope.of(context).requestFocus(_unitizerFocusNode);
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.qr_code_2,
              blink: false,
              onPressed: () {
                _scanBarcode(1);
              },
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.info_outline,
              blink: _isUnitizerBlink,
              onPressed: () {
                _openInfoPopup(
                  value: _unitizerController.text,
                  field: MaskFieldName.Unitizador,
                  title: 'Código do Unitizador',
                  icon: Icons.qr_code_2,
                  description:
                      'Este é o código de barras que identifica uma unidade de contagem (geralmente é um código por palete).',
                );
                //showScanInstructions(context);
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
                focusNode: _productFocusNode,
                style: const TextStyle(fontSize: 18), 
                decoration: InputDecoration(
                  labelText: "Produto",
                  labelStyle: const TextStyle(fontSize: 16.0), 
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _productController.clear();
                        _isProductBlink = false;
                        _syncDraft();
                        FocusScope.of(context).requestFocus(_productFocusNode);
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.qr_code_2,
              blink: false,
              onPressed: () {
                _scanBarcode(3);
              },
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.search,
              blink: false,
              onPressed: () {
                _searchProduct();
              },
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.info_outline,
              blink: _isProductBlink,
              onPressed: () {
                _openInfoPopup(
                  value: _productController.text,
                  field: MaskFieldName.Codigo,
                  title: 'Código do Produto',
                  icon: Icons.qr_code_2,
                  description:
                    'Este é o código de barras do peça/produto, você também pode informar o código do AX.',
                );
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
                focusNode: _positionFocusNode,
                style: const TextStyle(fontSize: 18.0), 
                decoration: InputDecoration(
                  labelText: "Posição",
                  labelStyle: const TextStyle(fontSize: 16.0), 
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _positionController.clear();
                        _isPositionBlink = false;
                        _syncDraft();
                        FocusScope.of(context).requestFocus(_positionFocusNode);
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.qr_code_2,
              blink: false,
              onPressed: () {
                _scanBarcode(2);
              },
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.info_outline,
              blink: _isPositionBlink,
              onPressed: () {
                _openInfoPopup(
                  value: _positionController.text,
                  field: MaskFieldName.Posicao,
                  title: 'Código da Posição',
                  icon: Icons.qr_code_2,
                  description:
                      'Este é o código de barras que identifica a posição contada na rua em que você esta.',
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityIntField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    VoidCallback? onEditingComplete,
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
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
          onEditingComplete: onEditingComplete,
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

  Widget _buildQuantityNumericField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    VoidCallback? onEditingComplete,
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
          focusNode: focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'^\d*\.?\d*$'),
            ),
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
          onEditingComplete: onEditingComplete,
          decoration: const InputDecoration(
            hintText: '0.0',
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
   /* return Consumer<InventoryService>(
      builder: (context, service, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _applyDraftToFields(service.draft);
        });*/
        final service = context.watch<InventoryService>();
        final double totalGeral =
            service.selectedInventory?.inventTotal ?? 0.0;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- CONTAINER DE TOTAL REATIVO ---
                  Container(
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
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            totalGeral % 1 == 0
                                ? totalGeral.toInt().toString()
                                : totalGeral.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Identificação
                  _buildSectionTitle("IDENTIFICAÇÃO"),
                  const SizedBox(height: 6),
                  _buildUnitizerTextField(),
                  const SizedBox(height: 6),
                  _buildPositionTextField(),
                  const SizedBox(height: 6),
                  _buildProductTextField(),
                  const SizedBox(height: 16),

                  // Quantidades
                  _buildSectionTitle("QUANTIDADES"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuantityIntField(
                          label: "QTD por Pilha",
                          controller: _qtdPorPilhaController,
                          focusNode: _qtdPorPilhaFocusNode,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildQuantityIntField(
                          label: "Nº de Pilhas",
                          controller: _numPilhasController,
                          focusNode: _numPilhasFocusNode,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildQuantityNumericField(
                          label: "QTD Avulsa",
                          controller: _qtdAvulsaController,
                          focusNode: _qtdAvulsaFocusNode,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      //},
   // );
  }

}

*/