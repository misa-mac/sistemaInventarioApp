import 'package:inventario_qr_app/core/hive/hive_manager.dart';
import 'package:inventario_qr_app/models/usuario_model.dart';
import 'package:inventario_qr_app/core/network/api_client.dart';
import 'package:inventario_qr_app/core/constants/api_constants.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<UsuarioModel?> login(String email, String password) async {
    try {
      debugPrint('🔐 Intentando login en servidor PostgreSQL: $email');
      
      if (email.isEmpty || password.isEmpty) {
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

        // Guardar token JWT y sesión en Hive
        await HiveManager.getSessionBox().put('token', token);
        await HiveManager.getSessionBox().put('usuario', usuario.toJson());

        debugPrint('✅ Login exitoso en servidor: ${usuario.email} (${usuario.rol})');
        return usuario;
      }
      
      debugPrint('❌ Respuesta de login inválida');
      return null;
    } catch (e) {
      debugPrint('❌ Error en login con servidor: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await HiveManager.getSessionBox().delete('token');
    await HiveManager.getSessionBox().delete('usuario');
  }

  UsuarioModel? getUsuarioLocal() {
    final datos = HiveManager.getSessionBox().get('usuario');
    if (datos != null) {
      return UsuarioModel.fromJson(Map<String, dynamic>.from(datos));
    }
    return null;
  }

  bool isLoggedIn() {
    return HiveManager.getSessionBox().containsKey('token') &&
           HiveManager.getSessionBox().containsKey('usuario');
  }
}
