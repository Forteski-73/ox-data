// -----------------------------------------------------------
// app/app.dart (Widget Principal do Aplicativo)
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oxdata/app/core/widgets/loading_overlay.dart';
import 'package:oxdata/app/core/routes/route_generator.dart';
import 'package:oxdata/app/core/injector/injector.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: Injector.providers,
      child: MaterialApp(
        title: 'OxData App',
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
              foregroundColor: MaterialStateProperty.all(const Color(0xFF333333)),
              overlayColor: MaterialStateProperty.resolveWith(
                (states) {
                  if (states.contains(MaterialState.pressed) || states.contains(MaterialState.focused)) {
                    return Colors.grey.withOpacity(0.2);
                  }
                  return Colors.transparent;
                },
              ),
            ),
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const Color(0xFF333333);
              }
              return Colors.white;
            }),
            checkColor: MaterialStateProperty.all(Colors.white),
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
            filled: true, // Habilita a pintura do background
            fillColor: Colors.grey.shade200, // Cor cinza clara para o background
            border: InputBorder.none, // Remove a borda padrão
            enabledBorder: InputBorder.none, // Remove a borda quando habilitado
            focusedBorder: InputBorder.none, // Remove a borda quando focado
          ),
          /*
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: const TextStyle(color: Colors.black), // Define a cor do rótulo como preto
            floatingLabelStyle: const TextStyle(color: Colors.blueAccent), // Define a cor do rótulo flutuante
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: Color(0xFF555555)), // Cor da borda padrão
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: Color(0xFF555555)), // Cor da borda quando habilitado
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: Color(0xFF555555)), // Cor da borda quando focado
            ),
          ),
          */
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
