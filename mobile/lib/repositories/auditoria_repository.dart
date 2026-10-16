import 'package:inventario_qr_app/core/network/api_client.dart';
import 'package:inventario_qr_app/core/constants/api_constants.dart';
import 'package:inventario_qr_app/models/auditoria_model.dart';
import 'package:flutter/foundation.dart';

class AuditoriaRepository {
  final ApiClient _apiClient = ApiClient();

  Future<AuditoriaModel?> crearAuditoria(
    String ambienteId,
    String tecnicoId,
    int totalEsperados,
  ) async {
    try {
      debugPrint('📋 Creando auditoría en servidor PostgreSQL...');
      debugPrint('Ambiente ID: $ambienteId');
      debugPrint('Auditor/Técnico ID: $tecnicoId');
      debugPrint('Total esperados: $totalEsperados');

      final body = {
        'ambiente_id': ambienteId,
        'auditor_id': tecnicoId,
        'tecnico_id': tecnicoId,
        'total_esperados': totalEsperados,
        'fecha_inicio': DateTime.now().toIso8601String(),
      };

      final response = await _apiClient.post(
        ApiConstants.auditoriasEndpoint,
        body,
      );

      if (response is Map && response.containsKey('id')) {
        debugPrint('✅ Auditoría creada exitosamente con ID: ${response['id']}');
        return AuditoriaModel.fromJson(response as Map<String, dynamic>);
      }

      debugPrint('❌ Respuesta inválida al crear auditoría: $response');
      return null;
    } catch (e) {
      debugPrint('Error creando auditoría: $e');
      return null;
    }
  }

  Future<bool> registrarDetalleAuditoria(
    String auditoriaId,
    String activoId,
    String estado,
    String? observacion, {
    String? codigoQr,
  }) async {
    try {
      final body = {
        'activo_id': activoId,
        'estado': estado,
        'observacion': observacion,
        'codigo_qr_escaneado': codigoQr,
        'fecha_escaneo': DateTime.now().toIso8601String(),
      };

      await _apiClient.post(
        '${ApiConstants.auditoriasEndpoint}/$auditoriaId/detalles',
        body,
      );
      return true;
    } catch (e) {
      debugPrint('Error registrando detalle de auditoría: $e');
      return false;
    }
  }

  Future<bool> finalizarAuditoria(
    String auditoriaId,
    int totalEncontrados,
  ) async {
    try {
      debugPrint('🏁 Finalizando auditoría: $auditoriaId');
      debugPrint('Total encontrados: $totalEncontrados');
      
      await _apiClient.patch(
        '${ApiConstants.auditoriasEndpoint}/$auditoriaId',
        {
          'total_encontrados': totalEncontrados,
          'estado': 'completada',
        },
      );

      debugPrint('✅ Auditoría finalizada en el servidor');
      return true;
    } catch (e) {
      debugPrint('❌ Error finalizando auditoría: $e');
      return false;
    }
  }

  Future<List<DetalleAuditoriaModel>> getDetallesAuditoria(String auditoriaId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.auditoriasEndpoint}/$auditoriaId/detalles',
      );

      List<DetalleAuditoriaModel> detalles = [];
      if (response is List) {
        detalles = (response).map((json) => DetalleAuditoriaModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      return detalles;
    } catch (e) {
      debugPrint('Error obteniendo detalles: $e');
      return [];
    }
  }

  Future<AuditoriaModel?> getUltimaAuditoria() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.auditoriasEndpoint}/ultima',
      );

      if (response is Map && response.containsKey('id')) {
        return AuditoriaModel.fromJson(response as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo última auditoría: $e');
      return null;
    }
  }

  Future<List<DetalleAuditoriaModel>> getMovimientosRecientes() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.auditoriasEndpoint}/movimientos-recientes',
      );

      List<DetalleAuditoriaModel> movimientos = [];
      if (response is List) {
        movimientos = response
            .map((json) => DetalleAuditoriaModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return movimientos;
    } catch (e) {
      debugPrint('Error obteniendo movimientos recientes: $e');
      return [];
    }
  }

  Future<List<AuditoriaModel>> obtenerAuditoriasDelDia(DateTime fecha) async {
    try {
      final fechaStr = fecha.toIso8601String().split('T')[0];
      final response = await _apiClient.get(
        '${ApiConstants.auditoriasEndpoint}?fecha=$fechaStr',
      );

      if (response is List) {
        return response
            .map((json) => AuditoriaModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error obteniendo auditorías del día: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> obtenerAuditoriaConDetalles(String auditoriaId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.auditoriasEndpoint}/$auditoriaId',
      );

      if (response is Map && response.containsKey('id')) {
        return response as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo auditoría: $e');
      return null;
    }
  }

  Future<List<String>> obtenerActivosEscaneadosDeAuditoria(String auditoriaId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.auditoriasEndpoint}/$auditoriaId/detalles',
      );

      List<String> activosIds = [];
      if (response is List) {
        activosIds = response
            .map((item) => (item['activo_id'] ?? item['codigo_qr_escaneado'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toList();
      }
      return activosIds;
    } catch (e) {
      debugPrint('Error obteniendo activos escaneados: $e');
      return [];
    }
  }

  Future<bool> eliminarDetalleAuditoria(String detalleId) async {
    try {
      await _apiClient.delete(
        '${ApiConstants.auditoriasEndpoint}/detalles/$detalleId',
      );
      return true;
    } catch (e) {
      debugPrint('Error eliminando detalle de auditoría: $e');
      return false;
    }
  }

  Future<bool> eliminarDetallesAuditoriaEnLote(List<String> detalleIds) async {
    if (detalleIds.isEmpty) return true;
    
    try {
      await _apiClient.post(
        '${ApiConstants.auditoriasEndpoint}/detalles/bulk-delete',
        {'ids': detalleIds},
      );
      return true;
    } catch (e) {
      debugPrint('Error eliminando detalles de auditoría en lote: $e');
      return false;
    }
  }
}
