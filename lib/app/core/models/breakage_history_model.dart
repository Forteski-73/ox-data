// -----------------------------------------------------------
// app/core/models/breakage_history_model.dart
// -----------------------------------------------------------
import 'package:flutter/material.dart';

/// Eventos da trilha de auditoria de um registro de quebra
/// (coluna `event` da tabela `breakage_history`).
/// Rótulos, ícones e cores ficam aqui, num único lugar.
class BreakageEvent {
  static const String criado           = 'CRIADO';
  static const String editado          = 'EDITADO';
  static const String aprovadoGerente  = 'APROVADO_GERENTE';
  static const String aprovadoCi       = 'APROVADO_CI';
  static const String devolvidoCi      = 'DEVOLVIDO_CI';
  static const String reenviadoCi      = 'REENVIADO_CI';
  static const String baixado          = 'BAIXADO';
  static const String excluido         = 'EXCLUIDO';

  /// Legado (v1): não é mais gerado.
  static const String rejeitadoGerente = 'REJEITADO_GERENTE';

  static const Color _oxfordColor = Color(0xFF002B49);

  /// Um envio a Controles Internos começa um novo ciclo na linha do tempo.
  static bool startsCycle(String event) => event == aprovadoGerente || event == reenviadoCi;

  /// Título exibido na linha do tempo.
  static String label(BreakageHistoryModel e) => switch (e.event) {
        criado           => 'Registrado por ${e.createdBy}',
        editado          => '${e.createdBy} alterou ${e.isPhotoChange ? 'Foto' : 'Quantidade'}',
        aprovadoGerente  => 'Aprovado pelo gerente ${e.createdBy}',
        reenviadoCi      => 'Reenviado a Controles Internos por ${e.createdBy}',
        devolvidoCi      => 'Reprovado por Controles Internos (${e.createdBy})',
        aprovadoCi       => 'Aprovado por Controles Internos (${e.createdBy})',
        baixado          => 'Baixado por ${e.createdBy}',
        excluido         => 'Excluído por ${e.createdBy}',
        rejeitadoGerente => 'Rejeitado por ${e.createdBy} (legado)',
        _                => '${e.event} • ${e.createdBy}',
      };

  static IconData icon(String event) => switch (event) {
        criado           => Icons.add_circle,
        editado          => Icons.edit,
        aprovadoGerente  => Icons.check_circle,
        reenviadoCi      => Icons.send,
        devolvidoCi      => Icons.undo,
        aprovadoCi       => Icons.verified,
        baixado          => Icons.inventory,
        excluido         => Icons.delete,
        rejeitadoGerente => Icons.cancel,
        _                => Icons.circle_outlined,
      };

  static Color color(String event) => switch (event) {
        criado           => _oxfordColor,
        editado          => Colors.amber.shade700,
        aprovadoGerente  => Colors.green,
        reenviadoCi      => Colors.orange,
        devolvidoCi      => Colors.red,
        aprovadoCi       => Colors.green.shade800,
        baixado          => Colors.blue,
        excluido         => Colors.grey,
        rejeitadoGerente => Colors.red,
        _                => Colors.grey,
      };
}

/// Campos editáveis registrados em eventos EDITADO (`fieldName`).
class BreakageField {
  static const String quantity = 'quantity';
  static const String photoUrl = 'photo_url';
}

/// Linha do histórico retornada por `GET /API/v1/Breakage/{id}/history`.
class BreakageHistoryModel {
  final int historyId;
  final int breakageId;
  final String event;
  final String? fieldName;
  final String? oldValue;
  final String? newValue;
  final String? justification;
  final String createdBy;
  final DateTime? createdAt;

  BreakageHistoryModel({
    required this.historyId,
    required this.breakageId,
    required this.event,
    this.fieldName,
    this.oldValue,
    this.newValue,
    this.justification,
    required this.createdBy,
    this.createdAt,
  });

  factory BreakageHistoryModel.fromMap(Map<String, dynamic> map) {
    return BreakageHistoryModel(
      historyId:     map['historyId'] as int? ?? 0,
      breakageId:    map['breakageId'] as int? ?? 0,
      event:         map['event'] as String? ?? '',
      fieldName:     map['fieldName'] as String?,
      oldValue:      map['oldValue'] as String?,
      newValue:      map['newValue'] as String?,
      justification: map['justification'] as String?,
      createdBy:     map['createdBy'] as String? ?? '',
      createdAt:     DateTime.tryParse(map['createdAt'] as String? ?? ''),
    );
  }

  /// Aceita tanto `photo_url` (coluna) quanto `photoUrl` (JSON).
  bool get isPhotoChange => fieldName == BreakageField.photoUrl || fieldName == 'photoUrl';
}
