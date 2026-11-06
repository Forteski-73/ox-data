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
import 'package:oxdata/app/core/widgets/delete_confirm_dialog.dart';
import 'package:oxdata/app/core/utils/download_file.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:oxdata/app/core/models/breakage_model.dart';
import 'package:oxdata/app/core/models/product_model.dart';
import 'package:oxdata/app/core/services/breakage_service.dart';
import 'package:oxdata/app/core/services/product_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/services/storage_service.dart';

class BreakagePage extends StatefulWidget {
  const BreakagePage({super.key});

  @override
  State<BreakagePage> createState() => _BreakagePageState();
}

class _BreakagePageState extends State<BreakagePage> {
  int _currentIndex = 0; // 0: Registrar, 1: Aprovações, 2: Baixar, 3: Histórico

  final StorageService _storage = StorageService();
  String _username = '';
  bool _canManage = false; // Acesso INVENTADM: libera Aprovações, Baixar e Histórico

  // Formulário State
  final TextEditingController _productController = TextEditingController();
  ProductModel? _selectedProduct;
  int _quantidade = 1;
  String _selectedMotivo = 'Acidente de Manuseio / Queda';
  Uint8List? _capturedPhoto;
  String _historicoFilter = 'TODOS';
  final Set<int> _selectedHistoricoIds = {};
  final Set<int> _selectedBaixaIds = {};

