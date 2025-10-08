import 'package:flutter/material.dart';
import 'dart:math';

class CustomAnimatedPageView extends StatefulWidget {
  const CustomAnimatedPageView({super.key});

  @override
  State<CustomAnimatedPageView> createState() => _CustomAnimatedPageViewState();
}

class _CustomAnimatedPageViewState extends State<CustomAnimatedPageView> {
  // 1. O PageController
  late PageController _pageController;
  
  // Usaremos este valor para calcular a posição exata, incluindo decimais durante o scroll.
  double _currentPage = 0.0; 
  
  // Nossas páginas e as cores correspondentes
  final List<Color> pageColors = [
    Colors.deepOrange,
    Colors.teal,
    Colors.indigo,
  ];
  
  final List<String> pageTitles = [
    "Página Um",
    "Página Dois",
    "Página Três",
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85, // Mostra um pouco da próxima página
    );
    
    // Adiciona um listener para atualizar _currentPage em cada frame de animação.
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Widget para construir cada página dentro do PageView
  Widget _buildPageItem(int index) {
    // Calcula a interpolação para o AnimatedContainer
    double diff = index - _currentPage;
    
    // Usamos o módulo e o Clamp para que a diferença seja entre -1.0 e 1.0
    // e apenas a página atual e a próxima/anterior sejam afetadas.
    double scaleFactor = (1 - (diff.abs() * 0.2)).clamp(0.8, 1.0);
    
    // Interpolação personalizada para a opacidade e margem.
    // Usamos um Math.cos para um efeito de "pressionar" mais suave.
    double marginFactor = (1 - (cos(diff * pi) + 1) / 2) * 50;

    return Center(
      // 2. AnimatedContainer: anima cor, margem e escala (via Transform)
      child: Transform.scale(
        scale: scaleFactor, // Aplica o fator de escala calculado
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(vertical: marginFactor),
          decoration: BoxDecoration(
            color: pageColors[index],
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              pageTitles[index],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget para construir o indicador de página animado
  Widget _buildIndicator() {
    // Largura total de um ponto indicador (ajuste se mudar o tamanho)
    const double indicatorWidth = 10.0;
    
    // Espaço entre os pontos
    const double spacing = 10.0; 
    
    // 3. Interpolação para o indicador
    // A posição horizontal (left) é calculada com base na página atual.
    double leftPosition = (_currentPage * (indicatorWidth + spacing)); 

    return Stack(
      alignment: Alignment.center,
      children: [
        // Fundo com todos os pontos cinzas (fixed)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pageColors.length, (index) {
            return Container(
              width: indicatorWidth,
              height: indicatorWidth,
              margin: EdgeInsets.symmetric(horizontal: spacing / 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),

        // Ponto animado (azul), que se move com o PageView
        Positioned(
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0), // Ajuste inicial
              child: Transform.translate(
                // Move o indicador com base na posição de scroll
                offset: Offset(leftPosition + 30.0, 0), // O 30.0 é um ajuste para centralizar
                child: Container(
                  width: indicatorWidth,
                  height: indicatorWidth,
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PageView com Animações Customizadas'),
        backgroundColor: Colors.blueAccent,
      ),
      // 4. Stack: para sobrepor o PageView e o Indicador de Página.
      body: Stack(
        children: <Widget>[
          // Conteúdo Principal (PageView)
          PageView.builder(
            controller: _pageController,
            itemCount: pageColors.length,
            itemBuilder: (context, index) {
              return _buildPageItem(index);
            },
          ),
          
          // Indicador de Página (Sobreposto)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: _buildIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}