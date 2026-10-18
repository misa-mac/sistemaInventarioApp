import 'package:sqflite/sqflite.dart';
import 'package:inventario_qr_app/core/network/api_client.dart';
import 'package:inventario_qr_app/core/constants/api_constants.dart';
import 'package:inventario_qr_app/models/ambiente_model.dart';
import 'package:inventario_qr_app/core/database/local_database.dart';
import 'package:flutter/foundation.dart';

class AmbienteRepository {
  final ApiClient _apiClient = ApiClient();
  final LocalDatabase _localDb = LocalDatabase.instance;

  Future<List<AmbienteModel>> getAmbientes() async {
    try {
      final response = await _apiClient.get(ApiConstants.ambientesEndpoint);
      
      List<AmbienteModel> ambientes = [];
      if (response is List) {
        ambientes = (response).map((json) => AmbienteModel.fromJson(json)).toList();
      }
      
      // Cachear en SQLite para soporte offline en lote dentro de transacción
      await _cacheAmbientesLocal(ambientes);
      
      return ambientes;
    } catch (e) {
      debugPrint('⚠️ Error obteniendo ambientes de API, usando caché SQLite: $e');
      return await _getCachedAmbientes();
    }
  }

  Future<void> _cacheAmbientesLocal(List<AmbienteModel> ambientes) async {
    try {
      final db = await _localDb.database;
      await db.transaction((txn) async {
        await txn.delete('cache_ambientes');
        final batch = txn.batch();
        for (var a in ambientes) {
          batch.insert(
            'cache_ambientes',
            {
              'id': a.id,
              'nombre': a.nombre,
              'descripcion': a.descripcion,
              'tiene_internet': a.tieneInternet ? 1 : 0,
              'latitude': a.latitude,
              'longitude': a.longitude,
              'radio_geofence': a.radioGeofence,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      debugPrint('Error cacheando ambientes en SQLite: $e');
    }
  }

  Future<List<AmbienteModel>> _getCachedAmbientes() async {
    try {
      final db = await _localDb.database;
      final rows = await db.query(
        'cache_ambientes',
        orderBy: 'nombre ASC',
      );
      return rows.map((r) => AmbienteModel(
        id: r['id'] as String,
        nombre: r['nombre'] as String,
        descripcion: (r['descripcion'] ?? '').toString(),
        tieneInternet: (r['tiene_internet'] as int) == 1,
        latitude: (r['latitude'] as num).toDouble(),
        longitude: (r['longitude'] as num).toDouble(),
        radioGeofence: (r['radio_geofence'] as num).toDouble(),
      )).toList();
    } catch (e) {
      debugPrint('Error leyendo caché de ambientes: $e');
      return [];
    }
  }

  Future<AmbienteModel?> getAmbientePorId(String ambienteId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.ambientesEndpoint}/$ambienteId',
      );
      
      if (response is Map) {
        return AmbienteModel.fromJson(response as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo ambiente de API, consultando caché local: $e');
      try {
        final db = await _localDb.database;
        final rows = await db.query(
          'cache_ambientes',
          where: 'id = ?',
          whereArgs: [ambienteId],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          final r = rows.first;
          return AmbienteModel(
            id: r['id'] as String,
            nombre: r['nombre'] as String,
            descripcion: (r['descripcion'] ?? '').toString(),
            tieneInternet: (r['tiene_internet'] as int) == 1,
            latitude: (r['latitude'] as num).toDouble(),
            longitude: (r['longitude'] as num).toDouble(),
            radioGeofence: (r['radio_geofence'] as num).toDouble(),
          );
        }
      } catch (_) {}
      return null;
    }
  }
}