  final Color _oxfordColor = const Color(0xFF002B49);
  final Color _goldColor = Colors.white;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _productController.addListener(_onProductTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BreakageService>().fetchBreakages();
    });
  }

  @override
  void dispose() {
    _productController.removeListener(_onProductTextChanged);
    _productController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final credentials = await _storage.readCredentials();
    final menus = await _storage.readMenus();
    if (!mounted) return;
    setState(() {
      _username = credentials['username'] ?? '';
      _canManage = menus.any((m) => m.routeName == 'INVENTADM');
      if (!_canManage) _currentIndex = 0;
    });
  }

  String _formatDate(DateTime? date) => date == null ? '-' : _dateFormat.format(date);

  @override
  Widget build(BuildContext context) {
    final breakageService = context.watch<BreakageService>();

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
                child: IndexedStack(
                  index: _canManage ? _currentIndex : 0,
                  children: [
                    _buildRegistrarTab(),
                    if (_canManage) ...[
                      _buildAprovacoesTab(breakageService),
                      _buildBaixarTab(breakageService),
                      _buildHistoricoTab(breakageService),
                    ],
                  ],
                ),
              ),

              // Navegação Inferior (Bottom Nav Bar)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.camera_alt_rounded, 'Registrar'),
                    if (_canManage) ...[
                      _buildNavItem(1, Icons.playlist_add_check_rounded, 'Aprovações',
                        badgeCount: breakageService.byStatus(BreakageStatus.pendente).length),
                      _buildNavItem(2, Icons.inventory_2_outlined, 'Baixar',
                        badgeCount: breakageService.notWrittenOff.length),
                      _buildNavItem(3, Icons.fact_check_outlined, 'Histórico'),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
    final hasError = service.errorMessage != null && service.breakages.isEmpty;
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

  // ==========================================
  // ABA 1: REGISTRAR QUEBRA
  // ==========================================
  Widget _buildRegistrarTab() {
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

          // 1. Evidência Fotográfica
          const Text('EVIDÊNCIA FOTOGRÁFICA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showPhotoOptions,
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

          // 2. Seleção de Produto
          const Text('SELECIONAR PRODUTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // 3. Quantidade
          const Text('QUANTIDADE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
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
          const SizedBox(height: 16),

          // 4. Motivo
          const Text('MOTIVO DA OCORRÊNCIA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedMotivo,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.indigo, size: 28),
            dropdownColor: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
            decoration: InputDecoration(
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
            ),
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

  /// Ao alterar o código manualmente (digitação, leitura ou limpar),
  /// descarta o produto selecionado que não corresponde mais ao campo.
  void _onProductTextChanged() {
    if (_selectedProduct != null && _selectedProduct!.productId != _productController.text.trim()) {
      setState(() => _selectedProduct = null);
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
    }
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
  Future<void> _showPhotoOptions() async {
    if (_isNativeMobile) {
      await _pickPhoto(ImageSource.camera);
      return;
    }

    final bytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => const BreakageCameraPage()),
    );
    if (bytes == null || !mounted) return;
    setState(() => _capturedPhoto = bytes);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    await CallAction.run(action: () async {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _capturedPhoto = bytes);
    });
  }

  Future<void> _submitQuebra() async {
    if (_capturedPhoto == null || _productController.text.trim().isEmpty) {
      MessageService.showWarning('Por favor, anexe a foto e selecione o produto!');
      return;
    }

    final breakageService = context.read<BreakageService>();
    final loadingService = context.read<LoadingService>();

    loadingService.show();
    await CallAction.run(
      action: () async {
        final product = await _resolveProduct();
        if (product == null) {
          MessageService.showWarning('Produto "${_productController.text.trim()}" não encontrado.');
          return;
        }

        breakageService.cacheProductName(product.productId, product.name);
        final response = await breakageService.registerBreakage(
          productId: product.productId,
          quantity: _quantidade,
          reason: _selectedMotivo,
          photoBytes: _capturedPhoto!,
          createdBy: _username,
        );

        if (!response.success) {
          MessageService.showError(response.message ?? 'Erro ao registrar a quebra.');
          return;
        }

        if (!mounted) return;
        setState(() {
          _capturedPhoto = null;
          _selectedProduct = null;
          _productController.clear();
          _quantidade = 1;
          _currentIndex = 1; // Vai para aprovações
        });
        MessageService.showSuccess('Quebra enviada para aprovação com sucesso!');
      },
      onFinally: loadingService.hide,
    );
  }

  // ==========================================
  // ABA 2: APROVAÇÕES (GESTOR)
  // ==========================================
  Widget _buildAprovacoesTab(BreakageService service) {
    final pendentes = service.byStatus(BreakageStatus.pendente);

    return RefreshIndicator(
      onRefresh: service.fetchBreakages,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.access_time, color: Colors.amber, size: 20)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PENDENTES', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text('${pendentes.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Fila de Aprovação', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),

          if (pendentes.isEmpty)
            _buildEmptyState(service, 'Nenhum registro pendente'),

          ...pendentes.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#${r.breakageId} • ${_formatDate(r.createdAt)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _oxfordColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(10)),
                      child: const Text(BreakageStatus.pendente, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(service.productName(r.productId), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text('Código: ${r.productId} • Colaborador: ${r.createdBy}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
                          Text('Motivo: ${r.reason}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _rejeitarRegistro(r),
                        child: const Text('Rejeitar', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0),
                        onPressed: () => _aprovarRegistro(r),
                        child: const Text('Aprovar', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
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
          MessageService.showError(response.message ?? 'Erro ao processar a solicitação.');
          return false;
        }
        MessageService.showSuccess(successMessage);
        return true;
      },
      onFinally: loadingService.hide,
    );
    return result ?? false;
  }

  void _aprovarRegistro(BreakageModel r) {
    _runAction(
      () => context.read<BreakageService>().approve(r, _username),
      'Registro #${r.breakageId} aprovado com sucesso!',
    );
  }

  Future<void> _rejeitarRegistro(BreakageModel r) async {
    final motivoController = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rejeitar registro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: motivoController,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Informe o motivo da rejeição',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, motivoController.text.trim()),
            child: const Text('Rejeitar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    motivoController.dispose();

    if (motivo == null || !mounted) return;
    if (motivo.isEmpty) {
      MessageService.showWarning('Informe o motivo da rejeição.');
      return;
    }

    await _runAction(
      () => context.read<BreakageService>().reject(r, _username, motivo),
      'Registro #${r.breakageId} rejeitado.',
    );
  }

  // ==========================================
  // ABA 3: BAIXAR (BAIXA NO ESTOQUE)
  // ==========================================
  Widget _buildBaixarTab(BreakageService service) {
    final pendentesBaixa = service.notWrittenOff;
    final selecionados = pendentesBaixa.where((r) => _selectedBaixaIds.contains(r.breakageId)).toList();
    final todosSelecionados = pendentesBaixa.isNotEmpty && selecionados.length == pendentesBaixa.length;
    final totalPecas = pendentesBaixa.fold(0, (sum, r) => sum + r.quantity);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildResumoCard(Icons.inventory_2_outlined, Colors.blue, 'AGUARDANDO BAIXA', '${pendentesBaixa.length}')),
              const SizedBox(width: 12),
              Expanded(child: _buildResumoCard(Icons.layers_outlined, Colors.blueGrey, 'PEÇAS A BAIXAR', '$totalPecas')),
            ],
          ),
          const SizedBox(height: 16),
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
              onRefresh: service.fetchBreakages,
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
                                      Text(service.productName(r.productId), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      Text('Código: ${r.productId} • ${r.quantity} un', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('#${r.breakageId} • ${_formatDate(r.createdAt)} • ${r.status}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        BreakageStatus.aprovado => Colors.green,
        BreakageStatus.baixado => Colors.blue,
        BreakageStatus.rejeitado => Colors.red,
        _ => Colors.amber,
      };

  void _toggleSelecaoBaixa(int id) {
    setState(() {
      if (!_selectedBaixaIds.remove(id)) _selectedBaixaIds.add(id);
    });
  }

  Future<void> _confirmarBaixa(List<BreakageModel> registros) async {
    final totalPecas = registros.fold(0, (sum, r) => sum + r.quantity);
    final confirmado = await showConfirmDialog(
      context: context,
      message: 'Dar baixa de ${registros.length} ${registros.length == 1 ? 'registro ' : 'registros'} ?',
    );
    if (!confirmado || !mounted) return;

    await _runAction(
      () => context.read<BreakageService>().writeOff(registros, _username),
      'Baixa realizada com sucesso! (${registros.length} ${registros.length == 1 ? 'registro' : 'registros'})',
    );
    if (!mounted) return;
    setState(() => _selectedBaixaIds.removeAll(registros.map((r) => r.breakageId)));
  }

  // ==========================================
  // ABA 4: HISTÓRICO E AUDITORIA
  // ==========================================
  Widget _buildHistoricoTab(BreakageService service) {
    final list = _historicoFilter == 'TODOS' ? service.breakages : service.byStatus(_historicoFilter);

    final selecionados = list.where((r) => _selectedHistoricoIds.contains(r.breakageId)).toList();
    final todosSelecionados = list.isNotEmpty && selecionados.length == list.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildFilterChip('TODOS', 'Todos'),
              const SizedBox(width: 4),
              _buildFilterChip(BreakageStatus.pendente, 'Pendentes'),
              const SizedBox(width: 4),
              _buildFilterChip(BreakageStatus.aprovado, 'Aprovados'),
              const SizedBox(width: 4),
              _buildFilterChip(BreakageStatus.baixado, 'Baixados'),
              const SizedBox(width: 4),
              _buildFilterChip(BreakageStatus.rejeitado, 'Rejeitados'),
            ],
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
              onRefresh: service.fetchBreakages,
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
                        final bool canDelete = r.status == BreakageStatus.pendente || r.status == BreakageStatus.rejeitado;
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
                                    Text(service.productName(r.productId), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    Text('${r.quantity} un • ${_formatDate(r.createdAt)} • ${r.createdBy}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    if (r.status == BreakageStatus.rejeitado && (r.rejectionReason ?? '').isNotEmpty)
                                      Text('Motivo rejeição: ${r.rejectionReason}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                                  ],
                                ),
                              ),
                              if (canDelete)
                                IconButton(
                                  tooltip: 'Excluir registro',
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade500),
                                  onPressed: () => _excluirRegistro(r),
                                )
                              else
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

  Future<void> _excluirRegistro(BreakageModel r) async {
    await showConfirmDelete(
      context: context,
      message: 'Deseja excluir o registro de quebra #${r.breakageId}?',
      onConfirm: () async {
        final ok = await _runAction(
          () => context.read<BreakageService>().deleteBreakage(r),
          'Registro #${r.breakageId} excluído.',
        );
        if (ok && mounted) setState(() => _selectedHistoricoIds.remove(r.breakageId));
      },
    );
  }

  static const List<String> _colunasExport = ['ID', 'Código', 'Produto', 'Quantidade', 'Motivo', 'Colaborador', 'Data', 'Status', 'Revisado por', 'Motivo Rejeição', 'Baixado por', 'Foto'];

  List<Object> _linhaExport(BreakageModel r) {
    final service = context.read<BreakageService>();
    return [
      r.breakageId,
      r.productId,
      service.productName(r.productId),
      r.quantity,
      r.reason,
      r.createdBy,
      _formatDate(r.createdAt),
      r.status,
      r.reviewedBy ?? '',
      r.rejectionReason ?? '',
      r.writtenOffBy ?? '',
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
        sheet.appendRow(_linhaExport(r));
      }

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
      final buffer = StringBuffer()..writeln(_colunasExport.join('\t'));
      for (final r in registros) {
        buffer.writeln(_linhaExport(r).join('\t'));
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

  Widget _buildFilterChip(String key, String label) {
    bool selected = _historicoFilter == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _historicoFilter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
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
