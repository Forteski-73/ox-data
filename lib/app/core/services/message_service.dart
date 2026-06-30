// -----------------------------------------------------------
// app/core/services/message_service.dart
// -----------------------------------------------------------
/*
import 'package:flutter/material.dart';

class MessageService {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showSuccess(String message, { Duration duration = const Duration(seconds: 3),}) {
    _showSnackBar(message, Colors.green, duration);
  }

  static void showError(String message, { Duration duration = const Duration(seconds: 3),}) {
    _showSnackBar(message, Colors.red, duration);
  }

  static void showInfo(String message, { Duration duration = const Duration(seconds: 3),}) {
    _showSnackBar(message, Colors.blue, duration);
  }

  static void showWarning(String message, { Duration duration = const Duration(seconds: 3),}) {
    _showSnackBar(message, Colors.yellow, duration);
  }

 static void _showSnackBar(String message, Color color, Duration duration) {
    final textColor = color == Colors.yellow ? Colors.black : Colors.white;

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0), 
        content: Row(
          children: [
            Expanded(
              child: Text(
                message,
                // Usa a cor da fonte definida na condição
                style: TextStyle(fontSize: 18, color: textColor),
              ),
            ),
            GestureDetector(
              onTap: () => messengerKey.currentState?.hideCurrentSnackBar(),
              child: Icon(
                Icons.close,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/

// app/core/services/message_service.dart

import 'package:flutter/material.dart';

enum _ToastType { success, error, warning, info }

class MessageService {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showSuccess(String message, {Duration duration = const Duration(seconds: 3)}) =>
      _show(message, _ToastType.success, duration);

  static void showError(String message, {Duration duration = const Duration(seconds: 4)}) =>
      _show(message, _ToastType.error, duration);

  static void showWarning(String message, {Duration duration = const Duration(seconds: 3)}) =>
      _show(message, _ToastType.warning, duration);

  static void showInfo(String message, {Duration duration = const Duration(seconds: 3)}) =>
      _show(message, _ToastType.info, duration);

  // ─────────────────────────────────────────────

  static void _show(String message, _ToastType type, Duration duration) {
    messengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(4, 0, 4, 24),
          content: _ToastWidget(message: message, type: type, duration: duration),
        ),
      );
  }
}

// ─────────────────────────────────────────────────────────────
// Widget interno do toast
// ─────────────────────────────────────────────────────────────

class _ToastWidget extends StatefulWidget {
  final String message;
  final _ToastType type;
  final Duration duration;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _barController;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _toastConfig(widget.type);

    return Container(
      decoration: BoxDecoration(
        color: cfg.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cfg.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Row(
              children: [
                // Ícone
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cfg.iconBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(cfg.icon, color: cfg.iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                // Mensagem
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: cfg.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Fechar
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.close_rounded, color: cfg.textColor, size: 16),
                  ),
                ),
              ],
            ),
          ),
          // Barra de progresso
          AnimatedBuilder(
            animation: _barController,
            builder: (_, __) => Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 3,
                width: MediaQuery.of(context).size.width * (1 - _barController.value),
                decoration: BoxDecoration(
                  color: cfg.barColor,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Configuração por tipo
// ─────────────────────────────────────────────────────────────

class _ToastConfig {
  final Color background;
  final Color border;
  final Color iconBackground;
  final Color iconColor;
  final Color textColor;
  final Color barColor;
  final IconData icon;

  const _ToastConfig({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.iconColor,
    required this.textColor,
    required this.barColor,
    required this.icon,
  });
}

_ToastConfig _toastConfig(_ToastType type) {
  switch (type) {
    case _ToastType.success:
      return _ToastConfig(
        background: const Color(0xFFEAF3DE),
        border:     const Color(0xFFC0DD97),
        iconBackground: const Color(0xFFC0DD97),
        iconColor:  const Color(0xFF3B6D11),
        textColor:  const Color(0xFF27500A),
        barColor:   const Color(0xFF639922),
        icon: Icons.check_rounded,
      );
    case _ToastType.error:
      return _ToastConfig(
        background: const Color(0xFFFCEBEB),
        border:     const Color(0xFFF7C1C1),
        iconBackground: const Color(0xFFF7C1C1),
        iconColor:  const Color(0xFFA32D2D),
        textColor:  const Color(0xFF501313),
        barColor:   const Color(0xFFE24B4A),
        icon: Icons.error_outline_rounded,
      );
    case _ToastType.warning:
      return _ToastConfig(
        background: const Color(0xFFFAEEDA),
        border:     const Color(0xFFFAC775),
        iconBackground: const Color(0xFFFAC775),
        iconColor:  const Color(0xFF854F0B),
        textColor:  const Color(0xFF412402),
        barColor:   const Color(0xFFBA7517),
        icon: Icons.warning_amber_rounded,
      );
    case _ToastType.info:
      return _ToastConfig(
        background: const Color(0xFFE6F1FB),
        border:     const Color(0xFFB5D4F4),
        iconBackground: const Color(0xFFB5D4F4),
        iconColor:  const Color(0xFF185FA5),
        textColor:  const Color(0xFF042C53),
        barColor:   const Color(0xFF378ADD),
        icon: Icons.info_outline_rounded,
      );
  }
}