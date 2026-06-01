import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/auth_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final PreferredSizeWidget? bottom;

  const AppBarCustom({super.key, required this.title, this.bottom});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final loadingService = context.read<LoadingService>();
    
    return AppBar(
      backgroundColor: const Color(0xFF06090F),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      
      title: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14, 
          fontWeight: FontWeight.w900,
          letterSpacing: 2.5,
          color: Colors.white,
        ),
      ),
      
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF06090F),
          border: Border(
            bottom: BorderSide(
              color: Colors.cyanAccent.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
      ),
      bottom: bottom,
      actions: [
        IconButton(
          iconSize: 22, 
          icon: const Icon(Icons.grid_view_rounded, color: Colors.white70),
          tooltip: 'Dashboard',
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(RouteGenerator.homePage, (route) => false);
          },
        ),
        const SizedBox(width: 4),
        IconButton(
          iconSize: 22,
          icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
          tooltip: 'Desconectar',
          onPressed: () => _showFuturisticLogoutDialog(context, authService, loadingService),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showFuturisticLogoutDialog(BuildContext context, AuthService authService, LoadingService loadingService) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1117),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.redAccent.withOpacity(0.3), width: 1.5),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.gpp_maybe_outlined, color: Colors.redAccent, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'TERMINAR SESSÃO',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5, color: Colors.white),
              ),
            ],
          ),
          content: const Text(
            'Deseja realmente desconectar este terminal do núcleo operacional?',
            style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
          ),
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('ABORTAR', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shadowColor: Colors.redAccent.withOpacity(0.4),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('CONFIRMAR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                loadingService.show();
                await authService.logout();
                if (context.mounted) {
                  loadingService.hide();
                  Navigator.of(context).pushReplacementNamed(RouteGenerator.loginPage);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // MUDANÇA AQUI: Cálculo inteligente e dinâmico da altura da barra
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom != null ? bottom!.preferredSize.height : 0.0), );
  
}


/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/auth_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final PreferredSizeWidget? bottom;

  const AppBarCustom({super.key, required this.title, this.bottom});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final loadingService = context.read<LoadingService>();
    
    return AppBar(
      backgroundColor: const Color(0xFF06090F), // O mesmo preto profundo do MotionTabBar
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      
      title: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14, 
          fontWeight: FontWeight.w900,
          letterSpacing: 2.5,
          color: Colors.white,
        ),
      ),
      
      // Acabamento estético de painel de controle
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF06090F),
          border: Border(
            bottom: BorderSide(
              color: Colors.cyanAccent.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
      ),
      bottom: bottom,
      actions: [
        IconButton(
          iconSize: 22, 
          icon: const Icon(Icons.grid_view_rounded, color: Colors.white70),
          tooltip: 'Dashboard',
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(RouteGenerator.homePage, (route) => false);
          },
        ),
        const SizedBox(width: 4),
        IconButton(
          iconSize: 22,
          icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
          tooltip: 'Desconectar',
          onPressed: () => _showFuturisticLogoutDialog(context, authService, loadingService),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // Caixa de diálogo sci-fi ultra harmônica com o tema dark/neon
  void _showFuturisticLogoutDialog(BuildContext context, AuthService authService, LoadingService loadingService) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1117),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.redAccent.withOpacity(0.3), width: 1.5),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.gpp_maybe_outlined, color: Colors.redAccent, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'TERMINAR SESSÃO',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5, color: Colors.white),
              ),
            ],
          ),
          content: const Text(
            'Deseja realmente desconectar este terminal do núcleo operacional?',
            style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
          ),
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('ABORTAR', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shadowColor: Colors.redAccent.withOpacity(0.4),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('CONFIRMAR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                loadingService.show();
                await authService.logout();
                if (context.mounted) {
                  loadingService.hide();
                  Navigator.of(context).pushReplacementNamed(RouteGenerator.loginPage);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  // Fornece a altura somada do AppBar + a altura exata definida para o MotionTabBar (65px)
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 65);
}

*/

/*
/* BOM */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/auth_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final PreferredSizeWidget? bottom;

  const AppBarCustom({super.key, required this.title, this.bottom});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final loadingService = context.read<LoadingService>();
    
    return AppBar(
      backgroundColor: const Color(0xFF06090F), // Preto profundo espacial
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      
      // Título estilo terminal/HUD de alta tecnologia
      title: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 15, 
          fontWeight: FontWeight.w800,
          letterSpacing: 2.5, // Espaçamento futurista de caracteres
          color: Colors.white,
        ),
      ),
      
      // Linha holográfica sutil na base do AppBar para dar profundidade
      flexibleSpace: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.cyanAccent.withOpacity(0.15),
              width: 1,
            ),
          ),
        ),
      ),
      
      bottom: bottom,
      
      actions: [
        // Botão Home Minimalista
        IconButton(
          iconSize: 22, 
          icon: const Icon(Icons.grid_view_rounded, color: Colors.white70), // Ícone mais tecnológico que o 'home' comum
          tooltip: 'Dashboard',
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              RouteGenerator.homePage, 
              (route) => false,
            );
          },
        ),
        
        const SizedBox(width: 4),
        
        // Botão Logout Futurista
        IconButton(
          iconSize: 22,
          icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent), // Vermelho cyber para alertar ação
          tooltip: 'Desconectar',
          onPressed: () {
            _showFuturisticLogoutDialog(context, authService, loadingService);
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Caixa de diálogo customizada com visual de painel de segurança tecnológica
  void _showFuturisticLogoutDialog(
    BuildContext context, 
    AuthService authService, 
    LoadingService loadingService
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8), // Escurece o fundo de forma dramática
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1117), // Fundo Dark tecnológico
          
          // Borda brilhante em Neon sutil (Harmonia total)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.redAccent.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gpp_maybe_outlined, color: Colors.redAccent, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'TERMINAR SESSÃO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          content: const Text(
            'Deseja realmente desconectar este terminal do núcleo operacional?',
            style: TextStyle(
              fontSize: 14, 
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          
          actions: <Widget>[
            // Botão Cancelar (Vazado e discreto)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text(
                'ABORTAR', 
                style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            
            // Botão Confirmar (Preenchimento Sólido Neon)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.redAccent.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'CONFIRMAR',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                loadingService.show();
                await authService.logout();
                if (context.mounted) {
                  loadingService.hide();
                  Navigator.of(context).pushReplacementNamed(RouteGenerator.loginPage);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
*/


/*
/* ORIGINAL */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oxdata/app/core/services/auth_service.dart';
import 'package:oxdata/app/core/services/loading_service.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final PreferredSizeWidget? bottom;

  const AppBarCustom({super.key, required this.title, this.bottom});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final loadingService = context.read<LoadingService>();
    
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(
        title,
        style: const TextStyle(fontSize: 18),
      ),
      centerTitle: true,
      bottom: bottom, // aqui você passa o TabBar
      actions: [
        IconButton(
          iconSize: 20, 
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(RouteGenerator.homePage, (route) => false,);
          },
        ),
        
        IconButton(
          iconSize: 20,
          icon: const Icon(Icons.logout),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: const Row(
                    children: [
                      Icon(Icons.exit_to_app_rounded, color: Colors.indigo, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Confirmação de Saída',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Deseja realmente sair do aplicativo?',
                    style: TextStyle(fontSize: 16),
                  ),
                  actions: <Widget>[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.black87)),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text(
                        'Sair',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();
                        loadingService.show();
                        await authService.logout();
                        if (context.mounted) {
                          loadingService.hide();
                          Navigator.of(context).pushReplacementNamed(RouteGenerator.loginPage);
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  //Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

*/