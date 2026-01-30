import 'package:flutter/material.dart';

class InventoryCountConfirm extends StatelessWidget {
  final String message;

  const InventoryCountConfirm({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      // ESTA É A LINHA QUE CENTRALIZA:
      actionsAlignment: MainAxisAlignment.center, 
      
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Aumentei um pouco o vertical
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
        textAlign: TextAlign.center, // Opcional: centraliza o texto da mensagem também
        style: const TextStyle(fontSize: 16),
      ),
      actions: <Widget>[
        // Se quiser que eles não fiquem colados, você pode envolver com um Padding 
        // ou apenas confiar no espaçamento padrão do AlertDialog
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Aumentei o horizontal para o botão ficar mais robusto
          ),
          child: const Text(
            'NÃO',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        const SizedBox(width: 8), // Pequeno espaço entre os botões
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            'SIM',
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
    builder: (dialogContext) => InventoryCountConfirm(message: message),
  );

  return result ?? false; // Se o usuário fechar o diálogo, retorna false
}