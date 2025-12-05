import 'package:flutter/material.dart';

// -------------------------------------------------------------------
// DEFINIÇÕES DE CORES (Constantes)
// -------------------------------------------------------------------
const Color _defaultColor = Color(0xFFE3F2FD); // Cor Original (Azul claro - Light Blue 50)
const Color _darkerColor = Color.fromARGB(255, 187, 211, 251);  // Cor Mais Escura (Azul mais escuro para o toque - Light Blue 100)
const Color _primaryColor = Color(0xFF3F51B5); // Cor Principal (Indigo 500)
const Color _successColor = Color(0xFF4CAF50);

// -------------------------------------------------------------------
// WIDGET REUTILIZÁVEL: _ColorChangingButton
// Gerencia a mudança de cor (piscar) e o evento de clique.
// (Mantido, para o efeito de piscar)
// -------------------------------------------------------------------
class _ColorChangingButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _ColorChangingButton({
    required this.icon,
    this.onPressed,
  });

  @override
  State<_ColorChangingButton> createState() => __ColorChangingButtonState();
}

class __ColorChangingButtonState extends State<_ColorChangingButton> {
  Color _containerColor = _defaultColor;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _containerColor = _darkerColor;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _containerColor = _defaultColor;
        });
      }
    });
  }

  void _handleTapCancel() {
    setState(() {
      _containerColor = _defaultColor;
    });
  }

  void _handleTap() {
    if (widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: _containerColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Icon(widget.icon, color: _primaryColor, size: 36),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------
// CLASSE PRINCIPAL: InventoryItemPage
// -------------------------------------------------------------------
class InventoryItemPage extends StatefulWidget {
  const InventoryItemPage({super.key});
  
  @override
  State<InventoryItemPage> createState() => _InventoryItemPageState();
}

class _InventoryItemPageState extends State<InventoryItemPage> {
  
  // Métodos de construção do Widget (mantidos no State)
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        const Icon(Icons.dashboard_customize, size: 20, color: _primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
      ],
    );
  }

Widget _buildUnitizerTextField({required String hint}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 18.0), 
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 18.0), 
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10), 
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ColorChangingButton(
            icon: Icons.qr_code_2,
            onPressed: () {
              debugPrint("QR Code Unitizador Clicado!");
            },
          ),
        ],
      ),
    ],
  );
}

  Widget _buildProductTextField({
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                style: const TextStyle(fontSize: 20), 
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(fontSize: 18.0), 
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.qr_code_2,
              onPressed: () {
                debugPrint("QR Code Produto Clicado!");
              },
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.search,
              onPressed: () {
                debugPrint("Pesquisar Produto Clicado!");
              },
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.info_outline,
              onPressed: () {
                debugPrint("Informação Produto Clicado!");
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPositionTextField({required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                style: const TextStyle(fontSize: 18.0), 
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(fontSize: 18.0), 
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.qr_code_2,
              onPressed: () {
                debugPrint("QR Code Posição Clicado!");
              },
            ),
            const SizedBox(width: 8),
            _ColorChangingButton(
              icon: Icons.info_outline,
              onPressed: () {
                debugPrint("Informação Posição Clicado!");
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityField({required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        const TextField(
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20), 
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(fontSize: 18.0), 
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Mantém o bottom fixo
      body: Stack(
        children: [
          SingleChildScrollView(
            // Adiciona padding na parte inferior para a barra de rodapé sobreposta
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 100), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Container de Total Calculado
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "TOTAL DE PEÇAS",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "0",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Campos de Identificação
                _buildSectionTitle("IDENTIFICAÇÃO"),
                const SizedBox(height: 6),
                _buildUnitizerTextField(hint: "Unitizador"),
                const SizedBox(height: 8),
                _buildPositionTextField(hint: "Posição"),
                const SizedBox(height: 8),
                _buildProductTextField(hint: "Produto"),
                const SizedBox(height: 8),
                
                // Campos de Quantidades
                _buildSectionTitle("QUANTIDADES"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildQuantityField(label: "QTD por Pilha")),
                    const SizedBox(width: 10),
                    Expanded(child: _buildQuantityField(label: "Nº de Pilhas")),
                    const SizedBox(width: 10),
                    Expanded(child: _buildQuantityField(label: "QTD Avulsa")),
                  ],
                ),
                const SizedBox(height: 100), // Espaço extra no final
              ],
            ),
          ),
          
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// FUNÇÃO PÚBLICA: buildInventoryBottomBar (Acessível pela classe pai)
// Esta função substitui o método _buildBottomBar na classe State.
// -------------------------------------------------------------------

Widget buildInventoryBottomBar(BuildContext context) {
  final double bottomPadding = MediaQuery.of(context).padding.bottom;

  return Container(
    // 1. Sombra e Forma Agradável
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 2,
          offset: const Offset(0, -3), // Sombra para cima
        ),
      ],
      // Bordas levemente arredondadas no topo
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(0),
        topRight: Radius.circular(0),
      ),
    ),
    padding: EdgeInsets.fromLTRB(8, 8, 8, bottomPadding + 16.0), // Padding generoso
    child: Row(
      children: [
        // Botão de Confirmação (Principal)
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              // 2. Usando a cor primária do tema para maior consistência
              backgroundColor: _successColor, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6), // Bordas arredondadas
              ),
              elevation: 4, // Elevação suave
            ),
            icon: const Icon(Icons.check, size: 30),
            label: const Text(
              "CONFIRMAR",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contagem Confirmada! ✅')),
              );
            },
          ),
        ),
      ],
    ),
  );
}