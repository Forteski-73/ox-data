import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
// Certifique-se de que o pacote marquee esteja importado em seu pubspec.yaml
import 'package:marquee/marquee.dart'; 
import 'package:oxdata/app/core/services/product_packing_service.dart';
import 'package:oxdata/app/core/models/product_pack_image_base64.dart';
import 'package:oxdata/app/core/utils/image_base.dart';

class FullScreenPackPopup extends StatefulWidget {
  final int packId;
  final String? productName;

  const FullScreenPackPopup({
    super.key,
    required this.packId,
    this.productName,
  });

  @override
  State<FullScreenPackPopup> createState() => _FullScreenPackPopupState();
}

class _FullScreenPackPopupState extends State<FullScreenPackPopup> {
  int _currentIndex = 0;
  bool _sidebarExpanded = true;
  bool _slideshowOn = false;
  Timer? _slideshowTimer;

  // Cache de bytes já decodificados, pra não decodificar de novo a cada rebuild.
  final Map<String, Uint8List> _decodedCache = {};

  // Largura da sidebar
  static const double _sidebarWidth = 200.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductPackingService>().fetchPackImages(widget.packId);
    });
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    super.dispose();
  }

  String _keyFor(ImagePackBase64 image, int index) =>
      image.imagePath ?? 'idx_$index';

  Future<Uint8List?> _decode(ImagePackBase64 image, int index) async {
    final key = _keyFor(image, index);
    if (_decodedCache.containsKey(key)) {
      return _decodedCache[key];
    }
    final dataUri = await ImageBase.decodeAndExtractSingleImage(image.imagesBase64);
    if (dataUri == null) return null;
    final bytes = base64Decode(dataUri.split(',').last);
    _decodedCache[key] = bytes;
    return bytes;
  }

  void _toggleSlideshow(bool value, int totalImages) {
    setState(() => _slideshowOn = value);
    _slideshowTimer?.cancel();
    if (value && totalImages > 1) {
      _slideshowTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        setState(() => _currentIndex = (_currentIndex + 1) % totalImages);
      });
    }
  }

  void _selectImage(int index) {
    setState(() {
      _currentIndex = index;
      if (_slideshowOn) {
        _slideshowOn = false;
        _slideshowTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<ProductPackingService>(
          builder: (context, packingService, child) {
            if (packingService.isLoading) {
              return const Center(
                child: SpinKitThreeBounce(color: Colors.white, size: 30.0),
              );
            }

            final images = packingService.packImages;

            /*
            if (images.isEmpty) {
              return const Center(
                child: Text(
                  'Nenhuma imagem disponível para esta embalagem.',
                  style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                ),
              );
            }
            */

            if (_currentIndex >= images.length) {
              _currentIndex = 0;
            }

            return Column(
              children: [
                // Letreiro Marquee ocupando toda a largura no topo absoluto da tela
                Container(
                  height: 68,
                  color: Colors.grey[200],
                  child: Marquee(
                    text: '${widget.productName}',
                    style: const TextStyle(
                      fontSize: 40, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.black87,
                    ),
                    blankSpace: 120.0,
                    velocity: 60.0, 
                    pauseAfterRound: const Duration(seconds: 1),
                    startPadding: 16.0,
                    fadingEdgeStartFraction: 0.1,
                    fadingEdgeEndFraction: 0.1,
                  ),
                ),

                // 2. O conteúdo restante da tela (Sidebar + Imagem Principal) ocupa o resto do espaço
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSidebar(images),
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _buildMainImage(images[_currentIndex], _currentIndex),
                            ),
                            if (!_sidebarExpanded)
                              Positioned(
                                top: 12, // Ajustado de 60 para 12 já que a barra flutuante sumiu
                                left: 8,
                                child: _buildSidebarToggleButton(),
                              ),
                            if (images.length > 1)
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: _buildPositionBadge(images.length),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSidebar(List<ImagePackBase64> images) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: _sidebarExpanded ? _sidebarWidth : 0,
      color: const Color(0xFF111111),
      child: _sidebarExpanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // Contador de fotos e botão de recolher a sidebar
                Padding(
                  padding: const EdgeInsets.only(top: 0, bottom: 0, left: 6, right: 6, ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      _buildSlideshowSwitch(images.length),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() => _sidebarExpanded = false),
                        child: const Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 6, left: 3, right: 6,),
                          child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),

                // Lista de miniaturas
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _currentIndex;
                      return GestureDetector(
                        onTap: () => _selectImage(index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? Colors.blueAccent : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: _buildThumbnail(images[index], index),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildSidebarToggleButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _sidebarExpanded = true),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildThumbnail(ImagePackBase64 image, int index) {
    return FutureBuilder<Uint8List?>(
      future: _decode(image, index),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.white10,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Container(
            color: Colors.white10,
            child: const Icon(Icons.broken_image, color: Colors.white24, size: 26),
          );
        }
        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, color: Colors.white24, size: 26),
        );
      },
    );
  }

  Widget _buildMainImage(ImagePackBase64 image, int index) {
    return FutureBuilder<Uint8List?>(
      key: ValueKey(_keyFor(image, index)),
      future: _decode(image, index),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SpinKitThreeBounce(color: Colors.white, size: 30.0),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
          );
        }
        return InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          clipBehavior: Clip.none,
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 100, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlideshowSwitch(int totalImages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: _slideshowOn,
              activeColor: Colors.blueAccent,
              onChanged: totalImages > 1
                  ? (value) => _toggleSlideshow(value, totalImages)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionBadge(int totalImages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${_currentIndex + 1} / $totalImages',
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}