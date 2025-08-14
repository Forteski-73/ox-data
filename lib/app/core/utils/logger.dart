import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart'; // Importe para usar kReleaseMode

// Um filtro que mostra apenas logs de erro em produção,
// mas mostra todos os logs em debug.
class MyFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) {
      // Em modo de produção, log apenas erros e logs de nível mais alto
      return event.level == Level.error;
    }
    // Em modo de debug, log tudo
    return true;
  }
}

// Crie a única instância do logger
final logger = Logger(
  filter: MyFilter(), // Usa nosso filtro personalizado
  printer: PrettyPrinter(
    printTime: true,
    methodCount: 2, // Quantidade de métodos para exibir no log
  ),
  level: Level.debug,
);