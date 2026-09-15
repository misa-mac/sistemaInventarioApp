import 'package:inventario_qr_app/core/network/api_client.dart';
import 'package:inventario_qr_app/core/constants/api_constants.dart';
import 'package:inventario_qr_app/models/activo_model.dart';
import 'package:inventario_qr_app/core/hive/hive_manager.dart';
import 'package:flutter/foundation.dart';

class ActivoRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<ActivoModel>> getActivosPorAmbiente(String ambienteId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.activosEndpoint}?ambiente_id=eq.$ambienteId',
      );
      
      List<ActivoModel> activos = [];
      if (response is List) {
        activos = (response).map((json) => ActivoModel.fromJson(json)).toList();
      }
      
      // Cachear en Hive
      await HiveManager.getActivosBox().put(ambienteId, 
        activos.map((a) => a.toJson()).toList());
      
      return activos;
    } catch (e) {
      // Devolver caché si falla
      final cached = HiveManager.getActivosBox().get(ambienteId);
      if (cached != null) {
        return (cached as List).map((json) => ActivoModel.fromJson(Map<String, dynamic>.from(json))).toList();
      }
      return [];
    }
  }

  Future<ActivoModel?> getActivoPorUuid(String uuid) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.activosEndpoint}?uuid=eq.$uuid',
      );
      
      if (response is List && (response).isNotEmpty) {
        return ActivoModel.fromJson((response)[0]);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo activo: $e');
      return null;
    }
  }



  Future<bool> actualizarEstadoActivo(String activoId, String nuevoEstado) async {
    try {
      await _apiClient.post(
        '${ApiConstants.activosEndpoint}?id=eq.$activoId',
        {'estado': nuevoEstado},
      );
      return true;
    } catch (e) {
      debugPrint('Error actualizando activo: $e');
      return false;
    }
  }

  Future<ActivoModel?> getUltimoActivoEscaneado() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.activosEndpoint}?order=updated_at.desc&limit=1',
      );

      if (response is List && response.isNotEmpty) {
        return ActivoModel.fromJson(response[0] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo último activo: $e');
      return null;
    }
  }

  Future<List<ActivoModel>> getActivosNuevos() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.activosEndpoint}?estado=eq.activo&order=created_at.desc&limit=3',
      );

      List<ActivoModel> activos = [];
      if (response is List) {
        activos = response.map((json) => ActivoModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      return activos;
    } catch (e) {
      debugPrint('Error obteniendo activos nuevos: $e');
      return [];
    }
  }

  Future<List<ActivoModel>> getActivosDeBaja() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.activosEndpoint}?estado=eq.baja&order=updated_at.desc&limit=3',
      );

      List<ActivoModel> activos = [];
      if (response is List) {
        activos = response.map((json) => ActivoModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      return activos;
    } catch (e) {
      debugPrint('Error obteniendo activos de baja: $e');
      return [];
    }
  }

  Future<bool> actualizarActivo(ActivoModel activo) async {
    try {
      debugPrint('🔄 Actualizando activo: ${activo.id}');
      
      await _apiClient.patch(
        '${ApiConstants.activosEndpoint}?id=eq.${activo.id}',
        activo.toJson(),
      );

      debugPrint('✅ Activo actualizado');
      return true;
    } catch (e) {
      debugPrint('❌ Error actualizando activo: $e');
      return false;
    }
  }

  Future<bool> eliminarActivo(String activoId) async {
    try {
      debugPrint('🗑️ Eliminando activo: $activoId');
      
      await _apiClient.delete(
        '${ApiConstants.activosEndpoint}?id=eq.$activoId',
      );

      debugPrint('✅ Activo eliminado');
      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando activo: $e');
      return false;
    }
  }

  Future<List<ActivoModel>> getTodosLosActivos() async {
    try {
      final response = await _apiClient.get(ApiConstants.activosEndpoint);
      List<ActivoModel> activos = [];
      if (response is List) {
        activos = response.map((json) => ActivoModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      return activos;
    } catch (e) {
      debugPrint('Error obteniendo todos los activos: $e');
      return [];
    }
  }

  Future<bool> crearActivo(ActivoModel activo) async {
    try {
      debugPrint('🆕 Creando activo: ${activo.nombre}');
      
      await _apiClient.post(
        ApiConstants.activosEndpoint,
        activo.toJson(),
      );

      debugPrint('✅ Activo creado');
      return true;
    } catch (e) {
      debugPrint('❌ Error creando activo: $e');
      return false;
    }
  }
}
