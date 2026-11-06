// -----------------------------------------------------------
// app/core/models/breakage_model.dart
// -----------------------------------------------------------

/// Status possíveis de um registro de quebra (coluna `status` da API).
class BreakageStatus {
  static const String pendente  = 'PENDENTE';
  static const String aprovado  = 'APROVADO';
  static const String rejeitado = 'REJEITADO';
  static const String baixado   = 'BAIXADO';
}

/// Representa um registro de quebra retornado/enviado pelo
/// endpoint `/API/v1/Breakage`.
class BreakageModel {
  final int breakageId;
  final String productId;
  final int quantity;
  final String reason;
  final String photoUrl;
  final String status;
  final String? rejectionReason;
  final String createdBy;
  final DateTime? createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? writtenOffBy;
  final DateTime? writtenOffAt;

  BreakageModel({
    this.breakageId = 0,
    required this.productId,
    required this.quantity,
    required this.reason,
    required this.photoUrl,
    this.status = BreakageStatus.pendente,
    this.rejectionReason,
    required this.createdBy,
    this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
    this.writtenOffBy,
    this.writtenOffAt,
  });

  factory BreakageModel.fromMap(Map<String, dynamic> map) {
    return BreakageModel(
      breakageId:      map['breakageId'] as int? ?? 0,
      productId:       map['productId'] as String? ?? '',
      quantity:        map['quantity'] as int? ?? 0,
      reason:          map['reason'] as String? ?? '',
      photoUrl:        map['photoUrl'] as String? ?? '',
      status:          map['status'] as String? ?? BreakageStatus.pendente,
      rejectionReason: map['rejectionReason'] as String?,
      createdBy:       map['createdBy'] as String? ?? '',
      createdAt:       DateTime.tryParse(map['createdAt'] as String? ?? ''),
      reviewedBy:      map['reviewedBy'] as String?,
      reviewedAt:      DateTime.tryParse(map['reviewedAt'] as String? ?? ''),
      writtenOffBy:    map['writtenOffBy'] as String?,
      writtenOffAt:    DateTime.tryParse(map['writtenOffAt'] as String? ?? ''),
    );
  }

  /// Corpo esperado pelo POST /API/v1/Breakage
  /// (breakageId = 0 cria um novo registro; > 0 atualiza o existente).
  Map<String, dynamic> toMap() {
    return {
      'breakageId':      breakageId,
      'productId':       productId,
      'quantity':        quantity,
      'reason':          reason,
      'photoUrl':        photoUrl,
      'status':          status,
      'rejectionReason': rejectionReason,
      'createdBy':       createdBy,
      'reviewedBy':      reviewedBy,
      'writtenOffBy':    writtenOffBy,
    };
  }

  BreakageModel copyWith({
    String? status,
    String? rejectionReason,
    String? reviewedBy,
    String? writtenOffBy,
  }) {
    return BreakageModel(
      breakageId:      breakageId,
      productId:       productId,
      quantity:        quantity,
      reason:          reason,
      photoUrl:        photoUrl,
      status:          status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdBy:       createdBy,
      createdAt:       createdAt,
      reviewedBy:      reviewedBy ?? this.reviewedBy,
      reviewedAt:      reviewedAt,
      writtenOffBy:    writtenOffBy ?? this.writtenOffBy,
      writtenOffAt:    writtenOffAt,
    );
  }
}
