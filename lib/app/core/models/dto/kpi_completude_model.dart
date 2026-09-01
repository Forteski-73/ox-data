/// Representa uma categoria de cobertura de imagens (Produto, Embalagem,
/// Paletização) dentro de `KpiCompletudeModel.categorias`.
class KpiCategoriaModel {
  final String label;
  final double percent; // 0.0 a 1.0

  KpiCategoriaModel({
    required this.label,
    required this.percent,
  });

  factory KpiCategoriaModel.fromMap(Map<String, dynamic> map) {
    return KpiCategoriaModel(
      label: map['label'] as String? ?? '',
      percent: (map['percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Representa o retorno de `GET /API/v1/Kpi/Completude`: os indicadores
/// de completude de imagens dos produtos, usados na KpiPage.
class KpiCompletudeModel {
  final double completudeGeral; // 0.0 a 1.0
  final int totalProdutos;
  final int produtosCompletos;
  final List<KpiCategoriaModel> categorias;

  KpiCompletudeModel({
    required this.completudeGeral,
    required this.totalProdutos,
    required this.produtosCompletos,
    required this.categorias,
  });

  factory KpiCompletudeModel.fromMap(Map<String, dynamic> map) {
    return KpiCompletudeModel(
      completudeGeral: (map['completudeGeral'] as num?)?.toDouble() ?? 0.0,
      totalProdutos: map['totalProdutos'] as int? ?? 0,
      produtosCompletos: map['produtosCompletos'] as int? ?? 0,
      categorias: (map['categorias'] as List<dynamic>? ?? [])
          .map((e) => KpiCategoriaModel.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
