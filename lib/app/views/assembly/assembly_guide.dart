
// -----------------------------------------------------------
// app/views/products/assembly_guide.dart (Guia de Montagem - Pesquisa Rápida)
// -----------------------------------------------------------
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:oxdata/app/core/services/product_service.dart';
import 'package:oxdata/app/core/services/device_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/services/image_service.dart';
import 'package:oxdata/app/core/models/product_model.dart';
import 'package:oxdata/app/core/models/tv_device_model.dart';
import 'package:oxdata/app/core/models/image_url_model.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';

// =============================================================================
// DESIGN TOKENS
// =============================================================================

class _Palette {
  const _Palette._();

  static const Color primary = Color(0xFF3F51B5);
  static const Color primaryDark = Color(0xFF303F9F);
  static const Color primarySoft = Color(0xFFE8EAF6);
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color success = Color(0xFF22C55E);
  static const Color disabledBg = Color(0xFFF1F5F9);
}

class _Space {
  const _Space._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

class _Corner {
  const _Corner._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 16;
}

class _Motion {
  const _Motion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
}

const String _kSetorEmbalagem = 'EMBALAGEM';

// Altura da linha de pesquisa (TextField + botão de scan).
const double _kSearchRowHeight = 56;
// Espaço entre a barra de pesquisa e o painel de sugestões.
const double _kSuggestionsGap = 4;



// =============================================================================
// PÁGINA
// =============================================================================

class AssemblyGuidePage extends StatefulWidget {
  const AssemblyGuidePage({super.key});

  @override
  State<AssemblyGuidePage> createState() => _AssemblyGuidePageState();
}

class _AssemblyGuidePageState extends State<AssemblyGuidePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounce;
  List<ProductModel> _suggestions = [];
  ProductModel? _selectedProduct;
  bool _isSearching = false;
  bool _noResultsFound = false;
  String? _imageUrl;

