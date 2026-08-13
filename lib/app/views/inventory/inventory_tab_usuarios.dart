import 'package:flutter/material.dart';

/// Aba "Usuários" da InventoryAdmPage.
///
/// Por enquanto é apenas um placeholder ("Hello World") para validar
/// a troca de widgets pelo header de ícones. O conteúdo real entra
/// aqui depois.
class InventoryTabUsuarios extends StatelessWidget {
  const InventoryTabUsuarios({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Hello World - Usuários',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}