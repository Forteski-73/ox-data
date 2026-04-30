import 'package:oxdata/app/core/models/product_pack_image_base64.dart';
import 'package:oxdata/app/core/models/product_pack_item.dart';

class ProductPackingModel {
  final int       packId;
  final String    packName;
  final String?   packUser;
  final DateTime? packCreated;

  List<dynamic>         images;       // metadata
  List<ImagePackBase64> imageBase64;  // base64 carregado depois
  List<ProductPackItem> items;

  ProductPackingModel({
    required this.packId,
    required this.packName,
    this.packUser,
    this.packCreated,
    required this.images,
    List<ImagePackBase64>? imageBase64,
    required this.items,
  }) : imageBase64 = imageBase64 ?? [];

  factory ProductPackingModel.fromJson(Map<String, dynamic> json) {
    return ProductPackingModel(
      packId:       json['packId'] ?? 0,
      packName:     json['packName'] ?? '',
      packUser:     json['packUser'],
      packCreated:  json['packCreated'] != null 
          ? DateTime.parse(json['packCreated']) 
          : null,

      // vem da API
      images: List<dynamic>.from(json['images'] ?? []),

      // NÃO vem da API → começa vazio
      imageBase64: [],

      // converter corretamente
      items: (json['items'] as List? ?? [])
          .map((e) => ProductPackItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    "packId":       packId,
    "packName":     packName,
    "packUser":     packUser,
    "packCreated":  packCreated?.toIso8601String(),
    "images":       images,
    "items":        items,
  };

}