  TvDeviceModel? _selectedTvDevice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceService>().fetchTvDevicesBySetor(_kSetorEmbalagem);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _noResultsFound = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchSuggestions(value.trim());
    });
  }

  Future<void> _fetchSuggestions(String txtFilter) async {
    if (txtFilter.isEmpty) return;

    final productService = context.read<ProductService>();
    setState(() {
      _isSearching = true;
      _noResultsFound = false;
    });

    try {
      final results = await productService.quickSearch(txtFilter);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _noResultsFound = results.isEmpty;
      });
    } catch (e) {
      if (!mounted) return;
      MessageService.showError('Erro ao pesquisar: $e');
      setState(() {
        _suggestions = [];
        _noResultsFound = false;
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _selectProduct(ProductModel product) async {
    final productService = context.read<ProductService>();

    setState(() {
      _selectedProduct = product;
      _suggestions = [];
      _noResultsFound = false;
      _searchController.text = product.name;
      _imageUrl = null;
    });

    _searchFocusNode.unfocus();

    try {
      final path = await productService.getProductImage(product.productId);
      if (!mounted) return;
      setState(() => _imageUrl = 'https://oxfordtec.com.br/Imagens/$path');
    } catch (e) {
      debugPrint('Erro ao carregar imagem remota, tentando fallback local: $e');
    }

    // Dispara a busca das imagens do passo a passo (montagem) associada
    // a este produto via ImageService, sem bloquear a seleção do produto.
    context.read<ImageService>().fetchProductImages(product.productId, _kSetorEmbalagem);

    // Se já existe uma TV selecionada, envia o novo transCode imediatamente.
    _sendTransCodeIfReady();
  }

  void _clearSelection() {
    setState(() {
      _selectedProduct = null;
      _suggestions = [];
      _noResultsFound = false;
      _imageUrl = null;
      _searchController.clear();
    });
    context.read<ImageService>().clear();
    _searchFocusNode.requestFocus();
  }

  void _onTvDeviceSelected(TvDeviceModel? device) {
    setState(() => _selectedTvDevice = device);

    // Se uma TV foi selecionada (não desmarcada) e já existe um produto
    // escolhido, envia o transCode para essa TV imediatamente.
    if (device != null) {
      _sendTransCodeIfReady();
    }
  }

  /// Envia o transCode (código do produto selecionado) para a TV
  /// selecionada, caso ambos estejam definidos.
  Future<void> _sendTransCodeIfReady() async {
    final product = _selectedProduct;
    final device = _selectedTvDevice;

    if (product == null || device == null) return;

    final deviceService = context.read<DeviceService>();

    final success = await deviceService.sendTransCode(
      deviceId: device.deviceId,
      setor: _kSetorEmbalagem,
      transCode: product.productId,
    );

    if (!mounted) return;

    if (!success) {
      MessageService.showError(
        deviceService.errorMessage ?? 'Erro ao enviar produto para a TV.',
      );
    }
  }

/*
  Future<void> _selectProduct(ProductModel product) async {
    final productService = context.read<ProductService>();

    setState(() {
      _selectedProduct = product;
      _suggestions = [];
      _noResultsFound = false;
      _searchController.text = product.name;
      _imageUrl = null;
    });

    _searchFocusNode.unfocus();

    try {
      final path = await productService.getProductImage(product.productId);
      if (!mounted) return;
      setState(() => _imageUrl = 'https://oxfordtec.com.br/Imagens/$path');
    } catch (e) {
      debugPrint('Erro ao carregar imagem remota, tentando fallback local: $e');
    }

    // Dispara a busca das imagens do passo a passo (montagem) associada
    // a este produto via ImageService, sem bloquear a seleção do produto.
    context.read<ImageService>().fetchProductImages(product.productId, _kSetorEmbalagem);
  }
  */
/*
  void _clearSelection() {
    setState(() {
      _selectedProduct = null;
      _suggestions = [];
      _noResultsFound = false;
      _imageUrl = null;
      _searchController.clear();
    });
    context.read<ImageService>().clear();
    _searchFocusNode.requestFocus();
  }

  void _onTvDeviceSelected(TvDeviceModel? device) {
    setState(() => _selectedTvDevice = device);
    // TODO: usar `_selectedTvDevice` para disparar o envio do guia de
    // montagem para essa TV, quando essa funcionalidade for implementada.
  }
*/

  Future<void> _scanBarcode() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      MessageService.showError(
        'Permita o acesso à câmera para escanear o código.',
      );
      return;
    }

    final res = await Navigator.of(context).push<Barcode?>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (res?.rawValue == null || !mounted) return;

    HapticFeedback.lightImpact();

    final scannedValue = res!.rawValue!;
    _debounce?.cancel();

    setState(() {
      _searchController.text = scannedValue;
      _selectedProduct = null;
    });

    await _fetchSuggestions(scannedValue);
  }

  String _getContentType(String fileName) {
    if (fileName.endsWith('.png')) return 'image/png';
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) return 'image/jpeg';
    if (fileName.endsWith('.gif')) return 'image/gif';
    return 'application/octet-stream';
  }

  Future<List<String>?> _decodeAndExtractImage(String? imageZipBase64) async {
    if (imageZipBase64 == null || imageZipBase64.isEmpty) return null;

    try {
      final zipBytes = base64Decode(imageZipBase64);
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final imagesDataUris = <String>[];

      for (final file in archive) {
        if (file.isFile &&
            (file.name.endsWith('.png') || file.name.endsWith('.jpg') || file.name.endsWith('.jpeg'))) {
          final imageBytes = Uint8List.fromList(file.content as List<int>);
          final base64Image = base64Encode(imageBytes);
          final contentType = _getContentType(file.name);
          imagesDataUris.add('data:$contentType;base64,$base64Image');
        }
      }
      return imagesDataUris.isNotEmpty ? imagesDataUris : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Offset (a partir do topo da área segura) onde o painel de sugestões
    // deve começar: logo abaixo da linha de pesquisa.
    final double suggestionsTop =
        _Space.md + _kSearchRowHeight + _kSuggestionsGap;
    // Padding superior do conteúdo rolável, para que ele comece sempre
    // abaixo da barra de pesquisa fixa.
    final double contentTopPadding =
        _Space.md + _kSearchRowHeight + _Space.lg;

    return Scaffold(
      backgroundColor: _Palette.background,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBarCustom(title: 'Guia de Montagem'),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            if (_suggestions.isNotEmpty || _noResultsFound) {
              setState(() {
                _suggestions = [];
                _noResultsFound = false;
              });
            }
            _searchFocusNode.unfocus();
          },
          behavior: HitTestBehavior.translucent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── CAMADA 1 (fundo): conteúdo rolável — produto ───────
              // selecionado + lista de TVs. Pintado primeiro, portanto
              // nunca fica na frente de nada.
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    _Space.md,
                    contentTopPadding,
                    _Space.md,
                    _Space.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSwitcher(
                        duration: _Motion.base,
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.02),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: _selectedProduct != null
                            ? Column(
                                key: ValueKey('product-${_selectedProduct!.productId}'),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _SelectedProductCard(
                                    product: _selectedProduct!,
                                    decodeImage: _decodeAndExtractImage,
                                    imageUrl: _imageUrl,
                                    onClear: _clearSelection,
                                  ),
                                  const SizedBox(height: _Space.md),
                                  const _AssemblyStepsSection(),
                                ],
                              )
                            : const SizedBox.shrink(key: ValueKey('empty')),
                      ),

                      const SizedBox(height: _Space.xl),
                      const Divider(height: 1, color: _Palette.border),
                      const SizedBox(height: _Space.lg),

                      // ── Lista de TVs ────
                      _TvDeviceSection(
                        setor: _kSetorEmbalagem,
                        onDeviceSelected: _onTvDeviceSelected,
                      ),
                    ],
                  ),
                ),
              ),

              // ── CAMADA 2 (meio): barra de pesquisa fixa no topo ────
              // Pintada depois do conteúdo rolável, então fica sempre
              // visível por cima dele ao rolar. O fundo opaco evita que
              // o texto por baixo apareça atrás da barra.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: _Palette.background,
                  padding: EdgeInsets.fromLTRB(_Space.md, _Space.md, _Space.md, 0),
                  child: _SearchRow(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    isSearching: _isSearching,
                    onChanged: (value) {
                      if (_selectedProduct != null) {
                        setState(() => _selectedProduct = null);
                      }
                      _onSearchChanged(value);
                    },
                    onSubmitted: (value) {
                      _debounce?.cancel();
                      _fetchSuggestions(value.trim());
                    },
                    onClear: _clearSelection,
                    onScan: _scanBarcode,
                  ),
                ),
              ),

              // ── CAMADA 3 (topo): painel de sugestões ───────────────
              // Pintado por último — sempre na frente do produto
              // selecionado, da lista de TVs e de qualquer outra
              // informação da tela, nunca atrás.
              if (_suggestions.isNotEmpty || _noResultsFound)
                Positioned(
                  top: suggestionsTop,
                  left: _Space.md,
                  right: _Space.md,
                  child: _SuggestionsPanel(
                    suggestions: _suggestions,
                    noResultsFound: _noResultsFound,
                    onSelect: _selectProduct,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _SearchRow
// =============================================================================

class _SearchRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onScan;

  const _SearchRow({
    required this.controller,
    required this.focusNode,
    required this.isSearching,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: _kSearchRowHeight,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _Palette.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Pesquisar produto',
                labelStyle: const TextStyle(color: _Palette.textSecondary),
                filled: true,
                fillColor: _Palette.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: AnimatedSwitcher(
                  duration: _Motion.fast,
                  child: isSearching
                      ? const Padding(
                          key: ValueKey('spinner'),
                          padding: EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: SpinKitThreeBounce(color: _Palette.primary, size: 14.0),
                          ),
                        )
                      : (controller.text.isNotEmpty
                          ? IconButton(
                              key: const ValueKey('clear'),
                              icon: const Icon(Icons.close_rounded, size: 20),
                              color: _Palette.textSecondary,
                              tooltip: 'Limpar pesquisa',
                              onPressed: onClear,
                            )
                          : const SizedBox.shrink(key: ValueKey('none'))),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_Corner.md),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_Corner.md),
                  borderSide: const BorderSide(color: _Palette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_Corner.md),
                  borderSide: const BorderSide(color: _Palette.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: _Space.sm),
        _ScanIconButton(onPressed: onScan),
      ],
    );
  }
}

