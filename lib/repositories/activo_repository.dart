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
        activos = (response as List).map((json) => ActivoModel.fromJson(json)).toList();
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
      
      if (response is List && (response as List).isNotEmpty) {
        return ActivoModel.fromJson((response as List)[0]);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo activo: $e');
      return null;
    }
  }

  Future<bool> crearActivo(ActivoModel activo) async {
    try {
      await _apiClient.post(ApiConstants.activosEndpoint, activo.toJson());
      return true;
    } catch (e) {
      debugPrint('Error creando activo: $e');
      return false;
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
}
