// -----------------------------------------------------------
// app/core/models/breakage_profile.dart
// -----------------------------------------------------------

/// Perfis da Gestão de Quebras (tabela `profiles`, identificados pelo `name`).
/// Existem só três perfis; um usuário pode ter mais de um e as permissões somam.
class BreakageProfile {
  static const String stockist        = 'ESTOQUISTA';
  static const String storeManager    = 'GERENTE_LOJA';
  static const String internalControl = 'CONTROLES_INT';

  final bool isStockist;
  final bool isStoreManager;
  final bool isInternalControl;

  const BreakageProfile({
    this.isStockist = false,
    this.isStoreManager = false,
    this.isInternalControl = false,
  });

  static const BreakageProfile none = BreakageProfile();

  /// Monta o perfil a partir dos nomes de perfil do usuário.
  factory BreakageProfile.fromNames(Iterable<String> names) {
    final codes = names.map((n) => n.trim().toUpperCase()).toSet();
    return BreakageProfile(
      isStockist:        codes.contains(stockist),
      isStoreManager:    codes.contains(storeManager),
      isInternalControl: codes.contains(internalControl),
    );
  }

  /// Usuário com algum dos três perfis.
  bool get hasAny => isStockist || isStoreManager || isInternalControl;

  /// Aba Registrar: ESTOQUISTA e GERENTE_LOJA.
  bool get canRegister => isStockist || isStoreManager;

  /// Aba Aprovações: GERENTE_LOJA (etapa 1) ou CONTROLES_INT (etapa 2).
  bool get canApprove => isStoreManager || isInternalControl;

  /// Aba Baixar: CONTROLES_INT.
  bool get canWriteOff => isInternalControl;

  /// Aba Histórico (só leitura): GERENTE_LOJA ou CONTROLES_INT.
  bool get canSeeHistory => isStoreManager || isInternalControl;
}
