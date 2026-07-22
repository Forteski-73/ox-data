// -----------------------------------------------------------
// app/core/services/video_service.dart
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:oxdata/app/core/models/video_model.dart';
import 'package:oxdata/app/core/repositories/video_repository.dart';

/// Service responsável por expor os dados de vídeos para a UI,
/// consumindo o VideoRepository (que fala com o VideoController da API).
class VideoService with ChangeNotifier {
  final VideoRepository _videoRepository;

  VideoService({required VideoRepository videoRepository})
      : _videoRepository = videoRepository;

  List<VideoModel> _videos = [];
  List<VideoModel> get videos => _videos;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Busca todos os vídeos ativos.
  Future<void> fetchAllVideos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _videoRepository.getAllVideos();

    if (response.success && response.data != null) {
      _videos = response.data!;
    } else {
      _videos = [];
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Agrupa os vídeos já carregados por categoria, mantendo a ordem
  /// em que vieram da API (que já respeita display_order das duas tabelas).
  /// Útil pra montar seções na tela do Guia do Usuário.
  Map<String, List<VideoModel>> get videosByCategory {
    final Map<String, List<VideoModel>> grouped = {};
    for (final video in _videos) {
      final key = video.categoryName ?? 'OUTROS';
      grouped.putIfAbsent(key, () => []).add(video);
    }
    return grouped;
  }

  void clear() {
    _videos = [];
    _errorMessage = null;
    notifyListeners();
  }
}