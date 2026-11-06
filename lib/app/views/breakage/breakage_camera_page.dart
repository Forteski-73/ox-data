import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oxdata/app/core/services/message_service.dart';

/// Tela de captura de foto usada na BreakagePage na versão web
/// (navegador do computador, tablet ou celular).
/// Retorna os bytes da foto (Uint8List) via Navigator.pop.
class BreakageCameraPage extends StatefulWidget {
  const BreakageCameraPage({super.key});

  @override
  State<BreakageCameraPage> createState() => _BreakageCameraPageState();
}

class _BreakageCameraPageState extends State<BreakageCameraPage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isCapturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('Nenhuma câmera encontrada.');
      }

      // Prefere a câmera traseira (celular/tablet); no computador usa a primeira.
      final backIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      _cameraIndex = backIndex >= 0 ? backIndex : 0;

      await _startCamera();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível acessar a câmera.\n$e');
    }
  }

  Future<void> _startCamera() async {
    final previous = _controller;
    final controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    setState(() => _controller = null);
    await previous?.dispose();
    await controller.initialize();

    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    try {
      await _startCamera();
    } catch (e) {
      MessageService.showError('Erro ao trocar de câmera: $e');
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      final file = await controller.takePicture();
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      Navigator.pop(context, bytes);
    } catch (e) {
      MessageService.showError('Erro ao tirar a foto: $e');
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  /// Preview ocupando a tela inteira (recorta as sobras, como o app de câmera do celular).
  Widget _buildFullScreenPreview(CameraController controller) {
    // Na web o vídeo já é criado com width/height 100% e object-fit: cover (camera_web);
    // basta ocupar a tela toda. Transformações (FittedBox) quebram o vídeo no Safari/iOS.
    if (kIsWeb) return SizedBox.expand(child: controller.buildPreview());

    final previewSize = controller.value.previewSize;
    if (previewSize == null) return controller.buildPreview();

    // No app nativo o previewSize vem em paisagem.
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final width = isPortrait ? previewSize.height : previewSize.width;
    final height = isPortrait ? previewSize.width : previewSize.height;

    return SizedBox.expand(
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(width: width, height: height, child: controller.buildPreview()),
        ),
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required String tooltip, VoidCallback? onPressed}) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  )
                : controller == null || !controller.value.isInitialized
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _buildFullScreenPreview(controller),
          ),

          // Botões superiores: fechar e trocar câmera
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCircleButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Fechar',
                      onPressed: _isCapturing ? null : () => Navigator.pop(context),
                    ),
                    if (_cameras.length > 1)
                      _buildCircleButton(
                        icon: Icons.cameraswitch_rounded,
                        tooltip: 'Trocar câmera',
                        onPressed: _isCapturing ? null : _switchCamera,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Botão de captura
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Center(
                  child: GestureDetector(
                    onTap: _error == null ? _takePicture : null,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _error == null ? Colors.white : Colors.white24,
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(18),
                                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
