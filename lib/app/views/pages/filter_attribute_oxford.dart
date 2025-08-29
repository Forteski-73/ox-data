import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';

// Importa o serviço e os modelos
import 'package:oxdata/app/core/services/product_service.dart';
import 'package:oxdata/app/core/models/product_brand.dart';
import 'package:oxdata/app/core/models/product_line.dart';
import 'package:oxdata/app/core/models/product_decoration.dart';

class FilterAttributeOxford extends StatefulWidget {
  const FilterAttributeOxford({Key? key}) : super(key: key);

  @override
  _FilterAttributeOxfordState createState() => _FilterAttributeOxfordState();
}

class _FilterAttributeOxfordState extends State<FilterAttributeOxford> {
  final TextEditingController _brandSearchController = TextEditingController();
  final TextEditingController _lineSearchController = TextEditingController();
  final TextEditingController _decorationSearchController = TextEditingController();

  ProductBrand? _selectedBrand;
  ProductLine? _selectedLine;
  ProductDecoration? _selectedDecoration;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductService>(context, listen: false).fetchBrands();
    });
    _brandSearchController.addListener(() => setState(() {}));
    _lineSearchController.addListener(() => setState(() {}));
    _decorationSearchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _brandSearchController.dispose();
    _lineSearchController.dispose();
    _decorationSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);

    final filteredBrands = productService.brands.where((brand) {
      final query = _brandSearchController.text.toLowerCase();
      return query.isEmpty || brand.brandDescription.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: const AppBarCustom(title: 'Filtrar Atributos Oxford'),
      body: Stack(
        children: [
          Column(
            children: [
              // Campo de pesquisa para MARCA - FIXO NO TOPO
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECEF),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: TextField(
                  controller: _brandSearchController,
                  decoration: const InputDecoration(
                    hintText: 'Pesquisar marca...',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                  ),
                ),
              ),
              // Conteúdo da lista de marcas - ROLÁVEL
              Expanded(
                child: ListView.builder(
                  // Padding inferior para que o conteúdo não seja coberto pelo botão "Aplicar"
                  padding: EdgeInsets.only(bottom: 70 + MediaQuery.of(context).padding.bottom),
                  itemCount: filteredBrands.length,
                  itemBuilder: (context, index) {
                    final brand = filteredBrands[index];
                    final isSelected = _selectedBrand?.brandId == brand.brandId;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 1.0),
                      decoration: BoxDecoration(
                        border: (_selectedBrand?.brandId == brand.brandId)
                            ? null
                            : Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
                      ),
                      child: ExpansionTile(
                        key: ValueKey('brand_${brand.brandId}'),
                        initiallyExpanded: isSelected,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),

                        // Controla o fundo no expandido e no fechado
                        backgroundColor: Colors.green.withOpacity(0.2),
                        collapsedBackgroundColor: Colors.white,

                        title: Text(
                          brand.brandDescription,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onExpansionChanged: (isExpanded) {
                          setState(() {
                            if (isExpanded) {
                              _selectedBrand = brand;
                              _selectedLine = null;
                              _selectedDecoration = null;
                              productService.fetchLinesByBrand(brand.brandId);
                            } else {
                              if (_selectedBrand?.brandId == brand.brandId) {
                                _selectedBrand = null;
                                _selectedLine = null;
                                _selectedDecoration = null;
                              }
                            }
                          });
                        },
                        children: [
                          if (_selectedBrand?.brandId == brand.brandId)
                            _buildLinesList(context, brand),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Botão "Aplicar" - posicionado no final da tela (e considerando a área segura)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(right: 3),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.0),
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'brand': _selectedBrand,
                      'line': _selectedLine,
                      'decoration': _selectedDecoration,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 36),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    elevation: 1,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 28, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Aplicar',style: TextStyle(fontSize: 16),),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // O código das funções _buildLinesList e _buildDecorationsList permanece o mesmo.

  Widget _buildLinesList(BuildContext context, ProductBrand brand) {
    final productService = Provider.of<ProductService>(context);
    final lines = productService.getLines(brand.brandId);

    if (lines == null) {
      return const Center(child: CircularProgressIndicator());
    } else if (lines.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(left: 48.0, top: 8.0, bottom: 8.0),
        child: Text("Nenhuma linha encontrada."),
      );
    } else {
      final filteredLines = lines.where((line) {
        final query = _lineSearchController.text.toLowerCase();
        return query.isEmpty || line.lineDescription.toLowerCase().contains(query);
      }).toList();

      return Column(
        children: [
          // Campo de pesquisa para LINHA - FIXO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECEF),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: TextField(
                controller: _lineSearchController,
                decoration: const InputDecoration(
                  hintText: 'Pesquisar linha...',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                ),
              ),
            ),
          ),

          // Lista de linhas - ROLÁVEL
          ...filteredLines.map((line) {
            final isSelected = _selectedLine?.lineId == line.lineId;
return Container(
  margin: const EdgeInsets.symmetric(vertical: 1.0),
  decoration: BoxDecoration(
    border: isSelected
        ? null
        : Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
  ),
  child: ExpansionTile(
    key: ValueKey('line_${brand.brandId}_${line.lineId}'),
    initiallyExpanded: isSelected,
    tilePadding: const EdgeInsets.only(left: 42.0, right: 16.0),

    // 🔑 controla o fundo expandido e colapsado
    backgroundColor: Colors.green.withOpacity(0.2),
    collapsedBackgroundColor: Colors.white,

    title: Text(
      line.lineDescription,
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    ),
    onExpansionChanged: (isExpanded) {
      setState(() {
        if (isExpanded) {
          _selectedLine = line;
          _selectedDecoration = null;
          productService.fetchDecorationsByBrandLine(
              brand.brandId, line.lineId);
        } else {
          if (_selectedLine?.lineId == line.lineId) {
            _selectedLine = null;
            _selectedDecoration = null;
          }
        }
      });
    },
    children: [
      if (_selectedLine?.lineId == line.lineId)
        _buildDecorationsList(context, brand.brandId, line),
    ],
  ),
);

          }).toList(),
        ],
      );
    }
  }

  Widget _buildDecorationsList(BuildContext context, String brandId, ProductLine line) {
    final productService = Provider.of<ProductService>(context);
    final decorations = productService.getDecorations(brandId, line.lineId);

    if (decorations == null) {
      return const Center(child: CircularProgressIndicator());
    } else if (decorations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(left: 64.0, top: 8.0, bottom: 8.0),
        child: Text("Nenhuma decoração encontrada."),
      );
    } else {
      final filteredDecorations = decorations.where((decoration) {
        final query = _decorationSearchController.text.toLowerCase();
        return query.isEmpty || decoration.decorationDescription.toLowerCase().contains(query);
      }).toList();

      return Column(
        children: [
          // Campo de pesquisa para DECORAÇÃO - FIXO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECEF),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: TextField(
                controller: _decorationSearchController,
                decoration: const InputDecoration(
                  hintText: 'Pesquisar decoração...',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                ),
              ),
            ),
          ),

          // Lista de decorações - ROLÁVEL
          ...filteredDecorations.map((decoration) {
            final isSelected = _selectedDecoration?.decorationId == decoration.decorationId;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 1.0),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green.withOpacity(0.2) : Colors.white,
                border: isSelected
                    ? null
                    : Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
              ),
              child: ListTile(
                key: ValueKey('decoration_${brandId}_${line.lineId}_${decoration.decorationId}'),
                contentPadding: const EdgeInsets.only(left: 62.0, right: 16.0),
                title: Text(
                  decoration.decorationDescription,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedDecoration = decoration;
                  });
                },
              ),
            );
          }).toList(),
        ],
      );
    }
  }
}