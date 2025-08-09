// -----------------------------------------------------------
// app/views/splash/splash_page.dart
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:oxdata/app/core/http/api_client.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';
import 'package:oxdata/app/core/services/storage_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    
    String? token = await StorageService().readAuthToken();

    final apiClient = ApiClient();
    
    // Aguarda um pequeno delay para a UX da splash screen.
    await Future.delayed(const Duration(milliseconds: 1500));

    if (token != null) {
      apiClient.updateToken(token);
      // Navega para a tela principal, substituindo a splash screen.
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(RouteGenerator.homePage);
      }
    } else {
      // Navega para a tela de login, substituindo a splash screen.
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(RouteGenerator.loginPage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove a cor de fundo do Scaffold
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/oxford-background1.jpg',
            fit: BoxFit.cover, // Preenche a tela inteira
          ),
          
          Container(
            color: Colors.black.withAlpha(166),
          ),
          
          const Center(
            child: SpinKitWanderingCubes(
              color: Colors.white,
              size: 60.0,
            ),
          ),
        ],
      ),
    );
  }
}