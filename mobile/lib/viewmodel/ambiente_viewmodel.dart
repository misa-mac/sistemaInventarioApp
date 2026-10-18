import 'package:flutter/material.dart';
import 'package:inventario_qr_app/repositories/ambiente_repository.dart';
import 'package:inventario_qr_app/models/ambiente_model.dart';
import 'package:inventario_qr_app/core/services/location_service.dart';

class AmbienteViewModel extends ChangeNotifier {
  final AmbienteRepository _ambienteRepository = AmbienteRepository();
  final LocationService _locationService = LocationService();

  List<AmbienteModel> _ambientes = [];
  AmbienteModel? _ambienteSeleccionado;
  bool _isLoading = false;
  String? _error;
  bool _dentroDeGeofence = false;
  double? _distanciaActual;
  double? _precisionActual;
  GeofenceCheckResult? _resultadoGeocerca;
  String? _mensajeUbicacion;

  // Getters
  List<AmbienteModel> get ambientes => _ambientes;
  AmbienteModel? get ambienteSeleccionado => _ambienteSeleccionado;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get dentroDeGeofence => _dentroDeGeofence;
  double? get distanciaActual => _distanciaActual;
  double? get precisionActual => _precisionActual;
  GeofenceCheckResult? get resultadoGeocerca => _resultadoGeocerca;
  String? get mensajeUbicacion => _mensajeUbicacion;

  Future<void> cargarAmbientes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ambientes = await _ambienteRepository.getAmbientes();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error cargando ambientes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> seleccionarAmbiente(AmbienteModel ambiente) async {
    _ambienteSeleccionado = ambiente;
    _dentroDeGeofence = false;
    _distanciaActual = null;
    _precisionActual = null;
    _resultadoGeocerca = null;
    _mensajeUbicacion = null;
    notifyListeners();

    // Verificar ubicación
    await verificarUbicacion();
  }

  Future<void> verificarUbicacion() async {
    if (_ambienteSeleccionado == null) return;

    try {
      final posicion = await _locationService.getCurrentLocation();
      
      if (posicion != null) {
        _precisionActual = posicion.accuracy;
        _distanciaActual = _locationService.calculateDistance(
          posicion.latitude,
          posicion.longitude,
          _ambienteSeleccionado!.latitude,
          _ambienteSeleccionado!.longitude,
        );
        _resultadoGeocerca = _locationService.evaluateGeofence(
          position: posicion,
          targetLat: _ambienteSeleccionado!.latitude,
          targetLon: _ambienteSeleccionado!.longitude,
          radiusMeters: _ambienteSeleccionado!.radioGeofence,
          ambienteNombre: _ambienteSeleccionado!.nombre,
        );
        _dentroDeGeofence = _resultadoGeocerca!.isInside;
        _mensajeUbicacion = _resultadoGeocerca!.message;
        _error = null;
      } else {
        _dentroDeGeofence = false;
        _error = 'Precisión GPS insuficiente (> 30m) o servicio de ubicación desactivado. Reintente en un área más despejada.';
        _mensajeUbicacion = _error;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Error verificando ubicación: $e';
      _mensajeUbicacion = _error;
      notifyListeners();
    }
  }

  void limpiarSeleccion() {
    _ambienteSeleccionado = null;
    _dentroDeGeofence = false;
    _distanciaActual = null;
    _precisionActual = null;
    _resultadoGeocerca = null;
    _mensajeUbicacion = null;
    _error = null;
    notifyListeners();
  }
}
