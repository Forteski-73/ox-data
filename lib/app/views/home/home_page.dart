import 'package:flutter/material.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/widgets/app_footer.dart';
import 'package:oxdata/app/core/widgets/buttom_card.dart';
import 'package:oxdata/app/core/models/menu_item_model.dart';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';

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
      case 'CARGA':         return RouteGenerator.loadPage;
      case 'INVENTARIO':    return RouteGenerator.inventoriesPage;
      case 'INVENTADM':     return RouteGenerator.inventoryAdmPage;
      case 'IA':            return RouteGenerator.aiPage;
      case 'FERRAMENTA':    return RouteGenerator.toolsPage;
      case 'ADMINISTRADOR': return RouteGenerator.adminPage;
      default:              return '/'; // Rota padrão caso dê ruim
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: const AppBarCustom(title: 'ACEP'),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
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

                      return ButtonCard(
                        imagePath: option.imagePath,
                        title: option.title,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            getRealRoute(option.routeName),
                          );
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


/*
import 'package:flutter/material.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/widgets/app_footer.dart';
import 'package:oxdata/app/core/widgets/buttom_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> _menuOptions = const [
    {
      'title': 'PRODUTOS',
      'routeName': RouteGenerator.productsPage,
      'imagePath': 'assets/images/product.png',
    },
    {
      'title': 'MONTAGEM',
      'routeName': RouteGenerator.packagingPage,
      'imagePath': 'assets/images/packaging.png',
    },
    {
      'title': 'PALLETS',
      'routeName': RouteGenerator.palletsPage,
      'imagePath': 'assets/images/pallet.png',
    },
    {
      'title': 'CARGAS',
      'routeName': RouteGenerator.loadPage,
      'imagePath': 'assets/images/truck.png',
    },
    {
      'title': 'INVENTÁRIOS',
      'routeName': RouteGenerator.inventoriesPage,
      'imagePath': 'assets/images/invent.png',
    },
    {
      'title': 'IA',
      'routeName': RouteGenerator.aiPage,
      'imagePath': 'assets/images/object.png',
    },
    {
      'title': 'ADMINISTRADOR',
      'routeName': RouteGenerator.adminPage,
      'imagePath': 'assets/images/admin.png',
    },
    {
      'title': 'FERRAMENTAS',
      'routeName': RouteGenerator.toolsPage,
      'imagePath': 'assets/images/tools.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarCustom(title: 'ACEP'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {

            int crossAxisCount = 2;
            if (constraints.maxWidth >= 1200) {
              crossAxisCount = 6; // Desktop grande
            } else if (constraints.maxWidth >= 900) {
              crossAxisCount = 5; // Desktop/tablet grande
            } else if (constraints.maxWidth >= 600) {
              crossAxisCount = 4; // Tablet
            } else {
              crossAxisCount = 2; // Celular
            }

            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.2,
              ),
              itemCount: _menuOptions.length,
              itemBuilder: (context, index) {
                final option = _menuOptions[index];
                return ButtonCard(
                  imagePath: option['imagePath'] as String?,
                  icon: option['icon'] as IconData?,
                  title: option['title'] as String,
                  onTap: () {
                    Navigator.of(context).pushNamed(option['routeName'] as String);
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
  
  */