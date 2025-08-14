import 'dart:convert';

/// Representa a entidade Product do C#.
class Product {
  String? productId;
  String? barcode;
  String? productName;
  bool? status; // Adicionado status, com base no uso em C#

  Product({
    this.productId,
    this.barcode,
    this.productName,
    this.status,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'] as String?,
      barcode: json['barcode'] as String?,
      productName: json['productName'] as String?,
      status: json['status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'barcode': barcode,
      'productName': productName,
      'status': status,
    };
  }
}

/// Representa a entidade Oxford do C#.
class Oxford {
  String? productId;
  String? familyDescription;
  String? brandDescription;
  String? lineDescription;
  String? decorationDescription;
  String? familyId; // Adicionado para compatibilidade com filtros
  String? brandId; // Adicionado para compatibilidade com filtros
  String? lineId; // Adicionado para compatibilidade com filtros
  String? decorationId; // Adicionado para compatibilidade com filtros
  String? typeId; // Adicionado para compatibilidade com filtros
  String? processId; // Adicionado para compatibilidade com filtros
  String? situationId; // Adicionado para compatibilidade com filtros
  String? qualityId; // Adicionado para compatibilidade com filtros
  String? baseProductId; // Adicionado para compatibilidade com filtros
  String? productGroupId; // Adicionado para compatibilidade com filtros
  String? baseProductDescription; // Adicionado para compatibilidade com ProductOxfordDetails

  Oxford({
    this.productId,
    this.familyDescription,
    this.brandDescription,
    this.lineDescription,
    this.decorationDescription,
    this.familyId,
    this.brandId,
    this.lineId,
    this.decorationId,
    this.typeId,
    this.processId,
    this.situationId,
    this.qualityId,
    this.baseProductId,
    this.productGroupId,
    this.baseProductDescription,
  });

  factory Oxford.fromJson(Map<String, dynamic> json) {
    return Oxford(
      productId: json['productId'] as String?,
      familyDescription: json['familyDescription'] as String?,
      brandDescription: json['brandDescription'] as String?,
      lineDescription: json['lineDescription'] as String?,
      decorationDescription: json['decorationDescription'] as String?,
      familyId: json['familyId'] as String?,
      brandId: json['brandId'] as String?,
      lineId: json['lineId'] as String?,
      decorationId: json['decorationId'] as String?,
      typeId: json['typeId'] as String?,
      processId: json['processId'] as String?,
      situationId: json['situationId'] as String?,
      qualityId: json['qualityId'] as String?,
      baseProductId: json['baseProductId'] as String?,
      productGroupId: json['productGroupId'] as String?,
      baseProductDescription: json['baseProductDescription'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'familyDescription': familyDescription,
      'brandDescription': brandDescription,
      'lineDescription': lineDescription,
      'decorationDescription': decorationDescription,
      'familyId': familyId,
      'brandId': brandId,
      'lineId': lineId,
      'decorationId': decorationId,
      'typeId': typeId,
      'processId': processId,
      'situationId': situationId,
      'qualityId': qualityId,
      'baseProductId': baseProductId,
      'productGroupId': productGroupId,
      'baseProductDescription': baseProductDescription,
    };
  }
}

/// Representa a entidade Invent do C#.
class Invent {
  String? productId;
  double? netWeight;
  double? taraWeight;
  double? grossWeight;
  double? grossDepth;
  double? grossWidth;
  double? grossHeight;
  double? unitVolume;
  double? unitVolumeML;
  int? nrOfItems;
  String? unitId;

  Invent({
    this.productId,
    this.netWeight,
    this.taraWeight,
    this.grossWeight,
    this.grossDepth,
    this.grossWidth,
    this.grossHeight,
    this.unitVolume,
    this.unitVolumeML,
    this.nrOfItems,
    this.unitId,
  });

  factory Invent.fromJson(Map<String, dynamic> json) {
    return Invent(
      productId: json['productId'] as String?,
      netWeight: (json['netWeight'] as num?)?.toDouble(),
      taraWeight: (json['taraWeight'] as num?)?.toDouble(),
      grossWeight: (json['grossWeight'] as num?)?.toDouble(),
      grossDepth: (json['grossDepth'] as num?)?.toDouble(),
      grossWidth: (json['grossWidth'] as num?)?.toDouble(),
      grossHeight: (json['grossHeight'] as num?)?.toDouble(),
      unitVolume: (json['unitVolume'] as num?)?.toDouble(),
      unitVolumeML: (json['unitVolumeML'] as num?)?.toDouble(),
      nrOfItems: json['nrOfItems'] as int?,
      unitId: json['unitId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'netWeight': netWeight,
      'taraWeight': taraWeight,
      'grossWeight': grossWeight,
      'grossDepth': grossDepth,
      'grossWidth': grossWidth,
      'grossHeight': grossHeight,
      'unitVolume': unitVolume,
      'unitVolumeML': unitVolumeML,
      'nrOfItems': nrOfItems,
      'unitId': unitId,
    };
  }
}

/// Representa a entidade InventDim (Location) do C#.
class InventDim {
  String? productId;
  String? locationId;
  double? price;
  double? quantity;

