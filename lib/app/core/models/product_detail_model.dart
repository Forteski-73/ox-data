// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

/// Classe principal que representa o objeto completo de resposta da API para um produto.
class ProductResponseModel {
  final ProductModel product;
  final OxfordModel oxford;
  final InventModel invent;
  final TaxInformationModel taxInformation;

  ProductResponseModel({
    required this.product,
    required this.oxford,
    required this.invent,
    required this.taxInformation,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'product': product.toMap(),
      'oxford': oxford.toMap(),
      'invent': invent.toMap(),
      'taxInformation': taxInformation.toMap(),
    };
  }

  factory ProductResponseModel.fromMap(Map<String, dynamic> map) {
    return ProductResponseModel(
      product: ProductModel.fromMap(map['product'] as Map<String, dynamic>),
      oxford: OxfordModel.fromMap(map['oxford'] as Map<String, dynamic>),
      invent: InventModel.fromMap(map['invent'] as Map<String, dynamic>),
      taxInformation: TaxInformationModel.fromMap(map['taxInformation'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory ProductResponseModel.fromJson(String source) => ProductResponseModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Modelo para a seção de informações básicas do produto.
class ProductModel {
  final String productId;
  final String productName;
  final String barcode;
  final bool status;
  final String? note;

  ProductModel({
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.status,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'barcode': barcode,
      'status': status,
      'note': note,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      barcode: map['barcode'] as String,
      status: map['status'] as bool,
      note: map['note'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory ProductModel.fromJson(String source) => ProductModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Modelo para a seção de informações da marca e características (Oxford).
class OxfordModel {
  final String productId;
  final String familyId;
  final String familyDescription;
  final String brandId;
  final String brandDescription;
  final String decorationId;
  final String decorationDescription;
  final String typeId;
  final String typeDescription;
  final String processId;
  final String processDescription;
  final String situationId;
  final String situationDescription;
  final String lineId;
  final String lineDescription;
  final String qualityId;
  final String qualityDescription;
  final String baseProductId;
  final String baseProductDescription;
  final String productGroupId;
  final String productGroupDescription;

  OxfordModel({
    required this.productId,
    required this.familyId,
    required this.familyDescription,
    required this.brandId,
    required this.brandDescription,
    required this.decorationId,
    required this.decorationDescription,
    required this.typeId,
    required this.typeDescription,
    required this.processId,
    required this.processDescription,
    required this.situationId,
    required this.situationDescription,
    required this.lineId,
    required this.lineDescription,
    required this.qualityId,
    required this.qualityDescription,
    required this.baseProductId,
    required this.baseProductDescription,
    required this.productGroupId,
    required this.productGroupDescription,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'productId': productId,
      'familyId': familyId,
      'familyDescription': familyDescription,
      'brandId': brandId,
      'brandDescription': brandDescription,
      'decorationId': decorationId,
      'decorationDescription': decorationDescription,
      'typeId': typeId,
      'typeDescription': typeDescription,
      'processId': processId,
      'processDescription': processDescription,
      'situationId': situationId,
      'situationDescription': situationDescription,
      'lineId': lineId,
      'lineDescription': lineDescription,
      'qualityId': qualityId,
      'qualityDescription': qualityDescription,
      'baseProductId': baseProductId,
      'baseProductDescription': baseProductDescription,
      'productGroupId': productGroupId,
      'productGroupDescription': productGroupDescription,
    };
  }

  factory OxfordModel.fromMap(Map<String, dynamic> map) {
    return OxfordModel(
      productId: map['productId'] as String,
      familyId: map['familyId'] as String,
      familyDescription: map['familyDescription'] as String,
      brandId: map['brandId'] as String,
      brandDescription: map['brandDescription'] as String,
      decorationId: map['decorationId'] as String,
      decorationDescription: map['decorationDescription'] as String,
      typeId: map['typeId'] as String,
      typeDescription: map['typeDescription'] as String,
      processId: map['processId'] as String,
      processDescription: map['processDescription'] as String,
      situationId: map['situationId'] as String,
      situationDescription: map['situationDescription'] as String,
      lineId: map['lineId'] as String,
      lineDescription: map['lineDescription'] as String,
      qualityId: map['qualityId'] as String,
      qualityDescription: map['qualityDescription'] as String,
      baseProductId: map['baseProductId'] as String,
      baseProductDescription: map['baseProductDescription'] as String,
      productGroupId: map['productGroupId'] as String,
      productGroupDescription: map['productGroupDescription'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory OxfordModel.fromJson(String source) => OxfordModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Modelo para a seção de inventário e dimensões do produto.
class InventModel {
  final String productId;
  final double netWeight;
  final double taraWeight;
  final double grossWeight;
  final double grossDepth;
  final double grossWidth;
  final double grossHeight;
  final double unitVolume;
  final double unitVolumeML;
  final int nrOfItems;
  final String unitId;

  InventModel({
    required this.productId,
    required this.netWeight,
    required this.taraWeight,
    required this.grossWeight,
    required this.grossDepth,
    required this.grossWidth,
    required this.grossHeight,
    required this.unitVolume,
    required this.unitVolumeML,
    required this.nrOfItems,
    required this.unitId,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
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

  factory InventModel.fromMap(Map<String, dynamic> map) {
    return InventModel(
      productId: map['productId'] as String,
      netWeight: (map['netWeight'] as num).toDouble(),
      taraWeight: (map['taraWeight'] as num).toDouble(),
      grossWeight: (map['grossWeight'] as num).toDouble(),
      grossDepth: (map['grossDepth'] as num).toDouble(),
      grossWidth: (map['grossWidth'] as num).toDouble(),
      grossHeight: (map['grossHeight'] as num).toDouble(),
      unitVolume: (map['unitVolume'] as num).toDouble(),
      unitVolumeML: (map['unitVolumeML'] as num).toDouble(),
      nrOfItems: map['nrOfItems'] as int,
      unitId: map['unitId'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory InventModel.fromJson(String source) => InventModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Modelo para a seção de informações fiscais do produto.
class TaxInformationModel {
  final String productId;
  final String taxationOrigin;
  final String taxFiscalClassification;
  final String productType;
  final String? cestCode;
  final String fiscalGroupId;
  final double approxTaxValueFederal;
  final double approxTaxValueState;
  final double approxTaxValueCity;

  TaxInformationModel({
    required this.productId,
    required this.taxationOrigin,
    required this.taxFiscalClassification,
    required this.productType,
    required this.cestCode,
    required this.fiscalGroupId,
    required this.approxTaxValueFederal,
    required this.approxTaxValueState,
    required this.approxTaxValueCity,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
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

  factory TaxInformationModel.fromMap(Map<String, dynamic> map) {
    return TaxInformationModel(
      productId: map['productId'] as String,
      taxationOrigin: map['taxationOrigin'] as String,
      taxFiscalClassification: map['taxFiscalClassification'] as String,
      productType: map['productType'] as String,
      cestCode: map['cestCode'] as String?,
      fiscalGroupId: map['fiscalGroupId'] as String,
      approxTaxValueFederal: (map['approxTaxValueFederal'] as num).toDouble(),
      approxTaxValueState: (map['approxTaxValueState'] as num).toDouble(),
      approxTaxValueCity: (map['approxTaxValueCity'] as num).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory TaxInformationModel.fromJson(String source) => TaxInformationModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
