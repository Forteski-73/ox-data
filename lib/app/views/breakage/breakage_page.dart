import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel;
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/widgets/app_confirm_dialog.dart';
import 'package:oxdata/app/core/widgets/product_search.dart';
import 'package:oxdata/app/views/product/search_products_page.dart';
import 'package:oxdata/app/views/breakage/breakage_camera_page.dart';
import 'package:oxdata/app/views/breakage/breakage_edit_dialog.dart';
import 'package:oxdata/app/views/breakage/breakage_filter_bar.dart';
import 'package:oxdata/app/views/breakage/breakage_history_sheet.dart';
import 'package:oxdata/app/core/utils/download_file.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:oxdata/app/core/models/breakage_model.dart';
import 'package:oxdata/app/core/models/product_model.dart';
import 'package:oxdata/app/core/models/store_model.dart';
import 'package:oxdata/app/core/services/breakage_service.dart';
import 'package:oxdata/app/core/services/product_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';

class BreakagePage extends StatefulWidget {
  const BreakagePage({super.key});

  @override
  State<BreakagePage> createState() => _BreakagePageState();
}

class _BreakagePageState extends State<BreakagePage> {
  // Ids fixos das abas; só aparecem as que o perfil pode ver (AGENTS.md 3.3).
  static const int _tabRegistrar  = 0;
  static const int _tabAprovacoes = 1;
  static const int _tabBaixar     = 2;
  static const int _tabHistorico  = 3;

  int _currentIndex = _tabRegistrar; // 0: Registrar, 1: Aprovações, 2: Baixar, 3: Histórico

  // Formulário State
  final TextEditingController _productController = TextEditingController();
  String? _selectedStoreId;
  ProductModel? _selectedProduct;
  double? _unitPrice;
  bool _loadingPrice = false;
  int _quantidade = 1;
  String _selectedMotivo = 'Acidente de Manuseio / Queda';
  Uint8List? _capturedPhoto;
  final Set<int> _selectedHistoricoIds = {};
  final Set<int> _selectedBaixaIds = {};

  final Color _oxfordColor = const Color(0xFF002B49);
  final Color _goldColor = Colors.white;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final NumberFormat _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _productController.addListener(_onProductTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _productController.removeListener(_onProductTextChanged);
    _productController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final service = context.read<BreakageService>();
    await service.loadProfile();
    if (!mounted) return;

    final tabs = _visibleTabs(service);
    if (tabs.isNotEmpty) setState(() => _currentIndex = tabs.first);

    await service.fetchStores();
    if (!mounted) return;
    _applyDefaultStore(service.stores, service.lastStoreId);

    await service.fetchBreakages();
  }

  /// Loja padrão do registro: a única do usuário ou a última escolhida.
  void _applyDefaultStore(List<StoreModel> stores, String? lastStoreId) {
    if (stores.isEmpty) return;
    final String storeId;
    if (stores.length == 1) {
      storeId = stores.first.storeId;
    } else if (stores.any((s) => s.storeId == lastStoreId)) {
      storeId = lastStoreId!;
    } else {
      return;
    }
    setState(() => _selectedStoreId = storeId);
  }

  List<int> _visibleTabs(BreakageService service) => [
        if (service.profile.canRegister) _tabRegistrar,
        if (service.canAccess(BreakageTab.approvals)) _tabAprovacoes,
        if (service.canAccess(BreakageTab.writeOff)) _tabBaixar,
        if (service.canAccess(BreakageTab.history)) _tabHistorico,
      ];

  String _formatDate(DateTime? date) => date == null ? '-' : _dateFormat.format(date);
  String _formatMoney(double? value) => value == null ? '—' : _currency.format(value);

