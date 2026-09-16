import 'package:inventario_qr_app/core/hive/hive_manager.dart';
import 'package:inventario_qr_app/models/usuario_model.dart';
import 'package:inventario_qr_app/core/network/api_client.dart';
import 'package:inventario_qr_app/core/constants/api_constants.dart';
import 'package:inventario_qr_app/core/services/encriptacion_service.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<UsuarioModel?> login(String email, String password) async {
    try {
      debugPrint('🔐 Intentando login: $email');
      
      // Validar que email y contraseña no estén vacíos
      if (email.isEmpty || password.isEmpty) {
        debugPrint('❌ Email o contraseña vacíos');
        return null;
      }

      final response = await _apiClient.get(
        '${ApiConstants.usuariosEndpoint}?email=eq.$email',
      );
      
      if (response is List && response.isNotEmpty) {
        final usuarioJson = response[0] as Map<String, dynamic>;
        final usuario = UsuarioModel.fromJson(usuarioJson);
        
        // Verificar contraseña encriptada
        final passwordHashAlmacenado = usuarioJson['password_hash'] as String?;
        
        if (passwordHashAlmacenado == null) {
          debugPrint('❌ Usuario sin contraseña almacenada');
          return null;
        }

        final passwordValida = EncriptacionService.verificarPassword(
          password,
          passwordHashAlmacenado,
        );

        if (!passwordValida) {
          debugPrint('❌ Contraseña incorrecta');
          // Registrar intento fallido
          await _registrarIntentoFallido(email);
          return null;
        }

        if (!usuario.activo) {
          debugPrint('❌ Usuario inactivo');
          return null;
        }

        debugPrint('✅ Login exitoso: $email');
        
        // Guardar en Hive
        await HiveManager.getSessionBox().put('usuario', usuario.toJson());
        
        // Registrar login exitoso
        await _registrarLoginExitoso(usuario.id);
        
        return usuario;
      }
      
      debugPrint('❌ Usuario no encontrado');
      return null;
    } catch (e) {
      debugPrint('❌ Error en login: $e');
      return null;
    }
  }

  Future<void> logout() async {
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
    return HiveManager.getSessionBox().containsKey('usuario');
  }

  // A09 - Logging & Monitoring: Registrar intentos de login
  Future<void> _registrarIntentoFallido(String email) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('📝 AUDIT LOG: Intento fallido de login - $email - $timestamp');
      // TODO: Guardar en tabla de auditoría de logins
    } catch (e) {
      debugPrint('Error registrando intento: $e');
    }
  }

  Future<void> _registrarLoginExitoso(String usuarioId) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('📝 AUDIT LOG: Login exitoso - $usuarioId - $timestamp');
      // TODO: Guardar en tabla de auditoría de logins
    } catch (e) {
      debugPrint('Error registrando login: $e');
    }
  }
}
