// -----------------------------------------------------------
// app/core/services/loading_service.dart
// -----------------------------------------------------------
import 'package:flutter/material.dart';

// Este serviço gerencia o estado global de carregamento.
// Ele estende ChangeNotifier para que os widgets possam "escutar"
// as mudanças no estado de carregamento e reagir a elas.
class LoadingService with ChangeNotifier {
  bool _isLoading = false;

  // Retorna o estado atual de carregamento
  bool get isLoading => _isLoading;

  // Mostra o overlay de carregamento.
  void show() {
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners(); // Notifica os widgets que estão escutando
    }
  }

  // Esconde o overlay de carregamento.
  void hide() {
    if (_isLoading) {
      _isLoading = false;
      notifyListeners(); // Notifica os widgets que estão escutando
    }
  }
}
