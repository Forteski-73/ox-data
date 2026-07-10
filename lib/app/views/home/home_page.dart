import 'package:flutter/material.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/widgets/app_footer.dart';
import 'package:oxdata/app/core/widgets/buttom_card.dart';
import 'package:oxdata/app/core/models/menu_item_model.dart';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';
import 'package:oxdata/app/core/utils/device.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final StorageService _storage = StorageService();

  List<MenuItemModel> _menuOptions = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadMenus();
  }

  Future<void> _loadMenus() async {

    final menus = await _storage.readMenus();

    setState(() {
      _menuOptions = menus;
      _isLoading = false;
    });
  }

  String getRealRoute(String dbRoute) {
    switch (dbRoute) {
      case 'PRODUTO':       return RouteGenerator.productsPage;
      case 'MONTAGEM':      return RouteGenerator.packagingPage;
      case 'PALLET':        return RouteGenerator.palletsPage;
      case 'PALETIZACAO':   return RouteGenerator.palletizingPage;
      case 'CARGA':         return RouteGenerator.loadPage;
      case 'INVENTARIO':    return RouteGenerator.inventoriesPage;
      case 'INVENTADM':     return RouteGenerator.inventoryAdmPage;
      case 'IA':            return RouteGenerator.aiPage;
      case 'FERRAMENTA':    return RouteGenerator.toolsPage;
      case 'ADMINISTRADOR': return RouteGenerator.adminPage;
      case 'GUIA':          return RouteGenerator.guidePage;
      default:              return '/'; // Rota padrão caso dê ruim
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: const AppBarCustom(title: 'ACEP'),
      body: _isLoading ? const Center(
          child: SpinKitThreeBounce(
            color: Colors.white,
            size: 30.0,
          ),
        )
      : Padding(
        padding: const EdgeInsets.all(16.0),

        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 2;
            if (constraints.maxWidth >= 1200) {
              crossAxisCount = 6;
            } else if (constraints.maxWidth >= 900) {
              crossAxisCount = 5;
            } else if (constraints.maxWidth >= 600) {
              crossAxisCount = 4;
            } else {
              crossAxisCount = 2;
            }

            return GridView.builder(
              padding: const EdgeInsets.all(8.0),

              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.2,
              ),

              itemCount: _menuOptions.length,

              itemBuilder: (context, index) {

                final option = _menuOptions[index];

                /*
                return ButtonCard(
                  imagePath: option.imagePath,
                  title: option.title,
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      getRealRoute(option.routeName),
                    );
                  },
                  
                );
                */
                return ButtonCard(
                  imagePath: option.imagePath,
                  title: option.title,
                  onTap: () async { // clique assíncrono
                    final targetRoute = getRealRoute(option.routeName);
                    dynamic routeArgs;

                    // Se a rota clicada for a de inventários, busca o GUID do dispositivo
                    if (targetRoute == RouteGenerator.inventoriesPage) {
                      routeArgs = await DeviceService.getExistingDeviceId();
                    }

                    // Garante que o contexto ainda é válido após o 'await' do DeviceId
                    if (context.mounted) {
                      Navigator.of(context).pushNamed(
                        targetRoute,
                        arguments: routeArgs,
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),

      bottomNavigationBar: const AppFooter(),
    );
  }
}