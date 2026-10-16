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

  // Getters
  List<AmbienteModel> get ambientes => _ambientes;
  AmbienteModel? get ambienteSeleccionado => _ambienteSeleccionado;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get dentroDeGeofence => _dentroDeGeofence;

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
    notifyListeners();

    // Verificar ubicación
    await verificarUbicacion();
  }

  Future<void> verificarUbicacion() async {
    if (_ambienteSeleccionado == null) return;

    try {
      final posicion = await _locationService.getCurrentLocation();
      
      if (posicion != null) {
        _dentroDeGeofence = _locationService.isInGeofence(
          posicion.latitude,
          posicion.longitude,
          _ambienteSeleccionado!.latitude,
          _ambienteSeleccionado!.longitude,
          _ambienteSeleccionado!.radioGeofence,
        );
      } else {
        _error = 'No se pudo obtener la ubicación';
      }
      notifyListeners();
    } catch (e) {
      _error = 'Error verificando ubicación: $e';
      notifyListeners();
    }
  }

  void limpiarSeleccion() {
    _ambienteSeleccionado = null;
    _dentroDeGeofence = false;
    _error = null;
    notifyListeners();
  }
}
