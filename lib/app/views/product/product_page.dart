import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/product_complete.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/product_service.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:marquee/marquee.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oxdata/app/core/utils/image_base.dart';
import 'package:oxdata/app/core/utils/logger.dart';
import 'package:archive/archive.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;

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

            final productImages = productComplete.images?.where((img) => img.finalidade == 'PRODUTO').toList() ?? [];
            final packagingImages = productComplete.images?.where((img) => img.finalidade == 'EMBALAGEM').toList() ?? [];
            final palletizationImages = productComplete.images?.where((img) => img.finalidade == 'PALETIZACAO').toList() ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 34,
                    color: Colors.grey[200],
                    child: Marquee(
                      text:
                          ' ${productComplete.product?.productId ?? ''}  -  ${productComplete.product?.productName ?? 'Nome do Produto Não Disponível'}',
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
                      _buildDetailRow('Cód. Barras:', productComplete.product?.barcode),
                      _buildDetailRow('Código:', productComplete.product?.productId),
                      _buildDetailRow('Status:', productComplete.product?.status == true ? 'Ativo' : 'Inativo'),
                      _buildDetailRow('Nome:', productComplete.product?.productName),
                      _buildDetailRow('Preço:', productComplete.location?.price?.toStringAsFixed(2)),
                      _buildDetailRow('Quantidade:', productComplete.location?.quantity?.toStringAsFixed(0)),
                      _buildDetailRow('ID Localização:', productComplete.location?.locationId),
                    ],
                  ),
                  _buildExpansionTile(
                    title: 'DIMENSÕES',
                    children: [
                      _buildDetailRow('Peso Líquido:', productComplete.invent?.netWeight?.toStringAsFixed(2)),
                      _buildDetailRow('Tara:', productComplete.invent?.taraWeight?.toStringAsFixed(2)),
                      _buildDetailRow('Peso Bruto:', productComplete.invent?.grossWeight?.toStringAsFixed(2)),
                      _buildDetailRow('Profundidade Bruta:', productComplete.invent?.grossDepth?.toStringAsFixed(2)),
                      _buildDetailRow('Largura Bruta:', productComplete.invent?.grossWidth?.toStringAsFixed(2)),
                      _buildDetailRow('Altura Bruta:', productComplete.invent?.grossHeight?.toStringAsFixed(2)),
                      _buildDetailRow('Volume Unitário:', productComplete.invent?.unitVolume?.toStringAsFixed(2)),
                      _buildDetailRow('Volume Unitário ML:', productComplete.invent?.unitVolumeML?.toStringAsFixed(2)),
                      _buildDetailRow('Número de Itens:', productComplete.invent?.nrOfItems?.toString()),
                      _buildDetailRow('Unidade:', productComplete.invent?.unitId),
                    ],
                  ),
                  _buildExpansionTile(
                    title: 'INFORMAÇÕES FISCAIS',
                    children: [
                      _buildDetailRow('Origem da Tributação:', productComplete.taxInformation?.taxationOrigin),
                      _buildDetailRow('Classificação Fiscal:', productComplete.taxInformation?.taxFiscalClassification),
                      _buildDetailRow('Tipo do Produto:', productComplete.taxInformation?.productType),
                      _buildDetailRow('CEST:', productComplete.taxInformation?.cestCode),
                      _buildDetailRow('Grupo Fiscal:', productComplete.taxInformation?.fiscalGroupId),
                      _buildDetailRow('Imposto Federal:', productComplete.taxInformation?.approxTaxValueFederal?.toStringAsFixed(2)),
                      _buildDetailRow('Imposto Estadual:', productComplete.taxInformation?.approxTaxValueState?.toStringAsFixed(2)),
                      _buildDetailRow('Imposto Municipal:', productComplete.taxInformation?.approxTaxValueCity?.toStringAsFixed(2)),
                    ],
                  ),
                  _buildExpansionTile(
                    title: 'OXFORD',
                    children: [
                      _buildDetailRow('Marca:', productComplete.oxford?.brandId),
                      _buildDetailRow('Linha:', productComplete.oxford?.lineId),
                      _buildDetailRow('Decoração:', productComplete.oxford?.decorationId),
                      _buildDetailRow('Tipo:', productComplete.oxford?.typeId),
                      _buildDetailRow('Processo:', productComplete.oxford?.processId),
                      _buildDetailRow('Situação:', productComplete.oxford?.situationId),
                      _buildDetailRow('Qualidade:', productComplete.oxford?.qualityId),
                      _buildDetailRow('Produto Base:', productComplete.oxford?.baseProductId),
                      _buildDetailRow('Grupo de Produto:', productComplete.oxford?.productGroupId),
                      _buildDetailRow('Marca:', productComplete.oxford?.brandDescription),
                      _buildDetailRow('Linha:', productComplete.oxford?.lineDescription),
                      _buildDetailRow('Decoração:', productComplete.oxford?.decorationDescription),
                      _buildDetailRow('Família:', productComplete.oxford?.familyDescription),
                      _buildDetailRow('Descrição Base:', productComplete.oxford?.baseProductDescription),
                    ],
                  ),
                  _buildTagsSection(productComplete),
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

  // Novo widget para a seção de Tags
