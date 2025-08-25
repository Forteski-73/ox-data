import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/auth_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AppBarCustom({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final loadingService = context.read<LoadingService>();
    
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(
        title,
        style: const TextStyle(fontSize: 18),
      ),
      centerTitle: true,
      
      actions: [
        IconButton(
          iconSize: 20, 
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).pushNamed(RouteGenerator.homePage);
          },
        ),
        
        IconButton(
          iconSize: 20,
          icon: const Icon(Icons.logout),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: const Row(
                    children: [
                      Icon(Icons.exit_to_app_rounded, color: Colors.indigo, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Confirmação de Saída',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Deseja realmente sair do aplicativo?',
                    style: TextStyle(fontSize: 16),
                  ),
                  actions: <Widget>[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.black87)),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text(
                        'Sair',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();
                        loadingService.show();
                        await authService.logout();
                        if (context.mounted) {
                          loadingService.hide();
                          Navigator.of(context).pushReplacementNamed(RouteGenerator.loginPage);
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}