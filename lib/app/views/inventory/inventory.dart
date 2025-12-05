import 'package:flutter/material.dart';
import 'dart:math';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/services/load_service.dart';
import 'package:provider/provider.dart';

// Importações das novas páginas de Inventário
import 'package:oxdata/app/views/inventory/search_inventory_page.dart';
import 'package:oxdata/app/views/inventory/inventory_page.dart';
import 'package:oxdata/app/views/inventory/inventory_item_page.dart';
import 'package:oxdata/app/views/inventory/synchronide_database.dart';

import 'package:oxdata/app/core/models/inventory_item.dart';

class InventoriesPage extends StatefulWidget {
  const InventoriesPage({super.key});

  @override
  State<InventoriesPage> createState() => _CustomAnimatedPageViewState();
}

class _CustomAnimatedPageViewState extends State<InventoriesPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  double _currentPage = 0.0;
  static const int _inventoryItemPageIndex = 2;

  // 1. Títulos solicitados
  final List<String> pageTitles = [
    "Meus Inventários",
    "Inventário em Andamento",
    "Adicionar Contagem no Inventário",
    "Sincrozizar Banco de Dados"
  ];

  late InventoryItem item1 = InventoryItem(
    title: "Inventário Geral Jan/24",
    date: "15/01/2024",
    status: "FECHADO",
    records: 2,
    totalItems: 72,
  );
  
  // 'pageContents' como 'late'
  // Isso diz ao Dart para esperar e inicializar esta variável mais tarde.
  late final List<Widget> pageContents = [
    SearchInventoryPage(),
    InventoryPage(inventory: item1),
    const InventoryItemPage(),
    const SynchronizeDBPage(),
  ];

  // 3. Ícones atualizados para o novo tema de Inventário
  final List<IconData> pageIcons = [
    Icons.playlist_add_rounded,
    Icons.play_lesson_outlined,
    Icons.qr_code_scanner,
    Icons.cloud_sync,
  ];

  // 4. Cores (Mantenha o mesmo número de elementos)
  final List<Color> pageColors = [
    const Color(0xFFF3F3F3),
    const Color(0xFFF3F3F3),
    Colors.blue,
    Colors.indigo,
  ];

  double floatingTop = 100;
  double floatingLeft = 20;

  bool isDragging = false;
  double dragStartX = 0;
  double dragStartY = 0;
  bool menuOpen = false;

  late List<AnimationController> _menuControllers;
  late List<Animation<double>> _menuAnimations;
  late LoadService _loadService;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _loadService = context.read<LoadService>();
    _loadService.addListener(_pageServiceListener);

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });

    // Controladores ajustados para o novo tamanho (3 páginas)
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        // Inicializa o botão no canto inferior direito
        floatingTop = screenSize.height - 180 - 60;
        floatingLeft = screenSize.width - 30 - 60;
      });
    });
  }

  void _pageServiceListener() {
    final newIndex = _loadService.currentPageIndex;
    final currentControllerIndex = _pageController.page?.round() ?? 0;
    if (currentControllerIndex != newIndex) {
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _loadService.removeListener(_pageServiceListener);
    _pageController.dispose();
    for (var c in _menuControllers) c.dispose();
    super.dispose();
  }

  Widget _buildPageItem(int index) {
    if (index >= pageContents.length || index < 0) {
      return const Center(child: Text("Erro: Página não encontrada", style: TextStyle(color: Colors.red)));
    }
    
    double diff = index - _currentPage;
    double scaleFactor = (1 - (diff.abs() * 0.2)).clamp(0.8, 1.0);
    double marginFactor = (1 - (cos(diff * pi) + 1) / 2) * 50;
    Widget contentWidget = pageContents[index];

    return Center(
      child: Transform.scale(
        scale: scaleFactor,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(vertical: marginFactor),
          decoration: BoxDecoration(
            color: pageColors[index].withOpacity(0.8), // Cor de fundo mais transparente
            borderRadius: BorderRadius.circular(2.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: contentWidget,
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    const double indicatorWidth = 10.0;
    const double spacing = 10.0;
    // Usa pageTitles.length para o número de indicadores
    final totalWidth =
        pageTitles.length * indicatorWidth + (pageTitles.length - 1) * spacing;
    final startOffset = -totalWidth / 2 + indicatorWidth / 2;
    double leftPosition =
        startOffset + (_currentPage * (indicatorWidth + spacing));

    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pageTitles.length, (index) { // Usa pageTitles.length
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
        Transform.translate(
          offset: Offset(leftPosition, 0),
          child: Container(
            width: indicatorWidth,
            height: indicatorWidth,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  List<double> _calculateAngles(
    int itemCount,
    double buttonX,
    double buttonY,
    double screenWidth,
    double screenHeight,
  ) {
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

    const double safePadding = 16.0;
    double availableWidth = leftSide
        ? screenWidth - buttonX - safePadding
        : buttonX - safePadding;
    double availableHeight = topSide
        ? screenHeight - buttonY - safePadding
        : buttonY - safePadding;

    const double minDistance = 130;
    double radius = max(min(availableWidth, availableHeight) / 1.5,
        minDistance + itemCount * 5);

    const int baseItems = 6;
    double baseAngleRange = endAngle - startAngle;

    if (itemCount > baseItems) {
      const double minAngleBetween = pi / 10;
      double requiredRange = minAngleBetween * (itemCount - 1);
      endAngle = startAngle + max(baseAngleRange, requiredRange);
    }

    return [startAngle, endAngle, radius];
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = 60.0;

    // Obtém o índice da página atual
    final int currentPageIndex = _currentPage.round();

    // Usa pageTitles.length
    List<double> angles = _calculateAngles(
        pageTitles.length, floatingLeft, floatingTop, screenWidth, screenHeight);

    double startAngle = angles[0];
    double endAngle = angles[1];
    double radius = angles[2];

    double angleStep =
        pageTitles.length > 1 ? (endAngle - startAngle) / (pageTitles.length - 1) : 0;

    if (menuOpen) {
      for (var c in _menuControllers) {
        c.forward(from: 0);
      }
    } else {
      for (var c in _menuControllers) {
        c.reverse();
      }
    }

    // Instancia o InventoryItemPage para que possamos acessar o bottom bar
    // É seguro fazer o cast pois sabemos o que tem no índice 2
    final inventoryItemPage = pageContents[_inventoryItemPageIndex] as InventoryItemPage;

    return Scaffold(
      // 🔑 SOLUÇÃO APLICADA: Evita o redimensionamento do Scaffold quando o teclado abre
      resizeToAvoidBottomInset: false, 
      appBar: AppBarCustom(
        title: context.watch<LoadService>().selectedLoadForEdit != null
            ? 'INVENTÁRIO #${context.watch<LoadService>().selectedLoadForEdit!.loadId}'
            : 'INVENTÁRIO',
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/oxford-box-background.png',
                fit: BoxFit.cover,
              ),
            ),
            PageView.builder(
              controller: _pageController,
              itemCount: pageTitles.length, // Usa pageTitles.length
              onPageChanged: (index) {
                _loadService.setPage(index);
              },
              itemBuilder: (context, index) => _buildPageItem(index),
            ),
            
            // 🔑 NOVO: Exibição condicional do Bottom Bar da página de Inventário
            if (currentPageIndex == _inventoryItemPageIndex)
              Align(
                alignment: Alignment.bottomCenter,
                child: buildInventoryBottomBar(context), // <--- Agora funciona!
              ),
              
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: _buildIndicator(),
              ),
            ),
            
            // Floating menu items (botões de navegação)
            ...List.generate(pageTitles.length, (index) {
              // Usa pageTitles.length
              double angle = startAngle + angleStep * index;
              return AnimatedBuilder(
                animation: _menuAnimations[index],
                builder: (context, child) {
                  double scale = _menuAnimations[index].value.clamp(0.0, 1.0);
                  double itemX = floatingLeft + (radius * cos(angle)) * scale;
                  double itemY = floatingTop + (radius * sin(angle)) * scale;
                  itemX = itemX.clamp(8.0, screenWidth - buttonSize);
                  itemY = itemY.clamp(8.0, screenHeight - buttonSize);
                  return Positioned(
                    top: itemY,
                    left: itemX,
                    child: Opacity(
                      opacity: scale,
                      child: Transform.scale(
                        scale: scale,
                        child: GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                            context.read<LoadService>().setPage(index);
                            setState(() {
                              menuOpen = false;
                            });
                          },
                          child: Container(
                            width: buttonSize,
                            height: buttonSize,
                            decoration: BoxDecoration(
                              color: menuOpen
                                  ? Colors.black
                                  : Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (menuOpen
                                              ? Colors.black
                                              : Colors.black.withOpacity(0.5))
                                          .withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              pageIcons[index],
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            // Floating Action Button principal (para abrir o menu)
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
                      final safeTop = MediaQuery.of(context).padding.top;
                      final safeBottom = MediaQuery.of(context).padding.bottom;
                      const double extraPadding = 8.0;
                      floatingLeft = (details.globalPosition.dx - dragStartX)
                          .clamp(extraPadding, screenWidth - buttonSize - extraPadding);
                      floatingTop = (details.globalPosition.dy - dragStartY).clamp(
                        safeTop + extraPadding,
                        screenHeight - buttonSize - safeBottom - extraPadding,
                      );
                    });
                  }
                },
                onLongPressEnd: (details) {
                  isDragging = false;
                },
                onTap: () {
                  if (!isDragging) {
                    setState(() {
                      menuOpen = !menuOpen;
                    });
                  }
                },
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    color: menuOpen ? Colors.black : Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 30,
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