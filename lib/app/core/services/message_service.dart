// -----------------------------------------------------------
// app/core/services/message_service.dart
// -----------------------------------------------------------
import 'package:flutter/material.dart';

class MessageService {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showSuccess(String message) {
    _showSnackBar(message, Colors.green);
  }

  static void showError(String message) {
    _showSnackBar(message, Colors.red);
  }

  static void showInfo(String message) {
    _showSnackBar(message, Colors.blue);
  }

  static void showWarning(String message) {
    _showSnackBar(message, Colors.yellow);
  }

  static void _showSnackBar(String message, Color color) {
    final textColor = color == Colors.yellow ? Colors.black : Colors.white;

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
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