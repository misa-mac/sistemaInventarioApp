import 'package:flutter/material.dart';
import 'package:inventario_qr_app/repositories/auth_repository.dart';
import 'package:inventario_qr_app/models/usuario_model.dart';

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

    final resultado = await _authRepository.login(email, password);
    
    _isLoading = false;
    if (resultado != null) {
      _usuario = resultado;
      notifyListeners();
      return true;
    } else {
      _error = 'Credenciales inválidas';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
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
