import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/core/models/dto/inventory_record_input.dart';
import 'package:oxdata/app/core/models/dto/status_result.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/utils/mask_validate.dart';
import 'package:oxdata/app/core/widgets/product_search_local.dart';
import 'package:oxdata/app/views/inventory/inventory_confirm_popup.dart';
import 'package:oxdata/app/views/inventory/inventory_info_popup.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:oxdata/db/app_database.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';

// ---------------------------------------------------------------------------
// Constantes
// ---------------------------------------------------------------------------

const Color _primaryColor    = Color(0xFF3F51B5);
const Color _defaultBtnColor = Color(0xFFE3F2FD);
const Color _darkBtnColor    = Color.fromARGB(255, 187, 211, 251);

enum _ScanTarget { unitizer, position, product }

// ---------------------------------------------------------------------------
// InventoryItemPage
// ---------------------------------------------------------------------------

class InventoryItemPage extends StatefulWidget {
  static final GlobalKey<_InventoryItemPageState> inventoryKey =
      GlobalKey<_InventoryItemPageState>();

  const InventoryItemPage({super.key});

  @override
  State<InventoryItemPage> createState() => _InventoryItemPageState();
}

class _InventoryItemPageState extends State<InventoryItemPage> {

  // ── Controllers & Nodes ──────────────────────────────────────────────────

  late final Map<String, TextEditingController> _controllers = {
    'unitizer':  TextEditingController(),
    'position':  TextEditingController(),
    'product':   TextEditingController(),
    'qtdPilha':  TextEditingController(),
    'numPilhas': TextEditingController(),
    'qtdAvulsa': TextEditingController(),
  };

  late final Map<String, FocusNode> _nodes = {
    'unitizer':  FocusNode(),
    'position':  FocusNode(),
    'product':   FocusNode(),
    'qtdPilha':  FocusNode(),
    'numPilhas': FocusNode(),
    'qtdAvulsa': FocusNode(),
  };

  final Map<String, bool> _controllerLocked = {
    'unitizer': false,
    'position': false,
  };

  // ── Estado de validação ───────────────────────────────────────────────────

  bool _isUnitizerBlink = false;
  bool _isPositionBlink = false;
  bool _isProductBlink  = false;

  /// Campos obrigatórios de identificação.
  static const List<String> _requiredFields = ['unitizer', 'position', 'product'];

  /// Campos que participam da validação de quantidade.
  static const List<String> _qtdFields = ['qtdPilha', 'numPilhas', 'qtdAvulsa'];

  /// `true` quando todos os campos estão válidos e o formulário pode ser confirmado.
  final ValueNotifier<bool> canConfirm = ValueNotifier(false);

  // ── Estado da UI ──────────────────────────────────────────────────────────

  final ScrollController _scrollController = ScrollController();
  String _productName = ' ';
  double _widthVal    = 10;
  bool   _justQtd     = false;

