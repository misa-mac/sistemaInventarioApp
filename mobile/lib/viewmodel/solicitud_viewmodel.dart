import 'package:flutter/foundation.dart';
import 'package:inventario_qr_app/models/solicitud_model.dart';
import 'package:inventario_qr_app/repositories/solicitud_repository.dart';

class SolicitudViewModel extends ChangeNotifier {
  final SolicitudRepository _repository = SolicitudRepository();

  List<SolicitudModel> _solicitudes = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _pendientesCount = 0;
  int _offlinePendingCount = 0;

  List<SolicitudModel> get solicitudes => _solicitudes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get pendientesCount => _pendientesCount;
  int get offlinePendingCount => _offlinePendingCount;

  Future<void> cargarSolicitudes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _solicitudes = await _repository.getMisSolicitudes();
      _offlinePendingCount = await _repository.getOfflinePendingCount();
      await cargarPendientesCount();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarPendientesCount() async {
    try {
      _pendientesCount = await _repository.getPendientesCount();
      _offlinePendingCount = await _repository.getOfflinePendingCount();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> solicitarAlta({
    required Map<String, dynamic> datos,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nueva = await _repository.crearSolicitud(
        tipo: 'alta',
        datos: datos,
      );
      _solicitudes.insert(0, nueva);
      _offlinePendingCount = await _repository.getOfflinePendingCount();
      await cargarPendientesCount();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> solicitarEdicion({
    required String activoId,
    required Map<String, dynamic> datos,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nueva = await _repository.crearSolicitud(
        tipo: 'edicion',
        activoId: activoId,
        datos: datos,
      );
      _solicitudes.insert(0, nueva);
      _offlinePendingCount = await _repository.getOfflinePendingCount();
      await cargarPendientesCount();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> solicitarBaja({
    required String activoId,
    required String motivo,
  }) async {
    if (motivo.trim().isEmpty) {
      _errorMessage = 'El motivo de la baja es obligatorio.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nueva = await _repository.crearSolicitud(
        tipo: 'baja',
        activoId: activoId,
        datos: {},
        motivo: motivo.trim(),
      );
      _solicitudes.insert(0, nueva);
      _offlinePendingCount = await _repository.getOfflinePendingCount();
      await cargarPendientesCount();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<int> sincronizarColaOffline() async {
    _isLoading = true;
    notifyListeners();

    try {
      final sincronizadas = await _repository.sincronizarPendientes();
      await cargarSolicitudes();
      return sincronizadas;
    } catch (e) {
      _errorMessage = e.toString();
      return 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
