
/*
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';

class DevPage extends StatelessWidget {
  const DevPage({super.key});

  // Como boa prática, isolamos a URL do asset. 
  // isso viria de um State Manager, injetado no construtor.
  static const String _modelUrl = 'https://oxfordtec.com.br/Imagens/GLB/Analise1.glb';
  static const Color _backgroundColor = Color(0xFFF5F5F5); // Fundo neutro destaca o modelo 3D

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: const AppBarCustom(title: 'PALLET 3D'),
      // O SafeArea garante que o modelo não invada os recortes de tela (Notch/Dynamic Island)
      body: const SafeArea(
        child: ModelViewer(
          src: _modelUrl,
          alt: 'Visualização 3D do modelo Analise1',
          
          // UI / UX
          autoRotate: true,          // Habilita o giro automático ao carregar
          autoRotateDelay: 0,        // Começa a girar imediatamente
          cameraControls: true,      // Permite pan, zoom e rotação via touch/mouse
          
          // Performance / Rendering
          ar: false,                 // Desativado se não for usar Realidade Aumentada (poupa recursos)
          backgroundColor: _backgroundColor,
          
          // O model-viewer já possui um loading state nativo elegante, 
          // mas da para personalizar as cores via CSS interno se necessário.
        ),
      ),
    );
  }
}
*/

// bom_tree_page.dart
//
// Página de exemplo: Estrutura de Produto (BOM) em diagrama de árvore
// expansível, no estilo de organograma.
//
// Como testar isoladamente:
//   1) flutter create bom_demo && cd bom_demo
//   2) Substitua lib/main.dart pelo conteúdo deste arquivo
//   3) flutter run
//
// Para usar dentro de um projeto existente:
//   - Copie este arquivo para lib/pages/bom_tree_page.dart
//   - Remova a função main()/BomDemoApp se já tiver seu próprio MaterialApp
//   - Navegue para BomTreePage(rootNode: seuNo) passando os dados vindos da API


import 'package:flutter/material.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';

void main() => runApp(const DevPage());

class DevPage extends StatelessWidget {
  const DevPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Estrutura de Produto (BOM)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      ),
      home: BomTreePage(rootNode: sampleBom),
    );
  }
}

// ---------------------------------------------------------------------------
// MODELO DE DADOS
// ---------------------------------------------------------------------------

enum BomNodeType { produtoAcabado, semiAcabado, materiaPrima, embalagem }

extension BomNodeTypeX on BomNodeType {
  String get label {
    switch (this) {
      case BomNodeType.produtoAcabado:
        return 'Produto Acabado';
      case BomNodeType.semiAcabado:
        return 'Semiacabado';
      case BomNodeType.materiaPrima:
        return 'Matéria-Prima';
      case BomNodeType.embalagem:
        return 'Embalagem';
    }
  }

  Color get color {
    switch (this) {
      case BomNodeType.produtoAcabado:
        return const Color(0xFF3F51B5);
      case BomNodeType.semiAcabado:
        return const Color(0xFFEF6C00);
      case BomNodeType.materiaPrima:
        return const Color(0xFF2E7D32);
      case BomNodeType.embalagem:
        return const Color(0xFF546E7A);
    }
  }

  IconData get icon {
    switch (this) {
      case BomNodeType.produtoAcabado:
        return Icons.inventory_2_rounded;
      case BomNodeType.semiAcabado:
        return Icons.precision_manufacturing_rounded;
      case BomNodeType.materiaPrima:
        return Icons.category_rounded;
      case BomNodeType.embalagem:
        return Icons.inventory_rounded;
    }
  }
}

class BomNode {
  final String id;
  final String code;
  final String name;
  final BomNodeType type;
  final double quantity;
  final String unit;
  final List<BomNode> children;

  BomNode({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.quantity,
    required this.unit,
    this.children = const [],
  });

  int get totalDescendants {
    int count = children.length;
    for (final c in children) {
      count += c.totalDescendants;
    }
    return count;
  }
}

// ---------------------------------------------------------------------------
// DADOS DE EXEMPLO (troque por dados vindos da sua API)
// ---------------------------------------------------------------------------

