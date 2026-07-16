import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';

class DevPage extends StatelessWidget {
  const DevPage({super.key});

  // Como boa prática, isolamos a URL do asset. 
  // isso viria de um State Manager, injetado no construtor.
  static const String _modelUrl = 'https://oxfordtec.com.br/Imagens/GLB/Analise1.glb';
  static const Color _backgroundColor = Color(0xFFF5F5F5); // Fundo neutro destaca o modelo 3D

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: const AppBarCustom(title: 'PALLET 3D'),
      // O SafeArea garante que o modelo não invada os recortes de tela (Notch/Dynamic Island)
      body: const SafeArea(
        child: ModelViewer(
          src: _modelUrl,
          alt: 'Visualização 3D do modelo Analise1',
          
          // UI / UX
          autoRotate: true,          // Habilita o giro automático ao carregar
          autoRotateDelay: 0,        // Começa a girar imediatamente
          cameraControls: true,      // Permite pan, zoom e rotação via touch/mouse
          
          // Performance / Rendering
          ar: false,                 // Desativado se não for usar Realidade Aumentada (poupa recursos)
          backgroundColor: _backgroundColor,
          
          // O model-viewer já possui um loading state nativo elegante, 
          // mas da para personalizar as cores via CSS interno se necessário.
        ),
      ),
    );
  }
}