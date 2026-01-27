import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String message;

  const ConfirmDialog({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: const Row(
        children: [
          Icon(Icons.help_outline, color: Colors.blueAccent, size: 28),
          SizedBox(width: 8),
          Text(
            'Confirmação',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 16),
      ),
      actions: <Widget>[
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: const Text('Cancelar'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          child: const Text(
            'OK',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// Função auxiliar para abrir o diálogo de confirmação
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => ConfirmDialog(message: message),
  );

  return result ?? false; // Se o usuário fechar o diálogo, retorna false
}