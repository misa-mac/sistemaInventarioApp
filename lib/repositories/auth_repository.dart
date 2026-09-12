import 'package:inventario_qr_app/core/hive/hive_manager.dart';
import 'package:inventario_qr_app/models/usuario_model.dart';
import 'package:inventario_qr_app/core/network/api_client.dart';
import 'package:inventario_qr_app/core/constants/api_constants.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<UsuarioModel?> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.usuariosEndpoint}?email=eq.$email',
        {'password': password},
      );
      
      if (response is List && response.isNotEmpty) {
        final usuario = UsuarioModel.fromJson(response[0]);
        // Guardar en Hive
        await HiveManager.getSessionBox().put('usuario', usuario.toJson());
        return usuario;
      }
      return null;
    } catch (e) {
      debugPrint('Error en login: $e');
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
}
