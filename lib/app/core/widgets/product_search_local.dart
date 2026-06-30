import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/db/app_database.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ProductSearchLocalDialog extends StatefulWidget {
  const ProductSearchLocalDialog({super.key});

  @override
  State<ProductSearchLocalDialog> createState() => _ProductSearchLocalDialogState();
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
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.only(
        top: 56, // respeita a safe area
        left: 8,
        right: 8,
        bottom: 10,
      ),
      alignment: Alignment.topCenter,
      child: Material(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER (Padrão FieldInfoPopup) ---
              _buildSectionHeader('Pesquisar Produto', Icons.search_rounded),
              
              const SizedBox(height: 8),

              // --- SEARCH FIELD (Estilo FieldInfoPopup) ---
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Digite o nome ou código..',
                  prefixIcon: const Icon(Icons.manage_search_rounded, color: Colors.indigo),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 22),
                          onPressed: () {
                            _controller.clear();
                            _search('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.indigo.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.indigo, width: 1),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // --- CORPO / LISTA ---
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 350),
                  child: _loading
                      ? const Center(child: SpinKitThreeBounce(color: Colors.white, size: 30.0),)
                      : _results.isEmpty && _controller.text.isNotEmpty
                          ? _buildEmptyState()
                          : _buildList(),
                ),
              ),

              const SizedBox(height: 22),

              // --- BOTÃO CANCELAR (Padrão FieldInfoPopup) ---
              _buildCloseButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text, IconData iconData) {
    return Stack(
      alignment: Alignment.centerLeft, // Alinha o ícone à esquerda
      children: [
        // Camada 1: O Texto centralizado na largura total
        SizedBox(
          width: double.infinity,
          child: Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          child: Icon(iconData, color: Colors.indigo, size: 28),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Nenhum produto encontrado',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(color: Colors.indigo.shade800, height: 3),
      itemBuilder: (context, index) {
        final p = _results[index];
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          title: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              p.productName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          subtitle: Text(
            'Código: ${p.productId}  •  ${p.barcode}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, size: 26),
          onTap: () => Navigator.pop(context, p),
        );
      },
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 160,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'CANCELAR',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}