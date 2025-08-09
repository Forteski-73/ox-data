// -----------------------------------------------------------
// app/core/routes/route_generator.dart
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:oxdata/app/views/home/home_page.dart';
import 'package:oxdata/app/views/login/login_page.dart';
import 'package:oxdata/app/views/login/registration_page.dart';
import 'package:oxdata/app/views/pages/splash_page.dart';
import 'package:oxdata/app/views/product/search_products_page.dart';
import 'package:oxdata/app/views/product/product_page.dart';

// Importe as outras páginas necessárias
// import 'package:oxdata/app/pages/collect_page.dart';
// import 'package:oxdata/app/pages/expedir_page.dart';
// ... e assim por diante.

class RouteGenerator {
  static const String splashPage = '/';
  static const String loginPage = 'loginPage';
  static const String loginReg = 'loginReg';
  static const String homePage = 'homePage';
  static const String productsPage = 'productsPage';
  static const String productPage = 'productPage';
  static const String inventoriesPage = 'inventoriesPage';

  // ... adicionar as demais rotas aqui.

  static Route<dynamic> controller(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case splashPage:
        return MaterialPageRoute(builder: (context) => const SplashPage());
      case loginPage:
        return MaterialPageRoute(builder: (context) => const LoginPage());
      case loginReg:
        return MaterialPageRoute(builder: (context) => const RegistrationPage());
      case homePage:
        return MaterialPageRoute(builder: (context) => const HomePage());
      case productsPage:
        return MaterialPageRoute(builder: (context) => const SearchProductsPage());
      case productPage: // Rota para a página de detalhes do produto
        // Verifica se o argumento é do tipo esperado (String para productId)
        if (args is String) {
          return MaterialPageRoute(
            builder: (context) => ProductPage(
              productId: args, // Passando o productId para o construtor da página de detalhes
            ),
          );
        }
        return _errorRoute(); // Se o argumento não for do tipo esperado, retorna uma rota de erro

      case inventoriesPage:
        return MaterialPageRoute(builder: (context) => const HomePage());
      // ... adicione os demais casos aqui
      // case collectPage:
      //   return MaterialPageRoute(builder: (context) => const CollectPage());
      // case collectDetailPage:
      //   return MaterialPageRoute(
      //     builder: (context) => CollectDetailPage(
      //       args: args as ResumoModel,
      //     ),
      //   );
      default:
        throw Exception('A rota ${settings.name} não existe!');
    }
  }
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: const Center(
          child: Text('Erro: Rota não encontrada ou argumento inválido!'),
        ),
      );
    });
  }
}