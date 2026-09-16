import 'package:flutter/material.dart';
import 'package:inventario_qr_app/repositories/auth_repository.dart';
import 'package:inventario_qr_app/models/usuario_model.dart';
import 'package:inventario_qr_app/repositories/auditoria_logs_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  UsuarioModel? _usuario;
  bool _isLoading = false;
  String? _error;

  // Getters
  UsuarioModel? get usuario => _usuario;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _authRepository.isLoggedIn();

  // Constructor
  AuthViewModel() {
    _cargarUsuarioLocal();
  }

  void _cargarUsuarioLocal() {
    _usuario = _authRepository.getUsuarioLocal();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final auditLog = AuditoriaLogsRepository();
    final resultado = await _authRepository.login(email, password);
    
    _isLoading = false;
    
    if (resultado != null) {
      _usuario = resultado;
      
      // Registrar login exitoso (A09)
      await auditLog.registrarAccion(
        usuarioId: resultado.id,
        accion: 'login',
        recurso: 'usuario',
        recursoId: resultado.id,
        resultado: 'exitoso',
        detalles: 'Email: $email',
      );
      
      notifyListeners();
      return true;
    } else {
      _error = 'Credenciales inválidas';
      
      // Registrar intento fallido (A09)
      await auditLog.registrarAccion(
        usuarioId: 'desconocido',
        accion: 'login',
        recurso: 'usuario',
        recursoId: email,
        resultado: 'fallido',
        detalles: 'Email: $email - Credenciales inválidas',
      );
      
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_usuario != null) {
      final auditLog = AuditoriaLogsRepository();
      
      // Registrar logout (A09)
      await auditLog.registrarAccion(
        usuarioId: _usuario!.id,
        accion: 'logout',
        recurso: 'usuario',
        recursoId: _usuario!.id,
        resultado: 'exitoso',
        detalles: 'Email: ${_usuario!.email}',
      );
    }
    
    await _authRepository.logout();
    _usuario = null;
    _error = null;
    notifyListeners();
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
