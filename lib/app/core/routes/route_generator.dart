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
import 'package:oxdata/app/views/palletizing/pallet_group.dart';
import 'package:oxdata/app/views/inventory/inventory.dart';
import 'package:oxdata/app/views/inventory/inventory_adm_page.dart';
import 'package:oxdata/app/views/assembly/assembly_guide.dart';
import 'package:oxdata/app/views/admin/AdminPage.dart';
import 'package:oxdata/app/views/ai/AIPage.dart';
import 'package:oxdata/app/views/developer/dev_page.dart';
import 'package:oxdata/app/views/tools/tools_page.dart';
import 'package:oxdata/app/views/guide/guide_page.dart';
import 'package:oxdata/app/views/setup/setup_inventory.dart';
import 'package:oxdata/app/views/setup/setup_initial.dart';
import 'package:oxdata/app/views/load/load.dart';
import 'package:oxdata/app/views/assembly/tv-popup.dart';
import 'package:oxdata/app/core/models/pallet_model.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/app/core/repositories/admin_repository.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/utils/device.dart';

class RouteGenerator {
  static const String splashPage         = '/';
  static const String loginPage          = 'loginPage';
  static const String loginReg           = 'loginReg';
  static const String homePage           = 'homePage';
  static const String productsPage       = 'productsPage';
  static const String productPage        = 'productPage';
  static const String inventoriesPage    = 'inventoriesPage';
  static const String inventoryAdmPage   = 'inventoryAdmPage';
  static const String packagingPage      = 'packagingPage';
  static const String palletsPage        = 'palletsPage';
  static const String palletizingPage    = 'palletizingPage';
  static const String palletBuilderPage  = 'palletBuilderPage';
  static const String palletReceivePage  = 'palletReceivePage';
  static const String loadPage           = 'CustomAnimatedPageView';
  static const String adminPage          = 'adminPage';
  static const String aiPage             = 'aiPage';
  static const String toolsPage          = 'toolsPage';
  static const String guidePage          = 'guidePage';
  static const String setupPage          = 'setupPage';
  static const String setupInitPage      = 'setupInitPage';
  static const String tvPage             = 'tvPage';
  static const String devPage            = 'devPage';

  static Route<dynamic> controller(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case splashPage:
        return MaterialPageRoute(builder: (context) => const SplashPage());
      case loginPage:
        return MaterialPageRoute(builder: (context) => const LoginPage());
      case loginReg:
        return MaterialPageRoute(builder: (context) => const RegistrationPage(), settings: settings);
      case homePage:
        return MaterialPageRoute(builder: (context) => const HomePage());
      case productsPage:
        return MaterialPageRoute(builder: (context) => const SearchProductsPage());
      case packagingPage:
        return MaterialPageRoute(builder: (context) => const AssemblyGuidePage());
      case adminPage:
        return MaterialPageRoute(builder: (context) => const AdminPage());
      case aiPage:
        return MaterialPageRoute(builder: (context) => const AIPage());
      case toolsPage:
        return MaterialPageRoute(builder: (context) => const ToolsPage());
      case loadPage:
        return MaterialPageRoute(builder: (context) => CustomAnimatedPageView());
      case tvPage:
        return MaterialPageRoute(builder: (context) => FullScreenTvPopup());
      case productPage: 
        if (args is String) {
          return MaterialPageRoute(
            builder: (context) => ProductPage(
              productId: args, 
            ),
          );
        }
        return _errorRoute(); 

      /* ---------------------- SINCRONIZA ANTES DE CHAMAR A PÁGINA DE ESQUEMA DE PALETIZAÇÃO ----------------------- */
      case palletizingPage:
        //final deviceId = settings.arguments as String?;
          
        return MaterialPageRoute(builder: (context) => const PalletGroupPage());

        //return MaterialPageRoute(builder: (_) => const PalletizingPage(), );
 
      /* ------------------------------------------------------------------------------------------- */
        
      /* ---------------------- AQUI SINCRONIZA ANTES DE CHAMAR A PÁGINA ----------------------- */
      case inventoriesPage:
        final deviceId = settings.arguments as String?;

        if (deviceId != null && deviceId.isNotEmpty) {
          return MaterialPageRoute(
            builder: (_) => const InventoriesPage(),
          );
        }

        return MaterialPageRoute(
          builder: (_) => const _SetupStateRedirector(),
        );
      /* ------------------------------------------------------------------------------------------- */

      case inventoryAdmPage:
        return MaterialPageRoute(builder: (context) => const InventoryAdmPage());
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
              pallet: args, 
            ),
          );
        }
        return _errorRoute(); 
      case guidePage:
        return MaterialPageRoute(builder: (context) => const GuidePage());
        case setupInitPage:
          final fromLogin = args is bool && args == true;

          return MaterialPageRoute(
            builder: (context) => SetupInitPage(
              inventoryService: context.read<InventoryService>(),
              adminRepository: context.read<AdminRepository>(),
              onFinished: fromLogin
                  ? () => Navigator.of(context).pushNamedAndRemoveUntil(
                        RouteGenerator.homePage,
                        (route) => false,
                      )
                  : null,
            ),
          );
      case setupPage:
        return MaterialPageRoute(
          builder: (context) => SetupPage(
            inventoryService: context.read<InventoryService>(),
            adminRepository: context.read<AdminRepository>(),
          ),
        );
      case devPage:
        return MaterialPageRoute(builder: (context) => DevPage());
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

// -----------------------------------------------------------
// WIDGET AUXILIAR DE REDIRECIONAMENTO (Totalmente Invisível)
// -----------------------------------------------------------
class _SetupStateRedirector extends StatefulWidget {
  const _SetupStateRedirector();

  @override
  State<_SetupStateRedirector> createState() => _SetupStateRedirectorState();
}

class _SetupStateRedirectorState extends State<_SetupStateRedirector> {
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await Navigator.of(context).pushNamed(RouteGenerator.setupPage);

      if (!mounted) return;

      final currentDeviceId = await DeviceService.getDeviceId();

      if (currentDeviceId != null && currentDeviceId.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const InventoriesPage()),
        );
      } else {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}