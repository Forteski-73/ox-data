// -----------------------------------------------------------
// app/core/models/image_url_model.dart
// -----------------------------------------------------------
class ImageUrlModel {
  final String productId;
  final String imagePath;
  final int sequence;
  final bool imageMain;
  final String finalidade;

  ImageUrlModel({
    required this.productId,
    required this.imagePath,
    required this.sequence,
    required this.imageMain,
    required this.finalidade,
  });

  factory ImageUrlModel.fromMap(Map<String, dynamic> map) {
    return ImageUrlModel(
      productId: map['productId'] as String,
      imagePath: map['imagePath'] as String,
      sequence: map['sequence'] as int,
      imageMain: map['imageMain'] as bool,
      finalidade: map['finalidade'] as String,
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
}