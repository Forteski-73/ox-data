import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/product_complete.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/product_service.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:marquee/marquee.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ProductPage extends StatefulWidget {
  final String productId;

  const ProductPage({super.key, required this.productId});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  // PageController para o carrossel de imagens
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<ImageBase64>? _reorderableImages; // A lista que será reordenada
  final ImagePicker _picker = ImagePicker();

  // Função para decodificar e extrair imagens de um ZIP Base64
  String _getContentType(String fileName) {
    if (fileName.endsWith('.png')) {
      return 'image/png';
    } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      return 'image/jpeg';
    } else if (fileName.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'application/octet-stream';
  }

  Future<String?> _decodeAndExtractSingleImage(String? imageZipBase64) async {
    if (imageZipBase64 == null || imageZipBase64.isEmpty) {
      debugPrint('imageZipBase64 é nulo ou vazio, não há imagem para decodificar.');
      return null;
    }

    try {
      final Uint8List zipBytes = base64Decode(imageZipBase64);
      final Archive archive = ZipDecoder().decodeBytes(zipBytes);

      final file = archive.firstWhere((f) =>
          f.isFile &&
          (f.name.endsWith('.png') ||
              f.name.endsWith('.jpg') ||
              f.name.endsWith('.jpeg')));

      final Uint8List imageBytes = Uint8List.fromList(file.content as List<int>);
      final String base64Image = base64Encode(imageBytes);
      final String contentType = _getContentType(file.name);
      final String dataUri = 'data:$contentType;base64,$base64Image';
      return dataUri;
    } on FormatException catch (e) {
      debugPrint('Erro de formato ao decodificar Base64 ou ZIP: $e');
      return null;
    } on StateError {
      debugPrint('Nenhuma imagem válida encontrada no ZIP.');
      return null;
    } on Exception catch (e) {
      debugPrint('Erro inesperado ao decodificar ou extrair imagem do ZIP: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productService = context.read<ProductService>();
      await context.read<ProductService>().fetchProductComplete(widget.productId);
      // Inicializa a lista de imagens reordenável
      setState(() {
        _reorderableImages = productService.productComplete?.images;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título do Produto
                  Container(
                    height: 34,
                    color: Colors.grey[200],
                    child: Marquee(
                      text: ' ${productComplete.product?.productId ?? ''}  -  ${productComplete.product?.productName ?? 
                        'Nome do Produto Não Disponível'}',
                      style: const TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold
                      ),
                      blankSpace: 40.0, // Espaço entre o final do texto e o início do próximo ciclo
                      velocity: 50.0, // Velocidade de rolagem (quanto maior, mais rápido)
                      pauseAfterRound: const Duration(seconds: 1), // Pausa entre os ciclos
                      startPadding: 16.0, // Espaçamento inicial
                      fadingEdgeStartFraction: 0.1, // Efeito de fade no início da rolagem
                      fadingEdgeEndFraction: 0.1, // Efeito de fade no final da rolagem
                    ),
                  ),
                  const SizedBox(height: 0),

                  _buildExpansionImg(
                    title: 'PRODUTO',
                    children: [
                      if (productComplete.images != null && productComplete.images!.isNotEmpty)

                        Column(
                          children: [
                            const Divider(
                              color: Colors.black12, // Cor cinza clara, quase transparente
                              height: 1,          // Espaço total que a divisória ocupa verticalmente
                              thickness: 1,        // Espessura da linha
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround, // Distribui o espaço entre os ícones
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.sync_alt_outlined,),
                                  color: Colors.indigo,
                                  onPressed: () {
                                    // TODO: Lógica para reordenar as imagens
                                    _showReorderImagesDialog();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_a_photo),
                                  color: Colors.indigo,
                                  onPressed: () {
                                    _showAddImageOptions();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever),
                                  color: Colors.indigo,
                                  onPressed: () {
                                    // TODO: Lógica para excluir a imagem atual
                                  },
                                ),
                              ],
                            ),
                            // Use o Stack para sobrepor a imagem e os pontos
                            Stack(
                              alignment: Alignment.bottomCenter, // Alinha os filhos na parte inferior central
                              children: [
                                SizedBox(
                                  height: 500,
                                  child: PageView.builder(
                                    controller: _pageController,
                                    itemCount: productComplete.images!.length,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentPage = index;
                                      });
                                    },
                                    itemBuilder: (context, index) {
                                      final imageBase64Data = productComplete.images![index];
                                      return FutureBuilder<String?>(
                                        future: _decodeAndExtractSingleImage(imageBase64Data.imagesBase64),
                                        builder: (context, imageSnapshot) {
                                          if (imageSnapshot.connectionState == ConnectionState.waiting) {
                                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                          } else if (imageSnapshot.hasData && imageSnapshot.data != null) {
                                            final String dataUri = imageSnapshot.data!;
                                            final String base64Image = dataUri.split(',').last;
                                            return Image.memory(
                                              base64Decode(base64Image),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 150),
                                            );
                                          } else {
                                            return const Icon(Icons.image_not_supported, size: 150, color: Colors.grey);
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),

                                // Indicador de Linha (Barra de Progresso)
                                Positioned (
                                  bottom: 0, // Encosta no fundo do carrossel
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 3, // Altura da barra
                                    margin: const EdgeInsets.symmetric(horizontal: 0),
                                    child: Row(
                                      children: List.generate(
                                        productComplete.images!.length,
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

                            // Remove o SizedBox(height: 8) e SizedBox(height: 0) que estavam fora
                            // e o SizedBox(height: 16) da sua implementação anterior.
                          ],
                        )
                      else
                        const Center(child: Text('Nenhuma imagem disponível.', style: TextStyle(fontStyle: FontStyle.italic))),
                    ],
                  ),
                  
                  // Seções Expansíveis
                  _buildExpansionTile(
                    title: 'EMBALAGEM',
                    children: [
                      const Text('Não foram encontradas imagens de embalagem.', style: TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                  _buildExpansionTile(
                    title: 'PALETIZAÇÃO',
                    children: [
                      const Text('Não foram encontradas imagens de paletização.', style: TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                  _buildExpansionTile(
                    title: 'INFORMAÇÕES DO PRODUTO',
                    children: [
                      _buildDetailRow('Cód. Barras:',    productComplete.product?.barcode),
                      _buildDetailRow('Código:',         productComplete.product?.productId),
                      _buildDetailRow('Status:',         productComplete.product?.status == true ? 'Ativo' : 'Inativo'),
                      _buildDetailRow('Nome:',           productComplete.product?.productName),
                      _buildDetailRow('Preço:',          productComplete.location?.price?.toStringAsFixed(2)),
                      _buildDetailRow('Quantidade:',     productComplete.location?.quantity?.toStringAsFixed(0)),
                      _buildDetailRow('ID Localização:', productComplete.location?.locationId),
                    ],
                  ),
                  _buildExpansionTile(
                    title: 'DIMENSÕES',
                    children: [
                      _buildDetailRow('Peso Líquido:',       productComplete.invent?.netWeight?.toStringAsFixed(2)),
                      _buildDetailRow('Tara:',               productComplete.invent?.taraWeight?.toStringAsFixed(2)),
                      _buildDetailRow('Peso Bruto:',         productComplete.invent?.grossWeight?.toStringAsFixed(2)),
                      _buildDetailRow('Profundidade Bruta:', productComplete.invent?.grossDepth?.toStringAsFixed(2)),
                      _buildDetailRow('Largura Bruta:',      productComplete.invent?.grossWidth?.toStringAsFixed(2)),
                      _buildDetailRow('Altura Bruta:',       productComplete.invent?.grossHeight?.toStringAsFixed(2)),
                      _buildDetailRow('Volume Unitário:',    productComplete.invent?.unitVolume?.toStringAsFixed(2)),
                      _buildDetailRow('Volume Unitário ML:', productComplete.invent?.unitVolumeML?.toStringAsFixed(2)),
                      _buildDetailRow('Número de Itens:',    productComplete.invent?.nrOfItems?.toString()),
                      _buildDetailRow('Unidade:',            productComplete.invent?.unitId),
                    ],
                  ),
                  _buildExpansionTile(
                    title: 'INFORMAÇÕES FISCAIS',
                    children: [
                      _buildDetailRow('NCM:',           productComplete.taxInformation?.ncm),
                      _buildDetailRow('CEST:',          productComplete.taxInformation?.cest),
                      _buildDetailRow('Tipo de Item:',  productComplete.taxInformation?.itemType),
                      _buildDetailRow('Origem:',        productComplete.taxInformation?.origin),
                      _buildDetailRow('Grupo de Imposto:',       productComplete.taxInformation?.taxGroup),
                      _buildDetailRow('Cód. Imposto Venda:',     productComplete.taxInformation?.salesTaxCode),
                      _buildDetailRow('Cód. Imposto Compra:',    productComplete.taxInformation?.purchaseTaxCode),
                      _buildDetailRow('Cód. Imposto Devolução:', productComplete.taxInformation?.returnTaxCode),
                    ],
                  ),
                  _buildExpansionTile(
                    title: 'OXFORD', // Se houver outros detalhes específicos de Oxford não cobertos
                    children: [
                      _buildDetailRow('Marca:',     productComplete.oxford?.brandId),
                      _buildDetailRow('Linha:',     productComplete.oxford?.lineId),
                      _buildDetailRow('Decoração:', productComplete.oxford?.decorationId),
                      _buildDetailRow('Tipo:',      productComplete.oxford?.typeId),
                      _buildDetailRow('Processo:',  productComplete.oxford?.processId),
                      _buildDetailRow('Situação:',  productComplete.oxford?.situationId),
                      _buildDetailRow('Qualidade:', productComplete.oxford?.qualityId),
                      _buildDetailRow('Produto Base:',     productComplete.oxford?.baseProductId),
                      _buildDetailRow('Grupo de Produto:', productComplete.oxford?.productGroupId),

                      _buildDetailRow('Marca:',     productComplete.oxford?.brandDescription),
                      _buildDetailRow('Linha:',     productComplete.oxford?.lineDescription),
                      _buildDetailRow('Decoração:', productComplete.oxford?.decorationDescription),
                      _buildDetailRow('Família:',   productComplete.oxford?.familyDescription),
                      _buildDetailRow('Descrição Base:', productComplete.oxford?.baseProductDescription),
                    ],
                  ),
                  _buildExpansionTile(
                    title: 'BOM', // Bill of Materials - Adicione aqui se tiver dados de BOM
                    children: [
                      const Text('Informações de BOM não disponíveis neste momento.', style: TextStyle(fontStyle: FontStyle.italic)),
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

  // Widget auxiliar para criar os ExpansionTile
  Widget _buildExpansionTile({required String title, required List<Widget> children}) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent, // sem linha divisória
        iconTheme: const IconThemeData(size: 36), // aumenta tamanho do ícone da seta
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
          iconColor: Colors.blueGrey, // cor seta expandido (opcional)
          collapsedIconColor: Colors.indigo, // cor seta recolhido (opcional)
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: children.isNotEmpty
            ? [
                const Divider(
                  color: Colors.black12, // Cor cinza clara, quase transparente
                  height: 1,
                  thickness: 1,
                ),
                ...children, // Operador spread para adicionar o restante dos children
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

  
  // Widget auxiliar para criar os ExpansionTile img
  Widget _buildExpansionImg({required String title, required List<Widget> children}) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent, // tira a linha do ExpansionTile
        iconTheme: const IconThemeData(size: 36), // aumenta o tamanho da flecha
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
          iconColor: Colors.blueGrey, // cor quando expandido
          collapsedIconColor: Colors.indigo, // cor quando fechado
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          childrenPadding: EdgeInsets.zero,
          children: children.isNotEmpty
              ? children
              : [
                  const Padding(
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

  // Widget auxiliar para criar linhas de detalhe
  Widget _buildDetailRow(String label, String? value) {
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

  Future<void> _showReorderImagesDialog() async {
    if (_reorderableImages == null || _reorderableImages!.isEmpty) {
      return;
    }

    // Pré-decodifique todas as imagens
    List<DecodedImage> tempImages = [];
    for (var imageBase64 in _reorderableImages!) {
      final imageData = imageBase64.imagesBase64;
      final dataUri = await _decodeAndExtractSingleImage(imageData);
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
              title: const Text('Reordenar Imagens'),
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
                        elevation: 4.0, // Adiciona uma sombra para o efeito de "cartão"
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0), // Cantos mais arredondados
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0), // Cantos arredondados na imagem
                            child: Image.memory(
                              tempImages[index].bytes,
                              width: 60, // Aumenta o tamanho da imagem para melhor visualização
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
                            color: Colors.grey, // Cor suave para o ícone
                          ),
                          // Você pode adicionar um subtítulo aqui se quiser mais informações
                          // subtitle: Text('Posição original: ${tempImages[index].originalImage.sequence}'),
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
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Salvar'),
                  onPressed: () {
                    setState(() {
                      _reorderableImages = tempImages.map((e) => e.originalImage).toList();
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addImagesFromSource(ImageSource source) async {
    try {
      List<XFile> pickedFiles = [];
      if (source == ImageSource.camera) {
        final XFile? file = await _picker.pickImage(source: source);
        if (file != null) {
          pickedFiles.add(file);
        }
      } else { // galeria
        pickedFiles = await _picker.pickMultiImage();
      }

      if (pickedFiles.isEmpty) {
        return;
      }

      final List<ImageBase64> newImages = [];
      final uuid = Uuid();

      for (var file in pickedFiles) {
        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);
        final uniqueFileName = uuid.v4();
        final fileExtension = path.extension(file.path);
        
        // Cria uma nova instância de ImageBase64 (seu modelo)
        final newImage = ImageBase64(
          imagePath: uniqueFileName + fileExtension, // Use um nome de arquivo único
          imagesBase64: base64Image,
          // Sequência será definida após a inserção na lista
          sequence: 0, 
        );
        newImages.add(newImage);
      }
      
      // Atualiza a lista principal com as novas imagens
      setState(() {
        if (_reorderableImages == null) {
          _reorderableImages = [];
        }
        _reorderableImages!.addAll(newImages);
        // Aqui você pode reordenar as sequências se necessário
        _reorderableImages!.asMap().forEach((index, img) => img.sequence = index + 1);
      });

    } catch (e) {
      debugPrint('Erro ao adicionar imagem: $e');
    }
  }

  Future<void> _showAddImageOptions() async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: const Text('Adicionar Imagem'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                _addImagesFromSource(ImageSource.camera);
              },
              child: const Text('Tirar foto com a Câmera'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                _addImagesFromSource(ImageSource.gallery);
              },
              child: const Text('Escolher da Galeria'),
            ),
          ],
        );
      },
    );
  }

}

// Adicione essa classe para armazenar os dados decodificados
class DecodedImage {
  final ImageBase64 originalImage;
  final Uint8List bytes;

  DecodedImage({required this.originalImage, required this.bytes});
}
