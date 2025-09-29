// -----------------------------------------------------------
// app/core/models/pallet_model.dart
// -----------------------------------------------------------
import 'dart:convert';

/// Classe que representa um palete no aplicativo.
class PalletModel {
  final int palletId;
  final int totalQuantity;
  final String status;
  final String location;
  final String createdUser;
  final String? updatedUser; // Nullable
  final String? imagePath; // Nullable
  final DateTime createdAt;

  PalletModel({
    required this.palletId,
    required this.totalQuantity,
    required this.status,
    required this.location,
    required this.createdUser,
    this.updatedUser,
    this.imagePath,
    required this.createdAt,
  });

  /// Converte uma instância de PalletModel para um mapa (Map<String, dynamic>).
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'palletId': palletId,
      'totalQuantity': totalQuantity,
      'status': status,
      'location': location,
      'createdUser': createdUser,
      'updatedUser': updatedUser,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Cria uma instância de PalletModel a partir de um mapa (Map<String, dynamic>).
  factory PalletModel.fromMap(Map<String, dynamic> map) {
    return PalletModel(
      palletId: map['palletId'] as int,
      totalQuantity: map['totalQuantity'] as int,
      status: map['status'] as String,
      location: map['location'] as String,
      createdUser: map['createdUser'] as String,
      updatedUser: map['updatedUser'] as String?,
      imagePath: map['imagePath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Converte uma instância de PalletModel para uma string JSON.
  String toJson() => json.encode(toMap());

  /// Cria uma instância de PalletModel a partir de uma string JSON.
  factory PalletModel.fromJson(String source) =>
      PalletModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PalletModel(palletId: $palletId, totalQuantity: $totalQuantity, status: $status, location: $location)';
  }

  /// Cria uma nova instância com valores atualizados.
  PalletModel copyWith({
    int? palletId,
    int? totalQuantity,
    String? status,
    String? location,
    String? createdUser,
    String? updatedUser,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return PalletModel(
      palletId: palletId ?? this.palletId,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      status: status ?? this.status,
      location: location ?? this.location,
      createdUser: createdUser ?? this.createdUser,
      updatedUser: updatedUser ?? this.updatedUser,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}