Widget _buildTagsSection(ProductComplete productComplete) {
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
            mainAxisAlignment: MainAxisAlignment.end,
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
                spacing: 8.0, // Espaçamento horizontal entre os chips
                runSpacing: 4.0, // Espaçamento vertical entre as linhas de chips
                children: productComplete.tags!.map((tag) => _buildTagChip(tag)).toList(),
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

// Adicione este novo widget na sua classe _ProductPageState
Widget _buildTagChip(Tag tag) {
  return Chip(
    label: Text(tag.valueTag),
    deleteIcon: const Icon(Icons.close, size: 18),
    onDeleted: () => _deleteSingleTag(tag),
    backgroundColor: Colors.blueGrey[50],
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  );
}
  // Funções existentes (mantidas para contexto)
  Widget _buildImageCarouselCard({
    required String title,
    required List<ImageBase64> images,
    required String finalidade,
  }) {
    // ... Código existente
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
          children: images.isNotEmpty
              ? [
                  const Divider(
                    color: Colors.black12,
                    height: 1,
                    thickness: 1,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sync_alt_outlined),
                        color: Colors.indigo,
                        onPressed: () => _showReorderImagesDialog(images, finalidade),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_a_photo),
                        color: Colors.indigo,
                        onPressed: () => _showAddImageOptions(finalidade),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever),
                        color: Colors.indigo,
                        onPressed: () => _deleteImageConfirm(images, finalidade),
                      ),
                    ],
                  ),
                  Stack(
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
                                if (imageSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                } else if (imageSnapshot.hasData && imageSnapshot.data != null) {
                                  final String dataUri = imageSnapshot.data!;
                                  final String base64Image = dataUri.split(',').last;
                                  return Image.memory(
                                    base64Decode(base64Image),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image, size: 150),
                                  );
                                } else {
                                  return const Icon(Icons.image_not_supported, size: 150, color: Colors.grey);
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
                                  color: _currentPage >= index ? Colors.blueAccent : Colors.grey.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]
              : [
                  const Padding(
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

  Widget _buildExpansionTile({required String title, required List<Widget> children}) {
    // ... Código existente
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

  Widget _buildDetailRow(String label, String? value) {
    // ... Código existente
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReorderImagesDialog(List<ImageBase64> currentImages, String finalidade) async {
    // ... Código existente
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
                  onPressed: () {
                    final newOrder = tempImages.map((e) => e.originalImage).toList();
                    _handleImageReorderBase64(newOrder, finalidade);
                    Navigator.of(dialogContext).pop();
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
  final loadingService = context.read<LoadingService>();

  loadingService.show();

  try {
    // 1. Converte a lista de ImageBase64 em uma lista de strings Base64
    final List<String> base64Images = newOrder
        .map((image) => image.imagesBase64!)
        .where((base64String) => base64String.isNotEmpty)
        .toList();

    // 2. Chama o método de upload com a lista de strings Base64
    await productService.uploadProductImagesBase64(
      widget.productId,
      finalidade,
      base64Images, // Passando a lista de Base64 extraída
    );

  } on Exception catch (e) {
    debugPrint('Erro ao reordenar e enviar imagens: $e');
  } finally {
    loadingService.hide();
  }
}


  Future<void> _deleteImageConfirm(List<ImageBase64> images, String finalidade) async {
    // ... Código existente
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
              onPressed: () {
                _handleImageDelete(finalidade, imageToDelete.imagePath!);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleImageDelete(String finalidade, String imagePath) async {
    // ... Código existente
    final productService = context.read<ProductService>();
    final loadingService = context.read<LoadingService>();

    loadingService.show();
    await productService.deleteProductImage(widget.productId, imagePath, finalidade);
    loadingService.hide();

    final images = productService.productComplete?.images?.where((img) => img.finalidade == finalidade).toList() ?? [];
    if (images.isNotEmpty) {
      final newIndex = _currentPage > 0 ? _currentPage - 1 : 0;
      _pageController.jumpToPage(newIndex);
    } else {
      setState(() {
        _currentPage = 0;
      });
    }
  }

  Future<void> _addImagesFromSource(String finalidade, [ImageSource? source]) async {
    try {
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
          // Usa o novo método para exibir a imagem no carrossel
          await _addNewImageToCarousel(pickedFile, finalidade);
        }
      } else { // ImageSource.gallery
        final List<XFile> pickedFiles = await picker.pickMultiImage();
        if (pickedFiles.isNotEmpty) {
          for (var file in pickedFiles) {
            // Itera sobre as imagens selecionadas e as adiciona ao carrossel
            await _addNewImageToCarousel(file, finalidade);
          }
        }
      }

    } catch (e) {
      debugPrint('Erro ao adicionar imagem: $e');
    }
  }

  Future<void> _addNewImageToCarousel(XFile file, String finalidade) async {
    final productService = context.read<ProductService>();
    final loadingService = context.read<LoadingService>();

    final existingImagesForFinality = productService.productComplete?.images
        ?.where((img) => img.finalidade == finalidade)
        .toList() ?? [];

    try {
      loadingService.show();

      final List<String> allImagesInOriginalFormat = [];

      for (final img in existingImagesForFinality) {
        final b64 = img.imagesBase64;
        if (b64 != null && b64.isNotEmpty) {
          allImagesInOriginalFormat.add(b64);
        }
      }

      final _FormatHint hint = _detectFormatHint(allImagesInOriginalFormat);

      // --- Nova lógica de redimensionamento aqui ---

      // 4) Lê os bytes originais da nova imagem.
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
        // Você pode ajustar o método de interpolação se desejar.
        interpolation: img.Interpolation.linear,
      );

      // Converte a imagem redimensionada de volta para bytes.
      // Usamos encodeJpg para garantir um formato e qualidade consistentes.
      final Uint8List resizedBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));

      // --- Fim da nova lógica de redimensionamento ---

      // 5) Converte a imagem redimensionada para o mesmo padrão da API.
      final String newImageEncoded = await _encodeMatchingExistingFormat(resizedBytes, hint);

      // 6) Adiciona a nova imagem na lista final.
      allImagesInOriginalFormat.add(newImageEncoded);

      // 7) Envia para a API.
      await productService.uploadProductImagesBase64(
        widget.productId,
        finalidade,
        allImagesInOriginalFormat,
      );
    } catch (e) {
      debugPrint('Erro ao adicionar nova imagem ao carrossel: $e');
    } finally {
      loadingService.hide();
    }
  }

  /*
  Future<void> _addNewImageToCarousel(XFile file, String finalidade) async {
    final productService = context.read<ProductService>();
    final loadingService = context.read<LoadingService>();

    // 1) Coleta as imagens existentes da mesma finalidade (sem mexer no conteúdo).
    final existingImagesForFinality = productService.productComplete?.images
            ?.where((img) => img.finalidade == finalidade)
            .toList() ??
        [];

    try {
      loadingService.show();

      // 2) Lista final no EXATO formato que a API já aceitou antes (mantém headers).
      final List<String> allImagesInOriginalFormat = [];

      // 2.1) Copia as existentes "como estão".
      for (final img in existingImagesForFinality) {
        final b64 = img.imagesBase64;
        if (b64 != null && b64.isNotEmpty) {
          allImagesInOriginalFormat.add(b64);
        }
      }

      // 3) Descobre o padrão esperado a partir de qualquer imagem existente válida.
      final _FormatHint hint = _detectFormatHint(allImagesInOriginalFormat);

      // 4) Lê os bytes da nova imagem.
      final Uint8List newBytes = await file.readAsBytes();

      // 5) Converte a nova imagem para o MESMO padrão (zip ou não, com ou sem header).
      final String newImageEncoded =
          await _encodeMatchingExistingFormat(newBytes, hint);

      // 6) Adiciona a nova imagem na lista final.
      allImagesInOriginalFormat.add(newImageEncoded);

      // 7) Envia para a API exatamente no mesmo padrão aceito no reorder.
      await productService.uploadProductImagesBase64(
        widget.productId,
        finalidade,
        allImagesInOriginalFormat,
      );
    } catch (e) {
      debugPrint('Erro ao adicionar nova imagem ao carrossel: $e');
    } finally {
      loadingService.hide();
    }
  }
  */


  /// Detecta, a partir das imagens existentes, se a API espera ZIP e se há header data:...,
  /// para replicar o padrão na nova imagem.
  _FormatHint _detectFormatHint(List<String> existing) {
    if (existing.isEmpty) {
      // Sem referência: default para "imagem sem header, não zipada".
      return const _FormatHint(isZipped: false, dataHeader: null);
    }

    // Pega a primeira não vazia.
    final sample = existing.firstWhere((s) => s.isNotEmpty, orElse: () => '');

    // Se tiver header data:..., preserva.
    String? header;
    String payload = sample;
    final commaIdx = sample.indexOf(',');
    if (commaIdx > 0 && sample.startsWith('data:')) {
      header = sample.substring(0, commaIdx + 1); // inclui a vírgula
      payload = sample.substring(commaIdx + 1);
    }

    // Verifica se é ZIP (base64 de "PK" começa com "UEs").
    final bool zipped = payload.startsWith('UEs');

    return _FormatHint(isZipped: zipped, dataHeader: header);
  }

  /// Converte os bytes da nova imagem para o mesmo padrão das existentes.
  /// - Se as existentes forem ZIP: cria um .zip com um único arquivo (image.bin) contendo os bytes.
  /// - Se NÃO forem ZIP: apenas base64Encode dos bytes.
  /// Em ambos os casos, aplica o mesmo header data:... se havia.
  Future<String> _encodeMatchingExistingFormat(Uint8List bytes, _FormatHint hint) async {
    String payloadB64;

    if (hint.isZipped) {
      // Cria um zip com um arquivo único (nome genérico, backend normalmente ignora o nome).
      final archive = Archive()
        ..addFile(ArchiveFile('image.bin', bytes.length, bytes));
      final zipBytes = ZipEncoder().encode(archive)!;
      payloadB64 = base64Encode(zipBytes);
    } else {
      // Apenas a imagem "crua" em base64.
      payloadB64 = base64Encode(bytes);
    }

    // Se as existentes tinham header data:..., preserva o mesmo header.
    if (hint.dataHeader != null) {
      return '${hint.dataHeader}$payloadB64';
    }
    return payloadB64;
  }

  Future<void> _showAddImageOptions(String finalidade) async {
    // ... Código existente
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: Text('Adicionar Imagem ($finalidade)'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                _addImagesFromSource(finalidade, ImageSource.camera);
              },
              child: const Text('Tirar foto com a Câmera'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                _addImagesFromSource(finalidade, ImageSource.gallery);
              },
              child: const Text('Escolher da Galeria'),
            ),
          ],
        );
      },
    );
  }

  // Novos métodos para Tags
  void _showAddTagDialog(ProductComplete productComplete) {
    _tagController.clear();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Adicionar Nova Tag'),
          content: TextField(
            controller: _tagController,
            decoration: const InputDecoration(hintText: "Digite a tag"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Adicionar'),
              onPressed: () {
                if (_tagController.text.isNotEmpty) {
                  _handleAddTag(productComplete.product!.productId!, _tagController.text);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAddTag(String productId, String valueTag) async {
    final productService = context.read<ProductService>();
    final loadingService = context.read<LoadingService>();
    loadingService.show();
    await productService.addTag(productId, valueTag);
    loadingService.hide();
  }

  void _showDeleteTagDialog(List<Tag> tags) {
    if (tags.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Excluir Tag'),
          content: DropdownButtonFormField<Tag>(
            decoration: const InputDecoration(labelText: 'Selecione a tag'),
            items: tags.map<DropdownMenuItem<Tag>>((Tag tag) {
              return DropdownMenuItem<Tag>(
                value: tag,
                child: Text(tag.valueTag),
              );
            }).toList(),
            onChanged: (Tag? newTag) {
              // Ações ao selecionar uma tag.
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            // Note: O botão de excluir é removido daqui e a exclusão é feita por item na lista
          ],
        );
      },
    );
  }
  
  void _deleteSingleTag(Tag tag) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Tem certeza de que deseja excluir a tag "${tag.valueTag}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _handleDeleteTag(tag);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteTag(Tag tag) async {
    final productService = context.read<ProductService>();
    final loadingService = context.read<LoadingService>();
    loadingService.show();
    await productService.deleteTag(tag.productId, tag.id!);
    loadingService.hide();
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