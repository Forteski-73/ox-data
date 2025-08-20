// -----------------------------------------------------------
// main.dart (Ponto de Entrada do App)
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'app/app.dart';
import 'app/core/injector/injector.dart';

void main() {
  // Garante que o Flutter está pronto para interagir com os plugins
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configura a injeção de dependências do projeto.
  // Embora esta chamada não seja estritamente necessária no
  // modelo atual com o 'MultiProvider', é uma boa prática
  // manter caso use outro método de injeção, como get_it.
  Injector.configureDependencies();
  
  // Configurações de localização
  Intl.defaultLocale = 'pt-BR';
  initializeDateFormatting('pt-BR', null);

  // Define a orientação da tela para portrait
  /*SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
    ],
  );*/

  // Inicia o aplicativo.
  // Não é mais necessário envolver o MyApp com o AuthService,
  // pois o MultiProvider no app.dart já faz isso.
  runApp(const MyApp());
}