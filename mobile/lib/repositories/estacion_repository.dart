import 'package:flutter/foundation.dart';
import 'package:inventario_qr_app/core/network/api_client.dart';
import 'package:inventario_qr_app/core/constants/api_constants.dart';
import 'package:inventario_qr_app/core/database/local_database.dart';
import 'package:inventario_qr_app/models/estacion_model.dart';

class EstacionRepository {
  final ApiClient _apiClient = ApiClient();
  final LocalDatabase _localDb = LocalDatabase.instance;

  /// Obtiene la información de la estación y sus componentes por código (ej. EST-LAB1-05).
  /// Primero intenta la API REST y almacena en SQLite para soporte offline.
  /// Si falla la red, recurre a la base de datos local SQLite.
  Future<EstacionModel?> getEstacionPorCodigo(String codigo) async {
    final cleanCode = codigo.trim();
    try {
      final response = await _apiClient.get(
        '${ApiConstants.estacionesEndpoint}/$cleanCode',
      );

      if (response != null && response is Map<String, dynamic>) {
        final estacion = EstacionModel.fromJson(response);
        // Guardar en SQLite para offline
        await _localDb.guardarEstaciones([estacion.toSqliteMap()]);
        return estacion;
      }
    } catch (e) {
      debugPrint('⚠️ Error en API al buscar estación ($cleanCode), consultando SQLite: $e');
    }

    // Fallback SQLite Offline
    try {
      final cached = await _localDb.getEstacionPorCodigo(cleanCode);
      if (cached != null) {
        debugPrint('📦 Estación recuperada desde caché SQLite offline');
        return EstacionModel.fromJson(cached);
      }
    } catch (dbErr) {
      debugPrint('❌ Error leyendo estación de SQLite: $dbErr');
    }

    return null;
  }

  /// Lista estaciones de un ambiente
  Future<List<EstacionModel>> getEstacionesPorAmbiente(String ambienteId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.estacionesEndpoint}?ambiente_id=$ambienteId',
      );

      if (response is List) {
        final list = response
            .map((json) => EstacionModel.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Guardar en SQLite
        await _localDb.guardarEstaciones(list.map((e) => e.toSqliteMap()).toList());
        return list;
      }
    } catch (e) {
      debugPrint('⚠️ Error obteniendo estaciones por ambiente: $e');
    }
    return [];
  }
}

