import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ButtonsTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<AppleTabItem> tabs;

  const ButtonsTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  /// Identifica em qual aba o dedo está posicionado e troca a tab se necessário
  void _handleGesture(Offset localPosition, double totalWidth, int tabCount) {
    if (totalWidth <= 0) return;
    
    // Calcula a largura exata de cada aba
    final double tabWidth = totalWidth / tabCount;

    // Calcula em qual índice o dedo está atualmente baseado na posição X
    final int targetIndex = (localPosition.dx / tabWidth).floor().clamp(0, tabCount - 1);

    // Só altera e vibra se a aba sob o dedo for diferente da aba atual
    if (controller.index != targetIndex) {
      HapticFeedback.selectionClick();
      controller.animateTo(
        targetIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

@override
  Widget build(BuildContext context) {
    // Definindo o raio apenas nos cantos superiores
    const topOnlyRadius = BorderRadius.vertical(top: Radius.circular(8));

    return Padding(
      padding: const EdgeInsets.all(0),
      child: ClipRRect(
        borderRadius: topOnlyRadius, // Cantos inferiores = 0
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 48,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22).withValues(alpha: 0.5),
              borderRadius: topOnlyRadius, // Cantos inferiores = 0
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: AnimatedBuilder(
              animation: controller.animation ?? controller,
              builder: (context, child) {
                final double animValue = controller.animation?.value ?? controller.index.toDouble();
                final int tabCount = tabs.length;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final double tabWidth = constraints.maxWidth / tabCount;
                    final double indicatorLeft = animValue * tabWidth;

                    return GestureDetector(
                      onTapDown: (details) => _handleGesture(
                        details.localPosition,
                        constraints.maxWidth,
                        tabCount,
                      ),
                      onHorizontalDragStart: (details) => _handleGesture(
                        details.localPosition,
                        constraints.maxWidth,
                        tabCount,
                      ),
                      onHorizontalDragUpdate: (details) => _handleGesture(
                        details.localPosition,
                        constraints.maxWidth,
                        tabCount,
                      ),
                      behavior: HitTestBehavior.opaque,
                      child: Stack(
                        children: [
                          // 1. CÁPSULA FLUTUANTE DE SELEÇÃO
                          Positioned(
                            left: indicatorLeft,
                            top: 0,
                            bottom: 0,
                            width: tabWidth,
                            child: Container(
                              margin: const EdgeInsets.only(top: 2, left: 2, right: 2, bottom: 0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.cyanAccent.withValues(alpha: 0.25),
                                    Colors.cyanAccent.withValues(alpha: 0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.cyanAccent.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 2. BOTÕES/ITENS DAS TABS
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Row(
                                children: List.generate(tabCount, (index) {
                                  final double distance = (animValue - index).abs().clamp(0.0, 1.0);
                                  final double selectFactor = 1.0 - distance;

                                  final Color iconColor = Color.lerp(
                                    Colors.white60,
                                    Colors.white,
                                    selectFactor,
                                  )!;

                                  final Color textColor = Color.lerp(
                                    Colors.white60,
                                    Colors.white,
                                    selectFactor,
                                  )!;

                                  final double scale = 0.95 + (0.05 * selectFactor);

                                  return Expanded(
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: Transform.scale(
                                        scale: scale,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              tabs[index].icon,
                                              size: 18,
                                              color: iconColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              tabs[index].label.toUpperCase(),
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 14,
                                                fontWeight: selectFactor > 0.5
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class AppleTabItem {
  final String label;
  final IconData icon;

  const AppleTabItem({required this.label, required this.icon});
}