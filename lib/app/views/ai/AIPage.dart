import 'dart:convert';
import 'dart:typed_data'; // Importação necessária para o Uint8List
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

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

  /// Redimensiona uma lista de bytes de imagem para no máximo 600x600 mantendo a proporção.
  /// Retorna a string em Base64 pronta para envio.
  Future<String> _resizeAndEncodeToBase64(Uint8List originalBytes) async { // Tipo alterado para Uint8List
    // 1. Decodifica os bytes originais para o formato do pacote 'image'
    final img.Image? decodedImage = img.decodeImage(originalBytes);
    
    if (decodedImage == null) {
      throw Exception('Falha ao decodificar a imagem para redimensionamento.');
    }

    // 2. Redimensiona para caber dentro de 600x600, mantendo a proporção
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
          _decorationResult = data['categoria'] != null && data['similaridade'] != null
              ? "${data['categoria']} (${data['similaridade'].toStringAsFixed(2)}%)"
              : 'Não identificado';
          
          // Salva a imagem tratada pelo backend no estado
          _processedImageBase64 = data['imagem_processada'];
        });

        //MessageService.showSuccess('Imagem identificada com sucesso!');
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

  /*
  Future<void> _analyzeImage() async {
    final loadingService = context.read<LoadingService>();

    await CallAction.run(
      action: () async {
        if (!_cameraInitialized) {
          throw Exception('Câmera ainda não inicializada.');
        }

        loadingService.show();

        final XFile picture = await _cameraController.takePicture();
        final bytes = await picture.readAsBytes();
        final base64Image = base64Encode(bytes);

        final data = await _aiService.analisarImagem(base64Image);

        setState(() {
          _decorationResult = data['categoria'] != null && data['similaridade'] != null
              ? "${data['categoria']} (${data['similaridade'].toStringAsFixed(2)}%)"
              : 'Não identificado';
          
          // Salva a imagem tratada pelo backend no estado
          _processedImageBase64 = data['imagem_processada'];
        });

        MessageService.showSuccess('Imagem identificada com sucesso!');
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
  */

  /*
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
        final base64Image = base64Encode(bytes);

        final data = await _aiService.analisarImagem(base64Image);

        setState(() {
          _decorationResult = data['categoria'] != null && data['similaridade'] != null
              ? "${data['categoria']} (${data['similaridade'].toStringAsFixed(2)}%)"
              : 'Não identificado';
          
          // Salva a imagem tratada pelo backend no estado
          _processedImageBase64 = data['imagem_processada'];
        });

        MessageService.showSuccess('Imagem identificada com sucesso!');
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
  */

  Future<void> _pickImageFromGallery() async {
    final loadingService = context.read<LoadingService>();

    await CallAction.run(
      action: () async {
        loadingService.show();

        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          // Mantive em 90 ou você pode até remover, já que nosso método trata o peso final
          imageQuality: 90, 
        );

        if (image == null) return;

        final bytes = await image.readAsBytes();
        
        // REUTILIZAÇÃO: Redimensiona para 600x600 e converte em Base64 de forma idêntica à câmera
        final base64Image = await _resizeAndEncodeToBase64(bytes);

        final data = await _aiService.analisarImagem(base64Image);

        setState(() {
          _decorationResult = data['categoria'] != null && data['similaridade'] != null
              ? "${data['categoria']} (${data['similaridade'].toStringAsFixed(2)}%)"
              : 'Não identificado';
          
          // Salva a imagem tratada pelo backend no estado
          _processedImageBase64 = data['imagem_processada'];
        });

        //MessageService.showSuccess('Imagem identificada com sucesso!');
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

            // 2. Overlay de Área
            /*Center(
              child: CustomPaint(
                size: const Size(280, 280),
                painter: ScannerBorderPainter(),
              ),
            ),*/

            // 3. Resultado da Identificação com Design Cyber-Glass Futurista
            if (_decorationResult != null)
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
                          // Fundo semi-transparente que reage ao conteúdo de trás
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
                                  width: 120, // Tamanho sutilmente reduzido para melhor balanço visual
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
                                    // Fundo do balão sutilmente contrastante com o vidro de trás
                                    color: Colors.white.withOpacity(0.9), 
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                      topLeft: Radius.circular(2), // Canto pontudo simulando o balão de chat
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
                            baseColor: const Color(0xFFEF4444), // Vermelho
                            onTap: () {
                              // TODO: Sua lógica para quando a IA errar
                              print("Feedback negativo enviado");
                            },
                          ),

                          const SizedBox(width: 12),

                          // 2. Botão de Feedback Positivo (Verde Futurista com Flash)
                          CyberGlassButton(
                            size: 120,
                            icon: Icons.thumb_up_alt_rounded,
                            baseColor: const Color(0xFF10B981), // Verde
                            onTap: () {
                              // TODO: Sua lógica para salvar na base de conhecimento
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
                      // Botão Galeria (Tamanho 70)
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

                      CyberGlassButton(
                        size: 80,
                        icon: Icons.photo_camera_rounded,
                        baseColor: Colors.indigo, // Verde Esmeralda
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

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:oxdata/app/core/services/ai_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/services/message_service.dart';
import 'package:oxdata/app/core/utils/call_action.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/widgets/pulse_icon.dart';

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

  Future<void> _analyzeImage() async {
    final loadingService = context.read<LoadingService>();

    await CallAction.run(
      action: () async {
        if (!_cameraInitialized) {
          throw Exception('Câmera ainda não inicializada.');
        }

        loadingService.show();

        // Tira a foto
        final XFile picture =
            await _cameraController.takePicture();

        // Converte para bytes
        final bytes = await picture.readAsBytes();

        // Base64
        final base64Image = base64Encode(bytes);

        // Envia para API
        final data = await _aiService.analisarImagem(base64Image);

        setState(() {
          _decorationResult = data['categoria'] != null && data['similaridade'] != null
              ? "${data['categoria']} (${data['similaridade'].toStringAsFixed(2)}%)"
              : 'Não identificado';
        });

        MessageService.showSuccess('Imagem identificada com sucesso!',);
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

        final XFile? image =
            await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
        );

        if (image == null) {
          return;
        }

        final bytes = await image.readAsBytes();

        final base64Image = base64Encode(bytes);

        final data =
            await _aiService.analisarImagem(base64Image);

        setState(() {
          _decorationResult = data['categoria'] != null && data['similaridade'] != null
              ? "${data['categoria']} (${data['similaridade'].toStringAsFixed(2)}%)"
              : 'Não identificado';
        });

        MessageService.showSuccess(
          'Imagem identificada com sucesso!',
        );
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
        preferredSize: Size.fromHeight(
          kToolbarHeight,
        ),
        child: AppBarCustom(
          title: 'Assistente IA - Visão',
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Camera Preview
            Positioned.fill(
              child: _cameraInitialized
                  ? CameraPreview(
                      _cameraController,
                    )
                  : const Center(
                      child:
                          CircularProgressIndicator(),
                    ),
            ),

            // 2. Overlay de Área
            Center(
              child: CustomPaint(
                size: const Size(280, 280),
                painter: ScannerBorderPainter(),
              ),
            ),

            // 3. Resultado da Identificação
            if (_decorationResult != null)
              Positioned(
                top: 20,
                left: 30,
                right: 30,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withOpacity(
                      0.9,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.1),
                        blurRadius: 10,
                        offset:
                            const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Text(
                    _decorationResult!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 15,
                      color: Colors.indigo,
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
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 25,
                  ),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      // Botão Galeria
                      Container(
                        decoration:
                            BoxDecoration(
                          shape:
                              BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors
                                  .black
                                  .withOpacity(
                                0.2,
                              ),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: SizedBox(
                          width: 70,
                          height: 70,
                          child:
                              PulseIconButton(
                            icon: Icons
                                .photo_library_rounded,
                            color:
                                Colors.white,
                            size: 45,
                            onPressed:
                                _pickImageFromGallery,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 25,
                      ),

                      // Botão Principal
                      Container(
                        decoration:
                            BoxDecoration(
                          shape:
                              BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors
                                  .black
                                  .withOpacity(
                                0.2,
                              ),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child:
                              PulseIconButton(
                            icon: Icons
                                .check_circle_rounded,
                            color: Colors
                                .cyanAccent,
                            size: 60,
                            onPressed:
                                _analyzeImage,
                          ),
                        ),
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

/// Pintor para a moldura de scan
class ScannerBorderPainter
    extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height,
      ),
      const Radius.circular(180),
    );

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) =>
      false;
}
*/