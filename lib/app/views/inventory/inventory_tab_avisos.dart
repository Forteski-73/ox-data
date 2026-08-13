import 'package:flutter/material.dart';

/// Aba "Avisos" da InventoryAdmPage.
///
/// Por enquanto é apenas um placeholder ("Hello World") para validar
/// a troca de widgets pelo header de ícones. O conteúdo real entra
/// aqui depois.
class InventoryTabAvisos extends StatelessWidget {
  const InventoryTabAvisos({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.announcement_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Hello World - Avisos',
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