import 'package:inventario_qr_app/core/storage/session_manager.dart';
import 'package:inventario_qr_app/models/usuario_model.dart';
import 'package:inventario_qr_app/core/network/api_client.dart';
import 'package:inventario_qr_app/core/constants/api_constants.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();
  String? lastError;

  Future<UsuarioModel?> login(String email, String password) async {
    try {
      lastError = null;
      debugPrint('🔐 Intentando login en servidor PostgreSQL: $email');
      
      if (email.isEmpty || password.isEmpty) {
        lastError = 'Email o contraseña vacíos';
        debugPrint('❌ Email o contraseña vacíos');
        return null;
      }

      final response = await _apiClient.post(
        ApiConstants.authLoginEndpoint,
        {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );
      
      if (response is Map && response.containsKey('token')) {
        final token = response['token'] as String;
        final userJson = response['user'] as Map<String, dynamic>;
        
        final usuario = UsuarioModel(
          id: userJson['id'] ?? '',
          email: userJson['email'] ?? email,
          nombreCompleto: userJson['nombre'] ?? userJson['nombre_completo'] ?? '',
          rol: userJson['rol'] ?? 'tecnico',
          activo: true,
        );

        // Guardar token JWT y sesión mediante SessionManager (aislado de SQLite)
        await SessionManager.saveSession(token, usuario);

        debugPrint('✅ Login exitoso en servidor: ${usuario.email} (${usuario.rol})');
        return usuario;
      }
      
      lastError = 'Respuesta de login inválida';
      debugPrint('❌ Respuesta de login inválida');
      return null;
    } catch (e) {
      debugPrint('❌ Error en login con servidor: $e');
      final str = e.toString();
      if (str.contains('Connection refused') || str.contains('SocketException')) {
        lastError = 'No se pudo conectar al servidor. Revisa que el backend esté iniciado.';
      } else if (str.contains('401')) {
        lastError = 'Credenciales inválidas (email o contraseña incorrectos)';
      } else if (str.contains('403')) {
        lastError = 'Usuario inactivo';
      } else {
        lastError = 'Error de conexión: $e';
      }
      return null;
    }
  }

  Future<void> logout() async {
    await SessionManager.clearSession();
  }

  UsuarioModel? getUsuarioLocal() {
    return SessionManager.getUsuario();
  }

  bool isLoggedIn() {
    return SessionManager.isLoggedIn();
  }
}
