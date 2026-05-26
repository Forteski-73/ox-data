import 'dart:io';
import 'dart:math';
import 'package:oxdata/app/core/services/product_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';


class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  int selectedIndex = 0;

  String? selectedCsvFile;

  double uploadProgress = 0;
  bool uploading = false;

  int totalLines = 0;
  int processedLines = 0;

  final List<_ToolMenuItem> menuItems = [
    _ToolMenuItem(
      title: 'Importar Produtos',
      icon: Icons.inventory_2_rounded,
    ),
    _ToolMenuItem(
      title: 'Importar Imagens',
      icon: Icons.image_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    context.read<LoadingService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBarCustom(
          title: 'Ferramentas',
        ),
      ),
      body: Row(
        children: [
          // =========================================================
          // MENU LATERAL
          // =========================================================
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.build_rounded,
                          color: Colors.indigo,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Ferramentas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Divider(height: 1),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    itemCount: menuItems.length,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      final isSelected = selectedIndex == index;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.indigo
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                selectedIndex = index;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 20,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.indigo,
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // =========================================================
          // CONTEÚDO
          // =========================================================
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (selectedIndex) {
      case 0:
        return _productsTab();

      case 1:
        return _imagesTab();

      default:
        return const SizedBox();
    }
  }

  // =========================================================
  // IMPORTAR PRODUTOS
  // =========================================================
  Widget _productsTab() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Importar Produtos',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Realize importações e atualizações em massa de produtos no sistema.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 32),

          _buildActionCard(
            title: 'Importar Arquivo',
            description:
                'Selecione um arquivo CSV, XLSX ou integração externa para realizar a importação dos produtos.',
            icon: Icons.upload_file_rounded,
            buttonText: 'Selecionar Arquivo',
            onPressed: () async { },
          ),
        ],
      ),
    );
  }

  // =========================================================
  // IMPORTAR IMAGENS
  // =========================================================
  Widget _imagesTab() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Importar Imagens',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Importe imagens em massa através de um arquivo CSV contendo o produto e a URL da imagem.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 32),

          _buildActionCard(
            title: 'Enviar Imagens',
            description:
                'Selecione um arquivo CSV contendo o código do produto e a URL da imagem.',
            icon: Icons.cloud_upload_rounded,
            buttonText: 'Selecionar Imagens *.csv',
            onPressed: () async {

              try {

                FilePickerResult? result =
                    await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['csv'],
                  allowMultiple: false,
                );

                if (result == null) {
                  return;
                }

                final file = result.files.first;

                setState(() {
                  selectedCsvFile = file.name;

                  uploadProgress = 0;
                  uploading = true;

                  totalLines = 0;
                  processedLines = 0;
                });

                final csvFile = File(file.path!);

                final lines = await csvFile.readAsLines();

                // =====================================================
                // REMOVE LINHAS VAZIAS
                // =====================================================
                final dataLines = lines
                    .where((e) => e.trim().isNotEmpty)
                    .toList();

                if (dataLines.isEmpty) {
                  throw Exception('CSV vazio.');
                }

                // =====================================================
                // REMOVE CABEÇALHO
                // =====================================================
                dataLines.removeAt(0);

                totalLines = dataLines.length;

                const int batchSize = 10;

                final int totalBatches =
                    (totalLines / batchSize).ceil();

                for (int batch = 0;
                    batch < totalBatches;
                    batch++) {

                  final start = batch * batchSize;

                  final end = min(
                    start + batchSize,
                    totalLines,
                  );

                  final currentBatch =
                      dataLines.sublist(start, end);

                  // =====================================================
                  // ATUALIZA UI ANTES DO ENVIO
                  // =====================================================
                  setState(() {
                    processedLines = start;

                    uploadProgress =
                        processedLines / totalLines;
                  });

                  // FORÇA RENDERIZAÇÃO DA BARRA
                  await Future.delayed(
                    const Duration(milliseconds: 50),
                  );

                  // =====================================================
                  // CONVERTE CSV -> JSON API
                  // =====================================================
                  final List<Map<String, String>> images = [];

                  for (final line in currentBatch) {

                    final columns = line.split(';');

                    if (columns.length < 2) {
                      continue;
                    }

                    final product =
                        columns[0]
                            .trim()
                            .padLeft(6, '0');

                    final urlImage =
                        columns[1].trim();

                    if (product.isEmpty ||
                        urlImage.isEmpty) {
                      continue;
                    }

                    images.add({
                      'product': product,
                      'urlImage': urlImage,
                    });
                  }

                  // =====================================================
                  // ENVIA PARA API
                  // =====================================================
                  if (images.isNotEmpty) {

                    debugPrint(
                      'Enviando lote ${batch + 1} '
                      'com ${images.length} registros',
                    );

                    final productService =
                        context.read<ProductService>();

                    await productService.importImagesByUrl(
                      finalidade: 'PRODUTO',
                      images: images,
                    );
                  }

                  // =====================================================
                  // ATUALIZA PROGRESSO APÓS ENVIO
                  // =====================================================
                  processedLines += currentBatch.length;

                  setState(() {
                    uploadProgress =
                        processedLines / totalLines;
                  });
                }

                setState(() {
                  uploading = false;
                  uploadProgress = 1;
                });

                debugPrint('Importação finalizada');

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Importação concluída com sucesso.',
                      ),
                    ),
                  );
                }

              } catch (e) {

                setState(() {
                  uploading = false;
                });

                debugPrint(
                  'Erro importando CSV: $e',
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erro ao importar CSV: $e',
                      ),
                    ),
                  );
                }
              }
            },
            extraContent: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                _buildCsvLayout(),

                if (selectedCsvFile != null) ...[

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            Colors.green.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [

                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                              Text(
                                selectedCsvFile!,
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                '$processedLines / $totalLines registros',
                                style: TextStyle(
                                  color:
                                      Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (uploading || uploadProgress > 0) ...[

                  const SizedBox(height: 22),

                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      minHeight: 18,
                      value: uploadProgress,
                      backgroundColor:
                          Colors.grey.shade300,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [

                      Text(
                        uploading
                            ? 'Enviando registros...'
                            : 'Processamento concluído',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      Text(
                        '${(uploadProgress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }


  // =========================================================
  // LAYOUT CSV
  // =========================================================
  Widget _buildCsvLayout() {
    return Container(
      margin: const EdgeInsets.only(top: 26),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.indigo.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: Colors.indigo.shade400,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'Layout esperado do CSV',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const SelectableText(
              'produto;url_imagem\n'
              '200001;https://site.com/imagem1.jpg\n'
              '200002;https://site.com/imagem2.jpg',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.8,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Utilize ";" como separador entre o produto e a URL da imagem.',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CARD DE AÇÃO
  // =========================================================
  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required String buttonText,
    required Future<void> Function() onPressed,
    Widget? extraContent,
  }) {
    return Container(
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.08),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              icon,
              size: 38,
              color: Colors.indigo,
            ),
          ),

          const SizedBox(width: 24),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),

                if (extraContent != null)
                  extraContent,

                const SizedBox(height: 28),

                ElevatedButton.icon(
                  onPressed: uploading
                      ? null
                      : () async {
                          await onPressed();
                        },
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                  ),
                  label: Text(buttonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolMenuItem {
  final String title;
  final IconData icon;

  _ToolMenuItem({
    required this.title,
    required this.icon,
  });
}