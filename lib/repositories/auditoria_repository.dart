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
      debugPrint('📋 Creando auditoría...');
      debugPrint('Ambiente ID: $ambienteId');
      debugPrint('Técnico ID: $tecnicoId');
      debugPrint('Total esperados: $totalEsperados');

      final auditoria = AuditoriaModel(
        id: '',
        ambienteId: ambienteId,
        tecnicoId: tecnicoId,
        fechaInicio: DateTime.now(),
        totalEsperados: totalEsperados,
        totalEncontrados: 0,
      );

      final response = await _apiClient.post(
        ApiConstants.auditoriasEndpoint,
        auditoria.toJson(),
      );

      debugPrint('Respuesta de BD: $response');

      // Si respuesta vacía, esperar a que Supabase retorne el registro
      if (response is Map) {
        if (response.containsKey('id') && response['id'] != null) {
          debugPrint('✅ Auditoría creada con ID: ${response['id']}');
          return AuditoriaModel.fromJson(response as Map<String, dynamic>);
        } else if (response.isEmpty) {
          // Consultar la auditoría recién creada
          debugPrint('⏳ Esperando que Supabase genere el ID...');
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Buscar la auditoría más reciente de este técnico
          final recentResponse = await _apiClient.get(
            '${ApiConstants.auditoriasEndpoint}?tecnico_id=eq.$tecnicoId&order=fecha_inicio.desc&limit=1',
          );
          
          if (recentResponse is List && recentResponse.isNotEmpty) {
            debugPrint('✅ Auditoría encontrada: ${recentResponse[0]['id']}');
            return AuditoriaModel.fromJson(recentResponse[0] as Map<String, dynamic>);
          }
        }
      }

      debugPrint('❌ No se pudo crear auditoría');
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
    String? observacion,
  ) async {
    try {
      final detalle = DetalleAuditoriaModel(
        id: '',
        auditoriaId: auditoriaId,
        activoId: activoId,
        estado: estado,
        observacion: observacion,
        fechaEscaneo: DateTime.now(),
      );

      await _apiClient.post(
        ApiConstants.detalleAuditoriaEndpoint,
        detalle.toJson(),
      );
      return true;
    } catch (e) {
      debugPrint('Error registrando detalle: $e');
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
      
      // Usar PATCH en lugar de POST para actualizar
      final response = await _apiClient.patch(
        '${ApiConstants.auditoriasEndpoint}?id=eq.$auditoriaId',
        {
          'fecha_fin': DateTime.now().toIso8601String(),
          'total_encontrados': totalEncontrados,
        },
      );

      debugPrint('📥 Respuesta finalizar: $response');
      return true;
    } catch (e) {
      debugPrint('❌ Error finalizando auditoría: $e');
      return false;
    }
  }

  Future<List<DetalleAuditoriaModel>> getDetallesAuditoria(String auditoriaId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.detalleAuditoriaEndpoint}?auditoria_id=eq.$auditoriaId',
      );

      List<DetalleAuditoriaModel> detalles = [];
      if (response is List) {
        detalles = (response).map((json) => DetalleAuditoriaModel.fromJson(json)).toList();
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
        '${ApiConstants.auditoriasEndpoint}?order=created_at.desc&limit=1',
      );

      if (response is List && response.isNotEmpty) {
        return AuditoriaModel.fromJson(response[0] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo última auditoría: $e');
      return null;
    }
  }

  Future<List<DetalleAuditoriaModel>> getMovimientosRecientes() async {
    try {
      // Obtenemos los últimos 3 detalles de auditoría como movimientos
      final response = await _apiClient.get(
        '${ApiConstants.detalleAuditoriaEndpoint}?order=fecha_escaneo.desc&limit=3',
      );

      List<DetalleAuditoriaModel> movimientos = [];
      if (response is List) {
        movimientos = response
            .map((json) => DetalleAuditoriaModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return movimientos;
    } catch (e) {
      debugPrint('Error obteniendo movimientos: $e');
      return [];
    }
  }

  Future<List<AuditoriaModel>> obtenerAuditoriasDelDia(DateTime fecha) async {
    try {
      final fechaInicio = DateTime(fecha.year, fecha.month, fecha.day);
      final fechaFin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);

      final response = await _apiClient.get(
        '${ApiConstants.auditoriasEndpoint}?fecha_inicio=gte.${fechaInicio.toIso8601String()}&fecha_inicio=lte.${fechaFin.toIso8601String()}&order=fecha_inicio.desc',
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
        '${ApiConstants.auditoriasEndpoint}?id=eq.$auditoriaId',
      );

      if (response is List && response.isNotEmpty) {
        return response[0] as Map<String, dynamic>;
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
        '${ApiConstants.detalleAuditoriaEndpoint}?auditoria_id=eq.$auditoriaId',
      );

      List<String> activosIds = [];
      if (response is List) {
        activosIds = response
            .map((item) => item['activo_id'] as String)
            .toList();
      }
      return activosIds;
    } catch (e) {
      debugPrint('Error obteniendo activos escaneados: $e');
      return [];
    }
  }
}
