// -----------------------------------------------------------
// app/app.dart (Widget Principal do Aplicativo)
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oxdata/app/core/widgets/loading_overlay.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';
import 'package:oxdata/app/core/injector/injector.dart';
import 'package:oxdata/app/core/services/message_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: Injector.providers,
      child: MaterialApp(
        scaffoldMessengerKey: MessageService.messengerKey,
        title: 'ACEP',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF333333),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(const Color(0xFF333333)),
              overlayColor: WidgetStateProperty.resolveWith(
                (states) {
                  if (states.contains(WidgetState.pressed) || states.contains(WidgetState.focused)) {
                    return Colors.grey.withAlpha(51);
                  }
                  return Colors.transparent;
                },
              ),
            ),
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF333333);
              }
              return Colors.white;
            }),
            checkColor: WidgetStateProperty.all(Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Tema para o BottomNavigationBar
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: Colors.black87,
            unselectedItemColor: Colors.black54,
          ),
          // Tema para campo texto
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: const TextStyle(color: Colors.black),
            floatingLabelStyle: const TextStyle(color: Colors.black),
            filled: true,                       // Habilita a pintura do background
            fillColor: Colors.grey.shade200,  // Cor cinza clara para o background
            border: InputBorder.none,           // Remove a borda padrão
            enabledBorder: InputBorder.none,    // Remove a borda quando habilitado
            focusedBorder: InputBorder.none,    // Remove a borda quando focado
          ),

          // Remove o "risco" (divider) globalmente
          dividerTheme: const DividerThemeData(
            color: Colors.transparent, // deixa invisível
            thickness: 0,              // espessura zero
            space: 0,                  // sem espaçamento
          ),

          // Configuração global para ExpansionTile
          expansionTileTheme: const ExpansionTileThemeData(
            collapsedShape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.transparent, width: 0), // sem borda colapsado
            ),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.transparent, width: 0), // sem borda expandido
            ),
            backgroundColor: Colors.white, // cor padrão fundo
            collapsedBackgroundColor: Colors.white,
            tilePadding: EdgeInsets.symmetric(horizontal: 16.0),
            childrenPadding: EdgeInsets.zero,
            iconColor: Colors.blueGrey,        // cor do ícone expandido
            collapsedIconColor: Colors.indigo, // cor do ícone colapsado
          ),

        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR')],
        initialRoute: RouteGenerator.splashPage,
        onGenerateRoute: RouteGenerator.controller,
        builder: (context, child) {
          return LoadingOverlay(child: child!);
        },
      ),
    );
  }
}
