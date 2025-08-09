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
        style: const TextStyle(fontSize: 16),
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
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirmação'),
                  content: const Text('Deseja realmente sair do aplicativo?'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('Sair'),
                      onPressed: () async {
                        Navigator.of(context).pop();
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