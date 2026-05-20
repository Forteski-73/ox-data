import 'dart:ui';
import 'package:flutter/material.dart';

class CyberGlassButton extends StatefulWidget {
  final double size;
  final IconData icon;
  final Color baseColor;
  final VoidCallback onTap;

  const CyberGlassButton({
    super.key,
    this.size = 100,
    required this.icon,
    required this.baseColor,
    required this.onTap,
  });

  @override
  State<CyberGlassButton> createState() => _CyberGlassButtonState();
}

class _CyberGlassButtonState extends State<CyberGlassButton> {
  // Começa com a opacidade padrão de 0.40 solicitada
  double _currentOpacity = 0.40;
  
  // Variável para gerenciar a cor da borda dinamicamente
  late Color _borderColor;

  @override
  void initState() {
    super.initState();
    // Inicializa a borda com o branco translúcido padrão
    _borderColor = Colors.white.withOpacity(0.5);
  }

  void _triggerFlashEffect() async {
    // 1. "Piscada": Cor sólida máxima e a borda assume a cor do botão
    setState(() {
      _currentOpacity = 1.0; 
      _borderColor = widget.baseColor; // Borda acende na cor do neon (vermelho ou verde)
    });

    // 2. Aguarda um milissegundo rápido (tempo do flash)
    await Future.delayed(const Duration(milliseconds: 150));

    // 3. Retorna suavemente para o estado original (vidro + borda branca)
    if (mounted) {
      setState(() {
        _currentOpacity = 0.40;
        _borderColor = Colors.white.withOpacity(0.5); // Borda volta a ser branca sutil
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onTap: () {
          _triggerFlashEffect(); // Ativa o efeito visual futurista
          widget.onTap();        // Executa a função passada por parâmetro
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150), // Reduzi ligeiramente para o "estalo" ser mais responsivo
          curve: Curves.easeOutCubic, // Curva que valoriza o efeito elétrico
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: widget.baseColor.withOpacity(_currentOpacity),
            border: Border.all(
              color: _borderColor, // Agora usa a nossa cor dinâmica!
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.baseColor.withOpacity(_currentOpacity * 0.4),
                blurRadius: 14,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 48,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}