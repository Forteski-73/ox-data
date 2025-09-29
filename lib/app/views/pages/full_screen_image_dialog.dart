import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart'; 

// Classe para exibir a imagem em tela cheia com zoom
class FullScreenImageDialog extends StatelessWidget {
  final String base64Image;

  const FullScreenImageDialog({Key? key, required this.base64Image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Uint8List bytes = base64Decode(base64Image);

    return Scaffold(
      backgroundColor: Colors.black, // Fundo preto é ideal para tela cheia
      body: Center(
        child: GestureDetector(
          // Duplo clique para fechar a tela cheia
          onDoubleTap: () => Navigator.pop(context), 
          child: InteractiveViewer(
            // Configurações de zoom na tela cheia
            minScale: 0.8,
            maxScale: 6.0, 
            child: Image.memory(
              bytes,
              fit: BoxFit.contain, // Ajusta a imagem para caber na tela
            ),
          ),
        ),
      ),
      // Adicione um botão de fechar para usabilidade
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}