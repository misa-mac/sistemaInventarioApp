import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:inventario_qr_app/core/network/api_client.dart';
import 'package:inventario_qr_app/core/constants/api_constants.dart';
import 'package:inventario_qr_app/models/auditoria_model.dart';
import 'package:inventario_qr_app/core/database/local_database.dart';
import 'package:flutter/foundation.dart';

class AuditoriaRepository {
  final ApiClient _apiClient = ApiClient();
  final LocalDatabase _localDb = LocalDatabase.instance;
  static const Uuid _uuid = Uuid();

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
        'fecha_inicio': DateTime.now().toUtc().toIso8601String(),
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

  /// Registra el escaneo en la base de datos local SQLite (escaneos_pendientes)
  /// e intenta enviarlo al servidor si hay conexión disponible.
  ///
  /// Cumple los requisitos:
  /// - id: UUID v4 generado en dispositivo para evitar duplicidad al reintentar.
  /// - fecha_escaneo: ISO-8601 en UTC (toUtc().toIso8601String()).
  /// - sincronizado: 0 por defecto, marcado como 1 solo al confirmar servidor.
  /// - Sin restricciones UNIQUE para permitir la lógica de duplicados de la app.
  Future<bool> registrarDetalleAuditoria(
    String auditoriaId,
    String activoId,
    String estado,
    String? observacion, {
    String? codigoQr,
  }) async {
    final String localId = _uuid.v4();
    final String fechaUtc = DateTime.now().toUtc().toIso8601String();
    final String qrEscaneado = (codigoQr != null && codigoQr.isNotEmpty)
        ? codigoQr
        : (activoId.isNotEmpty ? activoId : 'SIN_CODIGO');

    try {
      final db = await _localDb.database;

      // 1. Guardar primero en SQLite como pendiente (sincronizado = 0)
      await db.insert(
        'escaneos_pendientes',
        {
          'id': localId,
          'auditoria_id': auditoriaId,
          'activo_id': activoId.isNotEmpty ? activoId : null,
          'codigo_qr_escaneado': qrEscaneado,
          'estado': estado,
          'observacion': observacion,
          'fecha_escaneo': fechaUtc,
          'sincronizado': 0,
        },
      );

      debugPrint('💾 [SQLite] Escaneo registrado localmente con ID: $localId');

      // 2. Intentar registrar de inmediato en el servidor si hay conexión
      try {
        final body = {
          'id': localId,
          'activo_id': activoId.isNotEmpty ? activoId : null,
          'estado': estado,
          'observacion': observacion,
          'codigo_qr_escaneado': qrEscaneado,
          'fecha_escaneo': fechaUtc,
        };

        await _apiClient.post(
          '${ApiConstants.auditoriasEndpoint}/$auditoriaId/detalles',
          body,
        );

        // Confirmado por el servidor: marcar sincronizado = 1
        await db.update(
          'escaneos_pendientes',
          {'sincronizado': 1},
          where: 'id = ?',
          whereArgs: [localId],
        );
        debugPrint('🌐 [SQLite] Escaneo $localId confirmado y sincronizado con servidor.');
      } catch (netErr) {
        debugPrint('📡 [Offline] Sin conexión inmediata al servidor. Queda pendiente en SQLite: $netErr');
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error guardando detalle de auditoría en SQLite: $e');
      return false;
    }
  }

  /// Sincroniza escaneos pendientes (sincronizado = 0) enviándolos a POST /api/auditorias/sync.
  ///
  /// - Envía el localId de cada registro para no perder trazabilidad.
  /// - Marca sincronizado = 1 SOLO tras la confirmación del servidor.
  /// - Si falla parcialmente o la conexión se interrumpe, los pendientes quedan intactos.
  /// - Purga registros sincronizados con más de 30 días de antigüedad.
  Future<int> sincronizarPendientes({String? auditoriaId}) async {
    final db = await _localDb.database;

    // 1. Consultar pendientes con consultas parametrizadas
    List<Map<String, dynamic>> pendientes;
    if (auditoriaId != null && auditoriaId.isNotEmpty) {
      pendientes = await db.query(
        'escaneos_pendientes',
        where: 'auditoria_id = ? AND sincronizado = 0',
        whereArgs: [auditoriaId],
        orderBy: 'fecha_escaneo ASC',
      );
    } else {
      pendientes = await db.query(
        'escaneos_pendientes',
        where: 'sincronizado = 0',
        orderBy: 'fecha_escaneo ASC',
      );
    }

    if (pendientes.isEmpty) {
      debugPrint('ℹ️ [Sincronización] No hay escaneos pendientes para sincronizar.');
      await purgarSincronizadosAntiguos();
      return 0;
    }

    debugPrint('🔄 [Sincronización] Iniciando sincronización de ${pendientes.length} escaneos pendientes...');

    // 2. Agrupar por auditoría para enviar al endpoint de sincronización
    final Map<String, List<Map<String, dynamic>>> gruposPorAuditoria = {};
    for (var p in pendientes) {
      final audId = p['auditoria_id'] as String;
      gruposPorAuditoria.putIfAbsent(audId, () => []).add(p);
    }

    int sincronizadosConfirmados = 0;

    for (var entry in gruposPorAuditoria.entries) {
      final String audId = entry.key;
      final List<Map<String, dynamic>> items = entry.value;

      final payload = {
        'auditoria_id': audId,
        'detalles': items.map((row) => {
          'id': row['id'], // local UUID v4
          'auditoria_id': row['auditoria_id'],
          'activo_id': row['activo_id'],
          'codigo_qr_escaneado': row['codigo_qr_escaneado'],
          'estado': row['estado'],
          'observacion': row['observacion'],
          'fecha_escaneo': row['fecha_escaneo'],
        }).toList(),
      };

      try {
        final response = await _apiClient.post(
          '${ApiConstants.auditoriasEndpoint}/sync',
          payload,
        );

        if (response is Map && response.containsKey('message')) {
          final idsConfirmados = items.map((i) => i['id'] as String).toList();

          // Transacción por lotes para marcar sincronizados
          await db.transaction((txn) async {
            final batch = txn.batch();
            for (var id in idsConfirmados) {
              batch.update(
                'escaneos_pendientes',
                {'sincronizado': 1},
                where: 'id = ?',
                whereArgs: [id],
              );
            }
            await batch.commit(noResult: true);
          });

          sincronizadosConfirmados += idsConfirmados.length;
          debugPrint('✅ [Sincronización] Lote de auditoría $audId sincronizado con éxito (${idsConfirmados.length} registros).');
        }
      } catch (e) {
        debugPrint('⚠️ [Sincronización] Fallo al sincronizar lote de auditoría $audId: $e');
        // Los registros quedan intactos con sincronizado = 0 para el siguiente reintento
      }
    }

    // 3. Purgar los ya sincronizados con más de 30 días
    await purgarSincronizadosAntiguos();

    return sincronizadosConfirmados;
  }

  /// Purga escaneos ya sincronizados (sincronizado = 1) con antigüedad mayor a 30 días.
  Future<int> purgarSincronizadosAntiguos() async {
    try {
      final db = await _localDb.database;
      final limiteUtc = DateTime.now().toUtc().subtract(const Duration(days: 30)).toIso8601String();

      final eliminados = await db.delete(
        'escaneos_pendientes',
        where: 'sincronizado = 1 AND fecha_escaneo < ?',
        whereArgs: [limiteUtc],
      );

      if (eliminados > 0) {
        debugPrint('🧹 [SQLite] Purgados $eliminados escaneos antiguos sincronizados (> 30 días).');
      }
      return eliminados;
    } catch (e) {
      debugPrint('Error purgando escaneos antiguos en SQLite: $e');
      return 0;
    }
  }

  /// Retorna la cantidad de escaneos pendientes de sincronizar.
  Future<int> contarPendientes({String? auditoriaId}) async {
    try {
      final db = await _localDb.database;
      final List<Map<String, dynamic>> res;
      if (auditoriaId != null && auditoriaId.isNotEmpty) {
        res = await db.rawQuery(
          'SELECT COUNT(*) as count FROM escaneos_pendientes WHERE auditoria_id = ? AND sincronizado = 0',
          [auditoriaId],
        );
      } else {
        res = await db.rawQuery(
          'SELECT COUNT(*) as count FROM escaneos_pendientes WHERE sincronizado = 0',
        );
      }
      return Sqflite.firstIntValue(res) ?? 0;
    } catch (e) {
      debugPrint('Error contando escaneos pendientes: $e');
      return 0;
    }
  }

  Future<bool> finalizarAuditoria(
    String auditoriaId,
    int totalEncontrados,
  ) async {
    try {
      debugPrint('🏁 Finalizando auditoría: $auditoriaId');
      debugPrint('Total encontrados: $totalEncontrados');
      
      // Sincronizar pendientes antes de finalizar
      await sincronizarPendientes(auditoriaId: auditoriaId);

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
      // 1. Si hay conexión, consultar detalles del servidor
      final response = await _apiClient.get(
        '${ApiConstants.auditoriasEndpoint}/$auditoriaId/detalles',
      );

      List<DetalleAuditoriaModel> detalles = [];
      if (response is List) {
        detalles = (response)
            .map((json) => DetalleAuditoriaModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // 2. Fusionar con escaneos pendientes locales que aún no estén en el servidor
      try {
        final db = await _localDb.database;
        final pendientesRows = await db.query(
          'escaneos_pendientes',
          where: 'auditoria_id = ? AND sincronizado = 0',
          whereArgs: [auditoriaId],
        );

        if (pendientesRows.isNotEmpty) {
          final idsServidor = detalles.map((d) => d.id).toSet();
          for (var r in pendientesRows) {
            final id = r['id'] as String;
            if (!idsServidor.contains(id)) {
              detalles.add(DetalleAuditoriaModel(
                id: id,
                auditoriaId: r['auditoria_id'] as String,
                activoId: (r['activo_id'] ?? '').toString(),
                codigoQrEscaneado: r['codigo_qr_escaneado']?.toString(),
                estado: r['estado'] as String,
                observacion: r['observacion']?.toString(),
                fechaEscaneo: DateTime.parse(r['fecha_escaneo'] as String),
                sincronizado: false,
              ));
            }
          }
        }
      } catch (_) {}

      return detalles;
    } catch (e) {
      debugPrint('⚠️ Error obteniendo detalles de red; cargando de SQLite local: $e');
      // Modo offline: cargar directamente de SQLite
      try {
        final db = await _localDb.database;
        final rows = await db.query(
          'escaneos_pendientes',
          where: 'auditoria_id = ?',
          whereArgs: [auditoriaId],
          orderBy: 'fecha_escaneo ASC',
        );

        return rows.map((r) => DetalleAuditoriaModel(
          id: r['id'] as String,
          auditoriaId: r['auditoria_id'] as String,
          activoId: (r['activo_id'] ?? '').toString(),
          codigoQrEscaneado: r['codigo_qr_escaneado']?.toString(),
          estado: r['estado'] as String,
          observacion: r['observacion']?.toString(),
          fechaEscaneo: DateTime.parse(r['fecha_escaneo'] as String),
          sincronizado: (r['sincronizado'] as int) == 1,
        )).toList();
      } catch (dbErr) {
        debugPrint('Error leyendo escaneos locales de auditoría: $dbErr');
        return [];
      }
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
      debugPrint('Error obteniendo activos escaneados de red; consultando SQLite: $e');
      try {
        final db = await _localDb.database;
        final rows = await db.query(
          'escaneos_pendientes',
          columns: ['activo_id', 'codigo_qr_escaneado'],
          where: 'auditoria_id = ?',
          whereArgs: [auditoriaId],
        );
        return rows
            .map((r) => (r['activo_id'] ?? r['codigo_qr_escaneado'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<bool> eliminarDetalleAuditoria(String detalleId) async {
    try {
      // 1. Eliminar de SQLite
      final db = await _localDb.database;
      await db.delete(
        'escaneos_pendientes',
        where: 'id = ?',
        whereArgs: [detalleId],
      );

      // 2. Intentar eliminar del servidor
      try {
        await _apiClient.delete(
          '${ApiConstants.auditoriasEndpoint}/detalles/$detalleId',
        );
      } catch (e) {
        debugPrint('Nota: detalle eliminado localmente pero no en servidor (offline): $e');
      }

      return true;
    } catch (e) {
      debugPrint('Error eliminando detalle de auditoría: $e');
      return false;
    }
  }

  Future<bool> eliminarDetallesAuditoriaEnLote(List<String> detalleIds) async {
    if (detalleIds.isEmpty) return true;
    
    try {
      // 1. Eliminar de SQLite en una transacción por lotes
      final db = await _localDb.database;
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (var id in detalleIds) {
          batch.delete(
            'escaneos_pendientes',
            where: 'id = ?',
            whereArgs: [id],
          );
        }
        await batch.commit(noResult: true);
      });

      // 2. Intentar eliminar del servidor
      try {
        await _apiClient.post(
          '${ApiConstants.auditoriasEndpoint}/detalles/bulk-delete',
          {'ids': detalleIds},
        );
      } catch (e) {
        debugPrint('Nota: detalles eliminados localmente pero no en servidor (offline): $e');
      }

      return true;
    } catch (e) {
      debugPrint('Error eliminando detalles de auditoría en lote: $e');
      return false;
    }
  }
}
