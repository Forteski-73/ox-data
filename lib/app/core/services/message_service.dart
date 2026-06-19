// -----------------------------------------------------------
// app/core/services/message_service.dart
// -----------------------------------------------------------
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