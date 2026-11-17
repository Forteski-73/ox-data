// -----------------------------------------------------------
// app/core/models/breakage_model.dart
// -----------------------------------------------------------

/// Status possíveis de um registro de quebra (coluna `status` da API).
///
/// Fluxo: PENDENTE_GERENTE → PENDENTE_CI → APROVADO → BAIXADO,
/// com DEVOLVIDO (CI reprova e volta ao gerente) e EXCLUIDO (gerente exclui,
/// exclusão lógica). REJEITADO só existe em registros da v1.
class BreakageStatus {
  static const String pendenteGerente = 'PENDENTE_GERENTE';
  static const String pendenteCi      = 'PENDENTE_CI';
  static const String devolvido       = 'DEVOLVIDO';
  static const String aprovado        = 'APROVADO';
  static const String baixado         = 'BAIXADO';
  static const String excluido        = 'EXCLUIDO';

  /// Legado (v1): não é mais gerado.
  static const String rejeitado       = 'REJEITADO';

  /// Status da versão 1 (antes das duas etapas de aprovação).
  static const String _legacyPendente = 'PENDENTE';

  /// Status dos chips de filtro do Histórico (REJEITADO só aparece se houver).
  static const List<String> historyFilters = [pendenteGerente, pendenteCi, devolvido, aprovado, baixado, excluido];

  /// Rótulo amigável exibido na tela (nunca mostrar o código cru).
  static String label(String status) => switch (status) {
        pendenteGerente => 'Pend. Gerente',
        pendenteCi      => 'Pend. Controles Internos',
        devolvido       => 'Reprovado (CI)',
        aprovado        => 'Aprovado',
        baixado         => 'Baixado',
        excluido        => 'Excluído',
        rejeitado       => 'Rejeitado (legado)',
        _               => status,
      };

  /// Rótulo curto usado nos chips de filtro.
  static String shortLabel(String status) => switch (status) {
        pendenteGerente => 'Pend. Gerente',
        pendenteCi      => 'Pend. CI',
        devolvido       => 'Reprovados (CI)',
        aprovado        => 'Aprovados',
        baixado         => 'Baixados',
        excluido        => 'Excluídos',
        rejeitado       => 'Rejeitados (legado)',
        _               => status,
      };

  /// Fila de quem o registro está aguardando.
  static String queueLabel(String status) => switch (status) {
        pendenteGerente || devolvido => 'Gerente da Loja',
        pendenteCi                   => 'Controles Internos',
        aprovado                     => 'Controles Internos (baixa)',
        _                            => '—',
      };

  static String normalize(String? status) {
    if (status == null || status.isEmpty || status == _legacyPendente) return pendenteGerente;
    return status;
  }
}

/// Filtros de período, loja e status enviados ao GET /API/v1/Breakage.
class BreakageFilter {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? storeId;

  /// Status permitidos (vazio = todos).
  final List<String> statuses;

  const BreakageFilter({
    this.dateFrom,
    this.dateTo,
    this.storeId,
    this.statuses = const [],
  });

  bool get hasPeriod => dateFrom != null || dateTo != null;

  BreakageFilter copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? storeId,
    List<String>? statuses,
    bool clearPeriod = false,
    bool clearStore = false,
  }) {
    return BreakageFilter(
      dateFrom: clearPeriod ? null : (dateFrom ?? this.dateFrom),
      dateTo:   clearPeriod ? null : (dateTo ?? this.dateTo),
      storeId:  clearStore ? null : (storeId ?? this.storeId),
      statuses: statuses ?? this.statuses,
    );
  }

  /// Confere o registro localmente (a API também filtra; isso garante o
  /// recorte enquanto a API não aplica os parâmetros).
  bool matches(BreakageModel b) {
    if (statuses.isNotEmpty && !statuses.contains(b.status)) return false;
    // Sem filtro de status, excluídos ficam de fora (igual à API).
    if (statuses.isEmpty && b.status == BreakageStatus.excluido) return false;
    if (storeId != null && b.storeId != storeId) return false;
    final created = b.createdAt;
    if (created != null) {
      final day = DateTime(created.year, created.month, created.day);
      if (dateFrom != null && day.isBefore(dateFrom!)) return false;
      if (dateTo != null && day.isAfter(dateTo!)) return false;
    }
    return true;
  }
}

