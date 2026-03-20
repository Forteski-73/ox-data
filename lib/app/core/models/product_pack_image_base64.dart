class ImagePackBase64 {
  final String  codeId;
  final String  imagePath;
  final int     sequence;
  final String? imagesBase64;

  ImagePackBase64({
    required this.codeId,
    required this.imagePath,
    required this.sequence,
    this.imagesBase64,
  });

  factory ImagePackBase64.fromJson(Map<String, dynamic> json) {
    return ImagePackBase64(
      codeId:       json['codeId'] ?? '',
      imagePath:    json['imagePath'] ?? '',
      sequence:     json['sequence'] ?? 1,
      imagesBase64: json['imagesBase64'],
    );
  }
}