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
  String? _processedImageBase64; // Guardará o base64 vindo do backend
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
            
            final String categoria = dataContainer['categoria_detectada'] ?? 'Não identificado';
            _detectedCategory = categoria;
            
            // O seu servidor já entrega o texto pronto: "96.33%"
            // Pegamos como String direta para evitar erros de conversão de tipos
            final String similaridadeStr = dataContainer['porcentagem_similaridade'] ?? '0.0%';

            _decorationResult = "$categoria ($similaridadeStr)";
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
            final categoria = dataContainer['categoria_detectada'] ?? 'Não identificado';
            _detectedCategory = categoria;
            
            // O backend já envia a string formatada com o símbolo "%" (ex: "96.33%")
            final similaridadeStr = dataContainer['porcentagem_similaridade'] ?? '0.0%';

            _decorationResult = "$categoria ($similaridadeStr)";
          } else {
            // 2. Se reconhecido == false, exibe a mensagem enviada pelo backend
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
                  'Confirme ou ajuste o nome da DECORAÇÃO antes de salvar:',
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
                'Salvar no Treino',
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
                      child: Row(
                        children: [
                          // Miniatura de Imagem Processada com Moldura Minimalista
                          if (_processedImageBase64 != null && _processedImageBase64!.isNotEmpty)
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
                                  base64Decode(_processedImageBase64!.split(',').last),
                                  width: 120, 
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 120,
                                      height: 120,
                                      color: const Color(0xFFF1F5F9),
                                      child: const Icon(Icons.broken_image_rounded, size: 24, color: Color(0xFF94A3B8)),
                                    );
                                  },
                                ),
                              ),
                            ),
                          
                          if (_processedImageBase64 != null && _processedImageBase64!.isNotEmpty)
                            const SizedBox(width: 16),

                          // Área Informativa de Análise e Resultados (Estilo Balão de Chat)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Badge indicando que a IA respondeu
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                  child: Text(
                                    _decorationResult!,
                                    textAlign: TextAlign.left,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Color(0xFF1E293B),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // 1. Botão de Feedback Negativo (Vermelho Futurista com Flash)
                          CyberGlassButton(
                            size: 120,
                            icon: Icons.thumb_down_alt_rounded,
                            baseColor: const Color(0xFFEF4444), 
                            onTap: () {
                              setState(() {
                                _showInfoArea = false; // Esconde o painel inteiro ao clicar
                              });
                              print("Feedback negativo enviado e área ocultada");
                            },
                          ),

                          const SizedBox(width: 12),

                          // 2. Botão de Feedback Positivo (Abre a Popup de Validação do Treinamento)
                          CyberGlassButton(
                            size: 120,
                            icon: Icons.thumb_up_alt_rounded,
                            baseColor: const Color(0xFF10B981), 
                            onTap: () {
                              _handleTrainingFeedback();
                            },
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
  String? _processedImageBase64; // Guardará o base64 vindo do backend
  bool _showInfoArea = true; // Variável de controle para exibir/ocultar a área informativa

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
          // 1. Verifica se foi reconhecido (está na raiz do JSON)
          final bool reconhecido = data['reconhecido'] ?? false;
          
          if (reconhecido && data['data'] != null) {
            // Como reconhecido é true, entramos no mapa 'data'
            final Map<String, dynamic> dataContainer = data['data'] as Map<String, dynamic>;
            
            final String categoria = dataContainer['categoria_detectada'] ?? 'Não identificado';
            
            // O seu servidor já entrega o texto pronto: "96.33%"
            // Pegamos como String direta para evitar erros de conversão de tipos
            final String similaridadeStr = dataContainer['porcentagem_similaridade'] ?? '0.0%';

            _decorationResult = "$categoria ($similaridadeStr)";
          } else {
            // Se reconhecido for false, exibe a mensagem de erro ou aviso da API
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
          // 1. Verifica se a API conseguiu reconhecer a decoração
          final bool reconhecido = data['reconhecido'] ?? false;
          
          if (reconhecido && data['data'] != null) {
            // Como foi reconhecido, acessamos o mapa interno 'data'
            final dataContainer = data['data'] as Map<String, dynamic>;
            final categoria = dataContainer['categoria_detectada'] ?? 'Não identificado';
            
            // O backend já envia a string formatada com o símbolo "%" (ex: "96.33%")
            final similaridadeStr = dataContainer['porcentagem_similaridade'] ?? '0.0%';

            _decorationResult = "$categoria ($similaridadeStr)";
          } else {
            // 2. Se reconhecido == false, exibe a mensagem enviada pelo backend
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
                      child: Row(
                        children: [
                          // Miniatura de Imagem Processada com Moldura Minimalista
                          if (_processedImageBase64 != null && _processedImageBase64!.isNotEmpty)
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
                                  base64Decode(_processedImageBase64!.split(',').last),
                                  width: 120, 
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 120,
                                      height: 120,
                                      color: const Color(0xFFF1F5F9),
                                      child: const Icon(Icons.broken_image_rounded, size: 24, color: Color(0xFF94A3B8)),
                                    );
                                  },
                                ),
                              ),
                            ),
                          
                          if (_processedImageBase64 != null && _processedImageBase64!.isNotEmpty)
                            const SizedBox(width: 16),

                          // Área Informativa de Análise e Resultados (Estilo Balão de Chat)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Badge indicando que a IA respondeu
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                  child: Text(
                                    _decorationResult!,
                                    textAlign: TextAlign.left,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Color(0xFF1E293B),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // 1. Botão de Feedback Negativo (Vermelho Futurista com Flash)
                          CyberGlassButton(
                            size: 120,
                            icon: Icons.thumb_down_alt_rounded,
                            baseColor: const Color(0xFFEF4444), 
                            onTap: () {
                              setState(() {
                                _showInfoArea = false; // Esconde o painel inteiro ao clicar
                              });
                              print("Feedback negativo enviado e área ocultada");
                            },
                          ),

                          const SizedBox(width: 12),

                          // 2. Botão de Feedback Positivo (Verde Futurista com Flash)
                          CyberGlassButton(
                            size: 120,
                            icon: Icons.thumb_up_alt_rounded,
                            baseColor: const Color(0xFF10B981), 
                            onTap: () {
                              setState(() {
                                //final data = await _aiService.treinarImagem(base64Image);
                                _showInfoArea = false; // Esconde o painel inteiro ao clicar
                              });
                              print("Feedback positivo enviado");
                            },
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