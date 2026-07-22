// -----------------------------------------------------------
// app/pages/guide/guide_page.dart
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/models/video_model.dart';
import 'package:oxdata/app/core/services/video_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';

// ─────────────────────────────────────────────────────────────────
// CATALOG PAGE
// ─────────────────────────────────────────────────────────────────

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVideos());
  }

  /// Busca os vídeos usando o LoadingService global pra exibir o overlay.
  Future<void> _loadVideos() async {
    final loadingService = context.read<LoadingService>();
    loadingService.show();
    try {
      await context.read<VideoService>().fetchAllVideos();
    } finally {
      if (mounted) loadingService.hide();
    }
  }

  Future<void> _openPlayer(VideoModel video) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (_) => _VideoPlayerDialog(video: video),
    );
  }

  int _getColumnCount(double screenWidth) {
    if (screenWidth < 600) return 2;
    if (screenWidth < 1024) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = _getColumnCount(screenWidth);

    const double paddingHorizontal = 16.0;
    const double spacing = 16.0;

    final cardWidth = (screenWidth -
            (paddingHorizontal * 2) -
            (spacing * (crossAxisCount - 1))) /
        crossAxisCount;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBarCustom(title: 'GUIA DO USUÁRIO'),
      ),
      backgroundColor: const Color(0xFFF1F4F9),
      body: Consumer<VideoService>(
        builder: (context, videoService, _) {
          // Enquanto o LoadingService global está mostrando o overlay,
          // não faz sentido também renderizar erro/vazio por baixo —
          // então só decide o conteúdo quando não está carregando.
          final loadingService = context.watch<LoadingService>();

          if (loadingService.isLoading && videoService.videos.isEmpty) {
            // o overlay global (montado no root do app)
            // já cobre a tela inteira durante o carregamento.
            return const SizedBox.shrink();
          }

          if (videoService.errorMessage != null) {
            return _buildErrorState(
              message: videoService.errorMessage!,
              onRetry: _loadVideos,
            );
          }

          final videos = videoService.videos;

          if (videos.isEmpty) {
            return _buildEmptyState(onRetry: _loadVideos);
          }

          return RefreshIndicator(
            onRefresh: _loadVideos,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                paddingHorizontal,
                20,
                paddingHorizontal,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      '${videos.length} vídeos disponíveis',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: List.generate(videos.length, (index) {
                      return SizedBox(
                        width: cardWidth,
                        child: _VideoCard(
                          video: videos[index],
                          index: index,
                          onTap: () => _openPlayer(videos[index]),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library_outlined,
                size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text(
              'Nenhum vídeo disponível no momento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Atualizar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// VIDEO CARD
// ─────────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final VideoModel video;
  final int index;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.index,
    required this.onTap,
  });

  /// Converte a cor hex vinda da API (ex: '#22C55E') em Color.
  /// Se vier nula/inválida, cai num laranja padrão.
  Color _categoryColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFF59E0B);
    var value = hex.replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    try {
      return Color(int.parse(value, radix: 16));
    } catch (_) {
      return const Color(0xFFF59E0B);
    }
  }

  /// Mapeia o nome do ícone (vindo da API) pro IconData do Flutter.
  /// Adicione novos casos aqui conforme surgirem novas categorias.
  IconData _categoryIconData(String? iconName) {
    switch (iconName) {
      case 'space_dashboard_rounded':
        return Icons.space_dashboard_rounded;
      case 'inventory_2_rounded':
        return Icons.inventory_2_rounded;
      case 'inventory_rounded':
        return Icons.inventory_rounded;
      case 'bar_chart_rounded':
        return Icons.bar_chart_rounded;
      default:
        return Icons.play_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail: ícone temático por categoria
                  Container(
                    color: const Color(0xFF1E293B),
                    child: Icon(
                      _categoryIconData(video.categoryIcon),
                      size: 52,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  if (video.categoryName != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _categoryColor(video.categoryColor),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          video.categoryName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        video.formattedDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Color(0xFF4A6CF7),
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    video.description ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// VIDEO PLAYER DIALOG
// ─────────────────────────────────────────────────────────────────

class _VideoPlayerDialog extends StatefulWidget {
  final VideoModel video;

  const _VideoPlayerDialog({required this.video});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _isReady = false;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.videoUrl),
    );
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _isReady = true);
      _controller.play();
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.hardEdge,
      child: _hasError
          ? _buildErrorState()
          : _isReady
              ? _buildPlayer()
              : _buildLoadingState(),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 220,
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar o vídeo.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    return GestureDetector(
      onTap: _toggleControls,
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio == 0
            ? 16 / 9
            : _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          fit: StackFit.expand,
          children: [
            VideoPlayer(_controller),

            // Overlay de controles (fade)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showControls ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.35),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                      ],
                      stops: const [0.0, 0.2, 0.7, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Botão fechar
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),

                      // Play/Pause central
                      Center(
                        child: IconButton(
                          icon: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 56,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                      ),

                      // Barra de progresso + tempo
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 8,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              padding: EdgeInsets.zero,
                              colors: const VideoProgressColors(
                                playedColor: Color(0xFF4A6CF7),
                                bufferedColor: Colors.white30,
                                backgroundColor: Colors.white12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_controller.value.position),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  _formatDuration(_controller.value.duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}