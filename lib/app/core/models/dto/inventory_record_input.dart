import 'package:oxdata/app/core/models/inventory_record_model.dart';

class InventoryRecordInput {
  final int? id; // 👈 Adicionado: opcional para edições ou controle local
  final String unitizer;
  final String position;
  final String product;
  final double? qtdPorPilha;
  final double? numPilhas;
  final double? qtdAvulsa;

  InventoryRecordInput({
    this.id, // Não é obrigatório (pode ser null para novos registros)
    required this.unitizer,
    required this.position,
    required this.product,
    required this.qtdPorPilha,
    required this.numPilhas,
    required this.qtdAvulsa,
  });

  /// Método utilitário para calcular o total com base nos inputs
  double get total => ((numPilhas ?? 0) * (qtdPorPilha ?? 0)) + (qtdAvulsa ?? 0);

  /// Método para facilitar a conversão para o InventoryRecordModel do banco/API
  /// (Ajuste os nomes dos campos conforme sua necessidade)
  InventoryRecordModel toModel(String inventCode, String? user) {
    return InventoryRecordModel(
      id: id,
      inventCode: inventCode,
      inventUser: user,
      inventUnitizer: unitizer,
      inventLocation: position,
      inventProduct: product,
      inventStandardStack: (qtdPorPilha ?? 0).toInt(),
      inventQtdStack: (numPilhas ?? 0).toInt(),
      inventQtdIndividual: qtdAvulsa ?? 0,
      inventTotal: total,
      inventCreated: DateTime.now(),
    );
  }

  /// Verifica se os campos obrigatórios e a lógica de quantidade estão preenchidos
  bool get isValid {
    // Identificação básica obrigatória
    final bool hasBasics = unitizer.isNotEmpty && 
                           position.isNotEmpty && 
                           product.isNotEmpty;

    // Regra de Quantidade: (Pilha E NumPilhas) OU (Avulsa)
    final bool hasStackQuantity = (qtdPorPilha != null && qtdPorPilha! > 0) && 
                                  (numPilhas != null && numPilhas! > 0);
    
    final bool hasIndividualQuantity = (qtdAvulsa != null && qtdAvulsa! > 0);

    return hasBasics && (hasStackQuantity || hasIndividualQuantity);
  }
}