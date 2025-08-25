import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/product_complete.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/product_service.dart';
import 'package:oxdata/app/core/models/product_tag_model.dart'; 
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/widgets/delete_confirm_dialog.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:marquee/marquee.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oxdata/app/core/utils/image_base.dart';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:oxdata/app/core/widgets/pulse_icon.dart';

class ProductPage extends StatefulWidget {
  final String productId;

  const ProductPage({super.key, required this.productId});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProductService>().fetchProductComplete(widget.productId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loadingService = context.read<LoadingService>();

    return Scaffold(
      appBar: const AppBarCustom(title: 'Detalhes do Produto'),
      body: Consumer<ProductService>(
        builder: (context, productService, child) {
          final ProductComplete? productComplete = productService.productComplete;

          if (productComplete == null) {
            loadingService.show();
            return const Center(child: CircularProgressIndicator());
          } else {
            loadingService.hide();

            final productImages       = productComplete.images?.where((img) => img.finalidade == 'PRODUTO')     .toList() ?? [];
            final packagingImages     = productComplete.images?.where((img) => img.finalidade == 'EMBALAGEM')   .toList() ?? [];
            final palletizationImages = productComplete.images?.where((img) => img.finalidade == 'PALETIZACAO') .toList() ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 34,
                    color: Colors.grey[200],
                    child: Marquee(
                      text: ' ${productComplete.product?.productId ?? ''}  -  ${productComplete.product?.productName ?? 'Nome do Produto Não Disponível'}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      blankSpace: 40.0,
                      velocity: 50.0,
                      pauseAfterRound: const Duration(seconds: 1),
                      startPadding: 16.0,
                      fadingEdgeStartFraction: 0.1,
                      fadingEdgeEndFraction: 0.1,
                    ),
                  ),
                  const SizedBox(height: 0),

                  _buildImageCarouselCard(
                    title: 'PRODUTO',
                    images: productImages,
                    finalidade: 'PRODUTO',
                  ),

                  _buildImageCarouselCard(
                    title: 'EMBALAGEM',
                    images: packagingImages,
                    finalidade: 'EMBALAGEM',
                  ),

                  _buildImageCarouselCard(
                    title: 'PALETIZAÇÃO',
                    images: palletizationImages,
                    finalidade: 'PALETIZACAO',
                  ),

                  _buildExpansionTile(
                    title: 'INFORMAÇÕES DO PRODUTO',
                    children: [
                      _buildDetailRow(context, 'Cód. Barras:',    productComplete.product?.barcode),
                      _buildDetailRow(context, 'Código:',         productComplete.product?.productId),
                      _buildDetailRow(context, 'Status:',         productComplete.product?.status == true ? 'Ativo' : 'Inativo'),
                      _buildDetailRow(context, 'Nome:',           productComplete.product?.productName, isFullWidth: true),
                      _buildDetailRow(context, 'Preço:',          productComplete.location?.price?.toStringAsFixed(2)),
                      _buildDetailRow(context, 'Quantidade:',     productComplete.location?.quantity?.toStringAsFixed(0)),
                      _buildDetailRow(context, 'ID Localização:', productComplete.location?.locationId),
                    ],
                  ),
                  _buildExpansionTile(
                    title: 'DIMENSÕES',
                    children: [
                      _buildDetailRow(context, 'Peso Líquido:',       productComplete.invent?.netWeight?.toStringAsFixed(2)),
                      _buildDetailRow(context, 'Tara:',               productComplete.invent?.taraWeight?.toStringAsFixed(2)),
                      _buildDetailRow(context, 'Peso Bruto:',         productComplete.invent?.grossWeight?.toStringAsFixed(2)),
                      _buildDetailRow(context, 'Profundidade Bruta:', productComplete.invent?.grossDepth?.toStringAsFixed(2)),
                      _buildDetailRow(context, 'Largura Bruta:',      productComplete.invent?.grossWidth?.toStringAsFixed(2)),
                      _buildDetailRow(context, 'Altura Bruta:',       productComplete.invent?.grossHeight?.toStringAsFixed(2)),
                      _buildDetailRow(context, 'Volume Unitário:',    productComplete.invent?.unitVolume?.toStringAsFixed(2)),
                      _buildDetailRow(context, 'Volume Unitário ML:', productComplete.invent?.unitVolumeML?.toStringAsFixed(2)),
                      _buildDetailRow(context, 'Número de Itens:',    productComplete.invent?.nrOfItems?.toString()),
                      _buildDetailRow(context, 'Unidade:',            productComplete.invent?.unitId),
                    ],
                  ),
                  _buildExpansionTile(
                    title: 'INFORMAÇÕES FISCAIS',
                    children: [
                      _buildDetailRow(context, 'Origem da Tributação:', productComplete.taxInformation?.taxationOrigin, isFullWidth: true),
                      _buildDetailRow(context, 'Classificação Fiscal:', productComplete.taxInformation?.taxFiscalClassification),
                      _buildDetailRow(context, 'Tipo do Produto:',      productComplete.taxInformation?.productType),
                      _buildDetailRow(context, 'CEST:',                 productComplete.taxInformation?.cestCode),
                      _buildDetailRow(context, 'Grupo Fiscal:',         productComplete.taxInformation?.fiscalGroupId),
                      _buildDetailRow(context, 'Imposto Federal:',      productComplete.taxInformation?.approxTaxValueFederal?.toStringAsFixed(2)),
                      _buildDetailRow(context, 'Imposto Estadual:',     productComplete.taxInformation?.approxTaxValueState?.toStringAsFixed(2)),
                      _buildDetailRow(context, 'Imposto Municipal:',    productComplete.taxInformation?.approxTaxValueCity?.toStringAsFixed(2)),
                    ],
                  ),
                  _buildExpansionTile(
                    title: 'OXFORD',
                    children: [
                      _buildDetailRow(
                        context,
                        'Marca:',
                        '${productComplete.oxford?.brandId} - ${productComplete.oxford?.brandDescription}',
                        isFullWidth: true
                      ),
                      _buildDetailRow(
                        context,
                        'Linha:',
                        '${productComplete.oxford?.lineId} - ${productComplete.oxford?.lineDescription}',
                        isFullWidth: true
                      ),
                      _buildDetailRow(
                        context, 
                        'Decoração:', 
                        '${productComplete.oxford?.decorationId} - ${productComplete.oxford?.decorationDescription}',
                        isFullWidth: true
                      ),
                      _buildDetailRow(
                        context, 
                        'Família:', 
                        '${productComplete.oxford?.familyId} - ${productComplete.oxford?.familyDescription}',
                        isFullWidth: true
                      ),
                      _buildDetailRow(context, 'Tipo:',             productComplete.oxford?.typeId),
                      _buildDetailRow(context, 'Processo:',         productComplete.oxford?.processId),
                      _buildDetailRow(context, 'Situação:',         productComplete.oxford?.situationId),
                      _buildDetailRow(context, 'Qualidade:',        productComplete.oxford?.qualityId),
                      _buildDetailRow(context, 'Produto Base:',     productComplete.oxford?.baseProductId),
                      _buildDetailRow(context, 'Grupo de Produto:', productComplete.oxford?.productGroupId),                      
                      _buildDetailRow(context, 'Descrição Base:',   productComplete.oxford?.baseProductDescription, isFullWidth: true),
                    ],
                  ),
                  _buildTagExpansionTile(productComplete),
                  _buildExpansionTile(
                    title: 'BOM',
                    children: [
                      const Text('Informações de BOM não disponíveis neste momento.',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // widget para a seção de Tags
  Widget _buildTagExpansionTile(ProductComplete productComplete) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        iconTheme: const IconThemeData(size: 36),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: BorderSide.none,
        ),
        child: ExpansionTile(
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          iconColor: Colors.blueGrey,
          collapsedIconColor: Colors.indigo,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
          title: const Text(
            'TAGS',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            const Divider(color: Colors.black12, height: 1, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.indigo,
                  onPressed: () => _showAddTagDialog(productComplete),
                ),
              ],
            ),
            if (productComplete.tags != null && productComplete.tags!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 5.0, // Espaçamento horizontal entre os chips
                  runSpacing: 4.0, // Espaçamento vertical entre as linhas de chips
                  children: productComplete.tags!.map((tag) => _buildTagChip(context,tag)).toList(),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Informações de TAGS não disponíveis neste momento.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // widget para as imagens do produto
  Widget _buildImageCarouselCard({
    required String title,
    required List<ImageBase64> images,
    required String finalidade,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        iconTheme: const IconThemeData(size: 36),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: BorderSide.none,
        ),
        child: ExpansionTile(
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          iconColor: Colors.blueGrey,
          collapsedIconColor: Colors.indigo,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          childrenPadding: EdgeInsets.zero,
          children: [
            const Divider(
              color: Colors.black12,
              height: 1,
              thickness: 1,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                PulseIconButton(
                  icon: Icons.sync_alt_outlined, // Mude para IconData
                  color: Colors.indigo,
                  onPressed: images.isNotEmpty
                      ? () => _showReorderImagesDialog(images, finalidade)
                      : () {}, // Desabilita se não houver imagens
                ),
                PulseIconButton(
                  icon: Icons.add_a_photo,
                  color: Colors.indigo,
                  onPressed: () => _showAddImageOptions(finalidade), // Sempre habilitado
                ),
                PulseIconButton(
                  icon: Icons.delete_forever,
                  color: Colors.indigo,
                  onPressed: images.isNotEmpty
                      ? () => _deleteImageConfirm(images, finalidade)
                      : () {}, // Desabilita se não houver imagens
                ),
              ],
            ),
            // Conteúdo abaixo dos botões
            images.isNotEmpty
                ? Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      SizedBox(
                        height: 500,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final imageBase64Data = images[index];
                            return FutureBuilder<String?>(
                              future: ImageBase.decodeAndExtractSingleImage(
                                  imageBase64Data.imagesBase64),
                              builder: (context, imageSnapshot) {
                                if (imageSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2));
                                } else if (imageSnapshot.hasData &&
                                    imageSnapshot.data != null) {
                                  final String dataUri = imageSnapshot.data!;
                                  final String base64Image =
                                      dataUri.split(',').last;
                                  return Image.memory(
                                    base64Decode(base64Image),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image, size: 150),
                                  );
                                } else {
                                  return const Icon(Icons.image_not_supported,
                                      size: 150, color: Colors.grey);
                                }
                              },
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          child: Row(
                            children: List.generate(
                              images.length,
                              (index) => Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  height: 3,
                                  color: _currentPage >= index
                                      ? Colors.blueAccent
                                      : Colors.grey.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Nenhuma imagem disponível.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // widget para a itens das Tags
  Widget _buildTagChip(BuildContext context, ProductTagModel tag) {
    return Chip(
      label: Text(tag.valueTag),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: () => _deleteSingleTag(context, tag),
      backgroundColor: Colors.blueGrey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  // widget para card padrão
  Widget _buildExpansionTile({required String title, required List<Widget> children}) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        iconTheme: const IconThemeData(size: 36),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: BorderSide.none,
        ),
        child: ExpansionTile(
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          iconColor: Colors.blueGrey,
          collapsedIconColor: Colors.indigo,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: children.isNotEmpty
              ? [
                  const Divider(
                    color: Colors.black12,
                    height: 1,
                    thickness: 1,
                  ),
                  ...children,
                ]
              : const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Nenhuma informação disponível.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
        ),
      ),
    );
  }

  // widget para mostrar os detalhes
  Widget _buildDetailRow(
      BuildContext context,
      String label,
      String? value, {
      bool isFullWidth = false,
  }) {
    final theme = Theme.of(context);
    final content = isFullWidth
        ? SizedBox(
            width: double.infinity, // Faz o Column ocupar a largura total
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.left,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value ?? 'N/A',
                  textAlign: TextAlign.left,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value ?? 'N/A',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: content,
    );
  }

  Future<void> _showReorderImagesDialog(List<ImageBase64> currentImages, String finalidade) async {
    final loadingService = context.read<LoadingService>();
    if (currentImages.isEmpty) {
      return;
    }

    List<DecodedImage> tempImages = [];
    for (var imageBase64 in currentImages) {
      final imageData = imageBase64.imagesBase64;
      final dataUri = await ImageBase.decodeAndExtractSingleImage(imageData);
      if (dataUri != null) {
        final base64Image = dataUri.split(',').last;
        tempImages.add(DecodedImage(
          originalImage: imageBase64,
          bytes: base64Decode(base64Image),
        ));
      }
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Reordenar Imagens de $finalidade'),
              contentPadding: EdgeInsets.zero,
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  itemCount: tempImages.length,
                  onReorder: (int oldIndex, int newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final item = tempImages.removeAt(oldIndex);
                      tempImages.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      key: ValueKey(tempImages[index].originalImage.imagePath),
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.memory(
                              tempImages[index].bytes,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            'Imagem ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                          ),
                          trailing: const Icon(
                            Icons.drag_handle,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Salvar'),
                  onPressed: () async {
                    await CallAction.run(
                      action: () async {
                        loadingService.show();
                        final newOrder = tempImages.map((e) => e.originalImage).toList();
                        await _handleImageReorderBase64(newOrder, finalidade);
                      },
                      onFinally: () {
                        loadingService.hide();
                        Navigator.of(dialogContext).pop();
                      },
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleImageReorderBase64(
      List<ImageBase64> newOrder,
      String finalidade,
  ) async {
    final productService = context.read<ProductService>();

      // Converte a lista de ImageBase64 em uma lista de strings Base64
      final List<String> base64Images = newOrder
          .map((image) => image.imagesBase64!)
          .where((base64String) => base64String.isNotEmpty)
          .toList();

      // Chama o método de upload com a lista de strings Base64
      await productService.uploadProductImagesBase64(
        widget.productId,
        finalidade,
        base64Images, // Passa a lista de Base64
      );

      // Depois de salvar o reorder, chamar o método que atualiza a imagem na lista de pesquisa.
      final updatedProduct = productService.productComplete;
      if (updatedProduct != null) {
        // Chama o método para atualizar a  na SearchProductsPage
        productService.updateSingleProductModel(updatedProduct);
      }

      MessageService.showSuccess("Operação concluída com sucesso!");
  }

  Future<void> _deleteImageConfirm(List<ImageBase64> images, String finalidade) async {
    final loadingService = context.read<LoadingService>();
    if (images.isEmpty) {
      return;
    }
    final imageToDelete = images[_currentPage];
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Excluir Imagem de $finalidade'),
          content: const Text('Tem certeza de que deseja excluir a imagem selecionada?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await CallAction.run(
                  action: () async {
                    loadingService.show();
                    await _handleImageDelete(finalidade, imageToDelete.imagePath!);
                  },
                  onFinally: () {
                    loadingService.hide();
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleImageDelete(String finalidade, String imagePath) async {
    final productService = context.read<ProductService>();
    // Remove a imagem do ProductComplete localmente.
    final productComplete = productService.productComplete;
    if (productComplete != null && productComplete.images != null) {
      productComplete.images!.removeWhere((img) => img.imagePath == imagePath && img.finalidade == finalidade);
    }

    // Obtém a lista de imagens que restaram para a finalidade.
    final List<ImageBase64> remainingImages = productComplete?.images
            ?.where((img) => img.finalidade == finalidade)
            .toList() ??
        [];

    // Converte a lista de ImageBase64 em uma lista de strings Base64.
    final List<String> base64Images = remainingImages
        .map((image) => image.imagesBase64!)
        .where((base64String) => base64String.isNotEmpty)
        .toList();

    // Chama o método de upload para reenviar a lista de imagens restantes.
    await productService.uploadProductImagesBase64(
      widget.productId,
      finalidade,
      base64Images,
    );
    MessageService.showSuccess("Operação concluída com sucesso!");

    // Ajusta a posição do carrossel na UI.
    if (remainingImages.isNotEmpty) {
      final newIndex = _currentPage > 0 ? _currentPage - 1 : 0;
      _pageController.jumpToPage(newIndex);
    } else {
      setState(() {
        _currentPage = 0;
      });
    }
    
    MessageService.showSuccess("Imagem excluída com sucesso!");
  }

  Future<void> _addImagesFromSource(String finalidade, [ImageSource? source]) async {
    if (source == null) {
      source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext dialogContext) {
          return SimpleDialog(
            title: const Text('Adicionar Imagem'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, ImageSource.camera),
                child: const Text('Tirar foto com a Câmera'),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, ImageSource.gallery),
                child: const Text('Escolher da Galeria'),
              ),
            ],
          );
        },
      );
      if (source == null) return;
    }

    final ImagePicker picker = ImagePicker();

    if (source == ImageSource.camera) {
      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        await _addNewImageToCarousel(pickedFile, finalidade);
      }
    } else {
      final List<XFile> pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        for (var file in pickedFiles) {
          // Itera sobre as imagens selecionadas e as adiciona ao carrossel
          await _addNewImageToCarousel(file, finalidade);
        }
      }
    }
  }

  Future<void> _addNewImageToCarousel(XFile file, String finalidade) async {
    final productService = context.read<ProductService>();
    final _FormatHint hint;

    final existingImagesForFinality = productService.productComplete?.images
        ?.where((img) => img.finalidade == finalidade)
        .toList() ?? [];

    final List<String> allImagesInOriginalFormat = [];

    for (final img in existingImagesForFinality) {
      final b64 = img.imagesBase64;
      if (b64 != null && b64.isNotEmpty) {
        allImagesInOriginalFormat.add(b64);
      }
    }

    if(allImagesInOriginalFormat.isEmpty)
    {
      hint = _FormatHint(
        isZipped: true,
        dataHeader: null,
      );
    }
    else
    {
      hint = _detectFormatHint(allImagesInOriginalFormat);
    }

    // Lê os bytes originais da nova imagem.
    final Uint8List originalBytes = await file.readAsBytes();
    
    // Decodifica os bytes para um objeto Image.
    final img.Image? decodedImage = img.decodeImage(originalBytes);

    if (decodedImage == null) {
      throw Exception('Não foi possível decodificar a imagem para redimensionar.');
    }

    // Redimensiona para caber dentro de 300x300, mantendo a proporção.
    final img.Image resizedImage = img.copyResize(
      decodedImage,
      width: 300,
      height: 300,
      // Mantém a proporção e preenche o espaço extra, se necessário.
      interpolation: img.Interpolation.linear,
    );

    /*
    Converte a imagem redimensionada de volta para bytes.
    Usamos encodeJpg para garantir um formato e qualidade consistentes.
    */
    final Uint8List resizedBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));

    // Converte a imagem redimensionada para o mesmo padrão da API.
    final String newImageEncoded = await _encodeMatchingExistingFormat(resizedBytes, hint);

    // Adiciona a nova imagem na lista final.
    allImagesInOriginalFormat.add(newImageEncoded);

    // Envia para a API.
    await productService.uploadProductImagesBase64(
      widget.productId,
      finalidade,
      allImagesInOriginalFormat,
    );
    MessageService.showSuccess("Operação concluída com sucesso!");
  }

  /// Detecta a partir das imagens existentes, se a API espera ZIP para replicar o padrão na nova imagem.
  _FormatHint _detectFormatHint(List<String> existing) {
    if (existing.isEmpty) {
      // Sem referência: default para "imagem sem header, não zipada".
      return const _FormatHint(isZipped: false, dataHeader: null);
    }

    // Pega a primeira não vazia.
    final sample = existing.firstWhere((s) => s.isNotEmpty, orElse: () => '');

    // Preserva o header data se existir.
    String? header;
    String payload = sample;
    final commaIdx = sample.indexOf(',');
    if (commaIdx > 0 && sample.startsWith('data:')) {
      header = sample.substring(0, commaIdx + 1);
      payload = sample.substring(commaIdx + 1);
    }

    // Verifica se é ZIP (base64 de "PK" começa com "UEs").
    final bool zipped = payload.startsWith('UEs');

    return _FormatHint(isZipped: zipped, dataHeader: header);
  }

  /// Converte os bytes da nova imagem para o mesmo padrão das existentes.
  Future<String> _encodeMatchingExistingFormat(Uint8List bytes, _FormatHint hint) async {
    String payloadB64;

    if (hint.isZipped) {
      // Cria um zip com um arquivo único (nome genérico, backend normalmente ignora o nome). em base64
      final archive = Archive()
        ..addFile(ArchiveFile('image.bin', bytes.length, bytes));
      final zipBytes = ZipEncoder().encode(archive)!;
      payloadB64 = base64Encode(zipBytes);
    } else {
      payloadB64 = base64Encode(bytes); // Imagem crua em base64.
    }

    // Preserva o mesmo header se existir.
    if (hint.dataHeader != null) {
      return '${hint.dataHeader}$payloadB64';
    }
    return payloadB64;
  }

  Future<void> _showAddImageOptions(String finalidade) async {
    final loadingService = context.read<LoadingService>();
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: Text('Adicionar Imagem ($finalidade)'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                CallAction.run(
                  action: () async {
                    loadingService.show();
                    await _addImagesFromSource(finalidade, ImageSource.camera);
                  },
                  onFinally: () {
                    loadingService.hide();
                  },
                );
              },
              child: const Text('Tirar foto com a Câmera'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                CallAction.run(
                  action: () async {
                    loadingService.show();
                    await _addImagesFromSource(finalidade, ImageSource.gallery);
                  },
                  onFinally: () {
                    loadingService.hide();
                  },
                );
              },
              child: const Text('Escolher da Galeria'),
            ),
          ],
        );
      },
    );
  }

  /// Para adicionar nova Tag
  void _showAddTagDialog(ProductComplete productComplete) {
    _tagController.clear();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            children: [
              const Icon(Icons.label_important_rounded,
                  color: Colors.blueAccent, size: 28),
              const SizedBox(width: 8),
              const Text(
                'Adicionar Nova TAG',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: _tagController,
            decoration: InputDecoration(
              hintText: "Digite a tag",
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancelar', style: TextStyle(color: Colors.black87)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Adicionar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                if (_tagController.text.isNotEmpty) {
                  await CallAction.run(
                    action: () async {
                      _handleAddTag(productComplete, _tagController.text);
                    },
                    onFinally: () {
                      Navigator.of(dialogContext).pop();
                    },
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _handleAddTag(ProductComplete productComplete, String valueTag) async {
    final productService = context.read<ProductService>();
    
    // Cria nova lista de tags com a tag atualizada e a nova
    // A classe TagModel espelha a estrutura da API
    final newTag = ProductTagModel(productId: productComplete.product!.productId!, valueTag: valueTag);
    
    // Pega a lista de tags atual do produto senão cria uma lista vazia
    final List<ProductTagModel> tagsToSend = productComplete.tags ?? [];
    tagsToSend.add(newTag);

    await productService.updateTags(tagsToSend);
  }

  void _deleteSingleTag(BuildContext context, ProductTagModel tag) {
    final loadingService = context.read<LoadingService>();
    showConfirmDelete( // Chama a função auxiliar para mostrar o diálogo
      context: context,
      message: 'Tem certeza de que deseja excluir a tag "${tag.valueTag}"?',
      onConfirm: () async {
        await CallAction.run(
          action: () async {
            loadingService.show();
            await _handleDeleteTag(tag); // se for Future<void>, coloque await
          },
          onFinally: () {
            loadingService.hide();
          },
        );
      },
    );
  }

  Future<void> _handleDeleteTag(ProductTagModel tag) async {
    final productService = context.read<ProductService>();

    final ProductComplete? productComplete = productService.productComplete;
    if (productComplete != null && productComplete.tags != null) {
      productComplete.tags!.removeWhere((t) => t.valueTag == tag.valueTag);
    }

    // Pega a lista de tags que restaram.
    final List<ProductTagModel> remainingTags = productComplete?.tags ?? [];
    
    // Envia a lista restante para atualizar via API.
    await productService.updateTags(remainingTags);
    MessageService.showSuccess("Tag removida com sucesso!");
  }

}

class DecodedImage {
  final ImageBase64 originalImage;
  final Uint8List bytes;

  DecodedImage({required this.originalImage, required this.bytes});
}

/// Indica como as imagens EXISTENTES estão formatadas.
class _FormatHint {
  final bool isZipped;          // se o conteúdo base64 é um ZIP (PK => "UEs...")
  final String? dataHeader;     // "data:application/zip;base64," ou "data:image/jpeg;base64," etc (se houver)
  const _FormatHint({required this.isZipped, required this.dataHeader});
}