import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/models/product_complete.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/product_service.dart';
import 'package:oxdata/app/core/models/product_tag_model.dart'; 
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/widgets/delete_confirm_dialog.dart';
import 'dart:convert';
import 'package:marquee/marquee.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oxdata/app/core/utils/image_base.dart';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:oxdata/app/core/widgets/pulse_icon.dart';
import 'package:oxdata/app/views/pages/full_screen_image_dialog.dart'; 
import 'package:flutter/foundation.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:oxdata/app/core/models/menu_item_model.dart';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:oxdata/app/core/services/product_packing_service.dart';
import 'package:oxdata/app/core/models/product_packing_bom.dart';
import 'package:oxdata/app/core/models/product_bom_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';

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
  final TextEditingController _packSearchController = TextEditingController();
  final TextEditingController _insertBomItemController = TextEditingController();
  final TextEditingController _insertBomItemQuantityController = TextEditingController();
  int? _insertAfterIndex; // índice após o qual o campo de inserção está aberto
  List<MenuItemModel> _menuOptions = []; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      
      final packingService = context.read<ProductPackingService>();
      await Future.wait([
        context.read<ProductService>().fetchProductComplete(widget.productId),
        packingService.fetchAllPackings(),
        packingService.fetchPackingBom(widget.productId),
      ]);
    });
    _loadUserData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tagController.dispose();
    _packSearchController.dispose();
    _insertBomItemController.dispose();
    _insertBomItemQuantityController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final storage = StorageService();

    final menus = await storage.readMenus();
    final profileId = await storage.readProfileId();

    setState(() {
      _menuOptions = menus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loadingService = context.read<LoadingService>();

    return Scaffold(
      appBar: const AppBarCustom(title: 'Detalhes do Produto'),
      body: SafeArea(
        child: Consumer<ProductService>(
          builder: (context, productService, child) {
            final ProductComplete? productComplete = productService.productComplete;

            if (productComplete == null) {
              loadingService.show();
              return const Center(child: SpinKitThreeBounce(color: Colors.white, size: 30.0),);
            } else {
              loadingService.hide();

              final productImages       = productComplete.images?.where((img) => img.finalidade == 'PRODUTO')     .toList() ?? [];
              final packagingImages     = productComplete.images?.where((img) => img.finalidade == 'EMBALAGEM')   .toList() ?? [];
              final palletizationImages = productComplete.images?.where((img) => img.finalidade == 'PALETIZACAO') .toList() ?? [];
              
              final List<ProductPackingBom> packingBomItems = context.watch<ProductPackingService>().bomItems;

              
              //final productPack = productComplete.pack;

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

                    _buildProductPackCard(
                      title: 'SEQUÊNCIA DE EMBALAGEM',
                      bomItems: packingBomItems,
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
                    _buildBOMExpansionTile(productComplete.bom),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

Widget _buildBOMExpansionTile(List<ProductBomModel>? bom) {
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
          'BOM',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          const Divider(color: Colors.black12, height: 1, thickness: 1),
          if (bom != null && bom.isNotEmpty)
            ..._buildBomItems(bom)
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Informações de BOM não disponíveis neste momento.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    ),
  );
}

List<Widget> _buildBomItems(List<ProductBomModel> bom) {
  final widgets = <Widget>[];

  for (var i = 0; i < bom.length; i++) {
    widgets.add(_buildBomItemTile(bom[i]));
    if (i < bom.length - 1) {
      widgets.add(const Divider(color: Colors.black12, height: 1, thickness: 1));
    }
  }

  return widgets;
}

  Widget _buildBomItemTile(ProductBomModel item) {
    final nomeExibido =
        (item.productName != null && item.productName!.trim().isNotEmpty)
            ? item.productName!
            : '------';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeExibido,
                  style: const TextStyle(fontSize: 14),
                ),
                if (item.productBomId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      'Código: ${item.productBomId}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text(
                  'QTD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.productQty}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
            ],
          ),
        ],
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


  // widget para exibição da lista de BOM (Bill of Materials) do produto
  // O card já é reordenável, e cada divider permite inserir um novo item na posição

  Widget _buildProductPackCard({
    required String title,
    required List<ProductPackingBom> bomItems,
    required String finalidade,
  }) {

    final bool canEdit = _menuOptions.any((m) => m.routeName == 'PRODUTO' && m.isReadOnly == false);
    final loadingService = context.read<LoadingService>();
    final bool isBomLoading = context.watch<ProductPackingService>().isLoading;

    // Garante que a lista exibida esteja ordenada por productSeq
    final List<ProductPackingBom> sortedItems = List.from(bomItems)
      ..sort((a, b) => a.productSeq.compareTo(b.productSeq));

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
                  icon: Icons.backup_table,
                  color: canEdit ? Colors.indigo : Colors.grey.shade400,
                  onPressed: canEdit ? () => _genImageBom(bomItems) : () => null,
                ),

                /*
                PulseIconButton(
                  icon: Icons.playlist_add,
                  color: canEdit ? Colors.indigo : Colors.grey.shade400,
                  onPressed: canEdit ? () => _showAddBomItemOptions(finalidade) : () => null,
                ),
                
                
                PulseIconButton(
                  icon: Icons.delete_forever,
                  color: canEdit ? Colors.indigo : Colors.grey.shade400,
                  onPressed: (canEdit && sortedItems.isNotEmpty)
                      ? () => _deleteBomItemConfirm(sortedItems, finalidade)
                      : () => null,
                ),
                */
              ],
            ),
            
            // Conteúdo abaixo dos botões — reordenável + inserção entre itens
            sortedItems.isNotEmpty ? ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: sortedItems.length,
              buildDefaultDragHandles: canEdit,
              proxyDecorator: (Widget child, int index, Animation<double> animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (BuildContext context, Widget? child) {
                    return Material(
                      elevation: 3.0,
                      color: Colors.transparent,
                      shadowColor: Colors.blue.withAlpha((animation.value * 150).round()),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              onReorder: (int oldIndex, int newIndex) {
                if (!canEdit) return;

                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }

                final List<ProductPackingBom> newOrder = List.from(sortedItems);
                final item = newOrder.removeAt(oldIndex);
                newOrder.insert(newIndex, item);

                _handleBomReorder(newOrder);
              },
              itemBuilder: (context, index) {
                final bomItem = sortedItems[index];

                return Column(
                  key: ValueKey('${bomItem.productBomId}_${bomItem.id}_${bomItem.productSeq}'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Slidable(
                      key: ValueKey('slidable_${bomItem.productBomId}_${bomItem.id}_${bomItem.productSeq}'),
                      enabled: canEdit,
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.15, // largura da área revelada (15% do item)
                        children: [
                        CustomSlidableAction(
                          onPressed: (_) => _confirmDeleteSingleBomItem(sortedItems, bomItem),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Define o tamanho do icone (SlidableAction não da)
                              const Icon(Icons.delete_forever, size: 28), 
                              const SizedBox(height: 4),
                              const Text(
                                'Excluir',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        ],
                      ),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.withOpacity(0.1),
                            child: Text(
                              '${bomItem.productSeq}',
                              style: const TextStyle(
                                color: Colors.indigo,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            bomItem.productName?.isNotEmpty == true
                                ? bomItem.productName!
                                : 'Sem descrição',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            bomItem.productBomId?.isNotEmpty == true
                                ? 'Código: ${bomItem.productBomId}'
                                : 'Sem código vinculado',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'QTD',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${bomItem.productQty}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Divider com "+" no meio, ou campo de inserção expandido
                    if (index < sortedItems.length - 1)
                      _buildInsertBetweenRow(index, sortedItems, finalidade, canEdit),
                  ],
                );
              },
            )
          : isBomLoading ? Builder(
              builder: (_) {
                loadingService.show();
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: SpinKitThreeBounce(color: Colors.indigo, size: 30.0),
                  ),
                );
              },
            )
          : Builder(
              builder: (_) {
                loadingService.hide();
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Nenhum item disponível..',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSingleBomItem(
    List<ProductPackingBom> sortedItems,
    ProductPackingBom item,
  ) {
    //final loadingService = context.read<LoadingService>();

    showConfirmDelete(
      context: context,
      message: 'Tem certeza de que deseja excluir "${item.productName ?? 'este item'}"?',
      onConfirm: () async {
        await CallAction.run(
          action: () async {
            //loadingService.show();
            await _handleDeleteBomItem(sortedItems, item);
          },
          onFinally: () {
            //loadingService.hide();
          },
        );
      },
    );
  }

  /// Divider entre dois itens do BOM com botão "+" central.
  /// Ao clicar, expande os campos de texto para inserir um novo item nessa posição.
  Widget _buildInsertBetweenRow(
    int index,
    List<ProductPackingBom> sortedItems,
    String finalidade,
    bool canEdit,
  ) {
    if (!canEdit) {
      return const Divider(color: Colors.black12, height: 1, thickness: 1);
    }

    final bool isExpanded = _insertAfterIndex == index;

    // Borda arredondada padronizada
    final customBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8), // Altere aqui para deixar mais ou menos redondo
      borderSide: const BorderSide(color: Colors.black26, width: 1),
    );

    // Borda de quando o usuário clica no campo (Foco)
    final customFocusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: isExpanded
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Campo Descrição
                        TextField(
                          controller: _insertBomItemController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Descrição do novo item',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            // Força a borda arredondada em todos os estados:
                            border: customBorder,
                            enabledBorder: customBorder,
                            focusedBorder: customFocusedBorder,
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 8), // Espaço entre os campos
                        // Novo Campo Quantidade
                        TextField(
                          controller: _insertBomItemQuantityController,
                          keyboardType: TextInputType.number, // Teclado numérico para INT
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // Apenas números inteiros
                          ],
                          decoration: InputDecoration(
                            hintText: 'Quantidade',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            // Força a borda arredondada em todos os estados:
                            border: customBorder,
                            enabledBorder: customBorder,
                            focusedBorder: customFocusedBorder,
                          ),
                          onSubmitted: (_) async {
                            //loadingService.show();
                            await _confirmInsertBomItem(index, sortedItems, finalidade);
                            //loadingService.hide();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _confirmInsertBomItem(index, sortedItems, finalidade),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _insertAfterIndex = null;
                        _insertBomItemController.clear();
                        _insertBomItemQuantityController.clear();
                      });
                    },
                  ),
                ],
              ),
            )
          : SizedBox(
              height: 24,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Divider(color: Colors.black12, height: 1, thickness: 1),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        _insertAfterIndex = index;
                        _insertBomItemController.clear();
                        _insertBomItemQuantityController.clear();
                      });
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Colors.indigo,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Divider entre dois itens do BOM com botão "+" central.
  /// Ao clicar, expande um campo de texto para inserir um novo item nessa posição.
  /*
  Widget _buildInsertBetweenRow(
    int index,
    List<ProductPackingBom> sortedItems,
    String finalidade,
    bool canEdit,
  ) {
    if (!canEdit) {
      return const Divider(color: Colors.black12, height: 1, thickness: 1);
    }

    final bool isExpanded = _insertAfterIndex == index;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: isExpanded
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _insertBomItemController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Descrição do novo item',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onSubmitted: (_) => _confirmInsertBomItem(index, sortedItems, finalidade),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _confirmInsertBomItem(index, sortedItems, finalidade),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _insertAfterIndex = null;
                        _insertBomItemController.clear();
                      });
                    },
                  ),
                ],
              ),
            )
          : SizedBox(
              height: 24,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Divider(color: Colors.black12, height: 1, thickness: 1),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        _insertAfterIndex = index;
                        _insertBomItemController.clear();
                      });
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Colors.indigo,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  */

  /// Confirma a inserção do novo item na posição escolhida e readequa a sequência.
  Future<void> _confirmInsertBomItem(
    int afterIndex,
    List<ProductPackingBom> sortedItems,
    String finalidade,
  ) async {
    final text = _insertBomItemController.text.trim();
    if (text.isEmpty) return;

    final qtyText = _insertBomItemQuantityController.text.trim();
    final qty = int.tryParse(qtyText) ?? 1;

    final storage = StorageService();
    final credentials = await storage.readCredentials();
    final username = credentials['username'];

    final newItem = ProductPackingBom(
      productId: widget.productId,
      productName: text,
      productQty: qty,
      productSeq: 0, // recalculado em _handleBomReorder
      updatedUser: username,
    );

    final List<ProductPackingBom> newList = List.from(sortedItems);
    newList.insert(afterIndex + 1, newItem);

    setState(() {
      _insertAfterIndex = null;
      _insertBomItemController.clear();
    });

    await CallAction.run(
      action: () async {
        await _handleBomReorder(newList);
      },
      onFinally: () {
        //loadingService.hide();
      },
    );
  }

  /*
  // widget para exibição da lista de BOM (Bill of Materials) do produto
  // Agora o próprio card já é reordenável (sem precisar abrir um popup)
  Widget _buildProductPackCard({
    required String title,
    required List<ProductPackingBom> bomItems,
    required String finalidade,
  }) {

    final bool canEdit = _menuOptions.any((m) => m.routeName == 'PRODUTO' && m.isReadOnly == false);

    // Garante que a lista exibida esteja ordenada por productSeq
    final List<ProductPackingBom> sortedItems = List.from(bomItems)
      ..sort((a, b) => a.productSeq.compareTo(b.productSeq));

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
                  icon: Icons.playlist_add,
                  color: canEdit ? Colors.indigo : Colors.grey.shade400,
                  onPressed: canEdit ? () => _showAddBomItemOptions(finalidade) : () => null,
                ),

                PulseIconButton(
                  icon: Icons.delete_forever,
                  color: canEdit ? Colors.indigo : Colors.grey.shade400,
                  onPressed: (canEdit && sortedItems.isNotEmpty)
                      ? () => _deleteBomItemConfirm(sortedItems, finalidade)
                      : () => null,
                ),
              ],
            ),

            // Conteúdo abaixo dos botões — agora já reordenável diretamente no card
            sortedItems.isNotEmpty
                ? ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: sortedItems.length,
                    buildDefaultDragHandles: canEdit,
                    proxyDecorator: (Widget child, int index, Animation<double> animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (BuildContext context, Widget? child) {
                          return Material(
                            elevation: 6.0,
                            color: Colors.transparent,
                            shadowColor: Colors.blue.withAlpha((animation.value * 150).round()),
                            child: child,
                          );
                        },
                        child: child,
                      );
                    },
                    onReorder: (int oldIndex, int newIndex) {
                      if (!canEdit) return;

                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }

                      final List<ProductPackingBom> newOrder = List.from(sortedItems);
                      final item = newOrder.removeAt(oldIndex);
                      newOrder.insert(newIndex, item);

                      _handleBomReorder(newOrder);
                    },
                    itemBuilder: (context, index) {
                      final bomItem = sortedItems[index];

                      // Retornamos a Column para agrupar o ListTile + Divider
                      return Column(
                        key: ValueKey('${bomItem.productBomId}_${bomItem.id}_${bomItem.productSeq}'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo.withOpacity(0.1),
                              child: Text(
                                '${bomItem.productSeq}',
                                style: const TextStyle(
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              bomItem.productName?.isNotEmpty == true
                                  ? bomItem.productName!
                                  : 'Sem descrição',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              bomItem.productBomId?.isNotEmpty == true
                                  ? 'Código: ${bomItem.productBomId}'
                                  : 'Sem código vinculado',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 14),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'QTD',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${bomItem.productQty}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Só renderiza o divisor entre os itens. O último não ganha linha embaixo.
                          if (index < sortedItems.length - 1)
                            const Divider(color: Colors.black12, height: 1, thickness: 1),
                        ],
                      );
                    },
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Nenhum item de BOM disponível.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
  */



  // widget para as imagens do produto
  Widget _buildImageCarouselCard({
    required String title,
    required List<ImageBase64> images,
    required String finalidade,
  }) {
    final bool canEdit = _menuOptions.any((m) => m.routeName == 'PRODUTO' && m.isReadOnly == false);
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
                  icon: Icons.sync_alt_outlined,
                  color: Colors.indigo,
                  onPressed: images.isNotEmpty
                      ? () => _showReorderImagesDialog(images, finalidade)
                      : () {},
                ),
                PulseIconButton(
                  icon: Icons.add_a_photo,
                  color: canEdit ? Colors.indigo : Colors.grey.shade400,
                  onPressed: canEdit ? () => _showAddImageOptions(finalidade) : () => null,
                ),

                PulseIconButton(
                  icon: Icons.delete_forever,
                  color: canEdit ? Colors.indigo : Colors.grey.shade400,
                  onPressed: (canEdit && images.isNotEmpty)
                      ? () => _deleteImageConfirm(images, finalidade)
                      : () => null,
                ),
              ],
            ),

            // Conteúdo abaixo dos botões
            images.isNotEmpty
                ? Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      SizedBox(
                        height: 400,
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
                                imageBase64Data.imagesBase64,
                              ),
                              builder: (context, imageSnapshot) {
                                if (imageSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: SpinKitThreeBounce(color: Colors.white, size: 30.0),
                                  );
                                } else if (imageSnapshot.hasData &&
                                    imageSnapshot.data != null) {
                                  final String dataUri = imageSnapshot.data!;
                                  final String base64Image =
                                      dataUri.split(',').last;

                                  return GestureDetector(
                                    onDoubleTap: () {
                                      _openFullScreenImage(base64Image);
                                    },
                                    child: InteractiveViewer(
                                      minScale: 0.8,
                                      maxScale: 4.0,
                                      clipBehavior: Clip.none,
                                      child: Image.memory(
                                        base64Decode(base64Image),
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                          Icons.broken_image,
                                          size: 150,
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return const Icon(
                                    Icons.image_not_supported,
                                    size: 150,
                                    color: Colors.grey,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),

                      // SETA ESQUERDA (APENAS WEB)
                      if (kIsWeb && images.length > 1)
                        Positioned(
                          left: 10,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                if (_currentPage > 0) {
                                  _pageController.previousPage(
                                    duration:
                                        const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chevron_left,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // SETA DIREITA (APENAS WEB)
                      if (kIsWeb && images.length > 1)
                        Positioned(
                          right: 10,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                if (_currentPage < images.length - 1) {
                                  _pageController.nextPage(
                                    duration:
                                        const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // BARRA INDICADORA
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 8,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 0),
                          child: Row(
                            children: List.generate(
                              images.length,
                              (index) => Expanded(
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 300),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _currentPage >= index
                                        ? Colors.blueAccent
                                        : Colors.grey.withOpacity(0.5),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
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

/*
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
    */

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
                proxyDecorator: (Widget child, int index, Animation<double> animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (BuildContext context, Widget? child) {
                      return Material(
                        elevation: 6.0,
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10.0),
                        shadowColor: Colors.blue.withAlpha((animation.value * 150).round()),
                        child: child,
                      );
                    },
                    child: child,
                  );
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

    // Redimensiona para caber dentro de 612x612, mantendo a proporção.
    final img.Image resizedImage = img.copyResize(
      decodedImage,
      width: 640,
      height: 640,
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

  void _openFullScreenImage(String base64Image) {
  Navigator.push(
    context,
    PageRouteBuilder(
      // Transição sem animação para parecer um "pop-up" instantâneo
      pageBuilder: (context, animation, secondaryAnimation) => 
          FullScreenImageDialog(base64Image: base64Image),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      fullscreenDialog: true, // Indica que é um diálogo de tela cheia (opcional)
    ),
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


/* ***************************************** SEQUÊNCIA DE EMBALAGEM ***************************************** */

  /*
  Future<void> _showReorderBomDialog(
    List<ProductPackingBom> currentItems,
    String finalidade,
  ) async {
    final loadingService = context.read<LoadingService>();
    if (currentItems.isEmpty) {
      return;
    }

    // Cópia local para manipular a ordem sem afetar o estado original até salvar
    List<ProductPackingBom> tempItems = List.from(currentItems)
      ..sort((a, b) => a.productSeq.compareTo(b.productSeq));

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Reordenar Sequência de Embalagem'),
              contentPadding: EdgeInsets.zero,
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  itemCount: tempItems.length,
                  onReorder: (int oldIndex, int newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final item = tempItems.removeAt(oldIndex);
                      tempItems.insert(newIndex, item);
                    });
                  },
                  proxyDecorator: (Widget child, int index, Animation<double> animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (BuildContext context, Widget? child) {
                        return Material(
                          elevation: 6.0,
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10.0),
                          shadowColor: Colors.blue.withAlpha((animation.value * 150).round()),
                          child: child,
                        );
                      },
                      child: child,
                    );
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final item = tempItems[index];
                    return Padding(
                      key: ValueKey('${item.productBomId}_${item.id}_$index'),
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.withOpacity(0.1),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.indigo,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            item.productName?.isNotEmpty == true ? item.productName! : 'Sem descrição',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                          ),
                          subtitle: Text(
                            item.productBomId?.isNotEmpty == true
                                ? 'Código: ${item.productBomId} • Qtd: ${item.productQty}'
                                : 'Qtd: ${item.productQty}',
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
                        await _handleBomReorder(tempItems);
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
  */

  Future<void> _handleBomReorder(List<ProductPackingBom> newOrder) async {
    final packingService = context.read<ProductPackingService>();

    // Recalcula o productSeq de acordo com a nova posição na lista
    final List<ProductPackingBom> reorderedItems = [
      for (int i = 0; i < newOrder.length; i++)
        newOrder[i].copyWith(productSeq: i + 1),
    ];

    final response = await packingService.savePackingBom(widget.productId, reorderedItems);

    if (response.success) {
      MessageService.showSuccess("Sequência de embalagem atualizada com sucesso!");
      setState(() {});
    } else {
      MessageService.showSuccess(response.message ?? "Erro ao reordenar sequência.");
    }
  }

  /// Gera a imagem da bom
  Future<void> _genImageBom(List<ProductPackingBom> bomItems) async {
    await _handleBomReorder(bomItems);
  }

  /*
  Future<void> _showAddBomItemOptions(String finalidade) async {
    final loadingService = context.read<LoadingService>();
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');

    return showDialog(
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
              const Icon(Icons.playlist_add, color: Colors.indigo, size: 28),
              const SizedBox(width: 8),
              const Text(
                'Adicionar Item à Sequência',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: 'Código do item (opcional)',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantidade',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Adicionar', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                Navigator.of(dialogContext).pop();
                await CallAction.run(
                  action: () async {
                    loadingService.show();
                    await _handleAddBomItem(
                      codeController.text.trim(),
                      nameController.text.trim(),
                      int.tryParse(qtyController.text.trim()) ?? 1,
                    );
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
  

  Future<void> _handleAddBomItem(String code, String name, int qty) async {
    final packingService = context.read<ProductPackingService>();
    
    final storage = StorageService();
    final credentials = await storage.readCredentials();
    final username = credentials['username'];

    final currentItems = List<ProductPackingBom>.from(packingService.bomItems)
      ..sort((a, b) => a.productSeq.compareTo(b.productSeq));

    final newItem = ProductPackingBom(
      productId: widget.productId,
      productBomId: code.isNotEmpty ? code : null,
      productName: name,
      productQty: qty,
      productSeq: currentItems.length + 1,
      updatedUser: username,
    );

    currentItems.add(newItem);

    final response = await packingService.savePackingBom(widget.productId, currentItems);

    if (response.success) {
      MessageService.showSuccess("Item adicionado com sucesso!");
      setState(() {});
    } else {
      MessageService.showSuccess(response.message ?? "Erro ao adicionar item.");
    }
  }
  */

  Future<void> _deleteBomItemConfirm(
    List<ProductPackingBom> currentItems,
    String finalidade,
  ) async {
    final loadingService = context.read<LoadingService>();
    if (currentItems.isEmpty) {
      return;
    }

    final sortedItems = List<ProductPackingBom>.from(currentItems)
      ..sort((a, b) => a.productSeq.compareTo(b.productSeq));

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Excluir Item da Sequência'),
          contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: sortedItems.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = sortedItems[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.withOpacity(0.1),
                    child: Text('${item.productSeq}', style: const TextStyle(color: Colors.indigo)),
                  ),
                  title: Text(item.productName?.isNotEmpty == true ? item.productName! : 'Sem descrição'),
                  subtitle: item.productBomId?.isNotEmpty == true ? Text('Código: ${item.productBomId}') : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await CallAction.run(
                        action: () async {
                          loadingService.show();
                          await _handleDeleteBomItem(sortedItems, item);
                        },
                        onFinally: () {
                          loadingService.hide();
                        },
                      );
                    },
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
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteBomItem(
    List<ProductPackingBom> currentItems,
    ProductPackingBom itemToDelete,
  ) async {
    final packingService = context.read<ProductPackingService>();

    final remainingItems = currentItems
        .where((i) => i != itemToDelete)
        .toList();

    // Recalcula a sequência para não deixar buracos
    final List<ProductPackingBom> reorderedItems = [
      for (int i = 0; i < remainingItems.length; i++)
        remainingItems[i].copyWith(productSeq: i + 1),
    ];

    final response = await packingService.savePackingBom(widget.productId, reorderedItems);

    if (response.success) {
      MessageService.showSuccess("Item removido com sucesso!");
      setState(() {});
    } else {
      MessageService.showSuccess(response.message ?? "Erro ao remover item.");
    }
  }

  /* ***************************************** SEQUÊNCIA DE EMBALAGEM ***************************************** */


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