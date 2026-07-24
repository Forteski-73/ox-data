// -----------------------------------------------------------
// app/core/models/image_url_model.dart
// -----------------------------------------------------------
class ImageUrlModel {
  final String productId;
  final String imagePath;
  final int sequence;
  final bool imageMain;
  final String finalidade;
  final DateTime? updatedAt;

  ImageUrlModel({
    required this.productId,
    required this.imagePath,
    required this.sequence,
    required this.imageMain,
    required this.finalidade,
    this.updatedAt,
  });

  factory ImageUrlModel.fromMap(Map<String, dynamic> map) {
    return ImageUrlModel(
      productId: map['productId'] as String,
      imagePath: map['imagePath'] as String,
      sequence: map['sequence'] as int,
      imageMain: map['imageMain'] as bool,
      finalidade: map['finalidade'] as String,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'imagePath': imagePath,
      'sequence': sequence,
      'imageMain': imageMain,
      'finalidade': finalidade,
    };
  }

  /// Retorna a URL da imagem com cache busting baseado em updatedAt.
  /// Garante que o Flutter (e o navegador) baixem a versão nova
  /// sempre que a imagem for atualizada no servidor, mesmo mantendo
  /// o mesmo nome de arquivo.
  String buildUrl(String baseUrl) {
    final url = "$baseUrl/$imagePath";
    if (updatedAt == null) return url;

    return "$url?v=${updatedAt!.millisecondsSinceEpoch}";
  }
}