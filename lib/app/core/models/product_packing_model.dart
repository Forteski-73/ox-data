class ProductPackingModel {
  final int packId;
  final String packName;
  final String? packUser;
  final DateTime? packCreated;
  final List<dynamic> images;
  final List<dynamic> items;

  ProductPackingModel({
    required this.packId,
    required this.packName,
    this.packUser,
    this.packCreated,
    required this.images,
    required this.items,
  });

  factory ProductPackingModel.fromJson(Map<String, dynamic> json) {
    return ProductPackingModel(
      packId: json['packId'] ?? 0,
      packName: json['packName'] ?? '',
      packUser: json['packUser'],
      packCreated: json['packCreated'] != null 
          ? DateTime.parse(json['packCreated']) 
          : null,
      images: List<dynamic>.from(json['images'] ?? []),
      items: List<dynamic>.from(json['items'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    "packId": packId,
    "packName": packName,
    "packUser": packUser,
    "packCreated": packCreated?.toIso8601String(),
    "images": images,
    "items": items,
  };
}