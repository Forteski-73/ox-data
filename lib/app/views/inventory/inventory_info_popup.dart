import 'package:flutter/material.dart';
import 'package:oxdata/app/core/utils/mask_validate.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Um campo já "quebrado" da posição (ex: Rua, Módulo, Nível), pronto pra exibir.
/// [literal] indica que esse pedaço é fixo da máscara (ex: "BASE", "DPA"),
/// não é um dado que veio do scanner.
class _PosicaoField {
  final String label;
  final String valor;
  final bool literal;

  const _PosicaoField(this.label, this.valor, {this.literal = false});
}

class FieldInfoPopup extends StatelessWidget {
  final String value;
  final MaskFieldName field;
  final String title;
  final IconData icon;

  const FieldInfoPopup({
    super.key,
    required this.value,
    required this.field,
    required this.title,
    required this.icon,
  });

  String get description {
    switch (field) {
      case MaskFieldName.Unitizador:
        return "Código Único de itentificação.";
      case MaskFieldName.Posicao:
        return "Código da posição.";
      case MaskFieldName.Codigo:
        return "Código da Peça/Item.";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(title, icon),
              const SizedBox(height: 24),
              _buildFieldWidget(context),
              const SizedBox(height: 24),
              _buildOkButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // HEADER
  // ---------------------------------------------------
  Widget _buildSectionHeader(String text, IconData iconData) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: Colors.indigo, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------
  // CONTAINER PADRÃO
  // ---------------------------------------------------
  Widget _buildDescriptionContainer(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  // ---------------------------------------------------
  // STATUS DE VALIDAÇÃO (REUTILIZÁVEL)
  // ---------------------------------------------------
  Widget _buildValidationStatus({
    required bool hasValue,
    required bool isValid,
  }) {
    final Color statusColor = !hasValue
        ? Colors.grey
        : (isValid ? Colors.green.shade700 : Colors.red.shade700);

    final IconData statusIcon = !hasValue
        ? Icons.hourglass_empty
        : (isValid ? Icons.check_circle : Icons.cancel);

    final String statusText = !hasValue
        ? "Aguardando leitura.."
        : (isValid ? "VÁLIDO" : "INVÁLIDO");

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------
  // SWITCH PRINCIPAL
  // ---------------------------------------------------
  Widget _buildFieldWidget(BuildContext context) {
    switch (field) {
      case MaskFieldName.Unitizador:
        return _buildUnitizerContent(context);
      case MaskFieldName.Posicao:
        return _buildPosition8Content(context);
      case MaskFieldName.Codigo:
        return _buildProductContent(context);
      default:
        return _buildDescriptionContainer(
          Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
        );
    }
  }

  // ---------------------------------------------------
  // UNITIZADOR
  // ---------------------------------------------------
  Widget _buildUnitizerContent(BuildContext context) {
    return Column(
      children: [
        _buildDescriptionContainer(
          Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<String>>(
          future: getMasksForField(context, field),
          builder: (context, snapshot) {
            final masks = snapshot.data ?? [];
            final bool hasValue = value.isNotEmpty;
            final bool isValid =
                hasValue && MaskValidatorService.validateMask(value, masks);

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SpinKitThreeBounce(color: Colors.white, size: 30.0),
              );
            }

            return Column(
              children: [
                _buildMasksInfo(masks),
                const SizedBox(height: 20),
                _buildValue(value, isValid, hasValue),
                const SizedBox(height: 4),
                _buildValidationStatus(hasValue: hasValue, isValid: isValid),
              ],
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------
  // POSIÇÃO — agora suporta qualquer máscara cadastrada, não só o formato
  // fixo de 8 caracteres. Descobre qual máscara bateu com o valor lido e
  // monta a estrutura (Rua/Módulo/Nível etc.) de acordo com ELA. Se nenhuma
  // máscara bater, mostra o valor inteiro em vermelho em vez de forçar um
  // recorte errado.
  // ---------------------------------------------------
  Widget _buildPosition8Content(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDescriptionContainer(
          Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<String>>(
          future: FieldInfoPopup.getMasksForField(context, field),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SpinKitThreeBounce(color: Colors.white, size: 30.0),
              );
            }

            final masks = snapshot.data ?? [];
            final bool hasValue = value.isNotEmpty;
            final String? matchedMask =
                hasValue ? _findMatchingMask(value, masks) : null;
            final bool isValid = matchedMask != null;

            final Color statusColor = !hasValue
                ? Colors.grey
                : (isValid ? Colors.green.shade700 : Colors.red.shade700);
            final IconData statusIcon = !hasValue
                ? Icons.hourglass_empty
                : (isValid ? Icons.check_circle : Icons.cancel);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Formatos aceitos (lista todas as máscaras cadastradas)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.qr_code_scanner, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          masks.isEmpty
                              ? "Campo sem formato de entrada definido."
                              : "Formatos de endereço aceitos:\n" +
                                  masks
                                      .map((m) => "$m (${m.length} caracteres)")
                                      .join('\n'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                _buildValue(value, isValid, hasValue),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        !hasValue
                            ? "Aguardando leitura.."
                            : (isValid ? "VÁLIDO" : "INVÁLIDO"),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                if (hasValue) ...[
                  const SizedBox(height: 16),
                  _buildSectionHeader("Estrutura da Posição", Icons.layers_outlined),
                  const SizedBox(height: 6),
                  _buildDescriptionContainer(
                    isValid
                        ? Column(
                            children: _parsePosicao(value, matchedMask!)
                                .map((c) => _buildLocationRow(
                                      c.label,
                                      c.valor,
                                      literal: c.literal,
                                    ))
                                .toList(),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Não corresponde a nenhum formato de posição cadastrado:",
                                style: TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.red.shade300),
                                ),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLocationRow(String label, String val, {bool literal = false}) {
    final Color textColor = literal ? Colors.blueGrey.shade700 : Colors.black87;
    final Color backgroundColor =
        literal ? Colors.blueGrey.withOpacity(0.08) : Colors.green.shade100;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            literal ? '$label (fixo)' : label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          ),
          Text(
            val,
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------
  // PRODUTO
  // ---------------------------------------------------
  Widget _buildProductContent(BuildContext context) {
    return Column(
      children: [
        _buildDescriptionContainer(
          Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<String>>(
          future: getMasksForField(context, field),
          builder: (context, snapshot) {
            final masks = snapshot.data ?? [];
            final bool hasValue = value.isNotEmpty;
            final bool isValid =
                hasValue && MaskValidatorService.validateMask(value, masks);

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SpinKitThreeBounce(color: Colors.white, size: 30.0),
              );
            }

            return Column(
              children: [
                _buildMasksInfo(masks),
                const SizedBox(height: 20),
                _buildValue(value, isValid, hasValue),
                const SizedBox(height: 4),
                _buildValidationStatus(hasValue: hasValue, isValid: isValid),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildValue(String value, bool isValid, bool hasValue) {
    if (!hasValue) return const SizedBox.shrink();

    final Color statusColor = isValid ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: statusColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------
  // MÁSCARAS INFO
  // ---------------------------------------------------
  Widget _buildMasksInfo(List<String> masks) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_scanner, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              masks.isEmpty
                  ? "Campo sem formato de entrada definido."
                  : masks.map((m) => "$m (${m.length} caracteres)").join('\n'),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------
  // BOTÃO OK
  // ---------------------------------------------------
  Widget _buildOkButton(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 140,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'OK',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // CASAMENTO DE MÁSCARA (genérico, funciona pra qualquer formato)
  // ---------------------------------------------------

  /// Compara [value] com uma [mask] no padrão do banco: '*' = qualquer
  /// caractere; qualquer outro caractere precisa bater exatamente na mesma
  /// posição (ignorando maiúsculas/minúsculas). Só bate se o tamanho for igual.
  static bool _matchesMask(String value, String mask) {
    if (value.length != mask.length) return false;
    for (var i = 0; i < mask.length; i++) {
      final maskChar = mask[i];
      if (maskChar == '*') continue;
      if (maskChar.toUpperCase() != value[i].toUpperCase()) return false;
    }
    return true;
  }

  /// Retorna a primeira máscara da lista que bate com [value], ou null se
  /// nenhuma bater (inclusive quando a lista está vazia).
  static String? _findMatchingMask(String value, List<String> masks) {
    for (final mask in masks) {
      if (_matchesMask(value, mask)) return mask;
    }
    return null;
  }

  /// Quebra [value] nos campos (Rua/Módulo/Nível, etc.) de acordo com a
  /// estrutura da [mask] que bateu com ele — funciona pra qualquer máscara
  /// cadastrada, incluindo o formato antigo de 8 caracteres sem separador.
  static List<_PosicaoField> _parsePosicao(String value, String mask) {
    // Formato antigo: 8 caracteres, sem hífen, tudo curinga.
    // (Depósito 2 + Bloco 2 + Quadra 1 + Lote 2 + Andar 1)
    final somenteCuringas = mask.split('').every((c) => c == '*');
    if (mask.length == 8 && !mask.contains('-') && somenteCuringas) {
      return [
        _PosicaoField('Depósito', value.substring(0, 2)),
        _PosicaoField('Bloco', value.substring(2, 4)),
        _PosicaoField('Quadra', value.substring(4, 5)),
        _PosicaoField('Lote', value.substring(5, 7)),
        _PosicaoField('Andar', value.substring(7, 8)),
      ];
    }

    if (mask.contains('-')) {
      final maskParts = mask.split('-');
      final valueParts = value.split('-');
      if (maskParts.length != valueParts.length) {
        // Não deveria acontecer se o casamento foi validado certo antes,
        // mas por segurança: mostra o valor inteiro em vez de quebrar.
        return [_PosicaoField('Valor', value)];
      }

      final variavel = maskParts
          .map((p) => p.isNotEmpty && p.split('').every((c) => c == '*'))
          .toList();
      final totalmenteLiteral = variavel.every((v) => !v);

      if (totalmenteLiteral) {
        // Ex: ENTR-DPA, SAIDA-DPA — código especial fixo, sem Rua/Módulo/Nível.
        return [_PosicaoField('Código especial', value)];
      }

      const nomesPadrao = ['Rua', 'Módulo', 'Nível'];
      var proximoNome = 0;
      final campos = <_PosicaoField>[];
      for (var i = 0; i < maskParts.length; i++) {
        if (variavel[i]) {
          final nome = proximoNome < nomesPadrao.length
              ? nomesPadrao[proximoNome]
              : 'Campo ${proximoNome + 1}';
          proximoNome++;
          campos.add(_PosicaoField(nome, valueParts[i]));
        } else {
          campos.add(_PosicaoField('Complemento', valueParts[i], literal: true));
        }
      }
      return campos;
    }

    // Máscara sem separador e fora do formato antigo conhecido de 8 chars.
    return [_PosicaoField('Valor', value)];
  }

  // ---------------------------------------------------
  // SERVICE
  // ---------------------------------------------------
  static Future<List<String>> getMasksForField(
      BuildContext context, MaskFieldName fieldName) async {
    final service = context.read<InventoryService>();
    final masks = await service.getMasksByFieldName(fieldName);
    return masks.map((m) => m.fieldMask).toList();
  }
}


/*
import 'package:flutter/material.dart';
import 'package:oxdata/app/core/utils/mask_validate.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class FieldInfoPopup extends StatelessWidget {
  final String value;
  final MaskFieldName field;
  final String title;
  final IconData icon;

  const FieldInfoPopup({
    super.key,
    required this.value,
    required this.field,
    required this.title,
    required this.icon,
  });

  String get description {
    switch (field) {
      case MaskFieldName.Unitizador:
        return "Código Único de itentificação.";
      case MaskFieldName.Posicao:
        return "Código da posição (DEPÓSITO - BLOCO - QUADRA - LOTE - ANDAR).";
      case MaskFieldName.Codigo:
        return "Código da Peça/Item.";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(title, icon),
              const SizedBox(height: 24),
              _buildFieldWidget(context),
              const SizedBox(height: 24),
              _buildOkButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // HEADER
  // ---------------------------------------------------
  Widget _buildSectionHeader(String text, IconData iconData) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: Colors.indigo, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------
  // CONTAINER PADRÃO
  // ---------------------------------------------------
  Widget _buildDescriptionContainer(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  // ---------------------------------------------------
  // STATUS DE VALIDAÇÃO (REUTILIZÁVEL)
  // ---------------------------------------------------
  Widget _buildValidationStatus({
    required bool hasValue,
    required bool isValid,
  }) {
    final Color statusColor = !hasValue
        ? Colors.grey
        : (isValid ? Colors.green.shade700 : Colors.red.shade700);

    final IconData statusIcon = !hasValue
        ? Icons.hourglass_empty
        : (isValid ? Icons.check_circle : Icons.cancel);

    final String statusText = !hasValue
        ? "Aguardando leitura.."
        : (isValid ? "VÁLIDO" : "INVÁLIDO");

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------
  // SWITCH PRINCIPAL
  // ---------------------------------------------------
  Widget _buildFieldWidget(BuildContext context) {
    switch (field) {
      case MaskFieldName.Unitizador:
        return _buildUnitizerContent(context);
      case MaskFieldName.Posicao:
        return _buildPosition8Content(context); // _buildPositionContent(context);
      case MaskFieldName.Codigo:
        return _buildProductContent(context);
      default:
        return _buildDescriptionContainer(
          Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
        );
    }
  }

  // ---------------------------------------------------
  // UNITIZADOR
  // ---------------------------------------------------
  Widget _buildUnitizerContent(BuildContext context) {
    return Column(
      children: [
        _buildDescriptionContainer(
          Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
        ),
        const SizedBox(height: 16),

        FutureBuilder<List<String>>(
          future: getMasksForField(context, field),
          builder: (context, snapshot) {
            final masks = snapshot.data ?? [];
            final bool hasValue = value.isNotEmpty;
            final bool isValid =
                hasValue && MaskValidatorService.validateMask(value, masks);

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: SpinKitThreeBounce(color: Colors.white, size: 30.0),);
            }

            return Column(
              children: [
                _buildMasksInfo(masks),
                const SizedBox(height: 20),
                _buildValue(value, isValid, hasValue),
                const SizedBox(height: 4),
                _buildValidationStatus(
                  hasValue: hasValue,
                  isValid: isValid,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------
  // POSIÇÃO
  // ---------------------------------------------------

    Widget _buildPosition8Content(BuildContext context) {
    // Função auxiliar para extrair com segurança
    String safeExtract(String str, int start, int end) {
      if (str.length <= start) return "";
      return str.substring(start, str.length < end ? str.length : end).trim();
    }

    // Extração baseada na sua regra: 2, 2, 1, 2, 1 (Total 8)
    final deposito = safeExtract(value, 0, 2);
    final bloco = safeExtract(value, 2, 4);
    final quadra = safeExtract(value, 4, 5);
    final lote = safeExtract(value, 5, 7);
    final andar = safeExtract(value, 7, 8);
    final undefined = safeExtract(value, 8, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDescriptionContainer(
          Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
        ),
        const SizedBox(height: 16),

        // FutureBuilder englobando a validação e as máscaras
        FutureBuilder<List<String>>(
          future: FieldInfoPopup.getMasksForField(context, field),
          builder: (context, snapshot) {
            final masks = snapshot.data ?? [];
            final bool hasValue = value.isNotEmpty;
            
            // Validação em tempo real contra as máscaras do banco
            final bool isValid = hasValue && MaskValidatorService.validateMask(value, masks);

            // Cores e ícones dinâmicos
            final Color statusColor = !hasValue
                ? Colors.grey
                : (isValid ? Colors.green.shade700 : Colors.red.shade700);

            final IconData statusIcon = !hasValue
                ? Icons.hourglass_empty
                : (isValid ? Icons.check_circle : Icons.cancel);

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: SpinKitThreeBounce(color: Colors.white, size: 30.0),);
            }

            return Column(
              children: [
                // 2. Container de Informação de Máscaras
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_scanner, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          masks.isEmpty
                              ? "Campo sem formato de entrada definido."
                              : "Formatos de endereço aceitos:\n" + 
                                masks.map((m) => "$m (${m.length} caracteres)").join('\n'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                _buildValue(value, isValid, hasValue),
                const SizedBox(height: 4),
                // 1. Widget de Status de Validação
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        !hasValue 
                            ? "Aguardando leitura.." 
                            : (isValid ? "VÁLIDO" : "INVÁLIDO"),
                        style: TextStyle(
                          color: statusColor, 
                          fontSize: 16, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        // Detalhamento da Estrutura
        _buildSectionHeader("Estrutura da Posição", Icons.layers_outlined),
        const SizedBox(height: 6),
        _buildDescriptionContainer(
          Column(
            children: [
              _buildLocationRow("Depósito:", deposito, deposito.isEmpty, 2),
              _buildLocationRow("Bloco:", bloco, bloco.isEmpty, 2),
              _buildLocationRow("Quadra:", quadra, quadra.isEmpty, 1),
              _buildLocationRow("Lote:", lote, lote.isEmpty, 2),
              _buildLocationRow("Andar:", andar, andar.isEmpty, 1),
              if (undefined.isNotEmpty)
                _buildLocationRow("", undefined, true, undefined.length),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLocationRow(String label, String val, bool hasError, int maskLength) {
    Color textColor = hasError ? Colors.red.shade900 : Colors.black54;
    Color backgroundColor = hasError ? Colors.red.withOpacity(0.1) : Colors.green.shade100;
    if (value.isEmpty && label != "") {
      textColor = Colors.black54;
      backgroundColor = Colors.transparent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              color: textColor, 
              fontWeight: hasError ? FontWeight.bold : FontWeight.w500
            )
          ),
          Text(
            (hasError && label != "") ? ("*" * maskLength) : val,
            style: TextStyle(
              fontFamily: 'monospace', 
              fontWeight: FontWeight.bold, 
              color: textColor
            )
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------
  // PRODUTO
  // ---------------------------------------------------
  Widget _buildProductContent(BuildContext context) {
    return Column(
      children: [
        _buildDescriptionContainer(
          Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
        ),
        const SizedBox(height: 16),

        FutureBuilder<List<String>>(
          future: getMasksForField(context, field),
          builder: (context, snapshot) {
            final masks = snapshot.data ?? [];
            final bool hasValue = value.isNotEmpty;
            final bool isValid =
                hasValue && MaskValidatorService.validateMask(value, masks);

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: SpinKitThreeBounce(color: Colors.white, size: 30.0),);
            }

            return Column(
              children: [
                _buildMasksInfo(masks),
                const SizedBox(height: 20),
                _buildValue(value, isValid, hasValue),
                const SizedBox(height: 4),
                _buildValidationStatus(
                  hasValue: hasValue,
                  isValid: isValid,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildValue(String value, bool isValid, bool hasValue) {
  if (!hasValue) return const SizedBox.shrink();

  final Color statusColor = isValid ? Colors.green : Colors.red;

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),

    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: statusColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    ),
  );
}

  // ---------------------------------------------------
  // MÁSCARAS INFO
  // ---------------------------------------------------
  Widget _buildMasksInfo(List<String> masks) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_scanner, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              masks.isEmpty
                  ? "Campo sem formato de entrada definido."
                  : masks.map((m) => "$m (${m.length} caracteres)").join('\n'),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------
  // BOTÃO OK
  // ---------------------------------------------------
  Widget _buildOkButton(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 140,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'OK',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // SERVICE
  // ---------------------------------------------------
  static Future<List<String>> getMasksForField(
      BuildContext context, MaskFieldName fieldName) async {
    final service = context.read<InventoryService>();
    final masks = await service.getMasksByFieldName(fieldName);
    return masks.map((m) => m.fieldMask).toList();
  }
}

*/