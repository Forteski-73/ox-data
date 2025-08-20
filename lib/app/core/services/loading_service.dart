// -----------------------------------------------------------
// app/core/services/loading_service.dart
// -----------------------------------------------------------
import 'package:flutter/material.dart';

// Serviço que gerencia o estado global de carregamento.
// Estende ChangeNotifier para que os widgets possam "escutar" as mudanças no estado de carregamento e reagir a elas.
class LoadingService with ChangeNotifier {
  bool _isLoading = false;

  // Estado atual de carregamento
  bool get isLoading => _isLoading;

  // Mostra o overlay de carregamento.
  void show() {
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }
  }

  // Esconde o overlay de carregamento.
  void hide() {
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
    }
  }
  
}
