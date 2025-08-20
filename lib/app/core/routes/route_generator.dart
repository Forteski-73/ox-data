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

class RouteGenerator {
  static const String splashPage      = '/';
  static const String loginPage       = 'loginPage';
  static const String loginReg        = 'loginReg';
  static const String homePage        = 'homePage';
  static const String productsPage    = 'productsPage';
  static const String productPage     = 'productPage';
  static const String inventoriesPage = 'inventoriesPage';
  static const String tagsPage        = 'inventoriesPage';


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
        if (args is String) {
          return MaterialPageRoute(
            builder: (context) => ProductPage(
              productId: args, // Passando o productId para o construtor da página de detalhes
            ),
          );
        }
        return _errorRoute(); // Se o argumento não for do tipo esperado, retorna uma rota de erro

      case inventoriesPage: // *** Futura rota para inventário ***
        return MaterialPageRoute(builder: (context) => const HomePage());
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