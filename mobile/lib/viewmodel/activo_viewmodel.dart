import 'package:flutter/material.dart';
import 'package:inventario_qr_app/repositories/activo_repository.dart';
import 'package:inventario_qr_app/models/activo_model.dart';
import 'package:inventario_qr_app/core/services/qr_service.dart';

class ActivoViewModel extends ChangeNotifier {
  final ActivoRepository _activoRepository = ActivoRepository();
  final QrService _qrService = QrService();

  List<ActivoModel> _activos = [];
  ActivoModel? _activoActual;
  bool _isLoading = false;
  String? _error;
  ActivoModel? _ultimoEscaneado;
  List<ActivoModel> _activosNuevos = [];
  List<ActivoModel> _activosDeBaja = [];

  // Getters
  List<ActivoModel> get activos => _activos;
  ActivoModel? get activoActual => _activoActual;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ActivoModel? get ultimoEscaneado => _ultimoEscaneado;
  List<ActivoModel> get activosNuevos => _activosNuevos;
  List<ActivoModel> get activosDeBaja => _activosDeBaja;

  Future<void> cargarActivosPorAmbiente(String ambienteId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activos = await _activoRepository.getActivosPorAmbiente(ambienteId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error cargando activos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> procesarEscaneoQr(String datosQr) async {
    try {
      final uuid = _qrService.extractUuidFromQr(datosQr);
      _activoActual = await _activoRepository.getActivoPorUuid(uuid);
      
      if (_activoActual == null) {
        _error = 'Activo no encontrado';
      } else {
        _error = null;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Error procesando QR: $e';
      notifyListeners();
    }
  }

  void limpiarActivoActual() {
    _activoActual = null;
    _error = null;
    notifyListeners();
  }

  Future<bool> actualizarEstadoActivo(String activoId, String nuevoEstado) async {
    try {
      return await _activoRepository.actualizarEstadoActivo(activoId, nuevoEstado);
    } catch (e) {
      _error = 'Error actualizando estado: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> cargarReportes() async {
    try {
      _ultimoEscaneado = await _activoRepository.getUltimoActivoEscaneado();
      _activosNuevos = await _activoRepository.getActivosNuevos();
      _activosDeBaja = await _activoRepository.getActivosDeBaja();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando reportes de activos: $e');
      notifyListeners();
    }
  }
}
