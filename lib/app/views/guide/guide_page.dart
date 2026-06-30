import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoModel {
  final String title;
  final String driveId;
  final String description;
  final String duration;
  final String category;

  const VideoModel({
    required this.title,
    required this.driveId,
    required this.description,
    this.duration = '',
    this.category = '',
  });

  String get viewUrl => 'https://drive.google.com/file/d/$driveId/view';
}

// ─────────────────────────────────────────────────────────────────
// CATALOG PAGE
// ─────────────────────────────────────────────────────────────────

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final List<VideoModel> _videos = const [
    VideoModel(
      title: 'INTRODUÇÃO AO APP',
      driveId: '1fcsw5PHrzGRaLfNRcz0o7hJxIMhInMuH',
      description:
          'Conceitos básicos e utilidade geral do App: ACEP - Aplicativo de Consulta, Estrutura e Processos.',
      duration: '00:03:00',
      category: 'INTRODUÇÃO',
    ),
    VideoModel(
      title: 'MÓDULO DE INVENTÁRIO',
      driveId: '1fcsw5PHrzGRaLfNRcz0o7hJxIMhInMuH',
      description:
          'Passo a passo detalhado de como criar um inventário e fazer a contagem das peças',
      duration: '00:05:28',
      category: 'INVENTÁRIO',
    ),
    VideoModel(
      title: 'MÓDULO DE INVENTÁRIO',
      driveId: '1fcsw5PHrzGRaLfNRcz0o7hJxIMhInMuH',
      description:
          'Passo a passo detalhado de como criar um inventário e fazer a contagem das peças',
      duration: '00:05:28',
      category: 'INVENTÁRIO',
    ),
  ];

  Future<void> _openPlayer(VideoModel video) async {
    final uri = Uri.parse(video.viewUrl);
    
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o vídeo.')),
        );
      }
    }
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
      body: SingleChildScrollView(
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
                '${_videos.length} vídeos disponíveis',
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
              children: List.generate(_videos.length, (index) {
                return SizedBox(
                  width: cardWidth,
                  child: _VideoCard(
                    video: _videos[index],
                    index: index,
                    onTap: () => _openPlayer(_videos[index]),
                  ),
                );
              }),
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

  Color _categoryColor(String category) {
    switch (category) {
      case 'INTRODUÇÃO':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _thumbIcon(int i) {
    const icons = [
      Icons.space_dashboard_rounded,
      Icons.inventory_2_rounded,
      Icons.inventory_rounded,
      Icons.bar_chart_rounded,
    ];
    return icons[i % icons.length];
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
                      _thumbIcon(index),
                      size: 52,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _categoryColor(video.category),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        video.category,
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
                        video.duration,
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
                    video.description,
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