final sampleBom = BomNode(
  id: 'root',
  code: 'PA-1000',
  name: 'Mesa de Escritório Executiva 1,60m',
  type: BomNodeType.produtoAcabado,
  quantity: 1,
  unit: 'UN',
  children: [
    BomNode(
      id: 'n1',
      code: 'SA-2001',
      name: 'Tampo Envernizado 1,60x0,70m',
      type: BomNodeType.semiAcabado,
      quantity: 1,
      unit: 'UN',
      children: [
        BomNode(id: 'n1-1', code: 'MP-3010', name: 'Chapa de MDF 25mm', type: BomNodeType.materiaPrima, quantity: 1.12, unit: 'M2'),
        BomNode(id: 'n1-2', code: 'MP-3011', name: 'Verniz Poliuretano Fosco', type: BomNodeType.materiaPrima, quantity: 0.35, unit: 'L'),
        BomNode(id: 'n1-3', code: 'MP-3012', name: 'Fita de Borda PVC 22mm', type: BomNodeType.materiaPrima, quantity: 4.6, unit: 'M'),
      ],
    ),
    BomNode(
      id: 'n2',
      code: 'SA-2002',
      name: 'Estrutura Metálica Soldada',
      type: BomNodeType.semiAcabado,
      quantity: 1,
      unit: 'UN',
      children: [
        BomNode(
          id: 'n2-1',
          code: 'SA-2003',
          name: 'Pé Metálico Usinado',
          type: BomNodeType.semiAcabado,
          quantity: 4,
          unit: 'UN',
          children: [
            BomNode(id: 'n2-1-1', code: 'MP-3020', name: 'Barra de Aço SAE 1045', type: BomNodeType.materiaPrima, quantity: 0.8, unit: 'KG'),
            BomNode(id: 'n2-1-2', code: 'MP-3021', name: 'Pintura Eletrostática Preta', type: BomNodeType.materiaPrima, quantity: 0.15, unit: 'KG'),
          ],
        ),
        BomNode(id: 'n2-2', code: 'MP-3022', name: 'Tubo de Aço 40x40mm', type: BomNodeType.materiaPrima, quantity: 3.2, unit: 'M'),
        BomNode(id: 'n2-3', code: 'MP-3023', name: 'Solda Elétrica (Eletrodo)', type: BomNodeType.materiaPrima, quantity: 0.2, unit: 'KG'),
      ],
    ),
    BomNode(
      id: 'n3',
      code: 'EMB-4001',
      name: 'Kit de Fixação e Embalagem',
      type: BomNodeType.embalagem,
      quantity: 1,
      unit: 'KIT',
      children: [
        BomNode(id: 'n3-1', code: 'MP-3030', name: 'Parafuso M6x20mm', type: BomNodeType.materiaPrima, quantity: 12, unit: 'UN'),
        BomNode(id: 'n3-2', code: 'MP-3031', name: 'Bucha Plástica 6mm', type: BomNodeType.materiaPrima, quantity: 12, unit: 'UN'),
        BomNode(id: 'n3-3', code: 'MP-3032', name: 'Caixa de Papelão Reforçada', type: BomNodeType.materiaPrima, quantity: 1, unit: 'UN'),
      ],
    ),
  ],
);

// ---------------------------------------------------------------------------
// PÁGINA
// ---------------------------------------------------------------------------

class BomTreePage extends StatefulWidget {
  final BomNode rootNode;
  const BomTreePage({super.key, required this.rootNode});

  @override
  State<BomTreePage> createState() => _BomTreePageState();
}

