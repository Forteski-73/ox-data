import 'package:flutter/material.dart';

/// Exibe uma imagem de rede decidindo automaticamente a melhor estratégia
/// de enquadramento:
/// - Imagens com proporção próxima da tela (ex.: paisagem/16:9) usam
///   [BoxFit.cover], preenchendo o espaço todo sem barras.
/// - Imagens quadradas ou com proporção muito diferente (retrato, quadrada)
///   usam [BoxFit.contain] com barras neutras nas laterais/topo, evitando
///   zoom excessivo/corte agressivo do conteúdo.
class AdaptiveFitImage extends StatefulWidget {
  final String imageUrl;
  final Color letterboxColor;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context)? errorBuilder;

  /// Tolerância de proporção: se a diferença relativa entre a proporção
  /// da imagem e a da área disponível for menor que este valor, usa
  /// `cover`; caso contrário, usa `contain` com letterbox.
  final double aspectRatioTolerance;

  const AdaptiveFitImage({
    super.key,
    required this.imageUrl,
    this.letterboxColor = Colors.black,
    this.loadingBuilder,
    this.errorBuilder,
    this.aspectRatioTolerance = 0.25,
  });

  @override
  State<AdaptiveFitImage> createState() => _AdaptiveFitImageState();
}

class _AdaptiveFitImageState extends State<AdaptiveFitImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;

  double? _imageAspectRatio;
  bool _hasError = false;

  @override
  void didUpdateWidget(covariant AdaptiveFitImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageAspectRatio = null;
      _hasError = false;
      _resolveImage();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imageAspectRatio == null && !_hasError) {
      _resolveImage();
    }
  }

  void _resolveImage() {
    final provider = NetworkImage(widget.imageUrl);
    final newStream = provider.resolve(createLocalImageConfiguration(context));

    _listener?.let((l) => _stream?.removeListener(l));

    final listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!mounted) return;
        final width = info.image.width.toDouble();
        final height = info.image.height.toDouble();
        setState(() => _imageAspectRatio = width / height);
      },
      onError: (error, stackTrace) {
        if (!mounted) return;
        setState(() => _hasError = true);
      },
    );

    _stream = newStream;
    _listener = listener;
    newStream.addListener(listener);
  }

  @override
  void dispose() {
    if (_listener != null) {
      _stream?.removeListener(_listener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorBuilder?.call(context) ??
          const Center(
            child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
          );
    }

    if (_imageAspectRatio == null) {
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final areaAspectRatio = constraints.maxWidth / constraints.maxHeight;
        final diff = (_imageAspectRatio! - areaAspectRatio).abs() / areaAspectRatio;

        final useCover = diff <= widget.aspectRatioTolerance;

        return Container(
          color: widget.letterboxColor,
          alignment: Alignment.center,
          child: Image.network(
            widget.imageUrl,
            fit: useCover ? BoxFit.cover : BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) =>
                widget.errorBuilder?.call(context) ??
                const Center(
                  child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                ),
          ),
        );
      },
    );
  }
}

extension _Let<T> on T {
  void let(void Function(T) block) => block(this);
}