  InventDim({
    this.productId,
    this.locationId,
    this.price,
    this.quantity,
  });

  factory InventDim.fromJson(Map<String, dynamic> json) {
    return InventDim(
      productId: json['productId'] as String?,
      locationId: json['locationId'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'locationId': locationId,
      'price': price,
      'quantity': quantity,
    };
  }
}

/// Representa a entidade TaxInformation do C#.
class TaxInformation {
  String? productId;
  String? taxationOrigin;
  String? taxFiscalClassification;
  String? productType;
  String? cestCode;
  String? fiscalGroupId;
  double? approxTaxValueFederal;
  double? approxTaxValueState;
  double? approxTaxValueCity;

  TaxInformation({
    this.productId,
    this.taxationOrigin,
    this.taxFiscalClassification,
    this.productType,
    this.cestCode,
    this.fiscalGroupId,
    this.approxTaxValueFederal,
    this.approxTaxValueState,
    this.approxTaxValueCity,
  });

  factory TaxInformation.fromJson(Map<String, dynamic> json) {
    return TaxInformation(
      productId: json['productId'] as String?,
      taxationOrigin: json['taxationOrigin'] as String?,
      taxFiscalClassification: json['taxFiscalClassification'] as String?,
      productType: json['productType'] as String?,
      cestCode: json['cestCode'] as String?,
      fiscalGroupId: json['fiscalGroupId'] as String?,
      approxTaxValueFederal: json['approxTaxValueFederal'] is int
          ? (json['approxTaxValueFederal'] as int).toDouble()
          : json['approxTaxValueFederal'] as double?,
      approxTaxValueState: json['approxTaxValueState'] is int
          ? (json['approxTaxValueState'] as int).toDouble()
          : json['approxTaxValueState'] as double?,
      approxTaxValueCity: json['approxTaxValueCity'] is int
          ? (json['approxTaxValueCity'] as int).toDouble()
          : json['approxTaxValueCity'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'taxationOrigin': taxationOrigin,
      'taxFiscalClassification': taxFiscalClassification,
      'productType': productType,
      'cestCode': cestCode,
      'fiscalGroupId': fiscalGroupId,
      'approxTaxValueFederal': approxTaxValueFederal,
      'approxTaxValueState': approxTaxValueState,
      'approxTaxValueCity': approxTaxValueCity,
    };
  }
}

/// Representa a entidade ImageBase64 do C#.
class ImageBase64 {
  String? productId;
  String? imagePath;
  int? sequence;
  bool? imageMain;
  String? finalidade;
  String? imagesBase64; // Campo para a string Base64 do ZIP das imagens

  ImageBase64({
    this.productId,
    this.imagePath,
    this.sequence,
    this.imageMain,
    this.finalidade,
    this.imagesBase64,
  });

  factory ImageBase64.fromJson(Map<String, dynamic> json) {
    return ImageBase64(
      productId: json['productId'] as String?,
      imagePath: json['imagePath'] as String?,
      sequence: json['sequence'] as int?,
      imageMain: json['imageMain'] as bool?,
      finalidade: json['finalidade'] as String?,
      imagesBase64: json['imagesBase64'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'imagePath': imagePath,
      'sequence': sequence,
      'imageMain': imageMain,
      'finalidade': finalidade,
      'imagesBase64': imagesBase64,
    };
  }
}

/// Representa a entidade Tag do C#.
class Tag {
  int? id;
  String valueTag;
  String productId;

  Tag({
    this.id,
    required this.valueTag,
    required this.productId,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as int?,
      valueTag: json['valueTag'] as String,
      productId: json['productId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'valueTag': valueTag,
      'productId': productId,
    };
  }
}

// --- Classe Principal ProductComplete ---

/// Modelo completo de produto para o aplicativo, incluindo todas as informações relacionadas.
class ProductComplete {
  Product? product;
  Oxford? oxford;
  Invent? invent;
  InventDim? location;
  TaxInformation? taxInformation;
  List<ImageBase64>? images;
  List<Tag>? tags;

  ProductComplete({
    this.product,
    this.oxford,
    this.invent,
    this.location,
    this.taxInformation,
    this.images,
    this.tags,
  });

  factory ProductComplete.fromJson(Map<String, dynamic> json) {
    return ProductComplete(
      product: json['product'] != null
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      oxford: json['oxford'] != null
          ? Oxford.fromJson(json['oxford'] as Map<String, dynamic>)
          : null,
      invent: json['invent'] != null
          ? Invent.fromJson(json['invent'] as Map<String, dynamic>)
          : null,
      location: json['location'] != null
          ? InventDim.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      taxInformation: json['taxInformation'] != null
          ? TaxInformation.fromJson(json['taxInformation'] as Map<String, dynamic>)
          : null,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ImageBase64.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product?.toJson(),
      'oxford': oxford?.toJson(),
      'invent': invent?.toJson(),
      'location': location?.toJson(),
      'taxInformation': taxInformation?.toJson(),
      'images': images?.map((e) => e.toJson()).toList(),
      'tags': tags?.map((e) => e.toJson()).toList(),
    };
  }
}