class _BomTreePageState extends State<BomTreePage> {
  final Set<String> _expandedIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _expandedIds.add(widget.rootNode.id);
    for (final c in widget.rootNode.children) {
      _expandedIds.add(c.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _expandAll() {
    setState(() {
      void collect(BomNode n) {
        if (n.children.isNotEmpty) {
          _expandedIds.add(n.id);
          for (final c in n.children) {
            collect(c);
          }
        }
      }

      collect(widget.rootNode);
    });
  }

  void _collapseAll() {
    setState(() {
      _expandedIds
        ..clear()
        ..add(widget.rootNode.id);
    });
  }

  /// Retorna true se o nó ou algum descendente casa com a busca.
  /// Preenche [matchIds] (nós que casam diretamente) e
  /// [autoExpandIds] (nós que precisam ficar abertos por ter um match abaixo).
  bool _computeMatches(BomNode node, String query, Set<String> matchIds, Set<String> autoExpandIds) {
    final selfMatch = node.name.toLowerCase().contains(query) || node.code.toLowerCase().contains(query);
    bool childMatch = false;
    for (final c in node.children) {
      if (_computeMatches(c, query, matchIds, autoExpandIds)) {
        childMatch = true;
      }
    }
    if (selfMatch) matchIds.add(node.id);
    if (childMatch) autoExpandIds.add(node.id);
    return selfMatch || childMatch;
  }

  bool _subtreeHasMatch(BomNode node, Set<String> matchIds) {
    if (matchIds.contains(node.id)) return true;
    for (final c in node.children) {
      if (_subtreeHasMatch(c, matchIds)) return true;
    }
    return false;
  }

  int _countByType(BomNode node, BomNodeType type) {
    int count = node.type == type ? 1 : 0;
    for (final c in node.children) {
      count += _countByType(c, type);
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final matchIds = <String>{};
    final autoExpandIds = <String>{};
    final isSearching = query.isNotEmpty;
    if (isSearching) {
      _computeMatches(widget.rootNode, query, matchIds, autoExpandIds);
    }
    final effectiveExpanded = isSearching ? {..._expandedIds, ...autoExpandIds} : _expandedIds;

    final totalItens = widget.rootNode.totalDescendants;
    final totalMp = _countByType(widget.rootNode, BomNodeType.materiaPrima);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: const AppBarCustom(title: 'ESTRUTURA BOM'),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSummaryBar(totalItens, totalMp),
          _buildLegend(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (isSearching && matchIds.isEmpty)
                  _buildNoResults()
                else
                  _buildRoot(widget.rootNode, effectiveExpanded, isSearching, matchIds),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Nenhum item encontrado', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Buscar por código ou descrição...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _query = '';
                        }),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F2F6),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Expandir tudo',
            icon: const Icon(Icons.unfold_more_rounded),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F2F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _expandAll,
          ),
          IconButton(
            tooltip: 'Recolher tudo',
            icon: const Icon(Icons.unfold_less_rounded),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F2F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _collapseAll,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(int totalItens, int totalMp) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E8EF)),
      ),
      child: Row(
        children: [
          _summaryStat(Icons.inventory_2_rounded, widget.rootNode.code, widget.rootNode.name, isTitle: true),
          const SizedBox(width: 24),
          _summaryStat(Icons.account_tree_rounded, '$totalItens', 'Componentes na estrutura'),
          const SizedBox(width: 24),
          _summaryStat(Icons.category_rounded, '$totalMp', 'Itens de matéria-prima'),
        ],
      ),
    );
  }

  Widget _summaryStat(IconData icon, String value, String label, {bool isTitle = false}) {
    return Expanded(
      flex: isTitle ? 2 : 1,
      child: Row(
        children: [
          const Icon(Icons.circle, size: 0), // spacer noop (mantém alinhamento em telas estreitas)
          Icon(icon, size: 20, color: Colors.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), overflow: TextOverflow.ellipsis),
                Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: BomNodeType.values.map((t) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(color: t.color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(t.label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoot(BomNode root, Set<String> expanded, bool isSearching, Set<String> matchIds) {
    final isExpanded = expanded.contains(root.id);
    final dimmed = isSearching && !_subtreeHasMatch(root, matchIds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NodeCard(
          node: root,
          isExpanded: isExpanded,
          highlighted: isSearching && matchIds.contains(root.id),
          dimmed: dimmed,
          onTap: root.children.isNotEmpty ? () => _toggle(root.id) : null,
        ),
        if (isExpanded && root.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              children: List.generate(root.children.length, (i) {
                final child = root.children[i];
                final isLast = i == root.children.length - 1;
                return _buildNode(
                  node: child,
                  level: 0,
                  ancestorLines: const [],
                  isLast: isLast,
                  expanded: expanded,
                  isSearching: isSearching,
                  matchIds: matchIds,
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildNode({
    required BomNode node,
    required int level,
    required List<bool> ancestorLines,
    required bool isLast,
    required Set<String> expanded,
    required bool isSearching,
    required Set<String> matchIds,
  }) {
    final isExpanded = expanded.contains(node.id);
    final dimmed = isSearching && !_subtreeHasMatch(node, matchIds);
    const colWidth = 28.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: colWidth * (level + 1),
                child: CustomPaint(
                  painter: _TreeConnectorPainter(
                    level: level,
                    ancestorLines: ancestorLines,
                    isLast: isLast,
                    colWidth: colWidth,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _NodeCard(
                    node: node,
                    isExpanded: isExpanded,
                    highlighted: isSearching && matchIds.contains(node.id),
                    dimmed: dimmed,
                    onTap: node.children.isNotEmpty ? () => _toggle(node.id) : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isExpanded && node.children.isNotEmpty)
          Column(
            children: List.generate(node.children.length, (i) {
              final child = node.children[i];
              final childIsLast = i == node.children.length - 1;
              return _buildNode(
                node: child,
                level: level + 1,
                ancestorLines: [...ancestorLines, !isLast],
                isLast: childIsLast,
                expanded: expanded,
                isSearching: isSearching,
                matchIds: matchIds,
              );
            }),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CARTÃO DO NÓ
// ---------------------------------------------------------------------------

class _NodeCard extends StatelessWidget {
  final BomNode node;
  final bool isExpanded;
  final bool highlighted;
  final bool dimmed;
  final VoidCallback? onTap;

  const _NodeCard({
    required this.node,
    required this.isExpanded,
    required this.highlighted,
    required this.dimmed,
    required this.onTap,
  });

  String _formatQty(double q) {
    if (q == q.roundToDouble()) return q.toInt().toString();
    return q.toStringAsFixed(2);
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(node.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Código: ${node.code}', style: TextStyle(color: Colors.grey.shade600)),
            Text('Tipo: ${node.type.label}', style: TextStyle(color: Colors.grey.shade600)),
            Text('Quantidade: ${_formatQty(node.quantity)} ${node.unit}', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            const Text('Este item não possui subcomponentes cadastrados.', style: TextStyle(fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = node.type.color;
    return Opacity(
      opacity: dimmed ? 0.4 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap ?? () => _showDetails(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: highlighted ? color : const Color(0xFFE7E8EF),
              width: highlighted ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 34,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(node.type.icon, size: 17, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(node.code, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(node.type.label, style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      node.name,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1A1B25)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFF1F2F6), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${_formatQty(node.quantity)} ${node.unit}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1A1B25)),
                ),
              ),
              if (node.children.isNotEmpty) ...[
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
                ),
              ] else
                const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CONECTORES DA ÁRVORE (linhas estilo organograma)
// ---------------------------------------------------------------------------

class _TreeConnectorPainter extends CustomPainter {
  final int level;
  final List<bool> ancestorLines;
  final bool isLast;
  final double colWidth;

  _TreeConnectorPainter({
    required this.level,
    required this.ancestorLines,
    required this.isLast,
    required this.colWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD3D5E0)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    // Linhas verticais "passando" pelos níveis ancestrais que ainda têm irmãos abaixo
    for (int i = 0; i < ancestorLines.length; i++) {
      if (ancestorLines[i]) {
        final x = i * colWidth + colWidth / 2;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }

    // Conector em L do próprio nó até o cartão
    final x = level * colWidth + colWidth / 2;
    final midY = size.height / 2;
    canvas.drawLine(Offset(x, 0), Offset(x, midY), paint);
    canvas.drawLine(Offset(x, midY), Offset((level + 1) * colWidth, midY), paint);
    if (!isLast) {
      canvas.drawLine(Offset(x, midY), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeConnectorPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.isLast != isLast ||
        oldDelegate.colWidth != colWidth ||
        oldDelegate.ancestorLines.length != ancestorLines.length ||
        !_listEquals(oldDelegate.ancestorLines, ancestorLines);
  }

  bool _listEquals(List<bool> a, List<bool> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}