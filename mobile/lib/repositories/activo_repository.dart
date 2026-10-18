import 'package:sqflite/sqflite.dart';
import 'package:inventario_qr_app/core/network/api_client.dart';
import 'package:inventario_qr_app/core/constants/api_constants.dart';
import 'package:inventario_qr_app/models/activo_model.dart';
import 'package:inventario_qr_app/core/database/local_database.dart';
import 'package:flutter/foundation.dart';

class ActivoRepository {
  final ApiClient _apiClient = ApiClient();
  final LocalDatabase _localDb = LocalDatabase.instance;

  Future<List<ActivoModel>> getActivosPorAmbiente(String ambienteId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.activosEndpoint}?ambiente_id=$ambienteId',
      );
      
      List<ActivoModel> activos = [];
      if (response is List) {
        activos = (response).map((json) => ActivoModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      
      // Cachear en SQLite para soporte offline en lote dentro de transacción
      await _cacheActivosPorAmbienteLocal(ambienteId, activos);
      
      return activos;
    } catch (e) {
      debugPrint('⚠️ Error obteniendo activos de API, usando caché SQLite: $e');
      return await _getCachedActivosPorAmbiente(ambienteId);
    }
  }

  Future<void> _cacheActivosPorAmbienteLocal(String ambienteId, List<ActivoModel> activos) async {
    try {
      final db = await _localDb.database;
      await db.transaction((txn) async {
        await txn.delete(
          'cache_activos',
          where: 'ambiente_id = ?',
          whereArgs: [ambienteId],
        );
        final batch = txn.batch();
        for (var a in activos) {
          batch.insert(
            'cache_activos',
            {
              'id': a.id,
              'uuid': a.uuid,
              'nombre': a.nombre,
              'tipo': a.tipo,
              'marca': a.marca,
              'modelo': a.modelo,
              'numero_serie': a.numeroSerie,
              'estado': a.estado,
              'ambiente_id': a.ambienteId.isNotEmpty ? a.ambienteId : ambienteId,
              'ambiente_registro_id': a.ambienteRegistroId,
              'codigo_activo': a.qrCodigo,
              'imagen_url': a.imagenUrl,
              'observaciones': a.observaciones,
              'numero_correlativo': a.numeroCorrelativo,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      debugPrint('Error cacheando activos en SQLite: $e');
    }
  }

  Future<List<ActivoModel>> _getCachedActivosPorAmbiente(String ambienteId) async {
    try {
      final db = await _localDb.database;
      final rows = await db.query(
        'cache_activos',
        where: 'ambiente_id = ?',
        whereArgs: [ambienteId],
      );
      return rows.map((r) => ActivoModel(
        id: r['id'] as String,
        uuid: (r['uuid'] ?? r['id'] ?? '').toString(),
        nombre: (r['nombre'] ?? '').toString(),
        tipo: (r['tipo'] ?? '').toString(),
        marca: (r['marca'] ?? '').toString(),
        modelo: (r['modelo'] ?? '').toString(),
        numeroSerie: (r['numero_serie'] ?? '').toString(),
        estado: (r['estado'] ?? 'Activo').toString(),
        ambienteId: (r['ambiente_id'] ?? ambienteId).toString(),
        ambienteRegistroId: r['ambiente_registro_id']?.toString(),
        qrCodigo: (r['codigo_activo'] ?? '').toString(),
        imagenUrl: r['imagen_url']?.toString(),
        observaciones: r['observaciones']?.toString(),
        numeroCorrelativo: r['numero_correlativo'] as int?,
      )).toList();
    } catch (e) {
      debugPrint('Error leyendo caché de activos: $e');
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
      debugPrint('Error obteniendo activo de red, consultando caché SQLite: $e');
      try {
        final db = await _localDb.database;
        final rows = await db.query(
          'cache_activos',
          where: 'uuid = ? OR id = ? OR codigo_activo = ?',
          whereArgs: [codigo, codigo, codigo],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          final r = rows.first;
          return ActivoModel(
            id: r['id'] as String,
            uuid: (r['uuid'] ?? r['id'] ?? '').toString(),
            nombre: (r['nombre'] ?? '').toString(),
            tipo: (r['tipo'] ?? '').toString(),
            marca: (r['marca'] ?? '').toString(),
            modelo: (r['modelo'] ?? '').toString(),
            numeroSerie: (r['numero_serie'] ?? '').toString(),
            estado: (r['estado'] ?? 'Activo').toString(),
            ambienteId: (r['ambiente_id'] ?? '').toString(),
            ambienteRegistroId: r['ambiente_registro_id']?.toString(),
            qrCodigo: (r['codigo_activo'] ?? '').toString(),
            imagenUrl: r['imagen_url']?.toString(),
            observaciones: r['observaciones']?.toString(),
            numeroCorrelativo: r['numero_correlativo'] as int?,
          );
        }
      } catch (_) {}
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
