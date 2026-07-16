import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marquee/marquee.dart'; 
import 'package:oxdata/app/core/services/device_service.dart';
import 'package:oxdata/app/core/models/image_url_model.dart';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:oxdata/app/core/utils/device.dart' as device_utils;
import 'package:oxdata/app/core/widgets/screensaver_oxford.dart';
import 'package:oxdata/app/core/widgets/adaptive_fit_image.dart';

class FullScreenTvPopup extends StatefulWidget {
  const FullScreenTvPopup({super.key});

  @override
  State<FullScreenTvPopup> createState() => _FullScreenTvPopupState();
}

class _FullScreenTvPopupState extends State<FullScreenTvPopup> {
  int _currentIndex = 0;
  bool _sidebarExpanded = true;
  bool _slideshowOn = true; // inicia com o slider ativo
  
  Timer? _slideshowTimer;
  Timer? _apiRefreshTimer;

  String? _guid;
  String? _username;

  // Identificação fixa da TV para consulta ao endpoint TvDeviceIMG.
  //static const String _fixedGuid = '0218805c-ab50-486f-8656-aeb60ad0b769';
  // static const String _fixedUser = 'diones';
  static const double _sidebarWidth = 200.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final storage = StorageService();

      // Usa o prefixo do alias para resolver a ambiguidade
      final guid = await device_utils.DeviceService.getDeviceId();

      final credentials = await storage.readCredentials();
      final username = credentials['username'];

      if (!mounted) return;

      setState(() {
        _guid = guid;
        _username = username;
      });

      /*if (_guid == null || _guid!.isEmpty || _username == null || _username!.isEmpty) {
        return;
      }*/

      _fetchData();
      _startApiRefreshTimer();
    });
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    _apiRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    final deviceService = context.read<DeviceService>();
    await deviceService.fetchTvDeviceImages(guid: _guid!, user: _username!);

    // 2. Se o slideshow estiver marcado para ligar e houver mais de uma imagem, inicia o Timer
    if (_slideshowOn && deviceService.tvDeviceImages.length > 1 && _slideshowTimer == null) {
      _toggleSlideshow(true, deviceService.tvDeviceImages.length);
    }
  }

  void _startApiRefreshTimer() {
    _apiRefreshTimer?.cancel();
    _apiRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchData();
    });
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
    final imageLoading = context.watch<DeviceService>().isLoadingTvImages;
    final errorMessage = context.watch<DeviceService>().errorMessage;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: () {
          final currentImages = context.read<DeviceService>().tvDeviceImages;
          if (imageLoading && currentImages.isEmpty) {
            return const Center(
              child: SpinKitThreeBounce(color: Colors.white, size: 30.0),
            );
          }

          if (errorMessage != null && currentImages.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Consumer<DeviceService>(
            builder: (context, deviceService, child) {
              final images = deviceService.tvDeviceImages;

              if (images.isEmpty) {
                return const ScreensaverOxford();
              }

              if (_currentIndex >= images.length) {
                _currentIndex = 0;
              }

              final currentUrl = "https://oxfordtec.com.br/Imagens/${images[_currentIndex].imagePath}";
              final currentProductId = images[_currentIndex].productId;
              final currentFinalidade = images[_currentIndex].finalidade;

              return Column(
                children: [
                  Container(
                    height: 68,
                    color: Colors.grey[200],
                    child: Marquee(
                      text: 'Produto: $currentProductId - $currentFinalidade',
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

                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSidebar(images, deviceService),
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: _buildMainImage(currentUrl),
                              ),
                              if (!_sidebarExpanded)
                                Positioned(
                                  top: 12,
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
          );
        }(),
      ),
    );
  }

  Widget _buildSidebar(List<ImageUrlModel> images, DeviceService deviceService) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: _sidebarExpanded ? _sidebarWidth : 0,
      color: const Color(0xFF111111),
      child: _sidebarExpanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 0, bottom: 0, left: 6, right: 6),
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
                          padding: EdgeInsets.only(top: 6, bottom: 6, left: 3, right: 6),
                          child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _currentIndex;
                      final thumbnailUrl = "https://oxfordtec.com.br/Imagens/${images[index].imagePath}";
                      
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
                              child: _buildThumbnail(thumbnailUrl),
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

  Widget _buildThumbnail(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
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
      },
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image, color: Colors.white24, size: 26),
    );
  }

  /*
  Widget _buildMainImage(String url) {
    return InteractiveViewer(
      key: ValueKey(url),
      minScale: 1.0,
      maxScale: 4.0,
      clipBehavior: Clip.none,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: SpinKitThreeBounce(color: Colors.white, size: 30.0),
            );
          },
          errorBuilder: (context, error, stackTrace) =>
              const Center(
                child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
              ),
        ),
      ),
    );
  }
  */

  Widget _buildMainImage(String url) {
    return InteractiveViewer(
      key: ValueKey(url),
      minScale: 1.0,
      maxScale: 4.0,
      clipBehavior: Clip.none,
      child: AdaptiveFitImage(
        imageUrl: url,
        letterboxColor: Colors.black,
        loadingBuilder: (context) => const Center(
          child: SpinKitThreeBounce(color: Colors.white, size: 30.0),
        ),
        errorBuilder: (context) => const Center(
          child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSlideshowSwitch(int totalImages) {
    return Container(
      padding: EdgeInsets.zero,
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