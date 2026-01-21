import 'package:flutter/material.dart';
import 'package:oxdata/app/core/utils/mask_validate.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';

class FieldInfoPopup extends StatelessWidget {
  final String value;
  final MaskFieldName field;
  final String title;
  final IconData icon;
  final String description;

  const FieldInfoPopup({
    super.key,
    required this.value,
    required this.field,
    required this.title,
    required this.icon,
    required this.description,
  });

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
              const SizedBox(height: 32),
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
              return const Center(child: CircularProgressIndicator());
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
              return const Center(child: CircularProgressIndicator());
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
                const SizedBox(height: 20),
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

        // 3. Detalhamento da Estrutura
        _buildSectionHeader("Estrutura da Posição", Icons.layers_outlined),
        const SizedBox(height: 6),
        _buildDescriptionContainer(
          Column(
            children: [
              _buildLocationRow("Depósito", deposito, deposito.isEmpty),
              _buildLocationRow("Bloco", bloco, bloco.isEmpty),
              _buildLocationRow("Quadra", quadra, quadra.isEmpty),
              _buildLocationRow("Lote", lote, lote.isEmpty),
              _buildLocationRow("Andar", andar, andar.isEmpty),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLocationRow(String label, String val, bool hasError) {
    final Color textColor = hasError ? Colors.red.shade700 : Colors.black54;
    final Color backgroundColor = hasError ? Colors.red.withOpacity(0.1) : Colors.green.shade100;

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
            "$label:", 
            style: TextStyle(
              color: hasError ? Colors.red.shade900 : Colors.black54, 
              fontWeight: hasError ? FontWeight.bold : FontWeight.w500
            )
          ),
          Text(
            hasError ? "*" : val, 
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
              return const Center(child: CircularProgressIndicator());
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
                  : masks.map((m) => "• $m (${m.length} caracteres)").join('\n'),
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
