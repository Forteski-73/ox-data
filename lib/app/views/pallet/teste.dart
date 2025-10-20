import 'package:flutter/material.dart';
import 'dart:math';

class CustomAnimatedPageView extends StatefulWidget {
  const CustomAnimatedPageView({super.key});

  @override
  State<CustomAnimatedPageView> createState() =>
      _CustomAnimatedPageViewState();
}

class _CustomAnimatedPageViewState extends State<CustomAnimatedPageView>
    with TickerProviderStateMixin {
  late PageController _pageController;
  double _currentPage = 0.0;

  final List<Color> pageColors = [
    Colors.deepOrange,
    Colors.teal,
    Colors.indigo,
    Colors.black12,
    Colors.deepPurpleAccent,
    Colors.limeAccent,
    Colors.tealAccent,
    Colors.brown,
    Colors.black,
    Colors.redAccent,
  ];

  final List<String> pageTitles = [
    "Página Um",
    "Página Dois",
    "Página Três",
    "Página Quatro",
    "Página Cinco",
    "Página Seis",
    "Página Sete",
    "Página Oito",
    "Página Nove",
    "Página dez",
  ];

  double floatingTop = 100;
  double floatingLeft = 20;

  bool isDragging = false;
  double dragStartX = 0;
  double dragStartY = 0;

  bool menuOpen = false;

  late List<AnimationController> _menuControllers;
  late List<Animation<double>> _menuAnimations;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });

    // Inicializa animações individuais para cada botão do menu
    _menuControllers = List.generate(pageTitles.length, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 700 + 50 * index),
      );
    });

    _menuAnimations = _menuControllers
        .map((controller) => CurvedAnimation(
              parent: controller,
              curve: Curves.elasticOut,
            ))
        .toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var c in _menuControllers) c.dispose();
    super.dispose();
  }

  Widget _buildPageItem(int index) {
    double diff = index - _currentPage;
    double scaleFactor = (1 - (diff.abs() * 0.2)).clamp(0.8, 1.0);
    double marginFactor = (1 - (cos(diff * pi) + 1) / 2) * 50;

    return Center(
      child: Transform.scale(
        scale: scaleFactor,
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
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    const double indicatorWidth = 10.0;
    const double spacing = 10.0;
    double leftPosition = (_currentPage * (indicatorWidth + spacing));

    return Stack(
      alignment: Alignment.center,
      children: [
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
        Positioned(
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Transform.translate(
                offset: Offset(leftPosition + 30.0, 0),
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

  List<double> _calculateAngles(int itemCount, double buttonX, double buttonY,
      double screenWidth, double screenHeight) {
    double startAngle = 0;
    double endAngle = 2 * pi;

    bool leftSide = buttonX < screenWidth / 2;
    bool topSide = buttonY < screenHeight / 2;

    if (leftSide && topSide) {
      startAngle = 0;
      endAngle = pi / 2;
    } else if (!leftSide && topSide) {
      startAngle = pi / 2;
      endAngle = pi;
    } else if (!leftSide && !topSide) {
      startAngle = pi;
      endAngle = 3 * pi / 2;
    } else if (leftSide && !topSide) {
      startAngle = 3 * pi / 2;
      endAngle = 2 * pi;
    }

    double availableWidth = leftSide ? screenWidth - buttonX - 80 : buttonX - 80;
    double availableHeight = topSide ? screenHeight - buttonY - 80 : buttonY - 80;

    // aumenta o raio proporcional ao número de itens (mínimo de 80)
    double radius = max(min(availableWidth, availableHeight) / 1.5, 80 + itemCount * 5);

    return [startAngle, endAngle, radius];
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = 50.0;

    List<double> angles = _calculateAngles(
        pageTitles.length, floatingLeft, floatingTop, screenWidth, screenHeight);

    double startAngle = angles[0];
    double endAngle = angles[1];
    double radius = angles[2];

    double angleStep = pageTitles.length > 1 ? (endAngle - startAngle) / (pageTitles.length - 1) : 0;

    // Atualiza animação quando menu abre/fecha
    if (menuOpen) {
      for (var c in _menuControllers) {
        c.forward(from: 0);
      }
    } else {
      for (var c in _menuControllers) {
        c.reverse();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PageView com Menu Radial Melhorado'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: pageColors.length,
              itemBuilder: (context, index) => _buildPageItem(index),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: _buildIndicator(),
              ),
            ),

            // Menu radial com animação
            ...List.generate(pageTitles.length, (index) {
              double angle = startAngle + angleStep * index;
              return AnimatedBuilder(
                animation: _menuAnimations[index],
                builder: (context, child) {
                  double scale = _menuAnimations[index].value.clamp(0.0, 1.0);
                  double itemX = floatingLeft +
                      (radius * cos(angle)) * scale;
                  double itemY = floatingTop +
                      (radius * sin(angle)) * scale;

                  // Mantém dentro da tela
                  itemX = itemX.clamp(8.0, screenWidth - buttonSize);
                  itemY = itemY.clamp(8.0, screenHeight - buttonSize);

                  

                  return Positioned(
                    top: itemY,
                    left: itemX,
                    child: Opacity(
                      opacity: scale,
                      child: Transform.scale(
                        scale: scale, // anima a expansão do botão
                        child: GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                            setState(() {
                              menuOpen = false;
                            });
                          },
                          child: Container(
                            width: buttonSize,
                            height: buttonSize,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Botão flutuante principal
            Positioned(
              top: floatingTop,
              left: floatingLeft,
              child: GestureDetector(
                onLongPressStart: (details) {
                  isDragging = true;
                  dragStartX = details.globalPosition.dx - floatingLeft;
                  dragStartY = details.globalPosition.dy - floatingTop;
                },
                onLongPressMoveUpdate: (details) {
                  if (isDragging) {
                    setState(() {
                      floatingLeft =
                          (details.globalPosition.dx - dragStartX)
                              .clamp(0.0, screenWidth - buttonSize);
                      floatingTop =
                          (details.globalPosition.dy - dragStartY)
                              .clamp(0.0, screenHeight - buttonSize);
                    });
                  }
                },
                onLongPressEnd: (details) {
                  isDragging = false;
                },
                onTap: () {
                  if (!isDragging) { // só abre/fecha se não estiver arrastando
                    setState(() {
                      menuOpen = !menuOpen;
                    });
                  }
                },
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(2, 2)),
                    ],
                  ),
                  child: const Icon(Icons.menu, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*import 'package:flutter/material.dart';
import 'dart:math';

class CustomAnimatedPageView extends StatefulWidget {
  const CustomAnimatedPageView({super.key});

  @override
  State<CustomAnimatedPageView> createState() =>
      _CustomAnimatedPageViewState();
}

class _CustomAnimatedPageViewState extends State<CustomAnimatedPageView>
    with TickerProviderStateMixin {
  late PageController _pageController;
  double _currentPage = 0.0;

  final List<Color> pageColors = [
    Colors.deepOrange,
    Colors.teal,
    Colors.indigo,
    Colors.black12,
  ];

  final List<String> pageTitles = [
    "Página Um",
    "Página Dois",
    "Página Três",
    "Página Quatro",
  ];

  double floatingTop = 100;
  double floatingLeft = 20;

  bool isDragging = false;
  double dragStartX = 0;
  double dragStartY = 0;

  bool menuOpen = false;

  late List<AnimationController> _menuControllers;
  late List<Animation<double>> _menuAnimations;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });

    // Inicializa animações individuais para cada botão do menu
    _menuControllers = List.generate(pageTitles.length, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 700 + 50 * index),
      );
    });

    _menuAnimations = _menuControllers
        .map((controller) => CurvedAnimation(
              parent: controller,
              curve: Curves.elasticOut,
            ))
        .toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var c in _menuControllers) c.dispose();
    super.dispose();
  }

  Widget _buildPageItem(int index) {
    double diff = index - _currentPage;
    double scaleFactor = (1 - (diff.abs() * 0.2)).clamp(0.8, 1.0);
    double marginFactor = (1 - (cos(diff * pi) + 1) / 2) * 50;

    return Center(
      child: Transform.scale(
        scale: scaleFactor,
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
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    const double indicatorWidth = 10.0;
    const double spacing = 10.0;
    double leftPosition = (_currentPage * (indicatorWidth + spacing));

    return Stack(
      alignment: Alignment.center,
      children: [
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
        Positioned(
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Transform.translate(
                offset: Offset(leftPosition + 30.0, 0),
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

  List<double> _calculateAngles(int itemCount, double buttonX, double buttonY,
      double screenWidth, double screenHeight) {
    double startAngle = 0;
    double endAngle = 2 * pi;

    bool leftSide = buttonX < screenWidth / 2;
    bool topSide = buttonY < screenHeight / 2;

    if (leftSide && topSide) {
      startAngle = 0;
      endAngle = pi / 2;
    } else if (!leftSide && topSide) {
      startAngle = pi / 2;
      endAngle = pi;
    } else if (!leftSide && !topSide) {
      startAngle = pi;
      endAngle = 3 * pi / 2;
    } else if (leftSide && !topSide) {
      startAngle = 3 * pi / 2;
      endAngle = 2 * pi;
    }

    double availableWidth = leftSide ? screenWidth - buttonX - 80 : buttonX - 80;
    double availableHeight = topSide ? screenHeight - buttonY - 80 : buttonY - 80;
    double radius = min(availableWidth, availableHeight) / 1.5; // mais próximo do botão

    return [startAngle, endAngle, radius];
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = 50.0;

    List<double> angles = _calculateAngles(
        pageTitles.length, floatingLeft, floatingTop, screenWidth, screenHeight);

    double startAngle = angles[0];
    double endAngle = angles[1];
    double radius = angles[2];

    double angleStep = (endAngle - startAngle) / (pageTitles.length - 1);

    // Atualiza animação quando menu abre/fecha
    if (menuOpen) {
      for (var c in _menuControllers) {
        c.forward(from: 0);
      }
    } else {
      for (var c in _menuControllers) {
        c.reverse();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PageView com Menu Radial Melhorado'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: pageColors.length,
              itemBuilder: (context, index) => _buildPageItem(index),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: _buildIndicator(),
              ),
            ),

            // Menu radial com animação
            ...List.generate(pageTitles.length, (index) {
              double angle = startAngle + angleStep * index;
              return AnimatedBuilder(
                animation: _menuAnimations[index],
                builder: (context, child) {
                  double scale = _menuAnimations[index].value.clamp(0.0, 1.0);
                  double itemX = floatingLeft +
                      (radius * cos(angle)) * scale;
                  double itemY = floatingTop +
                      (radius * sin(angle)) * scale;

                  // Mantém dentro da tela
                  itemX = itemX.clamp(8.0, screenWidth - buttonSize);
                  itemY = itemY.clamp(8.0, screenHeight - buttonSize);

                  

                  return Positioned(
                    top: itemY,
                    left: itemX,
                    child: Opacity(
                      opacity: scale,
                      child: Transform.scale(
                        scale: scale, // anima a expansão do botão
                        child: GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                            setState(() {
                              menuOpen = false;
                            });
                          },
                          child: Container(
                            width: buttonSize,
                            height: buttonSize,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Botão flutuante principal
            Positioned(
              top: floatingTop,
              left: floatingLeft,
              child: GestureDetector(
                onLongPressStart: (details) {
                  isDragging = true;
                  dragStartX = details.globalPosition.dx - floatingLeft;
                  dragStartY = details.globalPosition.dy - floatingTop;
                },
                onLongPressMoveUpdate: (details) {
                  if (isDragging) {
                    setState(() {
                      floatingLeft =
                          (details.globalPosition.dx - dragStartX)
                              .clamp(0.0, screenWidth - buttonSize);
                      floatingTop =
                          (details.globalPosition.dy - dragStartY)
                              .clamp(0.0, screenHeight - buttonSize);
                    });
                  }
                },
                onLongPressEnd: (details) {
                  isDragging = false;
                },
                onTap: () {
                  if (!isDragging) { // só abre/fecha se não estiver arrastando
                    setState(() {
                      menuOpen = !menuOpen;
                    });
                  }
                },
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(2, 2)),
                    ],
                  ),
                  child: const Icon(Icons.menu, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/

/*********************************************************************** ESSE É BOM ****************************
import 'package:flutter/material.dart';
import 'dart:math';

class CustomAnimatedPageView extends StatefulWidget {
  const CustomAnimatedPageView({super.key});

  @override
  State<CustomAnimatedPageView> createState() => _CustomAnimatedPageViewState();
}

class _CustomAnimatedPageViewState extends State<CustomAnimatedPageView> {
  late PageController _pageController;
  double _currentPage = 0.0;

  final List<Color> pageColors = [
    Colors.deepOrange,
    Colors.teal,
    Colors.indigo,
    Colors.black12,
  ];

  final List<String> pageTitles = [
    "Página Um",
    "Página Dois",
    "Página Três",
    "Página Quatro",
  ];

  // Posição inicial do botão flutuante
  double floatingTop = 100;
  double floatingLeft = 20;

  bool isDragging = false;
  double dragStartX = 0;
  double dragStartY = 0;

  bool menuOpen = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
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

  Widget _buildPageItem(int index) {
    double diff = index - _currentPage;
    double scaleFactor = (1 - (diff.abs() * 0.2)).clamp(0.8, 1.0);
    double marginFactor = (1 - (cos(diff * pi) + 1) / 2) * 50;

    return Center(
      child: Transform.scale(
        scale: scaleFactor,
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

  Widget _buildIndicator() {
    const double indicatorWidth = 10.0;
    const double spacing = 10.0;
    double leftPosition = (_currentPage * (indicatorWidth + spacing));

    return Stack(
      alignment: Alignment.center,
      children: [
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
        Positioned(
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Transform.translate(
                offset: Offset(leftPosition + 30.0, 0),
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

  // Calcula o ângulo inicial e final para abrir o menu em arco, dependendo da posição
  List<double> _calculateAngles(int itemCount, double buttonX, double buttonY,
      double screenWidth, double screenHeight) {
    double startAngle = 0;
    double endAngle = 2 * pi;

    const double margin = 100; // margem mínima para não sair da tela
    bool leftSide = buttonX < screenWidth / 2;
    bool topSide = buttonY < screenHeight / 2;

    if (leftSide && topSide) {
      startAngle = 0;
      endAngle = pi / 2;
    } else if (!leftSide && topSide) {
      startAngle = pi / 2;
      endAngle = pi;
    } else if (!leftSide && !topSide) {
      startAngle = pi;
      endAngle = 3 * pi / 2;
    } else if (leftSide && !topSide) {
      startAngle = 3 * pi / 2;
      endAngle = 2 * pi;
    }

    // Garante espaço se estiver muito próximo da borda
    double availableWidth = leftSide
        ? screenWidth - buttonX - margin
        : buttonX - margin;
    double availableHeight = topSide
        ? screenHeight - buttonY - margin
        : buttonY - margin;

    double radius = min(availableWidth, availableHeight);
    return [startAngle, endAngle, radius];
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = 50.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PageView com Menu Radial Inteligente'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: pageColors.length,
              itemBuilder: (context, index) => _buildPageItem(index),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: _buildIndicator(),
              ),
            ),

            // Botão flutuante
            Positioned(
              top: floatingTop,
              left: floatingLeft,
              child: GestureDetector(
                onLongPressStart: (details) {
                  isDragging = true;
                  dragStartX = details.globalPosition.dx - floatingLeft;
                  dragStartY = details.globalPosition.dy - floatingTop;
                },
                onLongPressMoveUpdate: (details) {
                  if (isDragging) {
                    setState(() {
                      floatingLeft =
                          (details.globalPosition.dx - dragStartX)
                              .clamp(0.0, screenWidth - buttonSize);
                      floatingTop =
                          (details.globalPosition.dy - dragStartY)
                              .clamp(0.0, screenHeight - buttonSize);
                    });
                  }
                },
                onLongPressEnd: (details) {
                  isDragging = false;
                },
                onTap: () {
                  setState(() {
                    menuOpen = !menuOpen;
                  });
                },
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.menu, color: Colors.white),
                ),
              ),
            ),

            // Menu radial inteligente
            if (menuOpen)
              ...List.generate(pageTitles.length, (index) {
                List<double> angles = _calculateAngles(
                    pageTitles.length, floatingLeft, floatingTop, screenWidth, screenHeight);
                double startAngle = angles[0];
                double endAngle = angles[1];
                double radius = angles[2];

                double angleStep = (endAngle - startAngle) / (pageTitles.length - 1);
                double angle = startAngle + angleStep * index;

                double itemX =
                    (floatingLeft + buttonSize / 2 + radius * cos(angle) - buttonSize / 2)
                        .clamp(8.0, screenWidth - buttonSize);
                double itemY =
                    (floatingTop + buttonSize / 2 + radius * sin(angle) - buttonSize / 2)
                        .clamp(8.0, screenHeight - buttonSize);

                return Positioned(
                  top: itemY,
                  left: itemX,
                  child: GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                      setState(() {
                        menuOpen = false;
                      });
                    },
                    child: Container(
                      width: buttonSize,
                      height: buttonSize,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
***************************************************************************************************/


/***************************************************************************************************
import 'package:flutter/material.dart';
import 'dart:math';

class CustomAnimatedPageView extends StatefulWidget {
  const CustomAnimatedPageView({super.key});

  @override
  State<CustomAnimatedPageView> createState() =>
      _CustomAnimatedPageViewState();
}

class _CustomAnimatedPageViewState extends State<CustomAnimatedPageView>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  double _currentPage = 0.0;

  final List<Color> pageColors = [
    Colors.deepOrange,
    Colors.teal,
    Colors.indigo,
    Colors.black12,
  ];

  final List<String> pageTitles = [
    "Página Um",
    "Página Dois",
    "Página Três",
    "Página Quatro",
  ];

  // Posição inicial do botão flutuante
  double floatingTop = 300;
  double floatingLeft = 150;

  // Variáveis para arrasto
  bool isDragging = false;
  double dragStartX = 0;
  double dragStartY = 0;

  // Menu circular
  bool isMenuOpen = false;
  late AnimationController _menuAnimationController;
  late Animation<double> _menuAnimation;
  final double menuRadius = 100;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });

    _menuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _menuAnimation =
        CurvedAnimation(parent: _menuAnimationController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _menuAnimationController.dispose();
    super.dispose();
  }

  Widget _buildPageItem(int index) {
    double diff = index - _currentPage;
    double scaleFactor = (1 - (diff.abs() * 0.2)).clamp(0.8, 1.0);
    double marginFactor = (1 - (cos(diff * pi) + 1) / 2) * 50;

    return Center(
      child: Transform.scale(
        scale: scaleFactor,
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

  Widget _buildIndicator() {
    const double indicatorWidth = 10.0;
    const double spacing = 10.0;
    double leftPosition = (_currentPage * (indicatorWidth + spacing));

    return Stack(
      alignment: Alignment.center,
      children: [
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
        Positioned(
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Transform.translate(
                offset: Offset(leftPosition + 30.0, 0),
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

  void _toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
      if (isMenuOpen) {
        _menuAnimationController.forward();
      } else {
        _menuAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PageView com Menu Circular'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // PageView principal
            PageView.builder(
              controller: _pageController,
              itemCount: pageColors.length,
              itemBuilder: (context, index) => _buildPageItem(index),
            ),

            // Indicador
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: _buildIndicator(),
              ),
            ),

            // Botão flutuante
            Positioned(
              top: floatingTop,
              left: floatingLeft,
              child: GestureDetector(
                onTap: _toggleMenu,
                onLongPressStart: (details) {
                  isDragging = true;
                  dragStartX = details.globalPosition.dx - floatingLeft;
                  dragStartY = details.globalPosition.dy - floatingTop;
                },
                onLongPressMoveUpdate: (details) {
                  if (isDragging) {
                    setState(() {
                      floatingLeft =
                          (details.globalPosition.dx - dragStartX)
                              .clamp(0.0, MediaQuery.of(context).size.width - 50);
                      floatingTop =
                          (details.globalPosition.dy - dragStartY)
                              .clamp(0.0, MediaQuery.of(context).size.height - 50);
                    });
                  }
                },
                onLongPressEnd: (details) {
                  isDragging = false;
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.menu, color: Colors.white),
                ),
              ),
            ),

            // Menu circular
            ...List.generate(pageTitles.length, (index) {
              final angle = 2 * pi / pageTitles.length * index;
              return AnimatedBuilder(
                animation: _menuAnimationController,
                builder: (context, child) {
                  final offset = Offset(
                    cos(angle) * menuRadius * _menuAnimation.value,
                    sin(angle) * menuRadius * _menuAnimation.value,
                  );
                  return Positioned(
                    top: floatingTop + 25 + offset.dy,
                    left: floatingLeft + 25 + offset.dx,
                    child: Transform.scale(
                      scale: _menuAnimation.value,
                      child: GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                          _toggleMenu();
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 5,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
***************************************************************************************************
*/


/*
***************************************************************************************************
import 'package:flutter/material.dart';
import 'dart:math';

class CustomAnimatedPageView extends StatefulWidget {
  const CustomAnimatedPageView({super.key});

  @override
  State<CustomAnimatedPageView> createState() =>
      _CustomAnimatedPageViewState();
}

class _CustomAnimatedPageViewState extends State<CustomAnimatedPageView>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  double _currentPage = 0.0;

  final List<Color> pageColors = [
    Colors.deepOrange,
    Colors.teal,
    Colors.indigo,
    Colors.black12,
  ];

  final List<String> pageTitles = [
    "Página Um",
    "Página Dois",
    "Página Três",
    "Página Quatro",
  ];

  // Posição inicial do botão flutuante
  double floatingTop = 100;
  double floatingLeft = 20;

  // Variáveis para arrasto
  bool isDragging = false;
  double dragStartX = 0;
  double dragStartY = 0;

  // Controle do menu animado
  bool isMenuOpen = false;

  // Animação de escala do menu
  late AnimationController _menuAnimationController;
  late Animation<double> _menuScaleAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });

    _menuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _menuScaleAnimation =
        CurvedAnimation(parent: _menuAnimationController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _menuAnimationController.dispose();
    super.dispose();
  }

  // Construção de cada página com animação
  Widget _buildPageItem(int index) {
    double diff = index - _currentPage;
    double scaleFactor = (1 - (diff.abs() * 0.2)).clamp(0.8, 1.0);
    double marginFactor = (1 - (cos(diff * pi) + 1) / 2) * 50;

    return Center(
      child: Transform.scale(
        scale: scaleFactor,
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

  // Indicador animado
  Widget _buildIndicator() {
    const double indicatorWidth = 10.0;
    const double spacing = 10.0;
    double leftPosition = (_currentPage * (indicatorWidth + spacing));

    return Stack(
      alignment: Alignment.center,
      children: [
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
        Positioned(
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Transform.translate(
                offset: Offset(leftPosition + 30.0, 0),
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

  void _toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
      if (isMenuOpen) {
        _menuAnimationController.forward();
      } else {
        _menuAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PageView com Widget Flutuante'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // PageView principal
            PageView.builder(
              controller: _pageController,
              itemCount: pageColors.length,
              itemBuilder: (context, index) => _buildPageItem(index),
            ),

            // Indicador de página
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: _buildIndicator(),
              ),
            ),

            // Botão flutuante arrastável
            Positioned(
              top: floatingTop,
              left: floatingLeft,
              child: GestureDetector(
                onTap: _toggleMenu,
                onLongPressStart: (details) {
                  isDragging = true;
                  dragStartX = details.globalPosition.dx - floatingLeft;
                  dragStartY = details.globalPosition.dy - floatingTop;
                },
                onLongPressMoveUpdate: (details) {
                  if (isDragging) {
                    setState(() {
                      floatingLeft =
                          (details.globalPosition.dx - dragStartX)
                              .clamp(
                                  0.0, MediaQuery.of(context).size.width - 50);
                      floatingTop =
                          (details.globalPosition.dy - dragStartY)
                              .clamp(
                                  0.0, MediaQuery.of(context).size.height - 50);
                    });
                  }
                },
                onLongPressEnd: (details) {
                  isDragging = false;
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.menu, color: Colors.white),
                ),
              ),
            ),

            // Menu quadrado animado em 2x2
            Positioned(
              top: floatingTop - 80,
              left: floatingLeft - 80,
              child: ScaleTransition(
                scale: _menuScaleAnimation,
                alignment: Alignment.center,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(8),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(pageTitles.length, (index) {
                      return InkWell(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                          _toggleMenu();
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pageTitles[index],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

****************************************************************************************
*/

/*
import 'package:flutter/material.dart';
import 'dart:math';

class CustomAnimatedPageView extends StatefulWidget {
  const CustomAnimatedPageView({super.key});

  @override
  State<CustomAnimatedPageView> createState() =>
      _CustomAnimatedPageViewState();
}

class _CustomAnimatedPageViewState extends State<CustomAnimatedPageView>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  double _currentPage = 0.0;

  final List<Color> pageColors = [
    Colors.deepOrange,
    Colors.teal,
    Colors.indigo,
    Colors.black12,
  ];

  final List<String> pageTitles = [
    "Página Um",
    "Página Dois",
    "Página Três",
    "Página Quatro",
  ];

  // Posição inicial do botão flutuante
  double floatingTop = 100;
  double floatingLeft = 20;

  // Variáveis para arrasto
  bool isDragging = false;
  double dragStartX = 0;
  double dragStartY = 0;

  // Controle do menu animado
  bool isMenuOpen = false;

  // Animação de escala do menu
  late AnimationController _menuAnimationController;
  late Animation<double> _menuScaleAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });

    _menuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _menuScaleAnimation =
        CurvedAnimation(parent: _menuAnimationController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _menuAnimationController.dispose();
    super.dispose();
  }

  // Construção de cada página com animação
  Widget _buildPageItem(int index) {
    double diff = index - _currentPage;
    double scaleFactor = (1 - (diff.abs() * 0.2)).clamp(0.8, 1.0);
    double marginFactor = (1 - (cos(diff * pi) + 1) / 2) * 50;

    return Center(
      child: Transform.scale(
        scale: scaleFactor,
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

  // Indicador animado
  Widget _buildIndicator() {
    const double indicatorWidth = 10.0;
    const double spacing = 10.0;
    double leftPosition = (_currentPage * (indicatorWidth + spacing));

    return Stack(
      alignment: Alignment.center,
      children: [
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
        Positioned(
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Transform.translate(
                offset: Offset(leftPosition + 30.0, 0),
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

  void _toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
      if (isMenuOpen) {
        _menuAnimationController.forward();
      } else {
        _menuAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PageView com Widget Flutuante'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // PageView principal
            PageView.builder(
              controller: _pageController,
              itemCount: pageColors.length,
              itemBuilder: (context, index) => _buildPageItem(index),
            ),

            // Indicador de página
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: _buildIndicator(),
              ),
            ),

            // Botão flutuante arrastável
            Positioned(
              top: floatingTop,
              left: floatingLeft,
              child: GestureDetector(
                onTap: _toggleMenu,
                onLongPressStart: (details) {
                  isDragging = true;
                  dragStartX = details.globalPosition.dx - floatingLeft;
                  dragStartY = details.globalPosition.dy - floatingTop;
                },
                onLongPressMoveUpdate: (details) {
                  if (isDragging) {
                    setState(() {
                      floatingLeft =
                          (details.globalPosition.dx - dragStartX)
                              .clamp(
                                  0.0, MediaQuery.of(context).size.width - 50);
                      floatingTop =
                          (details.globalPosition.dy - dragStartY)
                              .clamp(
                                  0.0, MediaQuery.of(context).size.height - 50);
                    });
                  }
                },
                onLongPressEnd: (details) {
                  isDragging = false;
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.menu, color: Colors.white),
                ),
              ),
            ),

            // Menu animado com escala
            Positioned(
              top: floatingTop + 60,
              left: floatingLeft,
              child: ScaleTransition(
                scale: _menuScaleAnimation,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pageTitles.length, (index) {
                      return InkWell(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                          _toggleMenu();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            pageTitles[index],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/