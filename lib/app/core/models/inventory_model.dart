import 'dart:convert';
import 'package:oxdata/app/core/globals/ApiRoutes.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/models/inventory_guid_model.dart';
import 'package:oxdata/app/core/models/inventory_item.dart';
import 'package:oxdata/app/core/models/inventory_record_model.dart';
import 'package:oxdata/app/core/models/product_tag_model.dart';
import 'package:oxdata/app/core/repositories/auth_repository.dart';
import 'package:oxdata/app/core/models/product_brand.dart';
import 'package:oxdata/app/core/models/product_line.dart';
import 'package:oxdata/app/core/models/product_decoration.dart';

/// Enum para mapear o status do inventário
enum InventoryStatus {
  Iniciado,
  Finalizado,
}

/// Classe que representa o modelo de Inventário
class InventoryModel {
  final String inventCode;            // Corresponde a `invent_code` (PK)
  final String inventGuid;            // Corresponde a `invent_guid`
  final String? inventSector;         // Corresponde a `invent_sector`
  final DateTime? inventCreated;      // Corresponde a `invent_created`
  final String? inventUser;           // Corresponde a `invent_user`
  final InventoryStatus inventStatus; // Corresponde a `invent_status` (ENUM)
  double? inventTotal;             // Corresponde a `invent_total`

  InventoryModel({
    required this.inventCode,
    required this.inventGuid,
    this.inventSector,
    this.inventCreated,
    this.inventUser,
    this.inventStatus = InventoryStatus.Iniciado, // Default 'Iniciado'
    this.inventTotal,
  });

  // --- MÉTODOS DE CONVERSÃO ---

  /// Converte uma instância de InventoryModel para um mapa (Map<String, dynamic>).
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'invent_code': inventCode,
      'invent_guid': inventGuid,
      'invent_sector': inventSector,
      'invent_created': inventCreated?.toIso8601String(), // Formato ISO 8601 para DateTime
      'invent_user': inventUser,
      // Armazena o nome do enum (ex: 'Iniciado', 'Finalizado')
      'invent_status': inventStatus.name,
      'invent_total': inventTotal,
    };
  }

  /// Cria uma instância de InventoryModel a partir de um mapa (Map<String, dynamic>).
  factory InventoryModel.fromMap(Map<String, dynamic> map) {
    // Função auxiliar para converter String para InventoryStatus
    InventoryStatus parseStatus(String? status) {
      if (status == null) return InventoryStatus.Iniciado;
      try {
        // Encontra o valor do enum que corresponde à string (case-insensitive)
        return InventoryStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == status.toLowerCase(),
          orElse: () => InventoryStatus.Iniciado,
        );
      } catch (_) {
        return InventoryStatus.Iniciado;
      }
    }

return InventoryModel(
      inventCode: map['inventCode'] ?? '',
      inventGuid: map['inventGuid'] ?? '',
      inventSector: map['inventSector']?.toString(),
      inventCreated: map['inventCreated'] != null 
          ? DateTime.tryParse(map['inventCreated'].toString()) 
          : null,
      inventUser: map['inventUser']?.toString(),
      inventStatus: parseStatus(map['inventStatus']?.toString()),
      // Tratamento robusto para converter qualquer entrada numérica para double
      inventTotal: map['inventTotal'] != null 
          ? (map['inventTotal'] as num).toDouble() 
          : null,
    );
  }

  /// Converte uma instância de InventoryModel para uma string JSON.
  String toJson() => json.encode(toMap());

  /// Cria uma instância de InventoryModel a partir de uma string JSON.
  factory InventoryModel.fromJson(String source) => InventoryModel.fromMap(json.decode(source) as Map<String, dynamic>);

  // --- MÉTODOS DE UTILIDADE EM DART ---

  @override
  String toString() {
    return 'InventoryModel(inventCode: $inventCode, inventGuid: $inventGuid, inventSector: $inventSector, inventCreated: $inventCreated, inventUser: $inventUser, inventStatus: $inventStatus, inventTotal: $inventTotal)';
  }

  /// Cria uma nova instância com valores atualizados (imutabilidade).
  InventoryModel copyWith({
    String? inventCode,
    String? inventGuid,
    String? inventSector,
    DateTime? inventCreated,
    String? inventUser,
    InventoryStatus? inventStatus,
    double? inventTotal,
  }) {
    return InventoryModel(
      inventCode: inventCode ?? this.inventCode,
      inventGuid: inventGuid ?? this.inventGuid,
      inventSector: inventSector ?? this.inventSector,
      inventCreated: inventCreated ?? this.inventCreated,
      inventUser: inventUser ?? this.inventUser,
      inventStatus: inventStatus ?? this.inventStatus,
      inventTotal: inventTotal ?? this.inventTotal,
    );
  }
  
  // Sobrecarga de operadores para comparação de igualdade (útil para testes ou coleções)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is InventoryModel &&
      other.inventCode == inventCode &&
      other.inventGuid == inventGuid &&
      other.inventSector == inventSector &&
      other.inventCreated == inventCreated &&
      other.inventUser == inventUser &&
      other.inventStatus == inventStatus &&
      other.inventTotal == inventTotal;
  }

  @override
  int get hashCode {
    return inventCode.hashCode ^
      inventGuid.hashCode ^
      inventSector.hashCode ^
      inventCreated.hashCode ^
      inventUser.hashCode ^
      inventStatus.hashCode ^
      inventTotal.hashCode;
  }
}