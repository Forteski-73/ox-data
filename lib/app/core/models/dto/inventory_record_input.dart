class InventoryRecordInput {
  final String unitizer;
  final String position;
  final String product;
  final double qtdPorPilha;
  final double numPilhas;
  final double qtdAvulsa;

  InventoryRecordInput({
    required this.unitizer,
    required this.position,
    required this.product,
    required this.qtdPorPilha,
    required this.numPilhas,
    required this.qtdAvulsa,
  });
}