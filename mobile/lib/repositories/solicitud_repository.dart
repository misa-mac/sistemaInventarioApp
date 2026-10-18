import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:inventario_qr_app/core/network/api_client.dart';
import 'package:inventario_qr_app/core/database/local_database.dart';
import 'package:inventario_qr_app/models/solicitud_model.dart';

class SolicitudRepository {
  final ApiClient _apiClient = ApiClient();
  final LocalDatabase _localDb = LocalDatabase.instance;
  final Uuid _uuid = const Uuid();

  /// Crea una solicitud (alta, edición, baja).
  /// Guarda primero en SQLite (tabla solicitudes_pendientes) y la envía de inmediato
  /// a la API de forma idempotente con su ID UUID. Si no hay conexión, queda encolada.
  Future<SolicitudModel> crearSolicitud({
    required String tipo,
    String? activoId,
    required Map<String, dynamic> datos,
    String? motivo,
    String? customId,
  }) async {
    final id = customId ?? _uuid.v4();
    final fecha = DateTime.now();

    final solicitudLocal = SolicitudModel(
      id: id,
      tipo: tipo,
      activoId: activoId,
      datos: datos,
      motivo: motivo,
      createdAt: fecha,
      sincronizado: false,
    );

    // 1. Guardar en SQLite local
    final db = await _localDb.database;
    await db.insert(
      'solicitudes_pendientes',
      solicitudLocal.toDbMap(),
    );
    debugPrint('💾 [SolicitudRepository] Solicitud $id ($tipo) guardada en SQLite.');

    // 2. Intentar enviar a la API
    try {
      final res = await _apiClient.post('/solicitudes', solicitudLocal.toApiBody());
      
      // Marcar como sincronizada en SQLite
      await db.update(
        'solicitudes_pendientes',
        {'sincronizado': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('☁️ [SolicitudRepository] Solicitud $id sincronizada exitosamente con la API.');

      if (res is Map<String, dynamic>) {
        return SolicitudModel.fromJson(res);
      }
      return SolicitudModel(
        id: id,
        tipo: tipo,
        activoId: activoId,
        datos: datos,
        motivo: motivo,
        createdAt: fecha,
        sincronizado: true,
      );
    } catch (e) {
      debugPrint('⚠️ [SolicitudRepository] Sin conexión. La solicitud $id queda encolada offline: $e');
      return solicitudLocal;
    }
  }

  /// Sincroniza todas las solicitudes pendientes guardadas localmente en SQLite.
  /// Idempotente: la API reconoce el id UUID y no duplica si ya fue procesada.
  Future<int> sincronizarPendientes() async {
    final db = await _localDb.database;
    final List<Map<String, dynamic>> pendientesMaps = await db.query(
      'solicitudes_pendientes',
      where: 'sincronizado = 0',
      orderBy: 'fecha ASC',
    );

    if (pendientesMaps.isEmpty) {
      return 0;
    }

    int sincronizadas = 0;
    for (final map in pendientesMaps) {
      final sol = SolicitudModel.fromDbMap(map);
      try {
        await _apiClient.post('/solicitudes', sol.toApiBody());
        await db.update(
          'solicitudes_pendientes',
          {'sincronizado': 1},
          where: 'id = ?',
          whereArgs: [sol.id],
        );
        sincronizadas++;
      } catch (e) {
        debugPrint('❌ [SolicitudRepository] Error al sincronizar ${sol.id}: $e');
      }
    }

    debugPrint('🔄 [SolicitudRepository] Se sincronizaron $sincronizadas de ${pendientesMaps.length} solicitudes pendientes.');
    return sincronizadas;
  }

  /// Obtiene la lista de solicitudes del usuario actual.
  /// Combina la respuesta de la API con cualquier solicitud pendiente en SQLite.
  Future<List<SolicitudModel>> getMisSolicitudes() async {
    List<SolicitudModel> resultados = [];

    // 1. Cargar desde API
    try {
      final res = await _apiClient.get('/solicitudes');
      if (res is Map && res['data'] != null && res['data'] is List) {
        resultados = (res['data'] as List)
            .map((item) => SolicitudModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (res is List) {
        resultados = res
            .map((item) => SolicitudModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('⚠️ [SolicitudRepository] Error al conectar con API, cargando solicitudes locales: $e');
    }

    // 2. Cargar solicitudes pendientes locales no sincronizadas aún
    try {
      final db = await _localDb.database;
      final localList = await db.query(
        'solicitudes_pendientes',
        where: 'sincronizado = 0',
        orderBy: 'fecha DESC',
      );

      final localesNoSincronizadas = localList.map((m) => SolicitudModel.fromDbMap(m)).toList();
      
      // Combinar evitando duplicados por ID
      final existingIds = resultados.map((s) => s.id).toSet();
      for (final local in localesNoSincronizadas) {
        if (!existingIds.contains(local.id)) {
          resultados.insert(0, local);
        }
      }
    } catch (e) {
      debugPrint('Error leyendo solicitudes locales: $e');
    }

    return resultados;
  }

  /// Contador de pendientes para el badge del admin o técnico
  Future<int> getPendientesCount() async {
    try {
      final res = await _apiClient.get('/solicitudes/pendientes-count');
      if (res is Map && res['count'] != null) {
        return (res['count'] as num).toInt();
      }
    } catch (_) {}
    return 0;
  }

  /// Retorna la cantidad de solicitudes en la cola offline sin sincronizar
  Future<int> getOfflinePendingCount() async {
    try {
      final db = await _localDb.database;
      final res = await db.rawQuery('SELECT count(*) as count FROM solicitudes_pendientes WHERE sincronizado = 0');
      return (res.first['count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