  @override
  Widget build(BuildContext context) {
    final breakageService = context.watch<BreakageService>();
    final tabs = _visibleTabs(breakageService);
    final index = tabs.indexOf(_currentIndex);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBarCustom(title: 'Gestão de Quebras'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (breakageService.isLoading)
                LinearProgressIndicator(minHeight: 2, color: _oxfordColor, backgroundColor: Colors.transparent),

              // Área de Conteúdo Dinâmico (Abas)
              Expanded(
                child: !breakageService.profileLoaded
                    ? Center(child: CircularProgressIndicator(color: _oxfordColor))
                    : tabs.isEmpty
                        ? _buildNoProfileState(breakageService)
                        : IndexedStack(
                            index: max(0, index),
                            children: [
                              for (final tab in tabs)
                                switch (tab) {
                                  _tabRegistrar  => _buildRegistrarTab(breakageService),
                                  _tabAprovacoes => _buildAprovacoesTab(breakageService),
                                  _tabBaixar     => _buildBaixarTab(breakageService),
                                  _              => _buildHistoricoTab(breakageService),
                                },
                            ],
                          ),
              ),

              // Navegação Inferior (Bottom Nav Bar) — oculta se o usuário só tem uma aba
              if (tabs.length > 1)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (tabs.contains(_tabRegistrar))
                        _buildNavItem(_tabRegistrar, Icons.camera_alt_rounded, 'Registrar'),
                      if (tabs.contains(_tabAprovacoes))
                        _buildNavItem(_tabAprovacoes, Icons.playlist_add_check_rounded, 'Aprovações',
                            badgeCount: breakageService.approvalsBadge),
                      if (tabs.contains(_tabBaixar))
                        _buildNavItem(_tabBaixar, Icons.inventory_2_outlined, 'Baixar',
                            badgeCount: breakageService.writeOffBadge),
                      if (tabs.contains(_tabHistorico))
                        _buildNavItem(_tabHistorico, Icons.fact_check_outlined, 'Histórico'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Usuário sem ESTOQUISTA, GERENTE_LOJA nem CONTROLES_INT (ou falha ao ler o perfil).
  Widget _buildNoProfileState(BreakageService service) {
    final error = service.profileError;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(error != null ? Icons.cloud_off_outlined : Icons.lock_outline,
                color: error != null ? Colors.red : Colors.grey, size: 40),
            const SizedBox(height: 8),
            Text(
              error ?? 'Você não tem perfil de acesso à Gestão de Quebras.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (error != null)
              TextButton.icon(
                onPressed: _init,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Tentar novamente', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {int badgeCount = 0}) {
    final bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: isSelected ? Colors.black : Colors.grey.shade400, size: 22),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? _oxfordColor : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Miniatura da foto do registro: usa a imagem baixada do FTP (Base64) quando
  /// disponível; enquanto carrega exibe um indicador; senão tenta a URL pública.
  Widget _buildPhoto(String url, double size) {
    final service = context.read<BreakageService>();
    final bytes = service.photo(url);
    final cacheSize = (size * MediaQuery.of(context).devicePixelRatio).round();

    Widget child;
    if (url.isEmpty) {
      child = _buildPhotoPlaceholder(size);
    } else if (bytes != null) {
      child = Image.memory(
        bytes,
        width: size,
        height: size,
        cacheWidth: cacheSize,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(size),
      );
    } else if (service.isPhotoLoading(url)) {
      child = Container(
        width: size,
        height: size,
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: SizedBox(width: size * 0.3, height: size * 0.3, child: CircularProgressIndicator(strokeWidth: 2, color: _oxfordColor)),
      );
    } else {
      child = Image.network(
        url,
        width: size,
        height: size,
        cacheWidth: cacheSize,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(size),
      );
    }

    return ClipRRect(borderRadius: BorderRadius.circular(8), child: child);
  }

  Widget _buildPhotoPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey.shade100,
      child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: size * 0.4),
    );
  }

  /// Estado vazio / erro padrão das listas.
  Widget _buildEmptyState(BreakageService service, String message) {
    final hasError = service.errorMessage != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasError ? Icons.cloud_off_outlined : Icons.check_circle_outline,
              color: hasError ? Colors.red : Colors.green, size: 40),
          const SizedBox(height: 8),
          Text(
            hasError ? (service.errorMessage ?? 'Erro ao carregar registros') : message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          if (hasError)
            TextButton.icon(
              onPressed: service.isLoading ? null : service.fetchBreakages,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Tentar novamente', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        BreakageStatus.pendenteGerente => Colors.amber,
        BreakageStatus.pendenteCi      => Colors.orange,
        BreakageStatus.devolvido       => Colors.red,
        BreakageStatus.aprovado        => Colors.green,
        BreakageStatus.baixado         => Colors.blue,
        BreakageStatus.excluido        => Colors.grey,
        BreakageStatus.rejeitado       => Colors.red,
        _                              => Colors.grey,
      };

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(BreakageStatus.label(status), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildSectionLabel(String text) =>
      Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey));

  /// Link "Ver linha do tempo" + contador de edições + selo "Reprovado N×".
  Widget _buildHistoryLink(BreakageModel r, BreakageService service) {
    return InkWell(
      onTap: () => _showHistory(r, service),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timeline, size: 14, color: _oxfordColor),
                const SizedBox(width: 4),
                Text('Ver linha do tempo', style: TextStyle(fontSize: 11, color: _oxfordColor, fontWeight: FontWeight.bold)),
              ],
            ),
            if (r.editCount > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, size: 13, color: Colors.indigo.shade400),
                  Text(' ${r.editCount} ${r.editCount == 1 ? 'edição' : 'edições'}',
                      style: TextStyle(fontSize: 11, color: Colors.indigo.shade400)),
                ],
              ),
            if (r.returnCount > 0) _buildReturnBadge(r.returnCount),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
      child: Text('Reprovado $count×', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
    );
  }

  void _showHistory(BreakageModel r, BreakageService service) {
    showBreakageHistorySheet(
      context: context,
      breakage: r,
      productName: service.productName(r),
      storeName: service.storeName(r),
      statusColor: _statusColor(r.status),
      photoBuilder: _buildPhoto,
      onPhotoTap: _showPhotoViewer,
    );
  }

  // ==========================================
  // ABA 1: REGISTRAR QUEBRA
  // ==========================================
  Widget _buildRegistrarTab(BreakageService service) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _oxfordColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _oxfordColor.withOpacity(0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: _oxfordColor, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Registre avarias acidentais anexando uma foto nítida dos cacos e selecionando o item correspondente para auditoria.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF002B49), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. Loja
          _buildSectionLabel('LOJA'),
          const SizedBox(height: 8),
          _buildStoreField(service.stores),
          const SizedBox(height: 16),

          // 2. Evidência Fotográfica
          _buildSectionLabel('EVIDÊNCIA FOTOGRÁFICA'),
          const SizedBox(height: 8),
          InkWell(
            onTap: _takeRegisterPhoto,
            child: Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: _capturedPhoto == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                          child: Icon(Icons.camera_alt, color: _oxfordColor, size: 20),
                        ),
                        const SizedBox(height: 6),
                        const Text('Tirar Foto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const Text('Fotografe os cacos em local bem iluminado', style: TextStyle(fontSize: 9, color: Colors.grey)),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_capturedPhoto!, fit: BoxFit.cover),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                              child: const Text('Toque para alterar', style: TextStyle(color: Colors.white, fontSize: 9)),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Seleção de Produto
          _buildSectionLabel('SELECIONAR PRODUTO'),
          const SizedBox(height: 8),

          ProductSearch(
            controller: _productController,
            label: 'Produto',
            onSearch: () => _openProductSearch(context),
          ),

          if (_selectedProduct != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedProduct!.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  if (_selectedProduct!.barcode != null && _selectedProduct!.barcode!.isNotEmpty)
                    Text('QR Code: ${_selectedProduct!.barcode}', style: TextStyle(fontSize: 11, color: _oxfordColor, fontWeight: FontWeight.bold)),
                  Text(
                    _loadingPrice ? 'Valor unitário: carregando...' : 'Valor unitário: ${_formatMoney(_unitPrice)}',
                    style: TextStyle(fontSize: 11, color: _oxfordColor),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // 4. Quantidade
          _buildSectionLabel('QUANTIDADE'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () => setState(() => _quantidade = max(1, _quantidade - 1)), icon: const Icon(Icons.remove_rounded, color: Colors.indigo, size: 24)),
                Text('$_quantidade', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                IconButton(onPressed: () => setState(() => _quantidade++), icon: const Icon(Icons.add_rounded, color: Colors.indigo, size: 24)),
              ],
            ),
          ),
          if (_selectedProduct != null && _unitPrice != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Valor total: ${_formatMoney(_unitPrice! * _quantidade)}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _oxfordColor),
              ),
            ),
          const SizedBox(height: 16),

          // 5. Motivo
          _buildSectionLabel('MOTIVO DA OCORRÊNCIA'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedMotivo,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.indigo, size: 28),
            dropdownColor: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
            decoration: _fieldDecoration(),
            items: [
              'Acidente de Manuseio / Queda',
              'Tombamento de Palete / Empilhadeira',
              'Falha de Embalagem / Caixa Danificada',
              'Defeito no Forno / Trinca Térmica',
              'Outros',
            ].map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (val) => setState(() => _selectedMotivo = val!),
          ),
          const SizedBox(height: 24),

          // Botão Enviar
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _oxfordColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: _submitQuebra,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send, size: 16, color: _goldColor),
                const SizedBox(width: 8),
                const Text('ENVIAR PARA APROVAÇÃO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
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
    );
  }

  /// Uma loja: só leitura. Várias: dropdown com as lojas do usuário.
  Widget _buildStoreField(List<StoreModel> stores) {
    if (stores.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade100)),
        child: const Text('Nenhuma loja vinculada ao seu usuário.', style: TextStyle(fontSize: 12, color: Colors.red)),
      );
    }

    if (stores.length == 1) {
      return InputDecorator(
        decoration: _fieldDecoration(),
        child: Text(stores.first.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      );
    }

    return DropdownButtonFormField<String>(
      value: stores.any((s) => s.storeId == _selectedStoreId) ? _selectedStoreId : null,
      isExpanded: true,
      hint: const Text('Selecione a loja'),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.indigo, size: 28),
      dropdownColor: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
      decoration: _fieldDecoration(),
      items: stores
          .map((s) => DropdownMenuItem(value: s.storeId, child: Text(s.displayName, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: (val) => setState(() => _selectedStoreId = val),
    );
  }

  /// Ao alterar o código manualmente (digitação, leitura ou limpar),
  /// descarta o produto selecionado que não corresponde mais ao campo.
  void _onProductTextChanged() {
    if (_selectedProduct != null && _selectedProduct!.productId != _productController.text.trim()) {
      setState(() {
        _selectedProduct = null;
        _unitPrice = null;
      });
    }
  }

  Future<void> _openProductSearch(BuildContext context) async {
    final selectedProductData = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SearchProductsPage(shouldNavigate: false)),
    );
    if (selectedProductData != null && mounted) {
      final product = ProductModel(
        productId: selectedProductData['productId'],
        barcode:   selectedProductData['barcode'],
        name:      selectedProductData['productName'] ?? selectedProductData['productId'],
      );
      _productController.text = product.productId;
      setState(() => _selectedProduct = product);
      _loadUnitPrice(product.productId);
    }
  }

  /// Valor unitário só informativo; o que vale é o gravado pela API.
  Future<void> _loadUnitPrice(String productId) async {
    setState(() {
      _unitPrice = null;
      _loadingPrice = true;
    });
    final price = await CallAction.run(
      action: () => context.read<BreakageService>().fetchUnitPrice(productId),
      onError: (_) {},
    );
    if (!mounted || _selectedProduct?.productId != productId) return;
    setState(() {
      _unitPrice = price;
      _loadingPrice = false;
    });
  }

  /// Resolve o produto informado no campo (código digitado ou lido no scanner)
  /// quando ele não veio da página de pesquisa.
  Future<ProductModel?> _resolveProduct() async {
    final text = _productController.text.trim();
    if (text.isEmpty) return null;
    if (_selectedProduct != null && _selectedProduct!.productId == text) return _selectedProduct;

    final results = await context.read<ProductService>().quickSearch(text);
    if (results.isEmpty) return null;
    return results.firstWhere(
      (p) => p.productId == text || p.barcode == text,
      orElse: () => results.first,
    );
  }

  /// App nativo Android/iOS usa a câmera do sistema (image_picker).
  bool get _isNativeMobile =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// A evidência deve ser sempre uma foto tirada na hora (sem opção de galeria).
  /// Na web (computador/tablet/celular) usa a tela de captura própria (pacote camera).
  /// Usada no registro e na edição.
  Future<Uint8List?> _capturePhoto() async {
    if (_isNativeMobile) {
      return CallAction.run<Uint8List?>(action: () async {
        final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
        return picked == null ? null : await picked.readAsBytes();
      });
    }

    return Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => const BreakageCameraPage()),
    );
  }

  Future<void> _takeRegisterPhoto() async {
    final bytes = await _capturePhoto();
    if (bytes == null || !mounted) return;
    setState(() => _capturedPhoto = bytes);
  }

  Future<void> _submitQuebra() async {
    final service = context.read<BreakageService>();
    final storeId = service.stores.length == 1 ? service.stores.first.storeId : _selectedStoreId;

    if (storeId == null) {
      MessageService.showWarning('Selecione a loja!');
      return;
    }
    if (_capturedPhoto == null || _productController.text.trim().isEmpty) {
      MessageService.showWarning('Por favor, anexe a foto e selecione o produto!');
      return;
    }

    final loadingService = context.read<LoadingService>();

    loadingService.show();
    await CallAction.run(
      action: () async {
        final product = await _resolveProduct();
        if (product == null) {
          MessageService.showWarning('Produto "${_productController.text.trim()}" não encontrado.');
          return;
        }

        service.cacheProductName(product.productId, product.name);
        final response = await service.registerBreakage(
          storeId: storeId,
          productId: product.productId,
          quantity: _quantidade,
          reason: _selectedMotivo,
          photoBytes: _capturedPhoto!,
        );

        if (!response.success) {
          MessageService.showError(response.message ?? 'Erro ao registrar a quebra.');
          return;
        }

        if (!mounted) return;
        setState(() {
          _capturedPhoto = null;
          _selectedProduct = null;
          _unitPrice = null;
          _productController.clear();
          _quantidade = 1;
          _selectedStoreId = storeId; // mantém a loja
        });
        MessageService.showSuccess('Quebra enviada para aprovação do gerente');
      },
      onFinally: loadingService.hide,
    );
  }

  // ==========================================
  // ABA 2: APROVAÇÕES (GERENTE E CONTROLES INTERNOS)
  // ==========================================
  Widget _buildAprovacoesTab(BreakageService service) {
    final pendentes = service.breakages(BreakageTab.approvals);
    final totalValor = pendentes.fold(0.0, (sum, r) => sum + r.totalForSum);
    final showSections = service.isStoreManager && service.isInternalControl;

    List<Widget> buildQueue(List<BreakageModel> queue, bool isInternalControl, String emptyMessage) => [
          if (queue.isEmpty) _buildEmptyState(service, emptyMessage),
          ...queue.map((r) => _buildApprovalCard(r, service, isInternalControl: isInternalControl)),
        ];

    return RefreshIndicator(
      onRefresh: () => service.fetchTab(BreakageTab.approvals),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          BreakageFilterBar(
            filter: service.filter(BreakageTab.approvals),
            stores: service.stores,
            onChanged: (f) => service.setFilter(BreakageTab.approvals, f),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildResumoCard(Icons.access_time, Colors.amber, 'NA SUA FILA', '${pendentes.length}')),
              const SizedBox(width: 12),
              Expanded(child: _buildResumoCard(Icons.attach_money, Colors.blueGrey, 'VALOR TOTAL', _formatMoney(totalValor))),
            ],
          ),
          const SizedBox(height: 16),

          if (service.isStoreManager) ...[
            Text(showSections ? 'Etapa 1 — Gerente da Loja' : 'Fila de Aprovação', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            ...buildQueue(service.managerQueue, false, 'Nenhum registro na fila do gerente'),
          ],
          if (showSections) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
          ],
          if (service.isInternalControl) ...[
            Text(showSections ? 'Etapa 2 — Controles Internos' : 'Fila de Aprovação', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            ...buildQueue(service.internalControlQueue, true, 'Nenhum registro na fila de Controles Internos'),
          ],
        ],
      ),
    );
  }

  Widget _buildApprovalCard(BreakageModel r, BreakageService service, {required bool isInternalControl}) {
    final isDevolvido = r.status == BreakageStatus.devolvido;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDevolvido ? Colors.red.shade200 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${r.breakageId} • ${_formatDate(r.createdAt)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _oxfordColor)),
              _buildStatusChip(r.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(service.productName(r), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text('Loja: ${service.storeName(r)}', style: const TextStyle(fontSize: 11)),
          Text('Código: ${r.productId} • Colaborador: ${r.createdBy}', style: const TextStyle(fontSize: 10, color: Colors.grey)),

          if (isDevolvido)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reprovado por ${r.icReviewedBy ?? 'Controles Internos'} em ${_formatDate(r.icReviewedAt)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                  if ((r.rejectionReason ?? '').isNotEmpty)
                    Text('Motivo reprovação: ${r.rejectionReason}', style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                ],
              ),
            ),

          if (isInternalControl && r.managerReviewedBy != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Aprovação 1: ${r.managerReviewedBy} em ${_formatDate(r.managerReviewedAt)}',
                  style: const TextStyle(fontSize: 11, color: Colors.green)),
            ),

          const SizedBox(height: 8),
          Row(
            children: [
              InkWell(onTap: () => _showPhotoViewer(r.photoUrl), child: _buildPhoto(r.photoUrl, 60)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quantidade: ${r.quantity} un', style: const TextStyle(fontSize: 13)),
                    Text('Unitário: ${_formatMoney(r.unitPrice)} • Total: ${_formatMoney(r.totalValue)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('Motivo: ${r.reason}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          _buildHistoryLink(r, service),
          const SizedBox(height: 8),
          Row(
            children: isInternalControl
                ? [
                    Expanded(child: _buildOutlinedAction('Reprovar', Colors.red, () => _reprovarRegistro(r))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilledAction('Aprovar', Colors.green, () => _aprovarRegistro(r, isInternalControl: true))),
                  ]
                : [
                    Expanded(child: _buildOutlinedAction('Excluir', Colors.red, () => _excluirRegistro(r))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildOutlinedAction('Editar', _oxfordColor, () => _editarRegistro(r))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: isDevolvido
                          ? _buildFilledAction('Reenviar', Colors.orange, () => _reenviarRegistro(r))
                          : _buildFilledAction('Aprovar', Colors.green, () => _aprovarRegistro(r, isInternalControl: false)),
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  /// Mesmo formato do Aprovar (raio 12 e padding vertical 16, herdados do tema).
  Widget _buildOutlinedAction(String label, Color color, VoidCallback onPressed) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildFilledAction(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, elevation: 0),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  void _showPhotoViewer(String url) {
    if (url.isEmpty) return;
    final bytes = context.read<BreakageService>().photo(url);
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pop(dialogContext),
          child: InteractiveViewer(
            child: bytes != null
                ? Image.memory(bytes, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(200))
                : Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(200),
                  ),
          ),
        ),
      ),
    );
  }

  /// Executa uma ação no BreakageService exibindo o overlay de carregamento
  /// e a mensagem de sucesso/erro padrão do app.
  Future<bool> _runAction(Future<dynamic> Function() action, String successMessage) async {
    final loadingService = context.read<LoadingService>();
    loadingService.show();
    final result = await CallAction.run(
      action: () async {
        final response = await action();
        if (response.success != true) {
          // 409: outro usuário já agiu; o service já recarregou a fila.
          if (BreakageService.isConflict(response)) {
            MessageService.showWarning(response.message ?? 'O registro já foi alterado por outro usuário.');
          } else {
            MessageService.showError(response.message ?? 'Erro ao processar a solicitação.');
          }
          return false;
        }
        MessageService.showSuccess(successMessage);
        return true;
      },
      onFinally: loadingService.hide,
    );
    return result ?? false;
  }

  /// Mínimo de caracteres de motivos obrigatórios (Reprovar e Excluir).
  static const int _minReason = 10;

  /// Diálogo único para motivo/observação (Reprovar, Excluir e Reenviar).
  /// Com [minLength] > 0 o botão só habilita a partir desse tamanho.
  /// Retorna null se cancelado.
  Future<String?> _askReason({
    required String title,
    required String hint,
    required String actionLabel,
    required Color actionColor,
    required IconData icon,
    String? helperText,
    int minLength = _minReason,
  }) async {
    // O controller fica dentro do _ReasonDialog e é descartado no dispose() dele,
    // depois da animação de fechamento (descartar aqui, logo após o await,
    // quebrava com "_dependents.isEmpty" porque o TextField ainda estava montado).
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _ReasonDialog(
        title: title,
        hint: hint,
        actionLabel: actionLabel,
        actionColor: actionColor,
        icon: icon,
        helperText: helperText,
        minLength: minLength,
      ),
    );

    if (text == null || !mounted) return null;
    return text;
  }

  Future<void> _aprovarRegistro(BreakageModel r, {required bool isInternalControl}) async {
    final confirmado = await showConfirmDialog(
      context: context,
      message: isInternalControl
          ? 'Aprovar o registro #${r.breakageId}? Ele ficará aguardando baixa.'
          : 'Aprovar o registro #${r.breakageId} e enviar a Controles Internos?',
    );
    if (!confirmado || !mounted) return;

    await _runAction(
      () => context.read<BreakageService>().approve(r),
      isInternalControl
          ? 'Registro #${r.breakageId} aprovado.'
          : 'Registro #${r.breakageId} aprovado e enviado a Controles Internos.',
    );
  }

  /// CONTROLES_INT reprova: o registro volta ao gerente (DEVOLVIDO).
  Future<void> _reprovarRegistro(BreakageModel r) async {
    final motivo = await _askReason(
      title: 'Reprovar registro #${r.breakageId}',
      helperText: 'O registro voltará para o gerente da loja corrigir ou excluir.',
      hint: 'Informe o que precisa ser corrigido',
      actionLabel: 'Reprovar',
      actionColor: Colors.redAccent,
      icon: Icons.undo_rounded,
    );
    if (motivo == null || !mounted) return;

    await _runAction(
      () => context.read<BreakageService>().returnToManager(r, motivo),
      'Registro #${r.breakageId} reprovado e devolvido ao gerente.',
    );
  }

  /// GERENTE_LOJA exclui (exclusão lógica): o registro e a linha do tempo continuam no banco.
  Future<void> _excluirRegistro(BreakageModel r) async {
    final motivo = await _askReason(
      title: 'Excluir registro #${r.breakageId}',
      helperText: 'O registro sai da fila, mas continua consultável no Histórico (filtro "Excluídos").',
      hint: 'Informe o motivo da exclusão',
      actionLabel: 'Excluir',
      actionColor: Colors.redAccent,
      icon: Icons.warning_amber_rounded,
    );
    if (motivo == null || !mounted) return;

    await _runAction(
      () => context.read<BreakageService>().deleteBreakage(r, motivo),
      'Registro #${r.breakageId} excluído.',
    );
  }

  Future<void> _reenviarRegistro(BreakageModel r) async {
    final observacao = await _askReason(
      title: 'Reenviar a Controles Internos',
      hint: 'Observação (opcional)',
      actionLabel: 'Reenviar',
      actionColor: Colors.orange,
      icon: Icons.send_rounded,
      minLength: 0,
    );
    if (observacao == null || !mounted) return;

    await _runAction(
      () => context.read<BreakageService>().resubmit(r, observacao.isEmpty ? null : observacao),
      'Registro #${r.breakageId} reenviado a Controles Internos.',
    );
  }

  Future<void> _editarRegistro(BreakageModel r) async {
    final service = context.read<BreakageService>();
    final result = await showBreakageEditDialog(
      context: context,
      breakage: r,
      productName: service.productName(r),
      photoBuilder: _buildPhoto,
      onCapturePhoto: _capturePhoto,
    );
    if (result == null || !mounted) return;

    await _runAction(
      () => service.editBreakage(
        r,
        quantity: result.quantity,
        photoBytes: result.photo,
        justification: result.justification,
      ),
      'Registro #${r.breakageId} atualizado.',
    );
  }

  // ==========================================
  // ABA 3: BAIXAR (BAIXA NO ESTOQUE)
  // ==========================================
  Widget _buildBaixarTab(BreakageService service) {
    final pendentesBaixa = service.breakages(BreakageTab.writeOff);
    final selecionados = pendentesBaixa.where((r) => _selectedBaixaIds.contains(r.breakageId)).toList();
    final todosSelecionados = pendentesBaixa.isNotEmpty && selecionados.length == pendentesBaixa.length;
    final totalPecas = pendentesBaixa.fold(0, (sum, r) => sum + r.quantity);
    final totalValor = pendentesBaixa.fold(0.0, (sum, r) => sum + r.totalForSum);
    final valorSelecionado = selecionados.fold(0.0, (sum, r) => sum + r.totalForSum);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreakageFilterBar(
            filter: service.filter(BreakageTab.writeOff),
            stores: service.stores,
            onChanged: (f) => service.setFilter(BreakageTab.writeOff, f),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildResumoCard(Icons.inventory_2_outlined, Colors.blue, 'AGUARDANDO BAIXA', '${pendentesBaixa.length}')),
              const SizedBox(width: 12),
              Expanded(child: _buildResumoCard(Icons.layers_outlined, Colors.blueGrey, 'PEÇAS A BAIXAR', '$totalPecas')),
            ],
          ),
          const SizedBox(height: 8),
          _buildResumoCard(Icons.attach_money, Colors.green, 'VALOR A BAIXAR', _formatMoney(totalValor)),
          const SizedBox(height: 12),
          const Text('Registros a Baixar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            children: [
              Checkbox(
                value: todosSelecionados,
                activeColor: _oxfordColor,
                visualDensity: VisualDensity.compact,
                onChanged: pendentesBaixa.isEmpty
                    ? null
                    : (val) => setState(() {
                          if (val == true) {
                            _selectedBaixaIds.addAll(pendentesBaixa.map((r) => r.breakageId));
                          } else {
                            _selectedBaixaIds.removeAll(pendentesBaixa.map((r) => r.breakageId));
                          }
                        }),
              ),
              Text(
                selecionados.isEmpty ? 'Selecionar todos' : '${selecionados.length} selecionado(s)',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => service.fetchTab(BreakageTab.writeOff),
              child: pendentesBaixa.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [_buildEmptyState(service, 'Nenhum registro aguardando baixa')],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: pendentesBaixa.length,
                      itemBuilder: (context, index) {
                        final r = pendentesBaixa[index];
                        final bool isSelected = _selectedBaixaIds.contains(r.breakageId);
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _toggleSelecaoBaixa(r.breakageId),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                            decoration: BoxDecoration(
                              color: isSelected ? _oxfordColor.withOpacity(0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSelected ? _oxfordColor.withOpacity(0.4) : Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  activeColor: _oxfordColor,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: (_) => _toggleSelecaoBaixa(r.breakageId),
                                ),
                                Container(width: 4, height: 48, decoration: BoxDecoration(color: _statusColor(r.status), borderRadius: BorderRadius.circular(2))),
                                const SizedBox(width: 8),
                                InkWell(onTap: () => _showPhotoViewer(r.photoUrl), child: _buildPhoto(r.photoUrl, 48)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(service.productName(r), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      Text('Loja: ${service.storeName(r)}', style: const TextStyle(fontSize: 11)),
                                      Text('Código: ${r.productId} • ${r.quantity} un • ${_formatMoney(r.totalValue)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('#${r.breakageId} • ${_formatDate(r.createdAt)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      _buildHistoryLink(r, service),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
          if (selecionados.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('Valor selecionado: ${_formatMoney(valorSelecionado)}',
                  textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _oxfordColor)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _oxfordColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              minimumSize: const Size(double.infinity, 48),
              elevation: 0,
            ),
            onPressed: selecionados.isEmpty ? null : () => _confirmarBaixa(selecionados),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_alt, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  selecionados.isEmpty ? 'DAR BAIXA' : 'DAR BAIXA (${selecionados.length})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoCard(IconData icon, MaterialColor color, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSelecaoBaixa(int id) {
    setState(() {
      if (!_selectedBaixaIds.remove(id)) _selectedBaixaIds.add(id);
    });
  }

  Future<void> _confirmarBaixa(List<BreakageModel> registros) async {
    final totalValor = registros.fold(0.0, (sum, r) => sum + r.totalForSum);
    final confirmado = await showConfirmDialog(
      context: context,
      message: 'Dar baixa de ${registros.length} ${registros.length == 1 ? 'registro' : 'registros'} '
          '(${_formatMoney(totalValor)})?',
    );
    if (!confirmado || !mounted) return;

    await _runAction(
      () => context.read<BreakageService>().writeOff(registros),
      'Baixa realizada com sucesso! (${registros.length} ${registros.length == 1 ? 'registro' : 'registros'})',
    );
    if (!mounted) return;
    setState(() => _selectedBaixaIds.removeAll(registros.map((r) => r.breakageId)));
  }

  // ==========================================
  // ABA 4: HISTÓRICO E AUDITORIA
  // ==========================================
  Widget _buildHistoricoTab(BreakageService service) {
    final list = service.breakages(BreakageTab.history);

    final selecionados = list.where((r) => _selectedHistoricoIds.contains(r.breakageId)).toList();
    final todosSelecionados = list.isNotEmpty && selecionados.length == list.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          BreakageFilterBar(
            filter: service.filter(BreakageTab.history),
            stores: service.stores,
            onChanged: (f) => service.setFilter(BreakageTab.history, f),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(service, null, 'Todos'),
                for (final status in BreakageStatus.historyFilters)
                  _buildFilterChip(service, status, BreakageStatus.shortLabel(status)),
                // Legado (v1): só aparece se houver registros rejeitados.
                if (service.historyStatus == BreakageStatus.rejeitado || list.any((r) => r.status == BreakageStatus.rejeitado))
                  _buildFilterChip(service, BreakageStatus.rejeitado, BreakageStatus.shortLabel(BreakageStatus.rejeitado)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Barra de seleção e exportação
          Row(
            children: [
              Checkbox(
                value: todosSelecionados,
                activeColor: _oxfordColor,
                visualDensity: VisualDensity.compact,
                onChanged: list.isEmpty
                    ? null
                    : (val) => setState(() {
                          if (val == true) {
                            _selectedHistoricoIds.addAll(list.map((r) => r.breakageId));
                          } else {
                            _selectedHistoricoIds.removeAll(list.map((r) => r.breakageId));
                          }
                        }),
              ),
              Expanded(
                child: Text(
                  selecionados.isEmpty ? 'Selecionar todos' : '${selecionados.length} selecionado(s)',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              PopupMenuButton<String>(
                enabled: selecionados.isNotEmpty,
                tooltip: 'Exportar selecionados',
                onSelected: (formato) => formato == 'XLSX' ? _exportarExcel(selecionados) : _exportarTxt(selecionados),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'XLSX', child: Row(children: [Icon(Icons.grid_on, size: 18), SizedBox(width: 8), Text('Excel (.xlsx)', style: TextStyle(fontSize: 12))])),
                  PopupMenuItem(value: 'TXT', child: Row(children: [Icon(Icons.description_outlined, size: 18), SizedBox(width: 8), Text('Texto (.txt)', style: TextStyle(fontSize: 12))])),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selecionados.isNotEmpty ? _oxfordColor : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.file_download_outlined, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text('EXPORTAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => service.fetchTab(BreakageTab.history),
              child: list.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [_buildEmptyState(service, 'Nenhum registro encontrado')],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final r = list[index];
                        final bool isSelected = _selectedHistoricoIds.contains(r.breakageId);
                        final Color statusColor = _statusColor(r.status);
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _toggleSelecaoHistorico(r.breakageId),
                          child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
                          decoration: BoxDecoration(
                            color: isSelected ? _oxfordColor.withOpacity(0.05) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? _oxfordColor.withOpacity(0.4) : Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: _oxfordColor,
                                visualDensity: VisualDensity.compact,
                                onChanged: (_) => _toggleSelecaoHistorico(r.breakageId),
                              ),
                              Container(width: 4, height: 40, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 8),
                              InkWell(onTap: () => _showPhotoViewer(r.photoUrl), child: _buildPhoto(r.photoUrl, 40)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(service.productName(r), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                        _buildStatusChip(r.status),
                                      ],
                                    ),
                                    Text('Loja: ${service.storeName(r)}', style: const TextStyle(fontSize: 11)),
                                    Text('${r.quantity} un • ${_formatMoney(r.totalValue)} • ${_formatDate(r.createdAt)} • ${r.createdBy}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    if ((r.rejectionReason ?? '').isNotEmpty) ...[
                                      if (r.status == BreakageStatus.devolvido)
                                        Text('Motivo reprovação: ${r.rejectionReason}', style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                                      if (r.status == BreakageStatus.excluido)
                                        Text('Motivo exclusão: ${r.rejectionReason}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                      if (r.status == BreakageStatus.rejeitado)
                                        Text('Motivo rejeição: ${r.rejectionReason}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                                    ],
                                    _buildHistoryLink(r, service),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSelecaoHistorico(int id) {
    setState(() {
      if (!_selectedHistoricoIds.remove(id)) _selectedHistoricoIds.add(id);
    });
  }

  static const List<String> _colunasExport = [
    'ID', 'Cód. Loja', 'Loja', 'Código', 'Produto', 'Quantidade', 'Valor Unitário', 'Valor Total',
    'Motivo', 'Colaborador', 'Data', 'Status',
    'Aprovado Gerente por', 'Data Aprov. Gerente', 'Aprovado CI por', 'Data Aprov. CI',
    'Qtd. Reprovações', 'Último Motivo Reprovação/Exclusão', 'Qtd. Edições', 'Baixado por', 'Data Baixa', 'Foto',
  ];

  /// Linha da exportação. [formatNumber] define como os valores saem:
  /// no Excel ficam numéricos (somáveis); no TXT, com vírgula decimal.
  List<Object> _linhaExport(BreakageModel r, Object Function(double? value) formatNumber) {
    final service = context.read<BreakageService>();
    return [
      r.breakageId,
      r.storeId,
      service.storeName(r),
      r.productId,
      service.productName(r),
      r.quantity,
      formatNumber(r.unitPrice),
      formatNumber(r.totalValue),
      r.reason,
      r.createdBy,
      _formatDate(r.createdAt),
      BreakageStatus.label(r.status),
      r.managerReviewedBy ?? '',
      r.managerReviewedAt == null ? '' : _formatDate(r.managerReviewedAt),
      r.icReviewedBy ?? '',
      r.icReviewedAt == null ? '' : _formatDate(r.icReviewedAt),
      r.returnCount,
      r.rejectionReason ?? '',
      r.editCount,
      r.writtenOffBy ?? '',
      r.writtenOffAt == null ? '' : _formatDate(r.writtenOffAt),
      r.photoUrl,
    ];
  }

  String get _nomeArquivoExport {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'quebras_${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
  }

  Future<void> _exportarExcel(List<BreakageModel> registros) async {
    try {
      final workbook = excel.Excel.createExcel();
      const sheetName = 'Quebras';
      final sheet = workbook[sheetName];
      workbook.setDefaultSheet(sheetName);

      sheet.appendRow(_colunasExport);
      for (final r in registros) {
        sheet.appendRow(_linhaExport(r, (v) => v ?? ''));
      }

      // Linha de TOTAL (Quantidade e Valor Total).
      final total = List<Object>.filled(_colunasExport.length, '');
      total[0] = 'TOTAL';
      total[5] = registros.fold<int>(0, (sum, r) => sum + r.quantity);
      total[7] = registros.fold<double>(0, (sum, r) => sum + r.totalForSum);
      sheet.appendRow(total);

      final bytes = workbook.encode();
      if (bytes == null) throw Exception('Falha ao gerar o arquivo.');

      await DownloadFile.saveBytes(bytes, '$_nomeArquivoExport.xlsx');
      _mostrarResultadoExport(registros.length);
    } catch (e) {
      if (!mounted) return;
      MessageService.showError('Falha ao exportar para Excel: $e');
    }
  }

  Future<void> _exportarTxt(List<BreakageModel> registros) async {
    try {
      final decimal = NumberFormat('#,##0.00', 'pt_BR');
      final buffer = StringBuffer()..writeln(_colunasExport.join('\t'));
      for (final r in registros) {
        buffer.writeln(_linhaExport(r, (v) => v == null ? '' : decimal.format(v)).join('\t'));
      }

      await DownloadFile.saveTxt(buffer.toString(), '$_nomeArquivoExport.txt');
      _mostrarResultadoExport(registros.length);
    } catch (e) {
      if (!mounted) return;
      MessageService.showError('Falha ao exportar TXT: $e');
    }
  }

  void _mostrarResultadoExport(int total) {
    if (!mounted) return;
    MessageService.showSuccess('Exportação concluída! ($total ${total == 1 ? 'registro' : 'registros'})');
  }

  Widget _buildFilterChip(BreakageService service, String? status, String label) {
    final bool selected = service.historyStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: () => service.setHistoryStatus(status),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _oxfordColor : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: selected ? Colors.white : Colors.grey.shade700)),
        ),
      ),
    );
  }
}

/// Diálogo de motivo/observação usado por `_askReason` (Reprovar, Excluir e Reenviar).
/// Segue o layout do `ConfirmDialog` do app (ícone + título, Cancelar contornado e
/// botão de ação preenchido). É um StatefulWidget para que o TextEditingController
/// seja descartado só quando o diálogo sai da árvore (após a animação de fechamento).
class _ReasonDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String actionLabel;
  final Color actionColor;
  final IconData icon;
  final String? helperText;
  final int minLength;

  const _ReasonDialog({
    required this.title,
    required this.hint,
    required this.actionLabel,
    required this.actionColor,
    required this.icon,
    required this.helperText,
    required this.minLength,
  });

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final length = _controller.text.trim().length;
    final ok = length >= widget.minLength;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        children: [
          Icon(widget.icon, color: widget.actionColor, size: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.helperText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(widget.helperText!, style: const TextStyle(fontSize: 16)),
                ),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 3,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(hintText: widget.hint, border: const OutlineInputBorder()),
              ),
              if (widget.minLength > 0 && length > 0 && !ok)
                Text(
                  'Mínimo de ${widget.minLength} caracteres.',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.actionColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onPressed: ok
              ? () {
                  FocusScope.of(context).unfocus();
                  Navigator.pop(context, _controller.text.trim());
                }
              : null,
          child: Text(widget.actionLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
