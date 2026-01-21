import 'dart:convert';
import 'package:oxdata/db/app_database.dart';

/// Enum para mapear o status do inventário
enum InventoryStatus {
  Iniciado,
  Finalizado,
}

/// Classe que representa o modelo de Inventário
class InventoryModel {
  final String inventCode;             // PK
  final String inventName;
  final String inventGuid;
  final String? inventSector;
  final DateTime? inventCreated;
  final String? inventUser;
  final InventoryStatus inventStatus;
  final double? inventTotal;

  /// 🔥 Controle OFFLINE
  final bool? isSynced;

  InventoryModel({
    required this.inventCode,
    this.inventName = "",
    required this.inventGuid,
    this.inventSector,
    this.inventCreated,
    this.inventUser,
    this.inventStatus = InventoryStatus.Iniciado,
    this.inventTotal,
    this.isSynced,
  });

  // ----------------------------------------------------------------------
  // API
  // ----------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'InventCode': inventCode,
      'InventName': inventName,
      'InventGuid': inventGuid,
      'InventSector': inventSector,
      'InventCreated': inventCreated?.toIso8601String(),
      'InventUser': inventUser,
      'InventStatus': inventStatus.name,
      'InventTotal': inventTotal,
    };
  }

  factory InventoryModel.fromMap(Map<String, dynamic> map) {
    InventoryStatus parseStatus(String? status) {
      if (status == null) return InventoryStatus.Iniciado;
      return InventoryStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == status.toLowerCase(),
        orElse: () => InventoryStatus.Iniciado,
      );
    }

    return InventoryModel(
      inventCode: map['inventCode'] ?? map['InventCode'] ?? '',
      inventName: map['inventName'] ?? map['InventName'] ?? '',
      inventGuid: map['inventGuid'] ?? map['InventGuid'] ?? '',
      inventSector: map['inventSector'] ?? map['InventSector'],
      inventCreated: map['inventCreated'] != null
          ? DateTime.tryParse(map['inventCreated'].toString())
          : map['InventCreated'] != null
              ? DateTime.tryParse(map['InventCreated'].toString())
              : null,
      inventUser: map['inventUser'] ?? map['InventUser'],
      inventStatus: parseStatus(
        map['inventStatus']?.toString() ??
        map['InventStatus']?.toString(),
      ),
      inventTotal: map['inventTotal'] != null
          ? (map['inventTotal'] as num).toDouble()
          : map['InventTotal'] != null
              ? (map['InventTotal'] as num).toDouble()
              : null,
      isSynced: true, // veio da API → sincronizado
    );
  }

  String toJson() => json.encode(toMap());

  factory InventoryModel.fromJson(String source) =>
      InventoryModel.fromMap(json.decode(source));

  // ----------------------------------------------------------------------
  // DRIFT (LOCAL)
  // ----------------------------------------------------------------------

  /// 🔥 Constrói a partir do banco local (Drift)
  factory InventoryModel.fromLocal(InventoryData data) {
    return InventoryModel(
      inventCode: data.inventCode,
      inventName: data.inventName,
      inventGuid: data.inventGuid,
      inventSector: data.inventSector,
      inventCreated: data.inventCreated,
      inventUser: data.inventUser,
      inventStatus: data.inventStatus,
      inventTotal: data.inventTotal,
      isSynced: data.isSynced,
    );
  }

  // ----------------------------------------------------------------------
  // UTILIDADES
  // ----------------------------------------------------------------------

  InventoryModel copyWith({
    String? inventCode,
    String? inventName,
    String? inventGuid,
    String? inventSector,
    DateTime? inventCreated,
    String? inventUser,
    InventoryStatus? inventStatus,
    double? inventTotal,
    bool? isSynced,
  }) {
    return InventoryModel(
      inventCode: inventCode ?? this.inventCode,
      inventName: inventName ?? this.inventName,
      inventGuid: inventGuid ?? this.inventGuid,
      inventSector: inventSector ?? this.inventSector,
      inventCreated: inventCreated ?? this.inventCreated,
      inventUser: inventUser ?? this.inventUser,
      inventStatus: inventStatus ?? this.inventStatus,
      inventTotal: inventTotal ?? this.inventTotal,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() {
    return 'InventoryModel('
        'code: $inventCode, '
        'guid: $inventGuid, '
        'status: $inventStatus, '
        'total: $inventTotal, '
        'synced: $isSynced)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryModel &&
          inventCode == other.inventCode &&
          inventGuid == other.inventGuid;

  @override
  int get hashCode => inventCode.hashCode ^ inventGuid.hashCode;
}
