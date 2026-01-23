import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/db/app_database.dart';

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                      ? const Center(child: CircularProgressIndicator())
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


/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/db/app_database.dart'; // Certifique-se que o caminho está correto

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
      backgroundColor: Colors.transparent, // Fundo transparente para controlar o shape no Container
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500), // Limita largura em tablets/desktop
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFF475569), size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Buscar Produto',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    splashRadius: 24,
                  ),
                ],
              ),
            ),

            // --- SEARCH FIELD ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _search,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Digite o nome ou código...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                  prefixIcon: const Icon(Icons.manage_search_rounded, color: Colors.indigo),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel_rounded, size: 20, color: Colors.grey),
                          onPressed: () {
                            _controller.clear();
                            _search('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: Colors.indigo, width: 1),
                  ),
                ),
              ),
            ),

            const Divider(height: 24, thickness: 1),

            // --- CORPO ---
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 450),
                child: _loading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      )
                    : _results.isEmpty && _controller.text.isNotEmpty
                        ? _buildEmptyState()
                        : _buildList(),
              ),
            ),
            
            const SizedBox(height: 12), // Espaçamento final para respiro
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum produto encontrado',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final p = _results[index];
        return Material(
          color: Colors.transparent,
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            tileColor: Colors.white,
            hoverColor: Colors.indigo.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(
              p.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            subtitle: Row(
              children: [
                const Icon(Icons.tag, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${p.productId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.qr_code_scanner, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(p.barcode),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () => Navigator.pop(context, p),
          ),
        );
      },
    );
  }
}
*/