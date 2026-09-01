// -----------------------------------------------------------
// app/core/services/kpi_service.dart
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:oxdata/app/core/models/dto/kpi_completude_model.dart';
import 'package:oxdata/app/core/repositories/kpi_repository.dart';

/// Service responsável por expor os dados de KPIs para a UI,
/// consumindo o KpiRepository (que fala com o KpiController da API).
class KpiService with ChangeNotifier {
  final KpiRepository _kpiRepository;

  KpiService({required KpiRepository kpiRepository})
      : _kpiRepository = kpiRepository;

  KpiCompletudeModel? _completude;
  KpiCompletudeModel? get completude => _completude;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Busca os indicadores de completude de imagens dos produtos.
  Future<void> fetchCompletude() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _kpiRepository.getCompletude();

    if (response.success && response.data != null) {
      _completude = response.data;
    } else {
      _completude = null;
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }
}
