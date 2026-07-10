// -----------------------------------------------------------
// app/core/services/device_service.dart
// -----------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:oxdata/app/core/models/tv_device_model.dart';
import 'package:oxdata/app/core/repositories/device_repository.dart';

/// Service responsável por expor os dados de TV Devices para a UI,
/// consumindo o DeviceRepository (que fala com o DeviceController da API).
class DeviceService with ChangeNotifier {
  final DeviceRepository _deviceRepository;

  DeviceService({required DeviceRepository deviceRepository})
      : _deviceRepository = deviceRepository;

  List<TvDeviceModel> _tvDevices = [];
  List<TvDeviceModel> get tvDevices => _tvDevices;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Busca todos os devices vinculados a um setor específico.
  /// Ex.: DeviceService.fetchTvDevicesBySetor('EMBALAGEM')
  Future<void> fetchTvDevicesBySetor(String setor) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _deviceRepository.getTvDevicesBySetor(setor);

    if (response.success && response.data != null) {
      _tvDevices = response.data!;
    } else {
      _tvDevices = [];
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Busca todos os devices, sem filtro de setor.
  Future<void> fetchAllTvDevices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _deviceRepository.getAllTvDevices();

    if (response.success && response.data != null) {
      _tvDevices = response.data!;
    } else {
      _tvDevices = [];
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _tvDevices = [];
    _errorMessage = null;
    notifyListeners();
  }


  /// Envia um transCode para uma TV específica, atualizando o registro
  /// e notificando os listeners com o resultado.
  ///
  /// Retorna true/false indicando sucesso, e mantém _errorMessage
  /// preenchido em caso de falha para a UI poder exibir feedback.
  Future<bool> sendTransCode({
    required int deviceId,
    required String setor,
    required String transCode,
  }) async {
    _errorMessage = null;
    notifyListeners();

    final response = await _deviceRepository.sendTransCode(
      deviceId: deviceId,
      setor: setor,
      transCode: transCode,
    );

    if (response.success && response.data != null) {
      // Atualiza o device correspondente na lista local, se existir,
      // para refletir o novo transCode sem precisar recarregar tudo.
      final index = _tvDevices.indexWhere((d) => d.deviceId == deviceId);
      if (index != -1) {
        _tvDevices[index] = response.data!;
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  /// Busca um TV Device pelo deviceId.
  ///
  /// Retorna o objeto encontrado ou null em caso de erro.
  Future<TvDeviceModel?> getTvDevice(int deviceId) async {
    _errorMessage = null;
    notifyListeners();

    final response = await _deviceRepository.getTvDevice(deviceId);

    if (response.success && response.data != null) {
      return response.data!;
    }

    _errorMessage = response.message;
    notifyListeners();
    return null;
  }

}