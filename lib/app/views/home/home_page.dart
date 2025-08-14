// -----------------------------------------------------------
// app/views/home/home_page.dart (Tela Principal)
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/auth_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/widgets/app_footer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Lista de opções de menu que serão construídas
  final List<Map<String, dynamic>> _menuOptions = const [
    {
      'title': 'PRODUTOS',
      'routeName': RouteGenerator.productsPage,
      'imagePath': 'assets/images/product.png',
    },
    {
      'title': 'INVENTÁRIOS',
      'routeName': RouteGenerator.inventoriesPage,
      'imagePath': 'assets/images/invent.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final loadingService = context.read<LoadingService>();
    
    return Scaffold(
      appBar: const AppBarCustom(title: 'ACEP'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Botões de menu em um GridView para um layout organizado e visualmente atraente
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 colunas
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 1.2, // Proporção para botões retangulares
                ),
                itemCount: _menuOptions.length,
                itemBuilder: (context, index) {
                  final option = _menuOptions[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        // Navega para a rota especificada na opção de menu
                        Navigator.of(context).pushNamed(option['routeName'] as String);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Renderiza uma imagem se o imagePath existir, caso contrário, um ícone
                          if (option['imagePath'] != null)
                            Image.asset(
                              option['imagePath'] as String,
                              width: 60, // Aumentado para 60
                              height: 60, // Aumentado para 60
                            )
                          else
                            Icon(
                              option['icon'] as IconData,
                              size: 60,
                              color: Colors.black87,
                            ),
                          const SizedBox(height: 12),
                          Text(
                            option['title'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}