// =============================================================================
// _ScanIconButton
// =============================================================================

class _ScanIconButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _ScanIconButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Semantics(
      button: true,
      label: 'Ler código de barras ou QR code',
      child: Material(
        color: disabled ? _Palette.disabledBg : _Palette.primarySoft,
        borderRadius: BorderRadius.circular(_Corner.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(_Corner.md),
          onTap: onPressed,
          splashColor: _Palette.primary.withOpacity(0.15),
          highlightColor: _Palette.primaryDark.withOpacity(0.1),
          child: SizedBox(
            height: _kSearchRowHeight,
            width: 56,
            child: Icon(
              Icons.qr_code_scanner_rounded,
              color: disabled ? _Palette.textSecondary.withOpacity(0.4) : _Palette.primary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _SuggestionsPanel
// =============================================================================

class _SuggestionsPanel extends StatelessWidget {
  final List<ProductModel> suggestions;
  final bool noResultsFound;
  final ValueChanged<ProductModel> onSelect;

  const _SuggestionsPanel({
    required this.suggestions,
    required this.noResultsFound,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(_Corner.md),
      color: _Palette.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: suggestions.isNotEmpty
            ? ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final product = suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.inventory_2_outlined,
                      size: 20,
                      color: _Palette.textSecondary,
                    ),
                    title: Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Cód: ${product.productId}  •  Barras: ${product.barcode ?? '—'}',
                      style: const TextStyle(fontSize: 12, color: _Palette.textSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: _Palette.textSecondary),
                    onTap: () => onSelect(product),
                  );
                },
              )
            : const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 28, color: _Palette.textSecondary),
                    SizedBox(height: _Space.sm),
                    Text(
                      'Nenhum produto encontrado',
                      style: TextStyle(fontSize: 13, color: _Palette.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// =============================================================================
// _SearchHintState — estado inicial, antes de qualquer pesquisa
// =============================================================================

class _SearchHintState extends StatelessWidget {
  const _SearchHintState({super.key});

  @override
  Widget build(BuildContext context) {
    // Sem Center: este widget agora vive dentro de uma coluna rolável
    // (altura não limitada), e Center sem widthFactor/heightFactor exige
    // altura limitada — usar Center aqui geraria erro de "unbounded height".
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _Space.xl, horizontal: _Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 56,
            color: _Palette.textSecondary.withOpacity(0.35),
          ),
          const SizedBox(height: _Space.lg),
          const Text(
            'Pesquise por código, código de barras ou descrição',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _Palette.textSecondary,
            ),
          ),
          const SizedBox(height: _Space.xs),
          Text(
            'ou toque no ícone de câmera para escanear',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _Palette.textSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _AssemblyStepsSection — miniaturas do passo a passo de montagem.
//
// As imagens vêm do `ImageService` (Consumer/Provider), que busca em
// GET /API/v1/Image/Product/{productId}/EMBALAGEM e expõe a lista já
// ordenada por `sequence` em `productImages`. `buildFullImageUrl` resolve
// o `imagePath` relativo de cada item em uma URL carregável.
// =============================================================================

class _AssemblyStepsSection extends StatelessWidget {
  const _AssemblyStepsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageService>(
      builder: (context, imageService, child) {
        final images = imageService.productImages;

        if (imageService.isLoading && images.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: _Space.xl),
            decoration: BoxDecoration(
              color: _Palette.surface,
              borderRadius: BorderRadius.circular(_Corner.lg),
              border: Border.all(color: _Palette.border),
            ),
            child: const Center(
              child: SpinKitThreeBounce(color: _Palette.primary, size: 22.0),
            ),
          );
        }

        if (images.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: _Space.xl, horizontal: _Space.lg),
            decoration: BoxDecoration(
              color: _Palette.surface,
              borderRadius: BorderRadius.circular(_Corner.lg),
              border: Border.all(color: _Palette.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.construction_rounded, size: 28, color: _Palette.textSecondary),
                SizedBox(height: _Space.sm),
                Text(
                  'O passo a passo do guia de montagem\naparecerá aqui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: _Palette.textSecondary, height: 1.4),
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(_Space.md),
          decoration: BoxDecoration(
            color: _Palette.surface,
            borderRadius: BorderRadius.circular(_Corner.lg),
            border: Border.all(color: _Palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.construction_rounded, size: 18, color: _Palette.textSecondary),
                  const SizedBox(width: _Space.sm),
                  Text(
                    'Passo a passo (${images.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _Palette.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _Space.md),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: _Space.sm),
                  itemBuilder: (context, index) {
                    final imageUrl = imageService.buildFullImageUrl(images[index].imagePath);
                    return _AssemblyStepThumbnail(
                      step: index + 1,
                      imageUrl: imageUrl,
                      onTap: () => _openFullScreen(context, imageService, images, index),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFullScreen(
    BuildContext context,
    ImageService imageService,
    List<ImageUrlModel> images,
    int initialIndex,
  ) {
    final imageUrls = images.map((img) => imageService.buildFullImageUrl(img.imagePath)).toList();

    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => _AssemblyImageViewer(imageUrls: imageUrls, initialIndex: initialIndex),
    );
  }
}

class _AssemblyStepThumbnail extends StatelessWidget {
  final int step;
  final String imageUrl;
  final VoidCallback onTap;

  static const double _size = 96;

  const _AssemblyStepThumbnail({
    required this.step,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(_Corner.sm),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_Corner.sm),
        child: Stack(
          children: [
            Image.network(
              imageUrl,
              width: _size,
              height: _size,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: _size,
                  height: _size,
                  color: _Palette.disabledBg,
                  child: const Center(
                    child: SpinKitThreeBounce(color: _Palette.primary, size: 10.0),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                width: _size,
                height: _size,
                color: _Palette.disabledBg,
                child: const Icon(
                  Icons.broken_image_rounded,
                  size: 24,
                  color: _Palette.textSecondary,
                ),
              ),
            ),
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$step',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _AssemblyImageViewer — visualização em tela cheia, com zoom e swipe
// entre as imagens do passo a passo, aberta ao tocar em uma miniatura.
// =============================================================================

class _AssemblyImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _AssemblyImageViewer({required this.imageUrls, required this.initialIndex});

  @override
  State<_AssemblyImageViewer> createState() => _AssemblyImageViewerState();
}

class _AssemblyImageViewerState extends State<_AssemblyImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            bottom: 0,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Semantics(
              button: true,
              label: 'Fechar visualização',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.imageUrls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// _SelectedProductCard
// =============================================================================

class _SelectedProductCard extends StatelessWidget {
  final ProductModel product;
  final Future<List<String>?> Function(String?) decodeImage;
  final VoidCallback onClear;
  final String? imageUrl;

  const _SelectedProductCard({
    required this.product,
    required this.decodeImage,
    required this.onClear,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(_Corner.lg),
        border: Border.all(color: _Palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(_Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(_Corner.sm),
            child: _ProductThumbnail(
              imageUrl: imageUrl,
              decodeImage: decodeImage,
              imageZipBase64: product.imageZipBase64,
            ),
          ),
          const SizedBox(width: _Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _Palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Código: ${product.productId}  •  Barras: ${product.barcode ?? '—'}',
                  style: const TextStyle(fontSize: 12, color: _Palette.textSecondary),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'Remover produto selecionado',
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: _Palette.textSecondary, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onClear,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final Future<List<String>?> Function(String?) decodeImage;
  final String? imageZipBase64;

  const _ProductThumbnail({
    required this.imageUrl,
    required this.decodeImage,
    required this.imageZipBase64,
  });

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: _Motion.base,
            curve: Curves.easeOut,
            child: child,
          );
        },
        // SizedBox com altura fixa (_size) garante que o Center aqui
        // dentro nunca receba restrições de altura infinita.
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            width: _size,
            height: _size,
            child: Center(child: SpinKitThreeBounce(color: _Palette.primary, size: 12.0)),
          );
        },
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image_rounded,
          size: 28,
          color: _Palette.textSecondary,
        ),
      );
    }

    return FutureBuilder<List<String>?>(
      future: decodeImage(imageZipBase64),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: _size,
            height: _size,
            child: Center(child: SpinKitThreeBounce(color: _Palette.primary, size: 12.0)),
          );
        }
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          final base64Image = snapshot.data!.first.split(',').last;
          return Image.memory(
            base64Decode(base64Image),
            width: _size,
            height: _size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 28),
          );
        }
        return const SizedBox(
          width: _size,
          height: _size,
          child: Icon(Icons.image_outlined, size: 28, color: _Palette.textSecondary),
        );
      },
    );
  }
}

// =============================================================================
// _TvDeviceSection — lista de TVs do setor, dentro do fluxo normal da
// página (sem barra/rodapé fixo).
// =============================================================================

class _TvDeviceSection extends StatefulWidget {
  final String setor;
  final ValueChanged<TvDeviceModel?>? onDeviceSelected;

  const _TvDeviceSection({
    required this.setor,
    this.onDeviceSelected,
  });

  @override
  State<_TvDeviceSection> createState() => _TvDeviceSectionState();
}

class _TvDeviceSectionState extends State<_TvDeviceSection> {
  TvDeviceModel? _selectedDevice;

  void _handleSelect(TvDeviceModel device) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDevice = _selectedDevice?.deviceId == device.deviceId ? null : device;
    });
    widget.onDeviceSelected?.call(_selectedDevice);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceService>(
      builder: (context, deviceService, child) {
        if (deviceService.isLoading && deviceService.tvDevices.isEmpty) {
          // Row em vez de Center: evita o erro de altura infinita, já que
          // esta seção vive dentro de um SingleChildScrollView.
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: _Space.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitThreeBounce(color: _Palette.primary, size: 20.0),
              ],
            ),
          );
        }

        // Se não há devices cadastrados para o setor, a seção some por
        // completo — nada é renderizado no lugar dela.
        if (deviceService.tvDevices.isEmpty) {
          return const SizedBox.shrink();
        }

        final count = deviceService.tvDevices.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tv_rounded, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: _Space.sm),
                Text(
                  'TVs — ${widget.setor}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: _Space.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _Palette.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _Palette.primary,
                    ),
                  ),
                ),
                const Spacer(),
                if (_selectedDevice != null)
                  Flexible(
                    child: _SelectedTvPill(
                      label: _tvLabel(_selectedDevice!),
                      onClear: () {
                        setState(() => _selectedDevice = null);
                        widget.onDeviceSelected?.call(null);
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: _Space.md),
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: count,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final device = deviceService.tvDevices[index];
                  return _TvDeviceChip(
                    device: device,
                    isSelected: device.deviceId == _selectedDevice?.deviceId,
                    onTap: () => _handleSelect(device),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

String _tvLabel(TvDeviceModel device) {
  return device.customDeviceName?.isNotEmpty == true
      ? device.customDeviceName!
      : (device.deviceName ?? '${device.customDeviceName}');
}

class _SelectedTvPill extends StatelessWidget {
  final String label;
  final VoidCallback onClear;

  const _SelectedTvPill({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: _Palette.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          Semantics(
            button: true,
            label: 'Desmarcar TV selecionada',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.all(3),
                child: Icon(Icons.close_rounded, size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TvDeviceChip extends StatelessWidget {
  final TvDeviceModel device;
  final bool isSelected;
  final VoidCallback onTap;

  const _TvDeviceChip({
    required this.device,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = _tvLabel(device);

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'TV $label${isSelected ? ", selecionada" : ""}',
      child: AnimatedContainer(
        duration: _Motion.fast,
        curve: Curves.easeOut,
        width: 108,
        decoration: BoxDecoration(
          color: isSelected ? _Palette.primary.withOpacity(0.08) : _Palette.surface,
          borderRadius: BorderRadius.circular(_Corner.xl),
          border: Border.all(
            color: isSelected ? _Palette.primary : _Palette.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? _Palette.primary.withOpacity(0.15) : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_Corner.xl),
          child: InkWell(
            borderRadius: BorderRadius.circular(_Corner.xl),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected ? _Palette.primary : _Palette.primarySoft,
                          borderRadius: BorderRadius.circular(_Corner.md),
                        ),
                        child: Icon(
                          Icons.tv_rounded,
                          color: isSelected ? Colors.white : _Palette.primary,
                          size: 32,
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _Palette.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _Palette.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: _Space.sm),
                  Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? _Palette.primary : _Palette.textPrimary,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}