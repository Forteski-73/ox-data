import 'dart:convert';
import 'dart:typed_data'; // Importação necessária para o Uint8List
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;

import 'package:oxdata/app/core/services/ai_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/widgets/buttom_cyber_glass.dart';

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  late CameraController _cameraController;
  final AiService _aiService = AiService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _cameraInitialized = false;
  String? _decorationResult;

  String? _processedImageBase64; // Base64 vindo do backend
  List<Map<String, dynamic>> _rankingProximidade = []; // Ranking das decorações mais próximas encontradas

  bool _showInfoArea = true; // Variável de controle para exibir/ocultar a área informativa

  // Variáveis para controle do estado de treinamento e confirmação de dados
  String? _currentBase64Image;
  String _detectedCategory = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('Nenhuma câmera encontrada.');
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController.initialize();

      if (!mounted) return;

      setState(() {
        _cameraInitialized = true;
      });
    } catch (e) {
      MessageService.showError(
        'Erro ao inicializar câmera: $e',
      );
    }
  }

  @override
  void dispose() {
    if (_cameraInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  void _clearAnalysisContext() {
    setState(() {
      _decorationResult = null;

      _processedImageBase64 = null;

      _rankingProximidade = [];

      _showInfoArea = false;

      _currentBase64Image = null;

      _detectedCategory = '';
    });
  }

  /// Redimensiona uma lista de bytes de imagem para no máximo 640x640 mantendo a proporção.
  /// Retorna a string em Base64 pronta para envio.
  Future<String> _resizeAndEncodeToBase64(Uint8List originalBytes) async {
    final img.Image? decodedImage = img.decodeImage(originalBytes);
    
    if (decodedImage == null) {
      throw Exception('Falha ao decodificar a imagem para redimensionamento.');
    }

    final img.Image resizedImage = img.copyResize(
      decodedImage,
      width: 640,
      height: 640,
      interpolation: img.Interpolation.linear,
    );

    final List<int> resizedBytes = img.encodeJpg(resizedImage, quality: 85);

    return base64Encode(Uint8List.fromList(resizedBytes));
  }

  Future<void> _analyzeImage() async {
    final loadingService = context.read<LoadingService>();

    _clearAnalysisContext();

    await CallAction.run(
      action: () async {
        if (!_cameraInitialized) {
          throw Exception('Câmera ainda não inicializada.');
        }

        loadingService.show();

        final XFile picture = await _cameraController.takePicture();
        final bytes = await picture.readAsBytes();

        final base64Image = await _resizeAndEncodeToBase64(bytes);

        final data = await _aiService.analisarImagem(base64Image);

        setState(() {
          _currentBase64Image = base64Image;
          
          final bool reconhecido = data['reconhecido'] ?? false;
          
          if (reconhecido && data['data'] != null) {
            final Map<String, dynamic> dataContainer = data['data'] as Map<String, dynamic>;
            
            final String categoria =
                dataContainer['categoria_detectada'] ?? 'Não identificado';

            _detectedCategory = categoria;

            final String similaridadeStr =
                dataContainer['porcentagem_similaridade'] ?? '0.0%';

            _decorationResult = "$categoria ($similaridadeStr)";

            final ranking =
                dataContainer['ranking_proximidade'] as List<dynamic>? ?? [];

            _rankingProximidade = ranking
                .map((e) => Map<String, dynamic>.from(e))
                .toList();

          } else {
            _detectedCategory = 'Não identificado';
            _decorationResult = data['message'] ?? 'A imagem não pertence a nenhuma decoração catalogada.';
          }
          
          _processedImageBase64 = data['imagem_processada'];
          _showInfoArea = true;
        });
      },
      onError: (error) {
        MessageService.showError(
          error.toString().replaceAll('Exception: ', ''),
        );
      },
      onFinally: () {
        loadingService.hide();
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    final loadingService = context.read<LoadingService>();

    _clearAnalysisContext();

    await CallAction.run(
      action: () async {
        loadingService.show();

        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90, 
        );

        if (image == null) return;

        final bytes = await image.readAsBytes();
        
        final base64Image = await _resizeAndEncodeToBase64(bytes);

        final data = await _aiService.analisarImagem(base64Image);

        setState(() {
          _currentBase64Image = base64Image;

          final bool reconhecido = data['reconhecido'] ?? false;
          
          if (reconhecido && data['data'] != null) {
            final dataContainer = data['data'] as Map<String, dynamic>;

            final categoria =
                dataContainer['categoria_detectada'] ?? 'Não identificado';

            _detectedCategory = categoria;

            final similaridadeStr =
                dataContainer['porcentagem_similaridade'] ?? '0.0%';

            _decorationResult = "$categoria ($similaridadeStr)";

            final ranking =
                dataContainer['ranking_proximidade'] as List<dynamic>? ?? [];

            _rankingProximidade = ranking
                .map((e) => Map<String, dynamic>.from(e))
                .toList();

          } else {
            _rankingProximidade = [];
            _detectedCategory = 'Não identificado';
            _decorationResult = data['message'] ?? 'A imagem não pertence a nenhuma decoração catalogada.';
          }
          
          _processedImageBase64 = data['imagem_processada'];
          _showInfoArea = true;
        });
      },
      onError: (error) {
        MessageService.showError(
          error.toString().replaceAll('Exception: ', ''),
        );
      },
      onFinally: () {
        loadingService.hide();
      },
    );
  }

  /// NOVO: Carrega as categorias da API e abre o BottomSheet para listagem
  Future<void> _loadCategories() async {
    //final loadingService = context.read<LoadingService>();

    await CallAction.run(
      action: () async {
        //loadingService.show();

        // Faz o consumo usando o método criado anteriormente
        final Map<String, dynamic> response = await _aiService.listarCategorias();
        
        final List<dynamic> categoriasRaw = response['data'] ?? [];
        final List<String> categorias = categoriasRaw.map((e) => e.toString()).toList();

        if (mounted) {
          _showCategoriesBottomSheet(categorias);
        }
      },
      onError: (error) {
        MessageService.showError(
          'Erro ao buscar decorações: ${error.toString().replaceAll('Exception: ', '')}',
        );
      },
      onFinally: () {
        //loadingService.hide();
      },
    );
  }

  void _showCategoriesBottomSheet(List<String> todasCategorias) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      elevation: 0,
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 500),
        reverseDuration: const Duration(milliseconds: 350),
      ),
      builder: (context) {
        List<String> categoriasFiltradas = List.from(todasCategorias);

        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setModalState,
          ) {
            return DraggableScrollableSheet(
              initialChildSize: 0.82,
              minChildSize: 0.35,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 18,
                      sigmaY: 18,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 30,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),

                          // HANDLE
                          Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // TÍTULO
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.view_list_rounded,
                                  color: Colors.indigo.shade700,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Decorações Cadastradas (${todasCategorias.length})',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // PESQUISA
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            child: TextField(
                              onChanged: (value) {
                                setModalState(() {
                                  categoriasFiltradas = todasCategorias
                                      .where(
                                        (element) => element
                                            .toLowerCase()
                                            .contains(
                                              value.toLowerCase(),
                                            ),
                                      )
                                      .toList();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Pesquisar decoração...',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF1F5F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // LISTA
                          Expanded(
                            child: categoriasFiltradas.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Nenhuma decoração encontrada.',
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    controller: scrollController,
                                    physics:
                                        const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.all(16),
                                    itemCount:
                                        categoriasFiltradas.length,
                                    separatorBuilder:
                                        (context, index) {
                                      return const Divider(
                                        height: 1,
                                      );
                                    },
                                    itemBuilder:
                                        (context, index) {
                                      final item =
                                          categoriasFiltradas[index];

                                      return ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              Colors.indigo
                                                  .withOpacity(0.10),
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color: Colors
                                                  .indigo.shade800,
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          item,
                                          style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w600,
                                            color:
                                                Color(0xFF0F172A),
                                          ),
                                        ),
                                        trailing: const Icon(
                                          Icons
                                              .arrow_forward_ios_rounded,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showTrainingDialog(String initialCategory) {
    final TextEditingController categoryController = TextEditingController(text: initialCategory);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.model_training_rounded, color: Colors.indigo.shade700),
              const SizedBox(width: 10),
              const Text(
                'Treinar Sistema IA',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirme ou ajuste o nome da DECORAÇÃO antes de enviar para IA:',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: categoryController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Nome da Categoria',
                    labelStyle: TextStyle(color: Colors.indigo.shade600),
                    hintText: 'EX: MERESIA',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blueGrey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.indigo.shade600, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'O nome da categoria é obrigatório';
                    }
                    if (value.trim().length < 2) {
                      return 'Insira um nome válido';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final String categoriaFinal = categoryController.text.trim();
                
                Navigator.of(context).pop();

                final loadingService = this.context.read<LoadingService>();
                await CallAction.run(
                  action: () async {
                    loadingService.show();

                    final messageResult = await _aiService.treinarImagem(
                      categoria: categoriaFinal,
                      base64Image: _currentBase64Image,
                      augmentations: 10,
                    );

                    setState(() {
                      _showInfoArea = false;
                    });

                    MessageService.showSuccess(messageResult);
                  },
                  onError: (error) {
                    MessageService.showError(
                      error.toString().replaceAll('Exception: ', ''),
                    );
                  },
                  onFinally: () {
                    loadingService.hide();
                  },
                );
              },
              child: const Text(
                'Enviar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleTrainingFeedback() {
    if (_currentBase64Image == null || _detectedCategory.isEmpty) {
      MessageService.showError('Não há nenhuma imagem activa para realizar o treinamento.');
      return;
    }

    final String categoriaInicial = _detectedCategory == 'Não identificado' ? '' : _detectedCategory;

    _showTrainingDialog(categoriaInicial);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBarCustom(title: 'Assistente IA - Visão'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _cameraInitialized
                  ? CameraPreview(_cameraController)
                  : const Center(child: CircularProgressIndicator()),
            ),

            if (_decorationResult != null && _showInfoArea)
              Positioned(
                top: 24,
                left: 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.40), 
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3), 
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    if (_processedImageBase64 != null &&
        _processedImageBase64!.isNotEmpty)
      Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              base64Decode(
                _processedImageBase64!.split(',').last,
              ),
              width: 198,
              height: 198,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 198,
                  height: 198,
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(
                    Icons.broken_image_rounded,
                    size: 24,
                    color: Color(0xFF94A3B8),
                  ),
                );
              },
            ),
          ),
        ),
      ),

    const SizedBox(height: 20),

    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'IA SYSTEM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4F46E5),
              letterSpacing: 1.2,
            ),
          ),
        ),

        const SizedBox(height: 6),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
              topLeft: Radius.circular(2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_rankingProximidade.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._rankingProximidade
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  final categoria = item['categoria'] ?? '';
                  final confianca =
                      (item['confianca'] ?? 0).toDouble();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: index == 0 ? 24 : 14,
                          color: const Color(0xFF4F46E5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            categoria,
                            style: TextStyle(
                              fontWeight: index == 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: index == 0 ? 20 : 12,
                              color: index == 0
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        Text(
                          "${confianca.toStringAsFixed(2)}%",
                          style: TextStyle(
                            fontWeight: index == 0
                                ? FontWeight.w900
                                : FontWeight.bold,
                            fontSize: index == 0 ? 17 : 13,
                            color: const Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ] else ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.15),
                    ),
                  ),
                  child: const Text(
                    'A imagem não correspondeu a nenhuma decoração da nossa base de conhecimento.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  ],
),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CyberGlassButton(
                                size: 80,
                                icon: Icons.thumb_down_alt_rounded,
                                baseColor: const Color(0xFFEF4444),
                                onTap: () {
                                  setState(() {
                                    _showInfoArea = false;
                                  });
                                  print("Feedback negativo enviado e área ocultada");
                                },
                              ),
                              const SizedBox(width: 20),
                              CyberGlassButton(
                                size: 80,
                                icon: Icons.thumb_up_alt_rounded,
                                baseColor: const Color(0xFF10B981),
                                onTap: () {
                                  _handleTrainingFeedback();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 4. Interface Inferior Transparente com o Novo Botão Adicionado
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Botão Galeria
                      CyberGlassButton(
                        size: 80,
                        icon: Icons.photo_library_rounded,
                        baseColor: Colors.indigo,
                        onTap: () async {
                          await Future.delayed(const Duration(milliseconds: 600));
                          _pickImageFromGallery();
                        },
                      ),

                      const SizedBox(width: 20), // Ajustado sutilmente para acomodar 3 botões confortavelmente

                      // Botão Câmera (Centralizado/Principal)
                      CyberGlassButton(
                        size: 80,
                        icon: Icons.photo_camera_rounded,
                        baseColor: Colors.indigo, 
                        onTap: () async {
                          await Future.delayed(const Duration(milliseconds: 600));
                          _analyzeImage();
                        },
                      ),

                      const SizedBox(width: 20),

                      // NOVO: Botão Decorações (Listagem das Categorias da API)
                      CyberGlassButton(
                        size: 80,
                        icon: Icons.info_rounded, // Ícone elegante de mosaico/coleção
                        baseColor: Colors.indigo, 
                        onTap: () async {
                          await Future.delayed(const Duration(milliseconds: 600));
                          _loadCategories(); // Executa o fluxo de buscar e listar
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(60),
    );

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


/*
import 'dart:convert';
import 'dart:typed_data'; // Importação necessária para o Uint8List
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;

import 'package:oxdata/app/core/services/ai_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/widgets/buttom_cyber_glass.dart';

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  late CameraController _cameraController;
  final AiService _aiService = AiService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _cameraInitialized = false;
  String? _decorationResult;

  String? _processedImageBase64; // Base64 vindo do backend
  List<Map<String, dynamic>> _rankingProximidade = []; // Ranking das decorações mais próximas encontradas

  bool _showInfoArea = true; // Variável de controle para exibir/ocultar a área informativa

  // Variáveis para controle do estado de treinamento e confirmação de dados
  String? _currentBase64Image;
  String _detectedCategory = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('Nenhuma câmera encontrada.');
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController.initialize();

      if (!mounted) return;

      setState(() {
        _cameraInitialized = true;
      });
    } catch (e) {
      MessageService.showError(
        'Erro ao inicializar câmera: $e',
      );
    }
  }

  @override
  void dispose() {
    if (_cameraInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  /// Redimensiona uma lista de bytes de imagem para no máximo 640x640 mantendo a proporção.
  /// Retorna a string em Base64 pronta para envio.
  Future<String> _resizeAndEncodeToBase64(Uint8List originalBytes) async {
    // 1. Decodifica os bytes originais para o formato do pacote 'image'
    final img.Image? decodedImage = img.decodeImage(originalBytes);
    
    if (decodedImage == null) {
      throw Exception('Falha ao decodificar a imagem para redimensionamento.');
    }

    // 2. Redimensiona para caber dentro de 640x640, mantendo a proporção
    final img.Image resizedImage = img.copyResize(
      decodedImage,
      width: 640,   // É o padrão que o YOLO foi treinado ***
      height: 640,  // É o padrão que o YOLO foi treinado ***
      interpolation: img.Interpolation.linear,
    );

    // 3. Codifica a imagem redimensionada de volta para bytes (formato JPG)
    final List<int> resizedBytes = img.encodeJpg(resizedImage, quality: 85);

    // 4. Converte e retorna em Base64 (Garantindo o tipo correto via Uint8List)
    return base64Encode(Uint8List.fromList(resizedBytes));
  }

  Future<void> _analyzeImage() async {
    final loadingService = context.read<LoadingService>();

    await CallAction.run(
      action: () async {
        if (!_cameraInitialized) {
          throw Exception('Câmera ainda não inicializada.');
        }

        loadingService.show();

        // 1. Captura a imagem da câmera
        final XFile picture = await _cameraController.takePicture();
        final bytes = await picture.readAsBytes();

        // 2. Utiliza o novo método isolado para processar a imagem
        final base64Image = await _resizeAndEncodeToBase64(bytes);

        // 3. Envia para a API
        final data = await _aiService.analisarImagem(base64Image);

        setState(() {
          _currentBase64Image = base64Image;
          
          // 1. Verifica se foi reconhecido (está na raiz do JSON)
          final bool reconhecido = data['reconhecido'] ?? false;
          
          if (reconhecido && data['data'] != null) {
            // Como reconhecido é true, entramos no mapa 'data'
            final Map<String, dynamic> dataContainer = data['data'] as Map<String, dynamic>;
            
            final String categoria =
                dataContainer['categoria_detectada'] ?? 'Não identificado';

            _detectedCategory = categoria;

            final String similaridadeStr =
                dataContainer['porcentagem_similaridade'] ?? '0.0%';

            _decorationResult = "$categoria ($similaridadeStr)";

            // NOVO
            final ranking =
                dataContainer['ranking_proximidade'] as List<dynamic>? ?? [];

            _rankingProximidade = ranking
                .map((e) => Map<String, dynamic>.from(e))
                .toList();

          } else {
            // Se reconhecido for false, exibe a mensagem de erro ou aviso da API
            _detectedCategory = 'Não identificado';
            _decorationResult = data['message'] ?? 'A imagem não pertence a nenhuma decoração catalogada.';
          }
          
          // 2. Salva a imagem cortada pelo YOLO (está na raiz do JSON)
          _processedImageBase64 = data['imagem_processada'];
          
          // Força a área informativa a aparecer novamente ao carregar uma nova análise
          _showInfoArea = true;
        });
      },
      onError: (error) {
        MessageService.showError(
          error.toString().replaceAll('Exception: ', ''),
        );
      },
      onFinally: () {
        loadingService.hide();
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    final loadingService = context.read<LoadingService>();

    await CallAction.run(
      action: () async {
        loadingService.show();

        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90, 
        );

        if (image == null) return;

        final bytes = await image.readAsBytes();
        
        // REUTILIZAÇÃO: Redimensiona para 640x640 e converte em Base64 de forma idêntica à câmera
        final base64Image = await _resizeAndEncodeToBase64(bytes);

        final data = await _aiService.analisarImagem(base64Image);

        setState(() {
          _currentBase64Image = base64Image;

          // 1. Verifica se a API conseguiu reconhecer a decoração
          final bool reconhecido = data['reconhecido'] ?? false;
          
          if (reconhecido && data['data'] != null) {
            // Como foi reconhecido, acessamos o mapa interno 'data'
            final dataContainer = data['data'] as Map<String, dynamic>;

            final categoria =
                dataContainer['categoria_detectada'] ?? 'Não identificado';

            _detectedCategory = categoria;

            final similaridadeStr =
                dataContainer['porcentagem_similaridade'] ?? '0.0%';

            _decorationResult = "$categoria ($similaridadeStr)";

            // NOVO
            final ranking =
                dataContainer['ranking_proximidade'] as List<dynamic>? ?? [];

            _rankingProximidade = ranking
                .map((e) => Map<String, dynamic>.from(e))
                .toList();

          } else {
            // Se reconhecido == false, exibe a mensagem enviada pelo backend
            _rankingProximidade = [];
            _detectedCategory = 'Não identificado';
            _decorationResult = data['message'] ?? 'A imagem não pertence a nenhuma decoração catalogada.';
          }
          
          // Salva a imagem tratada pelo backend no estado (está na raiz do JSON)
          _processedImageBase64 = data['imagem_processada'];
          
          // Força a área informativa a aparecer novamente ao carregar uma nova análise
          _showInfoArea = true;
        });
      },
      onError: (error) {
        MessageService.showError(
          error.toString().replaceAll('Exception: ', ''),
        );
      },
      onFinally: () {
        loadingService.hide();
      },
    );
  }

  // POPUP PROFISSIONAL PARA CONFIRMAÇÃO E EDIÇÃO DA CATEGORIA DO PRODUTO
  void _showTrainingDialog(String initialCategory) {
    final TextEditingController categoryController = TextEditingController(text: initialCategory);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false, // Força o usuário a interagir com os botões
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.model_training_rounded, color: Colors.indigo.shade700),
              const SizedBox(width: 10),
              const Text(
                'Treinar Sistema IA',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirme ou ajuste o nome da DECORAÇÃO antes de enviar para IA:',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: categoryController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters, // Força caixa alta no teclado
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Nome da Categoria',
                    labelStyle: TextStyle(color: Colors.indigo.shade600),
                    hintText: 'EX: MERESIA',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blueGrey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.indigo.shade600, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'O nome da categoria é obrigatório';
                    }
                    if (value.trim().length < 2) {
                      return 'Insira um nome válido';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          actions: [
            // Botão Cancelar
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ),
            
            // Botão Confirmar e Enviar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), // Verde combinando com o joinha
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () async {
                // Valida se o campo não está vazio
                if (!formKey.currentState!.validate()) return;

                final String categoriaFinal = categoryController.text.trim();
                
                // Fecha a popup antes de disparar o loading global
                Navigator.of(context).pop();

                // Executa o treinamento com a categoria validada pelo usuário
                final loadingService = this.context.read<LoadingService>();
                await CallAction.run(
                  action: () async {
                    loadingService.show();

                    final messageResult = await _aiService.treinarImagem(
                      categoria: categoriaFinal,
                      base64Image: _currentBase64Image,
                      augmentations: 10,
                    );

                    setState(() {
                      _showInfoArea = false; // Esconde o painel de análise após o treino concluído
                    });

                    MessageService.showSuccess(messageResult);
                  },
                  onError: (error) {
                    MessageService.showError(
                      error.toString().replaceAll('Exception: ', ''),
                    );
                  },
                  onFinally: () {
                    loadingService.hide();
                  },
                );
              },
              child: const Text(
                'Enviar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // DISPARA O FLUXO DE CONFIRMAÇÃO/EDIÇÃO DA CATEGORIA
  void _handleTrainingFeedback() {
    if (_currentBase64Image == null || _detectedCategory.isEmpty) {
      MessageService.showError('Não há nenhuma imagem activa para realizar o treinamento.');
      return;
    }

    // Se a IA não reconheceu nada, abrimos o diálogo com o campo em branco para o usuário digitar
    final String categoriaInicial = _detectedCategory == 'Não identificado' ? '' : _detectedCategory;

    // Abre a popup profissional para o usuário conferir/editar
    _showTrainingDialog(categoriaInicial);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBarCustom(title: 'Assistente IA - Visão'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Camera Preview
            Positioned.fill(
              child: _cameraInitialized
                  ? CameraPreview(_cameraController)
                  : const Center(child: CircularProgressIndicator()),
            ),

            // 3. Resultado da Identificação com Design Cyber-Glass Futurista
            // Só renderiza o painel se houver resultado E se _showInfoArea for true
            if (_decorationResult != null && _showInfoArea)
              Positioned(
                top: 24,
                left: 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), // Efeito Frosted Glass premium
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.40), 
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3), 
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),



child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [

    // PRIMEIRA LINHA
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Miniatura de Imagem Processada com Moldura Minimalista
        if (_processedImageBase64 != null &&
            _processedImageBase64!.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                base64Decode(
                  _processedImageBase64!.split(',').last,
                ),
                width: 198,
                height: 198,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return Container(
                    width: 198,
                    height: 198,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(
                      Icons.broken_image_rounded,
                      size: 24,
                      color: Color(0xFF94A3B8),
                    ),
                  );
                },
              ),
            ),
          ),

        if (_processedImageBase64 != null &&
            _processedImageBase64!.isNotEmpty)
          const SizedBox(width: 16),

        // Área Informativa de Análise e Resultados
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [

              // Badge indicando que a IA respondeu
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'IA SYSTEM',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F46E5),
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Balão de Chat Futurista
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    topLeft: Radius.circular(2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // RANKING
                    if (_rankingProximidade.isNotEmpty) ...[
                      const SizedBox(height: 12),

                      ..._rankingProximidade
                          .asMap()
                          .entries
                          .map((entry) {

                        final index = entry.key;
                        final item = entry.value;

                        final categoria =
                            item['categoria'] ?? '';

                        final confianca =
                            (item['confianca'] ?? 0)
                                .toDouble();

                        return Container(
                          margin: const EdgeInsets.only(
                            bottom: 8,
                          ),
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo
                                .withOpacity(0.06),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [

                              Icon(
                                Icons.auto_awesome_rounded,
                                size:
                                    index == 0 ? 24 : 14,
                                color:
                                    const Color(0xFF4F46E5),
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: Text(
                                  categoria,
                                  style: TextStyle(
                                    fontWeight:
                                        index == 0
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                    fontSize:
                                        index == 0
                                            ? 20
                                            : 12,
                                    color:
                                        index == 0
                                            ? const Color(
                                                0xFF1E293B)
                                            : const Color(
                                                0xFF334155),
                                  ),
                                ),
                              ),

                              Text(
                                "${confianca.toStringAsFixed(2)}%",
                                style: TextStyle(
                                  fontWeight:
                                      index == 0
                                          ? FontWeight.w900
                                          : FontWeight.bold,
                                  fontSize:
                                      index == 0
                                          ? 17
                                          : 13,
                                  color:
                                      const Color(
                                          0xFF4F46E5),
                                ),
                              ),
                            ],
                          ),
                        );

                      }).toList(),
                    ] else ...[

                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.15),
                          ),
                        ),
                        child: const Text(
                          'A imagem não correspondeu a nenhuma decoração da nossa base de conhecimento.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color:Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),

    // ESPAÇAMENTO
    const SizedBox(height: 16),

    // SEGUNDA LINHA - BOTÕES
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        // BOTÃO NEGATIVO
        CyberGlassButton(
          size: 80,
          icon: Icons.thumb_down_alt_rounded,
          baseColor: const Color(0xFFEF4444),
          onTap: () {
            setState(() {
              _showInfoArea = false;
            });

            print(
              "Feedback negativo enviado e área ocultada",
            );
          },
        ),

        const SizedBox(width: 20),

        // BOTÃO POSITIVO
        CyberGlassButton(
          size: 80,
          icon: Icons.thumb_up_alt_rounded,
          baseColor: const Color(0xFF10B981),
          onTap: () {
            _handleTrainingFeedback();
          },
        ),
      ],
    ),
  ],
),
                    ),
                  ),
                ),
              ),

            // 4. Interface Inferior Transparente
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Botão Galeria (Tamanho 80)
                      CyberGlassButton(
                        size: 80,
                        icon: Icons.photo_library_rounded,
                        baseColor: Colors.indigo,
                        onTap: () async {
                          await Future.delayed(const Duration(milliseconds: 600));
                          _pickImageFromGallery();
                        },
                      ),

                      const SizedBox(width: 25),

                      // Botão Câmera (Tamanho 80)
                      CyberGlassButton(
                        size: 80,
                        icon: Icons.photo_camera_rounded,
                        baseColor: Colors.indigo, 
                        onTap: () async {
                          await Future.delayed(const Duration(milliseconds: 600));
                          _analyzeImage();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(60),
    );

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

*/