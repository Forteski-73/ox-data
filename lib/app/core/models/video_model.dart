// -----------------------------------------------------------
// app/core/models/video_model.dart
// -----------------------------------------------------------
class VideoModel {
  final int id;
  final String title;
  final String? description;
  final String videoUrl;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final int videoOrder;
  final String? categoryName;
  final String? categoryColor;
  final String? categoryIcon;

  VideoModel({
    required this.id,
    required this.title,
    this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    this.durationSeconds,
    required this.videoOrder,
    this.categoryName,
    this.categoryColor,
    this.categoryIcon,
  });

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      videoUrl: map['videoUrl'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      durationSeconds: map['durationSeconds'] as int?,
      videoOrder: map['videoOrder'] as int,
      categoryName: map['categoryName'] as String?,
      categoryColor: map['categoryColor'] as String?,
      categoryIcon: map['categoryIcon'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      'videoUrl': videoUrl,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      'videoOrder': videoOrder,
      if (categoryName != null) 'categoryName': categoryName,
      if (categoryColor != null) 'categoryColor': categoryColor,
      if (categoryIcon != null) 'categoryIcon': categoryIcon,
    };
  }

  /// Duração formatada como MM:SS (ou HH:MM:SS se passar de 1h).
  /// Útil pra exibir direto na UI sem lógica espalhada pelos widgets.
  String get formattedDuration {
    if (durationSeconds == null) return '--:--';
    final duration = Duration(seconds: durationSeconds!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}