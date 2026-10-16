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
        '${ApiConstants.activosEndpoint}?ambiente_id=$ambienteId',
      );
      
      List<ActivoModel> activos = [];
      if (response is List) {
        activos = (response).map((json) => ActivoModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      
      // Cachear en Hive para soporte offline
      await HiveManager.getActivosBox().put(ambienteId, 
        activos.map((a) => a.toJson()).toList());
      
      return activos;
    } catch (e) {
      debugPrint('⚠️ Error obteniendo activos de API, usando caché: $e');
      final cached = HiveManager.getActivosBox().get(ambienteId);
      if (cached != null) {
        return (cached as List).map((json) => ActivoModel.fromJson(Map<String, dynamic>.from(json))).toList();
      }
      return [];
    }
  }

  Future<ActivoModel?> getActivoPorUuid(String codigo) async {
    try {
      // 1. Buscar en el endpoint de búsqueda por código QR o serie
      try {
        final resSearch = await _apiClient.get(
          '${ApiConstants.activosEndpoint}/search/$codigo',
        );
        if (resSearch is Map && resSearch.containsKey('id')) {
          return ActivoModel.fromJson(resSearch as Map<String, dynamic>);
        }
      } catch (_) {}

      // 2. Si no, buscar por ID directo
      final resId = await _apiClient.get(
        '${ApiConstants.activosEndpoint}/$codigo',
      );
      if (resId is Map && resId.containsKey('id')) {
        return ActivoModel.fromJson(resId as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo activo: $e');
      return null;
    }
  }

  Future<bool> actualizarEstadoActivo(String activoId, String nuevoEstado) async {
    try {
      await _apiClient.put(
        '${ApiConstants.activosEndpoint}/$activoId',
        {'estado': nuevoEstado},
      );
      return true;
    } catch (e) {
      debugPrint('Error actualizando estado del activo: $e');
      return false;
    }
  }

  Future<ActivoModel?> getUltimoActivoEscaneado() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.activosEndpoint}/ultimo',
      );

      if (response is Map && response.containsKey('id')) {
        return ActivoModel.fromJson(response as Map<String, dynamic>);
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
        '${ApiConstants.activosEndpoint}?estado=Activo&limit=3',
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
        '${ApiConstants.activosEndpoint}?estado=Inactivo&limit=3',
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
      
      await _apiClient.put(
        '${ApiConstants.activosEndpoint}/${activo.id}',
        activo.toJson(),
      );

      debugPrint('✅ Activo actualizado exitosamente');
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
        '${ApiConstants.activosEndpoint}/$activoId',
      );

      debugPrint('✅ Activo eliminado exitosamente');
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

      debugPrint('✅ Activo creado exitosamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error creando activo: $e');
      return false;
    }
  }
}
