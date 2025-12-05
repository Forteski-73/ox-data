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
      'title': 'TAGS',
      'routeName': RouteGenerator.tagsPage,
      'imagePath': 'assets/images/tag.png',
    },
    {
      'title': 'PALLETS',
      'routeName': RouteGenerator.palletsPage,
      'imagePath': 'assets/images/pallet.png',
    },
    {
      'title': 'CARGAS',
      'routeName': RouteGenerator.TESTE,
      'imagePath': 'assets/images/truck.png',
    },
    {
      'title': 'INVENTÁRIOS',
      'routeName': RouteGenerator.inventoriesPage,
      'imagePath': 'assets/images/invent.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarCustom(title: 'ACEP'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
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
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}