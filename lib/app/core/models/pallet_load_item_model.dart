// Modelo para cada Item dentro do Pallet
// Modelo para cada Item dentro do Pallet
class PalletItemModel {
  final int palletId;
  final String productId;
  final String productNumber;
  final String productDescription;
  int quantity;
  int quantityReceived;
  String status; // Agora é STRING
  final String userId;

  PalletItemModel({
    required this.palletId,
    required this.productId,
    required this.productNumber,
    required this.productDescription,
    required this.quantity,
    required this.quantityReceived,
    required this.status,
    required this.userId,
  });

  factory PalletItemModel.fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return PalletItemModel(
      palletId: parseInt(map['palletId']),
      productId: map['productId']?.toString() ?? '',
      productNumber: map['productNumber']?.toString() ?? '',
      productDescription: map['productDescription']?.toString() ?? '',
      quantity: parseInt(map['quantity']),
      quantityReceived: parseInt(map['quantityReceived']),
      status: map['status']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'palletId': palletId,
        'productId': productId,
        'productNumber': productNumber,
        'productDescription': productDescription,
        'quantity': quantity,
        'quantityReceived': quantityReceived,
        'status': status,
        'userId': userId,
      };
}


// Modelo para a Resposta Completa do Endpoint
class PalletDetailsModel {
  final int palletId;
  final String status; // Agora é STRING
  final String location;
  final int totalQuantity;
  final List<PalletItemModel> items;

  PalletDetailsModel({
    required this.palletId,
    required this.status,
    required this.location,
    required this.totalQuantity,
    required this.items,
  });

  factory PalletDetailsModel.fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    var itemsList = map['items'] as List? ?? [];

    List<PalletItemModel> items = itemsList
        .map((i) => PalletItemModel.fromMap(i as Map<String, dynamic>))
        .toList();

    return PalletDetailsModel(
      palletId: parseInt(map['palletId']),
      status: map['status']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      totalQuantity: parseInt(map['totalQuantity']),
      items: items,
    );
  }

  Map<String, dynamic> toMap() => {
        'palletId': palletId,
        'status': status,
        'location': location,
        'totalQuantity': totalQuantity,
        'items': items.map((i) => i.toMap()).toList(),
      };
}