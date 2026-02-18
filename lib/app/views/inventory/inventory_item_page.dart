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
import 'package:oxdata/app/views/inventory/inventory_confirm_popup.dart';
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

  // Trava apenas para identificadores de local/logística
  final Map<String, bool> _controllerLocked = {
    'unitizer': false,
    'position': false,
  };

  bool _isUnitizerBlink = false;
  bool _isPositionBlink = false;
  bool _isProductBlink = false;

  final ScrollController _scrollController = ScrollController();
  String _productName = " ";

  double _widthVal = 10;
  bool _justQtd = false;
  final Map<String, bool> _controllerjustQtd = {
    'qtdPilha': false,
    'numPilhas': false,
    'qtdAvulsa': false,
  };

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

  Future<bool> handleConfirmAction() async {
    try {
      final service = context.read<InventoryService>();

      final unitizer  = _controllers['unitizer']?.text ?? '';
      final position  = _controllers['position']?.text ?? '';
      final product   = _controllers['product']?.text ?? '';
      final qtdPilha  = _controllers['qtdPilha']?.text ?? '0';
      final numPilhas = _controllers['numPilhas']?.text ?? '0';
      final qtdAvulsa = _controllers['qtdAvulsa']?.text ?? '0';

      if (product.isEmpty) {
        MessageService.showError("Informe o código do produto.");
        FocusScope.of(context).requestFocus(_nodes['product']);
        return false;
      }

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
      
      if (!mounted) return false; // garanto que o estado esta ok

      if (result.status == 1) {
        MessageService.showSuccess(result.message);

      final confirmed = await showConfirmDialog(
        context: context,
        message: "Encerrar contagem desse Unitizador?",
      );

        _resetFormAfterSuccess(confirmed); 

        return true;

      } else {
        MessageService.showError(result.message);
        return false;
      }
    } catch (e) {
      debugPrint("Erro na confirmação: $e");
      return false;
    }
  }

  void clearAllFields() {
    setState(() {
      _controllers.forEach((key, controller) {
        // Limpa se não estiver travado (Produto e Quantidades nunca são travados aqui)
        if (!(_controllerLocked[key] ?? false)) {
          controller.clear();
        }
      });
      _isUnitizerBlink = _isPositionBlink = _isProductBlink = false;
    });
    FocusScope.of(context).unfocus();
    _applySmartFocus();
  }

  void _resetFormAfterSuccess(bool confirmed) {
    setState(() {
      if (confirmed)
      {
        if (!(_controllerLocked['unitizer'] ?? false)) {
          _controllers['unitizer']?.clear();
        }
        if (!(_controllerLocked['position'] ?? false)) {
          _controllers['position']?.clear();
        }
      }
      
      FocusScope.of(context).requestFocus(_nodes['unitizer']);

      _controllers['product']?.clear();
      _controllers['qtdPilha']?.clear();
      _controllers['numPilhas']?.clear();
      _controllers['qtdAvulsa']?.clear();
      _isProductBlink = false;
      _productName = " ";

    });
    _applySmartFocus();
  }

  void _applySmartFocus() {
    Future.microtask(() {
      if (!mounted) return;
      if (!(_controllerLocked['unitizer'] ?? false)) {
        FocusScope.of(context).requestFocus(_nodes['unitizer']);
      } else if (!(_controllerLocked['position'] ?? false)) {
        FocusScope.of(context).requestFocus(_nodes['position']);
      } else {
        FocusScope.of(context).requestFocus(_nodes['product']);
      }
    });
  }

  Future<void> _setForEdit() async {
    final service = context.read<InventoryService>();
    final draft = service.draft;
    if (draft != null) {
      final product = await service.searchProductLocallyByCode(draft.product);
      setState(() {
        _controllers['unitizer']?.text = draft.unitizer;
        _controllers['position']?.text = draft.position;
        _controllers['product']?.text = draft.product;
        _productName = product?.productName ?? " ";
        _controllers['qtdPilha']?.text = (draft.qtdPorPilha != null && draft.qtdPorPilha! > 0) ? draft.qtdPorPilha!.toInt().toString() : '';
        _controllers['numPilhas']?.text = (draft.numPilhas != null && draft.numPilhas! > 0) ? draft.numPilhas!.toInt().toString() : '';
        _controllers['qtdAvulsa']?.text = (draft.qtdAvulsa != null && draft.qtdAvulsa! > 0) ? (draft.qtdAvulsa! % 1 == 0 ? draft.qtdAvulsa!.toInt().toString() : draft.qtdAvulsa!.toString()) : '';
      });
    }
  }

  void _initListeners() {
    _nodes['unitizer']!.addListener(() { if (!_nodes['unitizer']!.hasFocus) { _contagemJaExiste(); _validateField('unitizer', MaskFieldName.Unitizador); } });
    _nodes['position']!.addListener(() { if (!_nodes['position']!.hasFocus) { _contagemJaExiste(); _validateField('position', MaskFieldName.Posicao); } });
    _nodes['product']!.addListener(() { if (!_nodes['product']!.hasFocus) { _contagemJaExiste(); _validateField('product', MaskFieldName.Codigo); } });
  }

  Future<void> _contagemJaExiste() async {
    final unitizer = _controllers['unitizer']?.text ?? '';
    final position = _controllers['position']?.text ?? '';
    final product = _controllers['product']?.text ?? '';
    if (unitizer.isEmpty || position.isEmpty || product.isEmpty) return;
    
    final service = context.read<InventoryService>();
    final existingRecord = await service.checkExistingRecord(unitizer, position, product);
    if (existingRecord != null) {
      setState(() {
        _controllers['qtdPilha']!.text = existingRecord.inventStandardStack.toString();
        _controllers['numPilhas']!.text = existingRecord.inventQtdStack.toString();
        _controllers['qtdAvulsa']!.text = existingRecord.inventQtdIndividual.toString();
      });
      MessageService.showInfo("Contagem anterior carregada.");
    }
  }

  Future<void> _handleProductBlur() async {
    final code = _controllers['product']!.text;
    if (code.isEmpty) return;
    final product = await context.read<InventoryService>().searchProductLocallyByCode(code);
    setState(() {
      if (product != null) {
        _controllers['product']!.text = product.barcode;
        _isProductBlink = false;
        _productName = product.productName;
      } else {
        _productName = " ";
        _isProductBlink = true;
      }
    });
    if (product != null) FocusScope.of(context).requestFocus(_nodes['qtdPilha']);
  }

  Future<void> _validateField(String key, MaskFieldName field) async {
    final text = _controllers[key]!.text;
    if (text.isEmpty) { _setBlink(key, false); return; }
    final masks = await context.read<InventoryService>().getMasksByFieldName(field);
    final isValid = MaskValidatorService.validateMask(text, masks.map((m) => m.fieldMask).toList());
    _setBlink(key, !isValid);
  }

  void _setBlink(String key, bool value) {
    setState(() {
      if (key == 'unitizer') { _isUnitizerBlink = value; if(value) _openInfoPopup('unitizer', MaskFieldName.Unitizador, "Código Unitizador"); }
      if (key == 'position') { _isPositionBlink = value; if(value) _openInfoPopup('position', MaskFieldName.Posicao, "Código Posição"); }
      if (key == 'product') { _isProductBlink = value; if(value) _openInfoPopup('product', MaskFieldName.Codigo, "Código Produto"); }
    });
  }

  void _onJustQtd(bool val) {
    setState(() {
      _justQtd = val;
      _controllerjustQtd['qtdPilha'] = val;
      _controllerjustQtd['numPilhas'] = val;
      if (val) {
        _widthVal = 0;
        _controllers['qtdPilha']!.text = "";
        _controllers['numPilhas']!.text = "";
      }
      else {
        _widthVal = 10;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryService>().selectedInventory;
    final totalGeral    = inventory?.inventTotal ?? 0;
    final nameInventory = inventory?.inventName ?? "";

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTotalHeader(totalGeral, nameInventory),
              const SizedBox(height: 14),
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
                isLocked: _controllerLocked['unitizer']!,
                onLockToggle: () => setState(() => _controllerLocked['unitizer'] = !_controllerLocked['unitizer']!),
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
                isLocked: _controllerLocked['position']!,
                onLockToggle: () => setState(() => _controllerLocked['position'] = !_controllerLocked['position']!),
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
                // Sem cadeado para Produto
                showLock: false,
                isLocked: false,
                onLockToggle: () {},
              ),
              SizedBox(
                width: double.infinity,
                child: _productName.trim().isEmpty 
                  ? const SizedBox.shrink() 
                  : SingleChildScrollView(
                      controller: _scrollController, 
                      scrollDirection: Axis.horizontal,
                      // BouncingScrollPhysics dá aquele efeito de "mola" ao chegar no fim
                      physics: const BouncingScrollPhysics(), 
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          _productName,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            color: Colors.indigo.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
              ),
              const SizedBox(height: 12),
              _buildSwitchHeader(
                "QUANTIDADES",
                value: _justQtd,
                onChanged: _onJustQtd,
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  _buildQtyBox("QTD por Pilha", _controllers['qtdPilha']!, _nodes['qtdPilha']!,_controllerjustQtd['qtdPilha']!, true),
                  SizedBox(width: _widthVal),
                  _buildQtyBox("Nº de Pilhas", _controllers['numPilhas']!, _nodes['numPilhas']!,_controllerjustQtd['numPilhas']!, true),
                  SizedBox(width: _widthVal),
                  _buildQtyBox("QTD Avulsa", _controllers['qtdAvulsa']!, _nodes['qtdAvulsa']!,_controllerjustQtd['qtdAvulsa']!, false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQtyBox(String label, TextEditingController ctrl, FocusNode node, bool isDisabled, bool isInt) {
    if (isDisabled) {
      return const SizedBox.shrink(); // some do layout
    }
    return Expanded(
      child: TextField(
        controller: ctrl,
        focusNode: node,
        enabled: !isDisabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        onTapOutside: (_) => node.unfocus(),
        inputFormatters: [isInt ? FilteringTextInputFormatter.digitsOnly : FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
        decoration: InputDecoration(
          labelText: label,
          floatingLabelAlignment: FloatingLabelAlignment.center,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.indigo, width: 1)),
        ),
      ),
    );
  }

  /*
  Widget _buildTotalHeader(double total) {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(4)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("TOTAL DE PEÇAS", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(total % 1 == 0 ? total.toInt().toString() : total.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  */

  Widget _buildTotalHeader(double total, String inventoryName) {
    return Container(
      decoration: BoxDecoration(
        color: _primaryColor, 
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha com o Nome do Inventário
          Text(
            inventoryName.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Linha de Divisão
          Divider(
            color: Colors.white.withOpacity(0.3), // Branco suave para contrastar com o fundo
            thickness: 1, // Espessura da linha
            height: 12,    // Espaço total que o divider ocupa (margem cima/baixo)
          ),
          
          // Linha com o Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TOTAL DE PEÇAS", 
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
              ),
              Text(
                total % 1 == 0 ? total.toInt().toString() : total.toStringAsFixed(2), 
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
              ),
            ],
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

  Widget _buildSwitchHeader(
    String title, {
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            const Icon(
              Icons.dashboard_customize,
              size: 20,
              color: _primaryColor,
            ),
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
        ),
        Row(
          children: [
            const Text(
              "Apenas Avulsos?",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.indigo,
            ),
          ],
        ),
      ],
    );
  }


  Future<void> _scanBarcode(int flag) async {
    if (!(await Permission.camera.request().isGranted)) return;
    final res = await Navigator.of(context).push<Barcode?>(MaterialPageRoute(builder: (_) => const BarcodeScannerPage()));
    if (res?.rawValue == null) return;
    _controllers[flag == 1 ? 'unitizer' : flag == 2 ? 'position' : 'product']!.text = res!.rawValue!;
    if (flag == 1) _validateField('unitizer', MaskFieldName.Unitizador);
    else if (flag == 2) _validateField('position', MaskFieldName.Posicao);
    else _handleProductBlur();
  }

  void _clearField(String key) { _controllers[key]!.clear(); _setBlink(key, false); }

  void _openInfoPopup(String key, MaskFieldName field, String title) {
    showDialog(context: context, builder: (context) => FieldInfoPopup(value: _controllers[key]!.text, field: field, title: title, icon: Icons.qr_code_2));
  }

  Future<void> _searchProduct() async {
    final product = await showDialog<Product>(context: context, builder: (_) => const ProductSearchLocalDialog());
    if (product != null) { _controllers['product']!.text = product.barcode; _handleProductBlur(); }
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
  final bool isLocked;
  final VoidCallback onLockToggle;
  final bool showLock; // Nova flag para esconder o ícone

  const _InventoryField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.isBlinking,
    required this.onScan,
    required this.onInfo,
    required this.onClear,
    this.onSubmitted,
    this.extraIcon,
    this.onExtra,
    required this.isLocked,
    required this.onLockToggle,
    this.showLock = true, // Default é mostrar
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onSubmitted: onSubmitted,
              readOnly: isLocked, 
              onTapOutside: (_) => focusNode.unfocus(),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isLocked ? Colors.indigo.shade700 : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: label,
                filled: true,
                fillColor: isLocked ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showLock)
                      IconButton(
                        icon: Icon(
                          isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                          size: 20,
                          color: isLocked ? Colors.indigo : Colors.grey,
                        ),
                        onPressed: onLockToggle,
                      ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, _) => (value.text.isNotEmpty && !isLocked)
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: onClear,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                    color: isLocked ? Colors.indigo.withOpacity(0.5) : const Color(0xFFE2E8F0),
                    width: isLocked ? 1.5 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Colors.indigo, width: 1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ColorChangingButton(icon: Icons.qr_code_2, onPressed: isLocked ? null : onScan),
          if (extraIcon != null) ...[
            const SizedBox(width: 8),
            _ColorChangingButton(icon: extraIcon!, onPressed: isLocked ? null : onExtra),
          ],
          const SizedBox(width: 8),
          _ColorChangingButton(icon: Icons.info_outline, blink: isBlinking, onPressed: onInfo),
        ],
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
    bool isDisabled = widget.onPressed == null;
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: isDisabled ? null : (_) => setState(() => _bgColor = _darkBtnColor),
      onTapUp: isDisabled ? null : (_) => setState(() => _bgColor = _defaultBtnColor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54, width: 54,
        decoration: BoxDecoration(color: isDisabled ? Colors.grey.shade200 : _bgColor, borderRadius: BorderRadius.circular(4)),
        child: Icon(widget.icon, color: isDisabled ? Colors.grey : _primaryColor, size: 36),
      ),
    );
  }
}