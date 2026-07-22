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
    
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBarCustom(
          title: 'Ferramentas',
        ),
      ),
      body: Column(
        children: [
          // =========================================================
          // MENU SUPERIOR (ABAS ATIVAS)
          // =========================================================
          _buildTopMenu(isMobile),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          
          // CONTEÚDO PRINCIPAL
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildContent(isMobile),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CONSTRUTOR DO MENU NO TOPO
  // =========================================================
  Widget _buildTopMenu(bool isMobile) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 14,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(menuItems.length, (index) {
            final item = menuItems[index];
            final isSelected = selectedIndex == index;

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.indigo : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.indigo : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 18,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 13 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    switch (selectedIndex) {
      case 0:
        return _productsTab(isMobile);
      case 1:
        return _imagesTab(isMobile);
      default:
        return const SizedBox();
    }
  }

  // =========================================================
  // IMPORTAR PRODUTOS
  // =========================================================
  Widget _productsTab(bool isMobile) {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Deixe apenas esta linha
        children: [
          Text(
            'Importar Produtos',
            style: TextStyle(
              fontSize: isMobile ? 24 : 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Realize importações e atualizações em massa de produtos no sistema.',
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: isMobile ? 20 : 32),
          _buildActionCard(
            isMobile: isMobile,
            title: 'Importar Arquivo',
            description:
                'Selecione um arquivo CSV, XLSX ou integração externa para realizar a importação dos produtos.',
            icon: Icons.upload_file_rounded,
            buttonText: 'Selecionar Arquivo',
            onPressed: () async {},
          ),
        ],
      ),
    );
  }

  // =========================================================
  // IMPORTAR IMAGENS
  // =========================================================
  Widget _imagesTab(bool isMobile) {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Importar Imagens',
            style: TextStyle(
              fontSize: isMobile ? 24 : 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Importe imagens em massa através de um arquivo CSV contendo o produto e a URL da imagem.',
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: isMobile ? 20 : 32),
          _buildActionCard(
            isMobile: isMobile,
            title: 'Enviar Imagens',
            description:
                'Selecione um arquivo CSV contendo o código do produto e a URL da imagem.',
            icon: Icons.cloud_upload_rounded,
            buttonText: 'Selecionar Imagens *.csv',
            onPressed: () async {
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
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

                final dataLines =
                    lines.where((e) => e.trim().isNotEmpty).toList();

                if (dataLines.isEmpty) {
                  throw Exception('CSV vazio.');
                }

                dataLines.removeAt(0);

                totalLines = dataLines.length;

                const int batchSize = 10;

                final int totalBatches = (totalLines / batchSize).ceil();

                for (int batch = 0; batch < totalBatches; batch++) {
                  final start = batch * batchSize;

                  final end = min(
                    start + batchSize,
                    totalLines,
                  );

                  final currentBatch = dataLines.sublist(start, end);

                  setState(() {
                    processedLines = start;

                    uploadProgress = processedLines / totalLines;
                  });

                  await Future.delayed(
                    const Duration(milliseconds: 50),
                  );

                  final List<Map<String, String>> images = [];

                  for (final line in currentBatch) {
                    final columns = line.split(';');

                    if (columns.length < 2) {
                      continue;
                    }

                    final product = columns[0].trim().padLeft(6, '0');

                    final urlImage = columns[1].trim();

                    if (product.isEmpty || urlImage.isEmpty) {
                      continue;
                    }

                    images.add({
                      'product': product,
                      'urlImage': urlImage,
                    });
                  }

                  if (images.isNotEmpty) {
                    debugPrint(
                      'Enviando lote ${batch + 1} '
                      'com ${images.length} registros',
                    );

                    final productService = context.read<ProductService>();

                    await productService.importImagesByUrl(
                      finalidade: 'PRODUTO',
                      images: images,
                    );
                  }

                  processedLines += currentBatch.length;

                  setState(() {
                    uploadProgress = processedLines / totalLines;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCsvLayout(isMobile),
                if (selectedCsvFile != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.25),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedCsvFile!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$processedLines / $totalLines registros',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
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
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      minHeight: 18,
                      value: uploadProgress,
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

  Widget _buildCsvLayout(bool isMobile) {
    return Container(
      margin: EdgeInsets.only(top: isMobile ? 16 : 26),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.indigo.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            padding: EdgeInsets.all(isMobile ? 12 : 18),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SelectableText(
              'produto;url_imagem\n'
              '200001;https://site.com/imagem1.jpgn\n'
              '200002;https://site.com/imagem2.jpg',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: isMobile ? 12 : 14,
                height: 1.8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.orange.shade700,
                ),
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

  Widget _buildActionCard({
    required bool isMobile,
    required String title,
    required String description,
    required IconData icon,
    required String buttonText,
    required Future<void> Function() onPressed,
    Widget? extraContent,
  }) {
    Widget cardDetails = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            color: Colors.grey.shade700,
            height: 1.5,
            fontSize: isMobile ? 14 : 15,
          ),
        ),
        if (extraContent != null) extraContent,
        SizedBox(height: isMobile ? 20 : 28),
        SizedBox(
          width: isMobile ? double.infinity : null,
          child: ElevatedButton.icon(
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
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 34),
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
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIconContainer(icon, isMobile),
                const SizedBox(height: 20),
                cardDetails,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIconContainer(icon, isMobile),
                const SizedBox(width: 24),
                Expanded(child: cardDetails),
              ],
            ),
    );
  }

  Widget _buildIconContainer(IconData icon, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 22),
      ),
      child: Icon(
        icon,
        size: isMobile ? 32 : 38,
        color: Colors.indigo,
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
