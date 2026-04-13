import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/widgets/product_search.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oxdata/app/views/pages/barcode_scanner_page.dart';
import 'package:oxdata/app/views/product/search_products_page.dart';
import 'package:oxdata/app/core/widgets/pulse_icon.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/views/pages/search_image_dialog.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:archive/archive.dart';

// Novos Imports
import 'package:oxdata/app/core/models/product_packing_model.dart';
import 'package:oxdata/app/core/models/product_pack_image_base64.dart';
import 'package:oxdata/app/core/services/product_packing_service.dart';

class PackagingPage extends StatefulWidget {
  const PackagingPage({super.key});

  @override
  State<PackagingPage> createState() => _PackagingPageState();
}

class _PackagingPageState extends State<PackagingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final PageController _pageController = PageController();
  int _currentPage = 0;

  String productName = "";
  bool   _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));

    // Busca os dados assim que a tela inicia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductPackingService>().fetchAllPackings();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _productController.dispose();
    super.dispose();
  }

  // --- COMPONENTE: HEADER DE CONTEXTO (Layout original restaurado) ---
  Widget _buildSelectionHeader(ProductPackingModel? selected) {
    if (selected == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MONTAGEM SELECIONADA",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.withOpacity(0.7),
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  selected.packName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
          ),
          PulseIconButton(
            icon: Icons.swap_horiz,
            color: Colors.indigo,
            size: 34,
            onPressed: () => _tabController.animateTo(0),
          ),
        ],
      ),
    );
  }

  // --- COMPONENTE: CAMPO DE PESQUISA (Layout original restaurado) ---
  Widget _buildSearchField(ProductPackingService service) {
    return TextField(
      controller: _searchController,
      onChanged: (value) => service.filterPackings(value),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Pesquisar..',
        hintStyle: TextStyle(
          color: Colors.blueGrey[300],
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.indigo, size: 22),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  _searchController.clear();
                  service.filterPackings("");
                },
              )
            : null,
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
    );
  }

  // --- ABA 1: LISTA DE MONTAGENS (Layout original restaurado) ---
  Widget _buildPackagingTab(ProductPackingService service) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildSearchField(service),
        ),
        Expanded(
          child: service.isLoading 
            ? const Center(child: CircularProgressIndicator())
            : service.packings.isEmpty
              ? _buildEmptyState("Nenhuma montagem encontrada")
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: service.packings.length,
                  itemBuilder: (context, index) {
                    final pkg = service.packings[index];
                    final isSelected = service.selectedPacking?.packId == pkg.packId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () {
                          service.setSelectedPacking(pkg);
                          _tabController.animateTo(1);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.indigo : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.indigo : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(pkg.packName,
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.indigo : Colors.blueGrey[800])),
                                      const SizedBox(height: 8),
                                      _buildBadge("${pkg.items.length} Produtos"),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_forever_rounded, color: Colors.red[300]),
                                onPressed: () => _confirmDelete(pkg, service),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.indigo),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- ABA 2: IMAGENS (Ajustada para PageView / Slide) ---
  Widget _buildImagesTab(ProductPackingService service) {
    final selected = service.selectedPacking;
    if (selected == null) return _buildNoSelectionState("Selecione uma montagem primeiro.");

    final imagesFromApi = service.packImages;

    return Column(
      // Removendo qualquer espaçamento entre o header e o conteúdo
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildSelectionHeader(selected),
        Expanded(
          child: service.isLoading
              ? const Center(child: CircularProgressIndicator())
              : imagesFromApi.isEmpty
                  ? _buildEmptyState("Nenhuma imagem encontrada")
                  : Stack(
                      children: [
                        // PageView com o Controller
                        PageView.builder(
                          controller: _pageController,
                          itemCount: imagesFromApi.length,
                          onPageChanged: (int index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            // Sizedbox.expand garante que o container ocupe tudo
                            // O Align com topCenter joga o conteúdo para a aresta superior
                            return SizedBox.expand(
                              child: Align(
                                alignment: Alignment.topCenter, 
                                child: _buildFullScreenPhoto(context, imagesFromApi[index], service),
                              ),
                            );
                          },
                        ),

                      // --- NOVO: CONTADOR FLUTUANTE (1/3, 2/3, etc) ---
                      if (imagesFromApi.isNotEmpty)
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${_currentPage + 1}/${imagesFromApi.length}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // INDICADOR DE BOLINHAS (Dots Indicator)
                        if (imagesFromApi.length > 1)
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                imagesFromApi.length,
                                (index) => _buildDotIndicator(index),
                              ),
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildDotIndicator(int index) {
    final bool isActive = _currentPage == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 10,
      // Se quiser o efeito de "traço" quando ativo, mude para: isActive ? 20 : 10
      width: 10, 
      decoration: BoxDecoration(
        color: isActive
            ? Colors.indigo
            : Colors.white.withAlpha((0.5 * 255).toInt()),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          if (isActive)
            const BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            )
        ],
      ),
    );
  }


  // --- ITEM DO SLIDE (Tamanho da tela) ---
Widget _buildFullScreenPhoto(
    BuildContext context, 
    ImagePackBase64 imageDto, 
    ProductPackingService service) {

  return StatefulBuilder(
    builder: (context, setStateLocal) {
      final bool isExpanded = _isExpanded ?? false;
      final screenWidth = MediaQuery.of(context).size.width;

      return GestureDetector(
        onDoubleTap: () {
          setStateLocal(() {
            _isExpanded = !isExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.fromLTRB(0, 1, 0, 0),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
            ],
          ),
          child: InteractiveViewer(
            // Permitir pan apenas quando expandido para navegar na largura que sobrar
            panEnabled: isExpanded, 
            scaleEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: SizedBox.expand( // Faz o widget ocupar todo o espaço do TabBarView
              child: FittedBox(
                // fitHeight: Força a imagem a ocupar do topo ao fundo (bottom)
                // Se a imagem for larga, ela vai "sangrar" para as laterais (o que você deseja)
                fit: isExpanded ? BoxFit.fitHeight : BoxFit.contain,
                child: _loadImageFromZipBase64(imageDto.imagesBase64),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/*Widget _buildFullScreenPhoto(
    BuildContext context,
    ImagePackBase64 imageDto,
    ProductPackingService service) {

  return StatefulBuilder(
    builder: (context, setStateLocal) {

      final bool isExpanded = _isExpanded ?? false;
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      return GestureDetector(
        onDoubleTap: () {
          setStateLocal(() {
            _isExpanded = !isExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: screenWidth,
          height: isExpanded ? screenHeight : 300, // 👈 controla expansão vertical
          decoration: const BoxDecoration(
            color: Colors.white60,
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
            ],
          ),
          child: InteractiveViewer(
            panEnabled: true,
            scaleEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: FittedBox(
              fit: BoxFit.contain,
              child: _loadImageFromZipBase64(imageDto.imagesBase64),
            ),
          ),
        ),
      );
    },
  );
}*/

  /*Widget _buildFullScreenPhoto(BuildContext context, ImagePackBase64 imageDto, ProductPackingService service) {
    final screenWidth = MediaQuery.of(context).size.width; // largura da tela

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 1, 0, 0),
      decoration: BoxDecoration(
        color: Colors.white60,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: ClipRRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.topCenter,
              child: InteractiveViewer(
                panEnabled: true,
                scaleEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: SizedBox(
                  width: screenWidth,
                  child: FittedBox(
                    fit: BoxFit.contain, // mantém a proporção da imagem
                    child: _loadImageFromZipBase64(imageDto.imagesBase64),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }*/

  // Função auxiliar para processar o ZIP vindo da sua API C#
  Widget _loadImageFromZipBase64(String? base64Zip) {
    if (base64Zip == null || base64Zip.isEmpty) {
      return Container(color: Colors.grey[200], child: const Icon(Icons.broken_image));
    }

    try {
      // 1. Decodifica a string Base64 para Bytes
      final zipBytes = base64Decode(base64Zip);
      
      // 2. Descompacta o ZIP (Usando a biblioteca archive)
      final archive = ZipDecoder().decodeBytes(zipBytes);
      
      // 3. Pega o primeiro arquivo do ZIP
      if (archive.isNotEmpty) {
        final file = archive.first;
        final Uint8List imageBytes = file.content as Uint8List;
        return Image.memory(imageBytes, fit: BoxFit.cover);
      }
    } catch (e) {
      debugPrint("Erro ao processar imagem ZIP: $e");
    }

    return Container(color: Colors.grey[200], child: const Icon(Icons.error_outline));
  }

  // --- ABA 3: PRODUTOS (Layout original restaurado) ---
  Widget _buildProductsTab(ProductPackingService service) {
    final selected = service.selectedPacking;
    if (selected == null) return _buildNoSelectionState("Selecione uma montagem primeiro.");

    return Column(
      children: [
        _buildSelectionHeader(selected),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: ProductSearch(
                  controller: _productController,
                  label: 'Produto',
                  onScanBarcode: _scanBarcode,
                  onSearch: () => _openProductSearch(context),
                ),
              ),
              const SizedBox(width: 10),
              _ColorChangingButton(
                icon: Icons.add,
                size: 50,
                color: Colors.green,
                onPressed: () {
                  if (_productController.text.isNotEmpty) {
                    // Chamar service.addItemToPacking se existir
                    _productController.clear();
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: selected.items.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 16, right: 4),
                  leading: const Icon(Icons.qr_code_rounded, color: Colors.indigo),
                  title: Text(selected.items[index].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () { /* Lógica de remover item */ },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final service = context.watch<ProductPackingService>();

    return Scaffold(
      appBar: AppBarCustom(
        title: "ESQUEMA DE MONTAGEM",
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            indicatorColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'MONTAGEM', icon: Icon(Icons.all_inbox)),
              Tab(text: 'IMAGENS', icon: Icon(Icons.photo_library)),
              Tab(text: 'PRODUTOS', icon: Icon(Icons.list_alt)),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Conteúdo das Tabs
          TabBarView(
            controller: _tabController,
            children: [
              _buildPackagingTab(service),
              _buildImagesTab(service),
              _buildProductsTab(service),
            ],
          ),

          // Os botões aparecem apenas se estiver na aba de imagens (index 1)
          if (_tabController.index == 1 && service.selectedPacking != null) ...[
            _buildDynamicBtnDel(service),
            _buildDynamicBtnAdd(service)!, // O ! é porque sabemos que não é nulo aqui
          ],
        ],
      ),
      // Na aba 0, você pode manter o FAB padrão se preferir
      floatingActionButton: _tabController.index == 0 ? _buildDynamicBtnAdd(service) : null,
    );
  }

  Widget _buildDynamicBtnDel(ProductPackingService service) {
    final bool hasImages = service.packImages.isNotEmpty;

    return Positioned(
      bottom: 16,
      right: 86, // Posicionado à esquerda do botão de adicionar
      child: FloatingActionButton(
        heroTag: 'fab_delete',
        backgroundColor: hasImages ? Colors.red : Colors.grey[300],
        elevation: hasImages ? 6 : 0,
        shape: const CircleBorder(),
        onPressed: hasImages 
          ? () {
              final currentIndex = _currentPage;
              setState(() {
                service.packImages.removeAt(currentIndex);
                if (_currentPage >= service.packImages.length && _currentPage > 0) {
                  _currentPage--;
                }
              });
            }
          : null, 
        child: Icon(
          Icons.delete_forever_rounded, 
          color: hasImages ? Colors.white : Colors.grey[500], 
          size: 28
        ),
      ),
    );
  }

  Widget? _buildDynamicBtnAdd(ProductPackingService service) {
    if (_tabController.index == 0) {
      return FloatingActionButton(
        heroTag: 'fab_montagem',
        shape: const CircleBorder(),
        backgroundColor: Colors.indigo,
        onPressed: () => _showAddPackagingDialog(service),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      );
    }

    if (_tabController.index == 1 && service.selectedPacking != null) {
      // Usamos Positioned aqui para alinhar com o botão de deletar no Stack
      return Positioned(
        bottom: 16,
        right: 16,
        child: FloatingActionButton(
          heroTag: 'fab_foto',
          backgroundColor: Colors.indigo,
          elevation: 4,
          shape: const CircleBorder(),
          
          onPressed: () => _showAddImageOptions(service, service.selectedPacking!),

          /*
          onPressed: () async {
            final picker = ImagePicker();
            final XFile? image = await picker.pickImage(source: ImageSource.camera);
            if (image != null) {
              // Lógica de upload/save no service

            }
          },*/
          child: const Icon(
            Icons.add_a_photo_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      );
    }
    return null;
  }

  Future<void> _showAddImageOptions(ProductPackingService service, ProductPackingModel pkg) async {
    final loadingService = context.read<LoadingService>();

    await showDialog(
      context: context,
      builder: (context) => SearchImageDialog(
        onSourceSelected: (source) {
          // Aqui você executa a lógica de imagem que ficou na sua tela
          _executeImageAction(loadingService, source, service, pkg);
        },
      ),
    );
  }

  // Processa a imagem
  void _executeImageAction(LoadingService loadingService, ImageSource source, ProductPackingService service, ProductPackingModel pkg) {
    CallAction.run(
      action: () async {
        loadingService.show();
        final files = await _pickImages(source);

        if (files.isNotEmpty) {
          await _processNewImage(files, service, pkg);
        }
      },
      onFinally: () => loadingService.hide(),
    );
  }

  // --- HELPERS ORIGINAIS ---
  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildNoSelectionState(String msg) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.touch_app_outlined, size: 60, color: Colors.indigo.withValues(alpha: 0.2),),
        const SizedBox(height: 16),
        Text(msg, style: TextStyle(color: Colors.blueGrey[300])),
      ],
    ));
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_search_rounded,
            size: 60,
            color: Colors.indigo.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            msg,
            style: TextStyle(color: Colors.blueGrey[300]),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ProductPackingModel pkg, ProductPackingService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir?"),
        content: Text("Deseja remover '${pkg.packName}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // service.deletePacking(pkg.packId);
              Navigator.pop(context);
            },
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /*
  void _showAddPackagingDialog(ProductPackingService service) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nova Montagem"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Nome")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                // service.createPacking(controller.text.toUpperCase());
                Navigator.pop(context);
              }
            },
            child: const Text("CRIAR"),
          ),
        ],
      ),
    );
  }
  */

  void _showAddPackagingDialog(ProductPackingService service) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Material(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          elevation: 12,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header seguindo seu padrão
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inventory_2_outlined, color: Colors.indigo, size: 26),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'NOVA MONTAGEM',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Campo direto no código seguindo o padrão visual
                  TextFormField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Nome da montagem',
                      hintStyle: TextStyle(
                        color: Colors.blueGrey[300],
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      labelText: 'Nome da Montagem',
                      labelStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.grey[50],
                      errorStyle: const TextStyle(
                        fontSize: 0,  // Tamanho zero para não ocupar espaço
                        height: 0,    // Altura zero para não empurrar o layout
                      ),
                                        suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => controller.clear(),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.indigo, width: 2),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? '' : null,
                  ),
                  
                  const SizedBox(height: 30),

                  // Ações
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("CANCELAR", style: TextStyle(color: Colors.grey[600])),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                              final username = await _storage.read(key: 'username');
                              // Chamada ao service
                              final result = await service.createPacking(
                                controller.text.toUpperCase(),
                                username.toString(),
                              );

                              if (result.success) {
                                Navigator.pop(context);
                              } else {
                                // Exiba um SnackBar de erro **
                              }
                            }
                        },
                        child: const Text("CRIAR"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<String> _scanBarcode() async {
     var status = await Permission.camera.request();
     if (status.isDenied) return "";
     final barcodeRead = await Navigator.of(context).push<Barcode?>(
       MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
     );
     return barcodeRead?.rawValue ?? "";
  }

  Future<void> _openProductSearch(BuildContext context) async {
    final selectedProductData = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SearchProductsPage(shouldNavigate: false)),
    );
    if (selectedProductData != null) {
      _productController.text = selectedProductData['productId'];
    }
  }

  Future<List<XFile>> _pickImages(ImageSource source) async {
    final picker = ImagePicker();

    if (source == ImageSource.camera) {
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      return picked != null ? [picked] : [];
    } else {
      final pickedList = await picker.pickMultiImage(
        imageQuality: 80,
      );

      return pickedList;
    }
  }

  Future<void> _processNewImage(
    List<XFile> files,
    ProductPackingService service,
    ProductPackingModel pkg,
  ) async {
    if (files.isEmpty) return;

    try {
      List<ImagePackBase64> newImages = [];

      for (final fileX in files) {
        final file = File(fileX.path);
        if (!await file.exists()) continue;

        final originalBytes = await file.readAsBytes();

        final img.Image? decodedImage = img.decodeImage(originalBytes);
        if (decodedImage == null) continue;

        final img.Image resizedImage = img.copyResize(
          decodedImage,
          width: 300,
          height: 300,
          interpolation: img.Interpolation.linear,
        );

        final Uint8List resizedBytes =
            Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));

        final base64Image = await _zipAndEncode(
          resizedBytes,
          fileX.name,
        );

        final newImage = ImagePackBase64(
          codeId: pkg.packId.toString(),
          imagePath: fileX.name,
          sequence: service.packImages.length + newImages.length + 1,
          imagesBase64: base64Image,
        );

        newImages.add(newImage);
      }

      // Envia tudo de uma vez
      if (newImages.isNotEmpty) {
        await service.addOrUpdatePackImages(newImages, pkg);
      }

    } catch (e) {
      print('Erro ao processar imagem: $e');
    }
  }

  Future<String> _zipAndEncode(Uint8List bytes, String fileName) async {
    final archive = Archive();

    archive.addFile(ArchiveFile(fileName, bytes.length, bytes));

    final zippedBytes = ZipEncoder().encode(archive);

    return base64Encode(zippedBytes!);
  }

}

// --- WIDGET PERSONALIZADO ---
class _ColorChangingButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  const _ColorChangingButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 40,
    this.color,
  });

  @override
  State<_ColorChangingButton> createState() => __ColorChangingButtonState();
}

class __ColorChangingButtonState extends State<_ColorChangingButton> {
  late Color _containerColor;

  final Color _defaultColor = const Color(0xFFE3F2FD);
  final Color _darkerColor = const Color.fromARGB(255, 187, 211, 251);
  final Color _primaryIconColor = const Color(0xFF3F51B5);

  @override
  void initState() {
    super.initState();
    _containerColor = widget.color ?? _defaultColor;
  }

  void _handleTap() async {
    if (widget.onPressed == null) return;

    setState(() {
      _containerColor = widget.color != null 
          ? widget.color!.withOpacity(0.7) 
          : _darkerColor;
    });

    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      setState(() {
        _containerColor = widget.color ?? _defaultColor;
      });
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: widget.size,
        width: widget.size,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[200] : _containerColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            widget.icon,
            color: isDisabled 
                ? Colors.grey[400] 
                : (widget.color != null ? Colors.white : _primaryIconColor),
            size: widget.size * 0.6, 
          ),
        ),
      ),
    );
  }

}