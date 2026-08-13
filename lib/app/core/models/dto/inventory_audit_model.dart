/// Representa um item retornado pelo endpoint de auditoria de inventário
/// (`GET /API/v1/Inventory/InventoryAuditResult`), comparando o total
/// contado fisicamente (`totalInvent`) com o saldo disponível no
/// sistema (`availPhysical`) para um produto em uma localização.
class InventoryAuditModel {
  final String inventLocationId;
  final String inventProduct;
  final String? inventBarcode;
  final double totalInvent;
  final double availPhysical;

  InventoryAuditModel({
    required this.inventLocationId,
    required this.inventProduct,
    this.inventBarcode,
    required this.totalInvent,
    required this.availPhysical,
  });

  /// Diferença entre o total contado e o saldo do sistema.
  /// Positivo: sobra em relação ao sistema. Negativo: falta.
  double get difference => totalInvent - availPhysical;

  /// Indica se houve divergência entre a contagem e o saldo do sistema.
  bool get hasDivergence => difference != 0;

  factory InventoryAuditModel.fromJson(Map<String, dynamic> json) {
    return InventoryAuditModel(
      inventLocationId: json['inventLocationId'] as String? ?? '',
      inventProduct: json['inventProduct'] as String? ?? '',
      inventBarcode: json['inventBarcode'] as String?,
      totalInvent: (json['totalInvent'] as num?)?.toDouble() ?? 0.0,
      availPhysical: (json['availPhysical'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventLocationId': inventLocationId,
      'inventProduct': inventProduct,
      'inventBarcode': inventBarcode,
      'totalInvent': totalInvent,
      'availPhysical': availPhysical,
      'difference': difference,
      'hasDivergence': hasDivergence,
    };
  }

  InventoryAuditModel copyWith({
    String? inventLocationId,
    String? inventProduct,
    String? inventBarcode,
    double? totalInvent,
    double? availPhysical,
  }) {
    return InventoryAuditModel(
      inventLocationId: inventLocationId ?? this.inventLocationId,
      inventProduct: inventProduct ?? this.inventProduct,
      inventBarcode: inventBarcode ?? this.inventBarcode,
      totalInvent: totalInvent ?? this.totalInvent,
      availPhysical: availPhysical ?? this.availPhysical,
    );
  }
}