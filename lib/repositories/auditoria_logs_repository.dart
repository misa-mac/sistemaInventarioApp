import 'package:inventario_qr_app/core/network/api_client.dart';

import 'package:flutter/foundation.dart';

class AuditoriaLogsRepository {
  final ApiClient _apiClient = ApiClient();

  // Registrar acción de usuario
  Future<bool> registrarAccion({
    required String usuarioId,
    required String accion, // login, logout, crear_activo, editar_activo, eliminar_activo, etc
    required String recurso, // usuario, activo, auditoria, etc
    required String recursoId,
    required String resultado, // exitoso, fallido
    String? detalles,
  }) async {
    try {
      debugPrint('📝 Registrando acción: $usuarioId - $accion - $resultado');

      final ahora = DateTime.now().toIso8601String();

      final body = {
        'usuario_id': usuarioId,
        'accion': accion,
        'recurso': recurso,
        'recurso_id': recursoId,
        'resultado': resultado,
        'detalles': detalles,
        'fecha_hora': ahora,
        'ip_address': 'app_mobile', // En producción obtener IP real
      };

      // Usar POST para insertar en tabla de logs
      await _apiClient.post(
        '/rest/v1/audit_logs', // Esta tabla necesita ser creada
        body,
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error registrando acción: $e');
      return false;
    }
  }

  // Obtener logs de auditoría (solo administradores)
  Future<List<Map<String, dynamic>>> obtenerLogs({
    String? usuarioId,
    String? accion,
    int limite = 50,
  }) async {
    try {
      String endpoint = '/rest/v1/audit_logs?order=fecha_hora.desc&limit=$limite';

      if (usuarioId != null) {
        endpoint += '&usuario_id=eq.$usuarioId';
      }

      if (accion != null) {
        endpoint += '&accion=eq.$accion';
      }

      final response = await _apiClient.get(endpoint);

      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }

      return [];
    } catch (e) {
      debugPrint('Error obteniendo logs: $e');
      return [];
    }
  }

  // Obtener logs de login fallidos
  Future<List<Map<String, dynamic>>> obtenerIntentosFallidos({
    String? email,
    int minutosAtras = 60,
  }) async {
    try {
      final hace60Min = DateTime.now()
          .subtract(Duration(minutes: minutosAtras))
          .toIso8601String();

      String endpoint =
          '/rest/v1/audit_logs?accion=eq.login&resultado=eq.fallido&fecha_hora=gte.$hace60Min&order=fecha_hora.desc';

      if (email != null) {
        endpoint += '&detalles=ilike.%$email%';
      }

      final response = await _apiClient.get(endpoint);

      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }

      return [];
    } catch (e) {
      debugPrint('Error obteniendo intentos fallidos: $e');
      return [];
    }
  }

  // Detectar brute force (más de 5 intentos fallidos en 15 minutos)
  Future<bool> detectarBruteForce(String email) async {
    try {
      final intentos = await obtenerIntentosFallidos(
        email: email,
        minutosAtras: 15,
      );

      if (intentos.length >= 5) {
        debugPrint('⚠️ ALERTA: Posible brute force en $email');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error detectando brute force: $e');
      return false;
    }
  }
}
