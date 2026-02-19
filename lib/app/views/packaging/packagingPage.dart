import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';

class PackagingPage extends StatefulWidget {
  const PackagingPage({super.key});

  @override
  State<PackagingPage> createState() => _PackagingPageState();
}

class _PackagingPageState extends State<PackagingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _productController = TextEditingController();

  Map<String, dynamic>? _selectedPackaging;
  String _filterText = "";

  // Simulação de Banco de Dados Local
  final List<Map<String, dynamic>> _allPackagings = [
    {
      'id': 1,
      'nome': 'MONTAGEM PADRÃO A',
      'fotos': [],
      'produtos': ['PROD-001', 'PROD-002']
    },
    {
      'id': 2,
      'nome': 'MONTAGEM PADRÃO B',
      'fotos': [],
      'produtos': ['PROD-099']
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _productController.dispose();
    super.dispose();
  }

  // --- COMPONENTE: HEADER DE CONTEXTO ---
  Widget _buildSelectionHeader() {
    if (_selectedPackaging == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MONTAGEM SELECIONADA",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.withOpacity(0.7),
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  _selectedPackaging!['nome'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
          ),
          // Botão de troca usando o padrão ColorChanging
          _ColorChangingButton(
            icon: Icons.swap_horiz,
            size: 40,
            onPressed: () => _tabController.animateTo(0),
          ),
        ],
      ),
    );
  }

  // --- COMPONENTE: CAMPO DE PESQUISA ---
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _filterText = value.toLowerCase()),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Pesquisar..',
        hintStyle: TextStyle(
          color: Colors.blueGrey[300],
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.indigo, size: 22),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _filterText = "";
                  });
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.indigo, width: 1),
        ),
      ),
    );
  }

  Widget _buildSearchProduto() {
    return TextField(
      controller: _productController,
      onChanged: (value) => setState(() {}),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Código do produto..',
        hintStyle: TextStyle(
          color: Colors.blueGrey[300],
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.indigo, size: 22),
        suffixIcon: _productController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => setState(() => _productController.clear()),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.indigo, width: 1),
        ),
      ),
    );
  }

  // --- ABA 1: LISTA DE MONTAGENS ---
  Widget _buildPackagingTab() {
    final filteredList = _allPackagings
        .where((pkg) => pkg['nome'].toString().toLowerCase().contains(_filterText))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildSearchField(),
        ),
        Expanded(
          child: filteredList.isEmpty
              ? _buildEmptyState("Nenhuma montagem encontrada")
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final pkg = filteredList[index];
                    final isSelected = _selectedPackaging?['id'] == pkg['id'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedPackaging = pkg);
                          _tabController.animateTo(1);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.indigo : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.indigo : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(pkg['nome'],
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.indigo : Colors.blueGrey[800])),
                                      const SizedBox(height: 8),
                                      _buildBadge("${pkg['produtos'].length} Produtos"),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                                onPressed: () => _confirmDelete(pkg),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- ABA 2: IMAGENS ---
  Widget _buildImagesTab() {
    if (_selectedPackaging == null) return _buildNoSelectionState("Selecione uma montagem primeiro.");

    final List fotos = _selectedPackaging!['fotos'];

    return Column(
      children: [
        _buildSelectionHeader(),
        Expanded(
          child: fotos.isEmpty
              ? const Center(child: Text("Nenhuma imagem capturada."))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
                  ),
                  itemCount: fotos.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(fotos[index]), fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 5, right: 5,
                          child: GestureDetector(
                            onTap: () => setState(() => fotos.removeAt(index)),
                            child: const CircleAvatar(
                              radius: 14, backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _ColorChangingButton(
            icon: Icons.add_a_photo,
            color: Colors.indigo,
            onPressed: () async {
              final picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.camera);
              if (image != null) setState(() => fotos.add(image.path));
            },
          ),
        ),
      ],
    );
  }

  // --- ABA 3: PRODUTOS ---
  Widget _buildProductsTab() {
    if (_selectedPackaging == null) return _buildNoSelectionState("Selecione uma montagem primeiro.");

    final List produtos = _selectedPackaging!['produtos'];

    return Column(
      children: [
        _buildSelectionHeader(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: _buildSearchProduto(),
              ),
              const SizedBox(width: 10),
              _ColorChangingButton(
                icon: Icons.add,
                color: Colors.green,
                onPressed: () {
                  if (_productController.text.isNotEmpty) {
                    setState(() {
                      produtos.add(_productController.text.toUpperCase());
                      _productController.clear();
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: produtos.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.qr_code_rounded, color: Colors.indigo),
                  title: Text(produtos[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => setState(() => produtos.removeAt(index)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildNoSelectionState(String msg) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.touch_app_outlined, size: 60, color: Colors.indigo.withOpacity(0.2)),
        const SizedBox(height: 16),
        Text(msg, style: TextStyle(color: Colors.blueGrey[300])),
      ],
    ));
  }

  Widget _buildEmptyState(String msg) {
    return Center(child: Text(msg, style: TextStyle(color: Colors.blueGrey[300])));
  }

  void _confirmDelete(Map<String, dynamic> pkg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir?"),
        content: Text("Deseja remover '${pkg['nome']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _allPackagings.removeWhere((item) => item['id'] == pkg['id']);
                if (_selectedPackaging?['id'] == pkg['id']) _selectedPackaging = null;
              });
              Navigator.pop(context);
            },
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddPackagingDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nova Montagem"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Nome")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _allPackagings.add({
                  'id': DateTime.now().millisecondsSinceEpoch,
                  'nome': controller.text.toUpperCase(),
                  'fotos': [],
                  'produtos': []
                }));
                Navigator.pop(context);
              }
            },
            child: const Text("CRIAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        title: "ESQUEMA DE MONTAGEM",
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'MONTAGEM', icon: Icon(Icons.inventory_2)),
              Tab(text: 'IMAGENS', icon: Icon(Icons.photo_library)),
              Tab(text: 'PRODUTOS', icon: Icon(Icons.list_alt)),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPackagingTab(), _buildImagesTab(), _buildProductsTab()],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              backgroundColor: Colors.indigo,
              onPressed: _showAddPackagingDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// --- WIDGET PERSONALIZADO ---
class _ColorChangingButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  const _ColorChangingButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 54,
    this.color,
  });

  @override
  State<_ColorChangingButton> createState() => __ColorChangingButtonState();
}

class __ColorChangingButtonState extends State<_ColorChangingButton> {
  late Color _containerColor;

  final Color _defaultColor = const Color(0xFFE3F2FD);
  final Color _darkerColor = const Color.fromARGB(255, 187, 211, 251);
  final Color _primaryIconColor = const Color(0xFF3F51B5);

  @override
  void initState() {
    super.initState();
    _containerColor = widget.color ?? _defaultColor;
  }

  void _handleTap() async {
    if (widget.onPressed == null) return;

    setState(() {
      _containerColor = widget.color != null 
          ? widget.color!.withOpacity(0.7) 
          : _darkerColor;
    });

    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      setState(() {
        _containerColor = widget.color ?? _defaultColor;
      });
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: widget.size,
        width: widget.size,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[200] : _containerColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            widget.icon,
            color: isDisabled 
                ? Colors.grey[400] 
                : (widget.color != null ? Colors.white : _primaryIconColor),
            size: widget.size * 0.6, 
          ),
        ),
      ),
    );
  }
}