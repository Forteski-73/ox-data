import 'package:flutter/material.dart';
import 'package:oxdata/app/core/widgets/app_bar.dart';
import 'package:oxdata/app/core/widgets/app_footer.dart';
import 'package:oxdata/app/core/widgets/buttom_card.dart';
import 'package:oxdata/app/core/models/menu_item_model.dart';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:oxdata/app/core/services/update_service.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';
import 'package:oxdata/app/core/utils/device.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:oxdata/app/core/services/inventory_service.dart';
import 'package:oxdata/db/enums/mask_field_name.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/widgets/update_dialog.dart';

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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _loadMenus() async {

    final menus = await _storage.readMenus();

    setState(() {
      _menuOptions = menus;
      _isLoading = false;
    });
  }

  Future<void> _checkForUpdate() async {
    final updateService = context.read<UpdateService>();
    final hasUpdate = await updateService.checkForUpdate();

    if (hasUpdate && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const UpdateDialog(),
      );
    }
  }

  String getRealRoute(String dbRoute) {
    switch (dbRoute) {
      case 'PRODUTO':       return RouteGenerator.productsPage;
      case 'EMBALAGEM':      return RouteGenerator.packagingPage;
      case 'PALLET':        return RouteGenerator.palletsPage;
      case 'PALETIZACAO':   return RouteGenerator.palletizingPage;
      case 'CARGA':         return RouteGenerator.loadPage;
      case 'INVENTARIO':    return RouteGenerator.inventoriesPage;
      case 'INVENTADM':     return RouteGenerator.inventoryAdmPage;
      case 'IA':            return RouteGenerator.aiPage;
      case 'FERRAMENTA':    return RouteGenerator.toolsPage;
      case 'ADMINISTRADOR': return RouteGenerator.adminPage;
      case 'KPI':           return RouteGenerator.kpiPage;
      case 'GUIA':          return RouteGenerator.guidePage;
      case 'TV':            return RouteGenerator.tvPage;
      case 'DEV':           return RouteGenerator.devPage;
      default:              return '/'; // Rota padrão caso dê ruim
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppBarCustom(title: 'ACEP'),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            'assets/images/oxford-background1.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),

          // Overlay escuro pra dar contraste ao conteúdo
          Container(
            color: Colors.white.withAlpha(180),
          ),

          // Conteúdo original da tela
          _isLoading
              ? const Center(
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

                          return ButtonCard(
                            imagePath: option.imagePath,
                            title: option.title,
                            onTap: () async {
                              final targetRoute = getRealRoute(option.routeName);
                              dynamic routeArgs;

                              // verifica se precisa rodar o setup inicial para usar o inventário
                              if (targetRoute == RouteGenerator.inventoriesPage) { 
                                final inventoryService = context.read<InventoryService>();
                                final masks = await inventoryService.getMasksByFieldName(MaskFieldName.Codigo);

                                if (masks.isNotEmpty) {
                                  routeArgs = await DeviceService.getExistingDeviceId();
                                }
                              }

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
        ],
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}