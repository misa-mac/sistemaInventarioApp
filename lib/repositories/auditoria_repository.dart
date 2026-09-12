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
      final auditoria = AuditoriaModel(
        id: '', // Supabase genera
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

      return AuditoriaModel.fromJson(response);
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
      await _apiClient.post(
        '${ApiConstants.auditoriasEndpoint}?id=eq.$auditoriaId',
        {
          'fecha_fin': DateTime.now().toIso8601String(),
          'total_encontrados': totalEncontrados,
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error finalizando auditoría: $e');
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
        detalles = (response as List).map((json) => DetalleAuditoriaModel.fromJson(json)).toList();
      }
      return detalles;
    } catch (e) {
      debugPrint('Error obteniendo detalles: $e');
      return [];
    }
  }
}
