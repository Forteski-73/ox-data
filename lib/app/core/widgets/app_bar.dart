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
      
      title: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
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
        const SizedBox(width: 3),
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
            'Deseja realmente desconectar este terminal?',
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