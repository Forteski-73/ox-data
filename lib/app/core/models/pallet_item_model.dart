// -----------------------------------------------------------
// app/core/models/pallet_item_model.dart
// -----------------------------------------------------------
import 'dart:convert';

/// Classe que representa um item de palete no aplicativo.
class PalletItemModel {
  final int     palletId;
  final String  productId;
  String?       productName;
  final int     quantity;
  int?          quantityReceived;
  final String  userId;
  final String  status;

  PalletItemModel({
    required this.palletId,
    required this.productId,
    this.productName,
    required this.quantity,
    this.quantityReceived,
    required this.userId,
    required this.status,
  });

  /// Converte uma instância de PalletItemModel para um mapa (Map<String, dynamic>).
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'palletId':           palletId,
      'productId':          productId,
      'quantity':           quantity,
      'quantityReceived':   quantityReceived,
      'userId':             userId,
      'status':             status,
    };
  }

  /// Cria uma instância de PalletItemModel a partir de um mapa (Map<String, dynamic>).
  factory PalletItemModel.fromMap(Map<String, dynamic> map) {
    return PalletItemModel(
      palletId:         map['palletId']         as int,
      productId:        map['productId']        as String,
      productName:      map['productName']      as String?,
      quantity:         map['quantity']         as int,
      quantityReceived: map['quantityReceived'] as int,
      userId:           map['userId']           as String,
      status:           map['status']           as String,
    );
  }

  /// Converte uma instância de PalletItemModel para uma string JSON.
  String toJson() => json.encode(toMap());

  /// Cria uma instância de PalletItemModel a partir de uma string JSON.
  factory PalletItemModel.fromJson(String source) =>
      PalletItemModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PalletItemModel(palletId: $palletId, productId: $productId, quantity: $quantity, quantityReceived: $quantityReceived, userId: $userId, status: $status)';
  }

  /// Cria uma nova instância com valores atualizados.
  PalletItemModel copyWith({
    int?    palletId,
    String? productId,
    String? productName,
    int?    quantity,
    int?    quantityReceived,
    String? userId,
    String? status,
  }) {
    return PalletItemModel(
      palletId:         palletId          ?? this.palletId,
      productId:        productId         ?? this.productId,
      productName:      productName       ?? this.productName,
      quantity:         quantity          ?? this.quantity,
      quantityReceived: quantityReceived  ?? this.quantityReceived,
      userId:           userId            ?? this.userId,
      status:           status            ?? this.status,
    );
  }
}
