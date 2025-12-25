import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/db/app_database.dart';

class ProductSearchLocalDialog extends StatefulWidget {
  const ProductSearchLocalDialog({super.key});

  @override
  State<ProductSearchLocalDialog> createState() =>
      _ProductSearchLocalDialogState();
}

class _ProductSearchLocalDialogState extends State<ProductSearchLocalDialog> {
  final TextEditingController _controller = TextEditingController();
  List<Product> _results = [];
  bool _loading = false;
  late AppDatabase db;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = context.read<AppDatabase>();
  }

  Future<void> _search(String text) async {
    if (text.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _loading = true);

    final products = await db.searchProducts(text);

    if (!mounted) return;

    setState(() {
      _results = products;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- HEADER ---
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pesquisa de Produto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _search,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar..',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.indigo
                    ),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              _controller.clear();
                              _search('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                        color: Colors.indigo,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- CORPO ---
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: Colors.indigo,
                      ),
                    )
                  : _results.isEmpty && _controller.text.isNotEmpty
                      ? _buildEmptyState()
                      : _buildList(),
            ),
          ),

          // --- FOOTER ---
          Padding(
            padding: const EdgeInsets.all(0),
            child: TextButton.icon( // .icon para manter o ícone
              style: TextButton.styleFrom(
                backgroundColor: Colors.blueGrey, // Verde
                foregroundColor: Colors.white,            // Texto e ícone brancos para contraste
                minimumSize: const Size(double.infinity, 36), // Largura máxima e altura confortável
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                    topLeft: Radius.zero,
                    topRight: Radius.zero,
                  ),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 18),
              label: const Text(
                'CANCELAR',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhum produto encontrado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,      // Espaço total do widget Divider
        thickness: 4,  // A grossura da linha propriamente dita
        color: Colors.grey.shade200, // cinza levemente mais escuro
      ),
      itemBuilder: (context, index) {
        final p = _results[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          horizontalTitleGap: 0, // Remove o espaço entre o ícone (que não existe) e o texto
          minLeadingWidth: 0,    // Remove a largura mínima reservada para o ícone
          minVerticalPadding: 0, // Diminui o espaço entre o topo e o título
          title: SizedBox(
            //height: 18,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Text(
                p.productName,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          subtitle: Text(
            'Código:  ${p.productId}  •  ${p.barcode}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          onTap: () => Navigator.pop(context, p),
        );
      },
    );
  }
}