  // ── Ciclo de vida ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setForEdit());
  }

  @override
  void dispose() {
    _removeQtdListeners();
    canConfirm.dispose();
    for (final c in _controllers.values) c.dispose();
    for (final n in _nodes.values) n.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Listeners ─────────────────────────────────────────────────────────────

  void _initListeners() {
    _nodes['unitizer']!.addListener(_onUnitizerFocusChange);
    _nodes['position']!.addListener(_onPositionFocusChange);
    _nodes['product']!.addListener(_onProductFocusChange);

    for (final key in [..._requiredFields, ..._qtdFields]) {
      _controllers[key]!.addListener(_updateCanConfirm);
    }
  }

  void _removeQtdListeners() {
    for (final key in [..._requiredFields, ..._qtdFields]) {
      _controllers[key]!.removeListener(_updateCanConfirm);
    }
  }

  void _onUnitizerFocusChange() {
    if (!_nodes['unitizer']!.hasFocus) {
      _validateField('unitizer', MaskFieldName.Unitizador);
      if (_controllers['unitizer']!.text.isNotEmpty) {
        _contagemJaExiste();
        FocusScope.of(context).requestFocus(_nodes['position']);
      }
    }
  }

  void _onPositionFocusChange() {
    if (!_nodes['position']!.hasFocus) {
      _validateField('position', MaskFieldName.Posicao);
      if (_controllers['position']!.text.isNotEmpty) {
        _contagemJaExiste();
        FocusScope.of(context).requestFocus(_nodes['product']);
      }
    }
  }

  void _onProductFocusChange() {
    if (!_nodes['product']!.hasFocus) {
      _handleProductBlur();
    }
  }

  // ── Lógica de negócio ─────────────────────────────────────────────────────

  Future<void> _setForEdit() async {
    if (!mounted) return;
    final service = context.read<InventoryService>();
    final draft   = service.draft;
    if (draft == null) return;

    final product = await service.searchProductLocallyByCode(draft.product);
    if (!mounted) return;

    setState(() {
      _controllers['unitizer']!.text = draft.unitizer;
      _controllers['position']!.text = draft.position;
      _controllers['product']!.text  = draft.product;
      _productName = product?.productName ?? ' ';

      _controllers['qtdPilha']!.text = _formatQtd(draft.qtdPorPilha, forceInt: true);
      _controllers['numPilhas']!.text = _formatQtd(draft.numPilhas, forceInt: true);
      _controllers['qtdAvulsa']!.text = _formatQtd(draft.qtdAvulsa);
    });
  }

  /// Formata um valor de quantidade para exibição no campo de texto.
  String _formatQtd(double? value, {bool forceInt = false}) {
    if (value == null || value <= 0) return '';
    if (forceInt || value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }

  Future<void> _contagemJaExiste() async {
    final unitizer = _controllers['unitizer']!.text;
    final position = _controllers['position']!.text;
    final product  = _controllers['product']!.text;
    if (unitizer.isEmpty || position.isEmpty || product.isEmpty) return;

    final service = context.read<InventoryService>();

    final local = await service.checkExistingRecord(unitizer, position, product);
    if (!mounted) return;

    if (local != null) {
      _applyContagem(
        qtdPilha:  local.inventStandardStack,
        numPilhas: local.inventQtdStack,
        qtdAvulsa: local.inventQtdIndividual,
        message:   "Contagem anterior carregada.",
      );
      return;
    }

    /*
    final remote = await service.checkExistingRecordRemote(unitizer, position, product);
    if (!mounted) return;

    if (remote != null) {
      _applyContagem(
        qtdPilha:  remote.inventStandardStack,
        numPilhas: remote.inventQtdStack,
        qtdAvulsa: remote.inventQtdIndividual,
        message:   "Contagem remota carregada.",
      );
    }
    */
  }

  void _applyContagem({
    required int?    qtdPilha,
    required int?    numPilhas,
    required double? qtdAvulsa,
    required String  message,
  }) {
    setState(() {
      _controllers['qtdPilha']!.text  = (qtdPilha  ?? 0).toString();
      _controllers['numPilhas']!.text = (numPilhas ?? 0).toString();
      _controllers['qtdAvulsa']!.text = (qtdAvulsa ?? 0).toString();
    });
    MessageService.showInfo(message);
    FocusScope.of(context).requestFocus(_nodes['qtdAvulsa']);
  }

  Future<void> _handleProductBlur() async {
    final code = _controllers['product']!.text;
    if (code.isEmpty) return;

    final service = context.read<InventoryService>();
    final product = await service.searchProductLocallyByCode(code);
    if (!mounted) return;

    if (product != null) {
      setState(() {
        _controllers['product']!.text = product.barcode;
        _isProductBlink = false;
        _productName    = product.productName;
      });
      await _contagemJaExiste();
      if (mounted) FocusScope.of(context).requestFocus(_nodes['qtdPilha']);
    } else {
      setState(() {
        _productName    = ' ';
        _isProductBlink = true;
        _controllers['product']!.clear();
      });
      if (mounted) FocusScope.of(context).requestFocus(_nodes['product']);
      await _validateField('product', MaskFieldName.Codigo);
    }
  }

  Future<void> _validateField(String key, MaskFieldName field) async {
    final text = _controllers[key]!.text;
    if (text.isEmpty) {
      _setBlink(key, false);
      return; // ← sem requestFocus aqui
    }

    final service = context.read<InventoryService>();
    final masks   = await service.getMasksByFieldName(field);
    if (!mounted) return;

    final isValid = MaskValidatorService.validateMask(
      text, masks.map((m) => m.fieldMask).toList(),
    );
    _setBlink(key, !isValid);
  }

  Future<bool> handleConfirmAction() async {
    try {
      final service   = context.read<InventoryService>();
      final product   = _controllers['product']!.text;

      if (product.isEmpty) {
        MessageService.showError("Informe o código do produto.");
        FocusScope.of(context).requestFocus(_nodes['product']);
        return false;
      }

      final result = await service.confirmDraft(
        InventoryRecordInput(
          unitizer:    _controllers['unitizer']!.text,
          position:    _controllers['position']!.text,
          product:     product,
          qtdPorPilha: double.tryParse(_controllers['qtdPilha']!.text)  ?? 0,
          numPilhas:   double.tryParse(_controllers['numPilhas']!.text)  ?? 0,
          qtdAvulsa:   double.tryParse(_controllers['qtdAvulsa']!.text)  ?? 0,
        ),
      );

      if (!mounted) return false;

      if (result.status == 1) {
        MessageService.showSuccess(result.message);
        final encerrar = await showConfirmDialog(
          context: context,
          message: "Encerrar contagem desse Unitizador?",
        );
        _resetFormAfterSuccess(encerrar);
        return true;
      }

      MessageService.showError(result.message);
      return false;
    } catch (e) {
      debugPrint("Erro na confirmação: $e");
      return false;
    }
  }

  void clearAllFields() {
    setState(() {
      for (final entry in _controllers.entries) {
        if (!(_controllerLocked[entry.key] ?? false)) entry.value.clear();
      }
      _isUnitizerBlink = _isPositionBlink = _isProductBlink = false;
    });
    FocusScope.of(context).unfocus();
    _applySmartFocus();
  }

  void _resetFormAfterSuccess(bool encerrarUnitizador) {
    setState(() {
      if (encerrarUnitizador) {
        if (!(_controllerLocked['unitizer'] ?? false)) _controllers['unitizer']!.clear();
        if (!(_controllerLocked['position'] ?? false)) _controllers['position']!.clear();
      }
      _controllers['product']!.clear();
      _controllers['qtdPilha']!.clear();
      _controllers['numPilhas']!.clear();
      _controllers['qtdAvulsa']!.clear();
      _isProductBlink = false;
      _productName    = ' ';
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

  void _setBlink(String key, bool value) {
    setState(() {
      switch (key) {
        case 'unitizer':
          _isUnitizerBlink = value;
          if (value) _openInfoPopup('unitizer', MaskFieldName.Unitizador, "Código Unitizador");
        case 'position':
          _isPositionBlink = value;
          if (value) _openInfoPopup('position', MaskFieldName.Posicao, "Código Posição");
        case 'product':
          _isProductBlink = value;
          if (value) _openInfoPopup('product', MaskFieldName.Codigo, "Código Produto");
      }
    });
    _updateCanConfirm();
  }

  /// Avalia se o formulário está pronto para confirmação.
  /// Regra de quantidade: (qtdPilha + numPilhas) OU qtdAvulsa devem estar preenchidos.
  void _updateCanConfirm() {

    final anyBlink = _isUnitizerBlink || _isPositionBlink || _isProductBlink;
    
    final anyEmpty = _requiredFields.any(
      (key) => (_controllers[key]?.text ?? '').trim().isEmpty,
    );

    // Precisa de (qtdPilha + numPilhas) OU qtdAvulsa preenchido
    final qtdPilha  = (_controllers['qtdPilha']?.text  ?? '').trim();
    final numPilhas = (_controllers['numPilhas']?.text ?? '').trim();
    final qtdAvulsa = (_controllers['qtdAvulsa']?.text ?? '').trim();

    final hasPilhas  = qtdPilha.isNotEmpty && numPilhas.isNotEmpty;
    final hasAvulsa  = qtdAvulsa.isNotEmpty;
    final hasQtd     = hasPilhas || hasAvulsa;

    canConfirm.value = anyBlink || anyEmpty || !hasQtd;

  }

  void _onJustQtd(bool val) {
    setState(() {
      _justQtd  = val;
      _widthVal = val ? 0 : 10;
      if (val) {
        _controllers['qtdPilha']!.clear();
        _controllers['numPilhas']!.clear();
      }
    });
    _updateCanConfirm();

    if (val) {
      Future.microtask(() {
        if (mounted) FocusScope.of(context).requestFocus(_nodes['qtdAvulsa']);
      });
    }
  }

  // ── Scan / Produto ────────────────────────────────────────────────────────

  Future<void> _scanBarcode(_ScanTarget target) async {
    if (!await Permission.camera.request().isGranted) return;

    final res = await Navigator.of(context).push<Barcode?>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (res?.rawValue == null || !mounted) return;

    switch (target) {
      case _ScanTarget.unitizer:
        _controllers['unitizer']!.text = res!.rawValue!;
        await _validateField('unitizer', MaskFieldName.Unitizador);
        if (mounted && !_isUnitizerBlink) {
          FocusScope.of(context).requestFocus(_nodes['position']);
        }

      case _ScanTarget.position:
        _controllers['position']!.text = res!.rawValue!;
        await _validateField('position', MaskFieldName.Posicao);
        if (mounted && !_isPositionBlink) {
          FocusScope.of(context).requestFocus(_nodes['product']);
        }

      case _ScanTarget.product:
        _controllers['product']!.text = res!.rawValue!;
        await _handleProductBlur();
    }
  }

  void _clearField(String key) {
    if (key == 'product') _productName = ' ';
    _controllers[key]!.clear();
    _setBlink(key, false);
  }

  void _openInfoPopup(String key, MaskFieldName field, String title) {
    showDialog(
      context: context,
      builder: (_) => FieldInfoPopup(
        value: _controllers[key]!.text,
        field: field,
        title: title,
        icon:  Icons.qr_code_2,
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
      await _handleProductBlur();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final inventory     = context.watch<InventoryService>().selectedInventory;
    final totalGeral    = inventory?.inventTotal ?? 0;
    final nameInventory = inventory?.inventName  ?? '';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTotalHeader(totalGeral, nameInventory),
              const SizedBox(height: 12),
              _buildSectionHeader("IDENTIFICAÇÃO"),
              const SizedBox(height: 6),
              _InventoryField(
                label:        "Unitizador",
                controller:   _controllers['unitizer']!,
                focusNode:    _nodes['unitizer']!,
                isBlinking:   _isUnitizerBlink,
                isLocked:     _controllerLocked['unitizer']!,
                onScan:       () => _scanBarcode(_ScanTarget.unitizer),
                onClear:      () => _clearField('unitizer'),
                onSubmitted:  (_) => _validateField('unitizer', MaskFieldName.Unitizador),
                onInfo:       () => _openInfoPopup('unitizer', MaskFieldName.Unitizador, "Código Unitizador"),
                onLockToggle: () => setState(() =>
                    _controllerLocked['unitizer'] = !_controllerLocked['unitizer']!),
              ),
              _InventoryField(
                label:        "Posição",
                controller:   _controllers['position']!,
                focusNode:    _nodes['position']!,
                isBlinking:   _isPositionBlink,
                isLocked:     _controllerLocked['position']!,
                onScan:       () => _scanBarcode(_ScanTarget.position),
                onClear:      () => _clearField('position'),
                onSubmitted:  (_) => _validateField('position', MaskFieldName.Posicao),
                onInfo:       () => _openInfoPopup('position', MaskFieldName.Posicao, "Código Posição"),
                onLockToggle: () => setState(() =>
                    _controllerLocked['position'] = !_controllerLocked['position']!),
              ),
              _InventoryField(
                label:        "Produto",
                controller:   _controllers['product']!,
                focusNode:    _nodes['product']!,
                isBlinking:   _isProductBlink,
                isLocked:     false,
                showLock:     false,
                extraIcon:    Icons.search,
                onScan:       () => _scanBarcode(_ScanTarget.product),
                onClear:      () => _clearField('product'),
                onExtra:      _searchProduct,
                onSubmitted:  (_) => _handleProductBlur(),
                onInfo:       () => _openInfoPopup('product', MaskFieldName.Codigo, "Código Produto"),
                onLockToggle: () {},
              ),
              //if (_productName.trim().isNotEmpty)
                SingleChildScrollView(
                  controller:       _scrollController,
                  scrollDirection:  Axis.horizontal,
                  physics:          const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 0, top: 0),
                    child: Text(
                      _productName,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        color:      Colors.indigo.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize:   13,
                      ),
                    ),
                  ),
                ),
              _buildSwitchHeader(
                "QUANTIDADES",
                value:     _justQtd,
                onChanged: _onJustQtd,
              ),
              Row(
                children: [
                  _buildQtyBox("QTD por Pilha", _controllers['qtdPilha']!,  _nodes['qtdPilha']!,  _justQtd, isInt: true, nextNode: _nodes['numPilhas']),
                  SizedBox(width: _widthVal),
                  _buildQtyBox("Nº de Pilhas",  _controllers['numPilhas']!, _nodes['numPilhas']!, _justQtd, isInt: true, nextNode: _nodes['qtdAvulsa']),
                  SizedBox(width: _widthVal),
                  _buildQtyBox("QTD Avulsa",    _controllers['qtdAvulsa']!, _nodes['qtdAvulsa']!, false, isInt: false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets auxiliares ────────────────────────────────────────────────────

  Widget _buildQtyBox(
    String label,
    TextEditingController ctrl,
    FocusNode node,
    bool isDisabled, {
    required bool isInt,
    FocusNode? nextNode,
  }) {
    if (isDisabled) return const SizedBox.shrink();

    return Expanded(
      child: TextField(
        controller:   ctrl,
        focusNode:    node,
        enabled:      true,
        textAlign:    TextAlign.center,
        keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
        style:        const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        onTapOutside: (_) => node.unfocus(),
        onSubmitted:     (_) {
          if (nextNode != null) {
            FocusScope.of(context).requestFocus(nextNode);
          } else {
            node.unfocus();
          }
        },
        inputFormatters: [
          isInt
              ? FilteringTextInputFormatter.digitsOnly
              : FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
        ],
        decoration: InputDecoration(
          labelText:              label,
          floatingLabelAlignment: FloatingLabelAlignment.center,
          filled:                 true,
          fillColor:              const Color(0xFFF8FAFC),
          contentPadding:         const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide:   BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide:   const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide:   const BorderSide(color: Colors.indigo),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalHeader(double total, String inventoryName) {
    final totalStr = total % 1 == 0
        ? total.toInt().toString()
        : total.toStringAsFixed(2);

    return Container(
      decoration: BoxDecoration(
        color:        _primaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        mainAxisSize:     MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            inventoryName.toUpperCase(),
            style: TextStyle(
              color:      Colors.white.withOpacity(0.9),
              fontSize:   15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.3), thickness: 1, height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TOTAL DE PEÇAS",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                totalStr,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor),
        ),
      ],
    );
  }

  /*
  Widget _buildSwitchHeader(
    String title, {
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment:  MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            const Icon(Icons.dashboard_customize, size: 20, color: _primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor),
            ),
          ],
        ),
        Row(
          children: [
            const Text("Apenas Avulsos?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            Transform.scale(
              scale: 0.75, // ajuste de escala 
              child: Switch(value: value, onChanged: onChanged, activeColor: Colors.indigo),
            ),
          ],
        ),
      ],
    );
  }
  */

  Widget _buildSwitchHeader(
    String title, {
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment:  MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            const Icon(Icons.dashboard_customize, size: 20, color: _primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor),
            ),
          ],
        ),
        Row(
          children: [
            const Text("Apenas Avulsos?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            Transform.scale(
              scale: 0.75, 
              child: Switch(
                value: value, 
                onChanged: onChanged, 
                activeColor: Colors.indigo,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // 💡 REMOVE O ESPAÇO EXTRA VERTICAL
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _InventoryField
// ---------------------------------------------------------------------------

class _InventoryField extends StatelessWidget {
  final String                label;
  final TextEditingController controller;
  final FocusNode             focusNode;
  final bool                  isBlinking;
  final bool                  isLocked;
  final bool                  showLock;
  final VoidCallback          onScan;
  final VoidCallback          onInfo;
  final VoidCallback          onClear;
  final VoidCallback          onLockToggle;
  final Function(String)?     onSubmitted;
  final IconData?             extraIcon;
  final VoidCallback?         onExtra;

  const _InventoryField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.isBlinking,
    required this.isLocked,
    required this.onScan,
    required this.onInfo,
    required this.onClear,
    required this.onLockToggle,
    this.showLock   = true,
    this.onSubmitted,
    this.extraIcon,
    this.onExtra,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _buildTextField()),
          const SizedBox(width: 8),
          _ColorChangingButton(
            icon:      Icons.qr_code_2,
            onPressed: isLocked ? null : onScan,
          ),
          if (extraIcon != null) ...[
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon:      extraIcon!,
              onPressed: isLocked ? null : onExtra,
            ),
          ],
          const SizedBox(width: 8),
          _ColorChangingButton(
            icon:      Icons.info_outline,
            blink:     isBlinking,
            onPressed: onInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller:   controller,
      focusNode:    focusNode,
      onSubmitted:  onSubmitted,
      readOnly:     isLocked,
      onTapOutside: (_) => focusNode.unfocus(),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(
        fontSize:   16,
        fontWeight: FontWeight.w500,
        color:      isLocked ? Colors.indigo.shade700 : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText:  label,
        filled:     true,
        fillColor:  isLocked ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLock)
              IconButton(
                icon: Icon(
                  isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  size:  20,
                  color: isLocked ? Colors.indigo : Colors.grey,
                ),
                onPressed: onLockToggle,
              ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, __) => (value.text.isNotEmpty && !isLocked)
                  ? IconButton(
                      icon:      const Icon(Icons.close_rounded, size: 20),
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
          borderSide:   const BorderSide(color: Colors.indigo),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ColorChangingButton
// ---------------------------------------------------------------------------

class _ColorChangingButton extends StatefulWidget {
  final IconData       icon;
  final VoidCallback?  onPressed;
  final bool           blink;

  const _ColorChangingButton({
    required this.icon,
    this.onPressed,
    this.blink = false,
  });

  @override
  State<_ColorChangingButton> createState() => _ColorChangingButtonState();
}

class _ColorChangingButtonState extends State<_ColorChangingButton> {
  Color  _bgColor    = _defaultBtnColor;
  Timer? _blinkTimer;
  bool   _blinkState = false;

  @override
  void initState() {
    super.initState();
    if (widget.blink) _startBlink();
  }

  @override
  void didUpdateWidget(covariant _ColorChangingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blink == oldWidget.blink) return;
    widget.blink ? _startBlink() : _stopBlink();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  void _startBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {
        _blinkState = !_blinkState;
        _bgColor    = _blinkState ? _darkBtnColor : _defaultBtnColor;
      });
    });
  }

  void _stopBlink() {
    _blinkTimer?.cancel();
    if (mounted) setState(() => _bgColor = _defaultBtnColor);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return GestureDetector(
      onTap:     widget.onPressed,
      onTapDown: disabled ? null : (_) => setState(() => _bgColor = _darkBtnColor),
      onTapUp:   disabled ? null : (_) => setState(() => _bgColor = _defaultBtnColor),
      child: AnimatedContainer(
        duration:  const Duration(milliseconds: 200),
        height:    54,
        width:     54,
        decoration: BoxDecoration(
          color:        disabled ? Colors.grey.shade200 : _bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          widget.icon,
          color: disabled ? Colors.grey : _primaryColor,
          size:  36,
        ),
      ),
    );
  }
}