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
import 'package:oxdata/app/views/pallet/search_pallet_page.dart';
import 'package:oxdata/app/views/pallet/pallet_builder_page.dart';
import 'package:oxdata/app/views/pallet/pallet_receive_page.dart';
import 'package:oxdata/app/views/inventory/inventory.dart';
import 'package:oxdata/app/core/models/pallet_model.dart';
import 'package:oxdata/app/views/load/load.dart';

class RouteGenerator {
  static const String splashPage        = '/';
  static const String loginPage         = 'loginPage';
  static const String loginReg          = 'loginReg';
  static const String homePage          = 'homePage';
  static const String productsPage      = 'productsPage';
  static const String productPage       = 'productPage';
  static const String inventoriesPage   = 'inventoriesPage';
  static const String tagsPage          = 'inventoriesPage';
  static const String palletsPage       = 'palletsPage';
  static const String palletBuilderPage = 'palletBuilderPage';
  static const String palletReceivePage = 'palletReceivePage';
  static const String TESTE             = 'CustomAnimatedPageView';

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
      case TESTE:
        return MaterialPageRoute(builder: (context) => CustomAnimatedPageView());
      case productPage: // Rota para a página de detalhes do produto
        if (args is String) {
          return MaterialPageRoute(
            builder: (context) => ProductPage(
              productId: args, // Passando o productId para o construtor da página de detalhes
            ),
          );
        }
        return _errorRoute(); // Se o argumento não for do tipo esperado, retorna uma rota de erro
      case productsPage:
        return MaterialPageRoute(builder: (context) => const SearchProductsPage());
      case inventoriesPage: // *** Futura rota para inventário ***
        return MaterialPageRoute(builder: (context) => const InventoriesPage());
      case palletsPage:
        return MaterialPageRoute(builder: (context) => const SearchPalletPage());
      case palletBuilderPage:
        if (args is PalletModel?) {
          return MaterialPageRoute(
            builder: (context) => PalletBuilderPage(
              pallet: args,
            ),
          );
        }
        return _errorRoute();
        case palletReceivePage:
          if (args is PalletModel) {
            return MaterialPageRoute(
              builder: (context) => PalletReceivePage(
                pallet: args, // A página REQUER um PalletModel
              ),
            );
          }
        return _errorRoute(); 
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