/// Representa um registro de quebra retornado/enviado pelo
/// endpoint `/API/v1/Breakage`.
class BreakageModel {
  final int breakageId;
  final String storeId;
  final String? storeName;
  final String productId;
  final String? productName;
  final int quantity;
  final double? unitPrice;
  final double? totalValue;
  final String reason;
  final String photoUrl;
  final String status;
  final String? rejectionReason;
  final int editCount;
  final int returnCount;
  final String createdBy;
  final DateTime? createdAt;
  final String? managerReviewedBy;
  final DateTime? managerReviewedAt;
  final String? icReviewedBy;
  final DateTime? icReviewedAt;
  final String? writtenOffBy;
  final DateTime? writtenOffAt;

  BreakageModel({
    this.breakageId = 0,
    required this.storeId,
    this.storeName,
    required this.productId,
    this.productName,
    required this.quantity,
    this.unitPrice,
    this.totalValue,
    required this.reason,
    required this.photoUrl,
    this.status = BreakageStatus.pendenteGerente,
    this.rejectionReason,
    this.editCount = 0,
    this.returnCount = 0,
    this.createdBy = '',
    this.createdAt,
    this.managerReviewedBy,
    this.managerReviewedAt,
    this.icReviewedBy,
    this.icReviewedAt,
    this.writtenOffBy,
    this.writtenOffAt,
  });

  factory BreakageModel.fromMap(Map<String, dynamic> map) {
    final quantity  = map['quantity'] as int? ?? 0;
    final unitPrice = (map['unitPrice'] as num?)?.toDouble();

    return BreakageModel(
      breakageId:        map['breakageId'] as int? ?? 0,
      storeId:           map['storeId']?.toString() ?? '',
      storeName:         map['storeName'] as String?,
      productId:         map['productId'] as String? ?? '',
      productName:       map['productName'] as String?,
      quantity:          quantity,
      unitPrice:         unitPrice,
      totalValue:        (map['totalValue'] as num?)?.toDouble() ?? (unitPrice == null ? null : unitPrice * quantity),
      reason:            map['reason'] as String? ?? '',
      photoUrl:          map['photoUrl'] as String? ?? '',
      status:            BreakageStatus.normalize(map['status'] as String?),
      rejectionReason:   map['rejectionReason'] as String?,
      editCount:         map['editCount'] as int? ?? 0,
      returnCount:       map['returnCount'] as int? ?? 0,
      createdBy:         map['createdBy'] as String? ?? '',
      createdAt:         DateTime.tryParse(map['createdAt'] as String? ?? ''),
      // Registros da v1 só têm reviewedBy/reviewedAt (aprovação única).
      managerReviewedBy: map['managerReviewedBy'] as String? ?? map['reviewedBy'] as String?,
      managerReviewedAt: DateTime.tryParse(map['managerReviewedAt'] as String? ?? map['reviewedAt'] as String? ?? ''),
      icReviewedBy:      map['icReviewedBy'] as String?,
      icReviewedAt:      DateTime.tryParse(map['icReviewedAt'] as String? ?? ''),
      writtenOffBy:      map['writtenOffBy'] as String?,
      writtenOffAt:      DateTime.tryParse(map['writtenOffAt'] as String? ?? ''),
    );
  }

  /// Corpo esperado pelo POST /API/v1/Breakage (somente criação).
  /// Status, preço, usuário e datas são definidos pela API.
  Map<String, dynamic> toCreateMap() {
    return {
      'breakageId': 0,
      'storeId':    storeId,
      'productId':  productId,
      'quantity':   quantity,
      'reason':     reason,
      'photoUrl':   photoUrl,
    };
  }

  /// Valor total para somas (registros antigos sem preço contam como 0).
  double get totalForSum => totalValue ?? 0;

  /// Gerente pode editar (foto/quantidade) somente nestes status.
  bool get isEditable => status == BreakageStatus.pendenteGerente || status == BreakageStatus.devolvido;

  /// Gerente pode excluir (exclusão lógica) somente nestes status.
  bool get isDeletable => status == BreakageStatus.pendenteGerente || status == BreakageStatus.devolvido;
}
