class InventorLocationModel {
  final String inventLocationId;
  final String inventLocationName;
  final bool status;

  InventorLocationModel({
    required this.inventLocationId,
    required this.inventLocationName,
    required this.status,
  });

  factory InventorLocationModel.fromJson(Map<String, dynamic> json) {
    return InventorLocationModel(
      inventLocationId: json['inventLocationId'] as String? ?? '',
      inventLocationName: json['inventLocationName'] as String? ?? '',
      status: json['status'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'inventLocationId': inventLocationId,
        'inventLocationName': inventLocationName,
        'status': status,
      };
}
