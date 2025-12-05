class PalletLoadLineModel {
  final int loadId;
  final int palletId;
  bool carregado;
  final String palletLocation;
  int palletTotalQuantity;

  PalletLoadLineModel({
    required this.loadId,
    required this.palletId,
    required this.carregado,
    required this.palletLocation,
    required this.palletTotalQuantity,
  });

  factory PalletLoadLineModel.fromMap(Map<String, dynamic> map) {
    return PalletLoadLineModel(
      loadId: map['loadId'] as int,
      palletId: map['palletId'] as int,
      carregado: map['carregado'] as bool,
      palletLocation: map['palletLocation'] as String,
      palletTotalQuantity: map['palletTotalQuantity'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'loadId': loadId,
      'palletId': palletId,
      'carregado': carregado,
      'palletLocation': palletLocation,
      'palletTotalQuantity': palletTotalQuantity,
    };
  }

  Map<String, dynamic> toApiMap() {
    final map = <String, dynamic>{
      'loadId': loadId,
      'palletId': palletId,
    };
    
    map['carregado'] = carregado;
    

    return map;
  }

}