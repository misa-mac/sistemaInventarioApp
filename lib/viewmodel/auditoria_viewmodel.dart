import 'package:flutter/material.dart';
import 'package:inventario_qr_app/repositories/auditoria_repository.dart';
import 'package:inventario_qr_app/models/auditoria_model.dart';

class AuditoriaViewModel extends ChangeNotifier {
  final AuditoriaRepository _auditoriaRepository = AuditoriaRepository();

  AuditoriaModel? _auditoriaActual;
  List<DetalleAuditoriaModel> _detalles = [];
  bool _isLoading = false;
  String? _error;
  int _escaneosCont = 0;
  AuditoriaModel? _ultimaAuditoria;
  List<DetalleAuditoriaModel> _movimientosRecientes = [];

  // Getters
  AuditoriaModel? get auditoriaActual => _auditoriaActual;
  List<DetalleAuditoriaModel> get detalles => _detalles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get escaneosCont => _escaneosCont;
  AuditoriaModel? get ultimaAuditoria => _ultimaAuditoria;
  List<DetalleAuditoriaModel> get movimientosRecientes => _movimientosRecientes;

  Future<bool> iniciarAuditoria(
    String ambienteId,
    String tecnicoId,
    int totalEsperados,
  ) async {
    _isLoading = true;
    _error = null;
    _escaneosCont = 0;
    _detalles = [];
    notifyListeners();

    try {
      _auditoriaActual = await _auditoriaRepository.crearAuditoria(
        ambienteId,
        tecnicoId,
        totalEsperados,
      );

      _isLoading = false;
      if (_auditoriaActual != null) {
        notifyListeners();
        return true;
      } else {
        _error = 'No se pudo crear la auditoría';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error iniciando auditoría: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrarEscaneo(
    String activoId,
    String estado,
    String? observacion,
  ) async {
    if (_auditoriaActual == null) return false;

    try {
      debugPrint('📝 Registrando escaneo: $activoId');
      
      final resultado = await _auditoriaRepository.registrarDetalleAuditoria(
        _auditoriaActual!.id,
        activoId,
        estado,
        observacion,
      );

      if (resultado) {
        _escaneosCont++;
        debugPrint('✅ Escaneo registrado. Total: $_escaneosCont');
        notifyListeners(); // ← CRÍTICO: Actualizar UI
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error registrando escaneo: $e';
      debugPrint('❌ Error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> finalizarAuditoria() async {
    if (_auditoriaActual == null) {
      debugPrint('❌ No hay auditoría activa');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🏁 Finalizando auditoría: ${_auditoriaActual!.id}');
      debugPrint('Total escaneados: $_escaneosCont');
      debugPrint('Ambiente ID: ${_auditoriaActual!.ambienteId}');
      
      final resultado = await _auditoriaRepository.finalizarAuditoria(
        _auditoriaActual!.id,
        _escaneosCont,
      );

      debugPrint('Resultado: $resultado');
      
      if (resultado) {
        _auditoriaActual = _auditoriaActual!; // Mantener referencia
      }
      
      _isLoading = false;
      notifyListeners();
      return resultado;
    } catch (e) {
      debugPrint('❌ Error finalizando: $e');
      _error = 'Error finalizando auditoría: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> cargarDetalles() async {
    if (_auditoriaActual == null) return;

    try {
      _detalles = await _auditoriaRepository.getDetallesAuditoria(
        _auditoriaActual!.id,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Error cargando detalles: $e';
      notifyListeners();
    }
  }

  void limpiarAuditoria() {
    _auditoriaActual = null;
    _detalles = [];
    _escaneosCont = 0;
    _error = null;
    notifyListeners();
  }

  Future<void> cargarReportes() async {
    try {
      _ultimaAuditoria = await _auditoriaRepository.getUltimaAuditoria();
      _movimientosRecientes = await _auditoriaRepository.getMovimientosRecientes();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando reportes: $e');
      notifyListeners();
    }
  }
}
