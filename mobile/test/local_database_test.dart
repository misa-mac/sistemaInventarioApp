import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

void main() {
  // Inicializar motor FFI de SQLite para ejecución de pruebas en memoria
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  const Uuid uuid = Uuid();

  setUp(() async {
    // Crear base de datos fresca en memoria para cada prueba
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          // Tabla escaneos_pendientes
          await db.execute('''
            CREATE TABLE escaneos_pendientes (
              id TEXT PRIMARY KEY,
              auditoria_id TEXT NOT NULL,
              activo_id TEXT,
              codigo_qr_escaneado TEXT NOT NULL,
              estado TEXT NOT NULL,
              observacion TEXT,
              fecha_escaneo TEXT NOT NULL,
              sincronizado INTEGER NOT NULL DEFAULT 0
            );
          ''');

          // Índice compuesto
          await db.execute('''
            CREATE INDEX idx_escaneos_auditoria_sincronizado 
            ON escaneos_pendientes (auditoria_id, sincronizado);
          ''');

          // Tabla cache_ambientes
          await db.execute('''
            CREATE TABLE cache_ambientes (
              id TEXT PRIMARY KEY,
              nombre TEXT NOT NULL,
              descripcion TEXT,
              tiene_internet INTEGER NOT NULL DEFAULT 1,
              latitude REAL NOT NULL DEFAULT 0.0,
              longitude REAL NOT NULL DEFAULT 0.0,
              radio_geofence REAL NOT NULL DEFAULT 50.0
            );
          ''');

          // Tabla cache_activos
          await db.execute('''
            CREATE TABLE cache_activos (
              id TEXT PRIMARY KEY,
              uuid TEXT,
              nombre TEXT,
              tipo TEXT,
              marca TEXT,
              modelo TEXT,
              numero_serie TEXT,
              estado TEXT,
              ambiente_id TEXT NOT NULL,
              ambiente_registro_id TEXT,
              codigo_activo TEXT,
              imagen_url TEXT,
              observaciones TEXT,
              numero_correlativo INTEGER
            );
          ''');

          await db.execute('''
            CREATE INDEX idx_cache_activos_ambiente_id 
            ON cache_activos (ambiente_id);
          ''');
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Pruebas SQLite - Tabla escaneos_pendientes', () {
    test('1. Insertar escaneos pendientes con UUID v4 y fecha UTC', () async {
      final id = uuid.v4();
      final fechaUtc = DateTime.now().toUtc().toIso8601String();

      await db.insert('escaneos_pendientes', {
        'id': id,
        'auditoria_id': 'aud-001',
        'activo_id': 'act-101',
        'codigo_qr_escaneado': '1500101-01',
        'estado': 'presente',
        'observacion': 'En buen estado',
        'fecha_escaneo': fechaUtc,
        'sincronizado': 0,
      });

      final rows = await db.query(
        'escaneos_pendientes',
        where: 'id = ?',
        whereArgs: [id],
      );

      expect(rows.length, equals(1));
      expect(rows.first['id'], equals(id));
      expect(rows.first['sincronizado'], equals(0));
      expect(rows.first['estado'], equals('presente'));
      expect(rows.first['fecha_escaneo'], equals(fechaUtc));
    });

    test('2. Listar pendientes filtrados por auditoria_id', () async {
      const aud1 = 'aud-aaa';
      const aud2 = 'aud-bbb';

      // Insertar en auditoría 1
      await db.insert('escaneos_pendientes', {
        'id': uuid.v4(),
        'auditoria_id': aud1,
        'activo_id': 'act-1',
        'codigo_qr_escaneado': 'QR-1',
        'estado': 'presente',
        'fecha_escaneo': DateTime.now().toUtc().toIso8601String(),
        'sincronizado': 0,
      });
      await db.insert('escaneos_pendientes', {
        'id': uuid.v4(),
        'auditoria_id': aud1,
        'activo_id': 'act-2',
        'codigo_qr_escaneado': 'QR-2',
        'estado': 'faltante',
        'fecha_escaneo': DateTime.now().toUtc().toIso8601String(),
        'sincronizado': 0,
      });

      // Insertar en auditoría 2
      await db.insert('escaneos_pendientes', {
        'id': uuid.v4(),
        'auditoria_id': aud2,
        'activo_id': 'act-3',
        'codigo_qr_escaneado': 'QR-3',
        'estado': 'no_esperado',
        'fecha_escaneo': DateTime.now().toUtc().toIso8601String(),
        'sincronizado': 0,
      });

      final pendientesAud1 = await db.query(
        'escaneos_pendientes',
        where: 'auditoria_id = ? AND sincronizado = 0',
        whereArgs: [aud1],
      );

      expect(pendientesAud1.length, equals(2));

      final pendientesAud2 = await db.query(
        'escaneos_pendientes',
        where: 'auditoria_id = ? AND sincronizado = 0',
        whereArgs: [aud2],
      );

      expect(pendientesAud2.length, equals(1));
    });

    test('3. Marcar escaneos como sincronizados (sincronizado = 1)', () async {
      final id1 = uuid.v4();
      final id2 = uuid.v4();

      await db.insert('escaneos_pendientes', {
        'id': id1,
        'auditoria_id': 'aud-001',
        'activo_id': 'act-1',
        'codigo_qr_escaneado': 'QR-1',
        'estado': 'presente',
        'fecha_escaneo': DateTime.now().toUtc().toIso8601String(),
        'sincronizado': 0,
      });
      await db.insert('escaneos_pendientes', {
        'id': id2,
        'auditoria_id': 'aud-001',
        'activo_id': 'act-2',
        'codigo_qr_escaneado': 'QR-2',
        'estado': 'presente',
        'fecha_escaneo': DateTime.now().toUtc().toIso8601String(),
        'sincronizado': 0,
      });

      // Marcar id1 como sincronizado tras confirmación de servidor
      await db.update(
        'escaneos_pendientes',
        {'sincronizado': 1},
        where: 'id = ?',
        whereArgs: [id1],
      );

      final row1 = (await db.query('escaneos_pendientes', where: 'id = ?', whereArgs: [id1])).first;
      final row2 = (await db.query('escaneos_pendientes', where: 'id = ?', whereArgs: [id2])).first;

      expect(row1['sincronizado'], equals(1));
      expect(row2['sincronizado'], equals(0));
    });

    test('4. Comportamiento de duplicados: se permiten múltiples escaneos del mismo activo sin violación de restricciones', () async {
      const qrMismo = '1500101-99';
      const activoMismo = 'act-99';

      // Primer escaneo
      await db.insert('escaneos_pendientes', {
        'id': uuid.v4(),
        'auditoria_id': 'aud-dups',
        'activo_id': activoMismo,
        'codigo_qr_escaneado': qrMismo,
        'estado': 'presente',
        'fecha_escaneo': DateTime.now().toUtc().toIso8601String(),
        'sincronizado': 0,
      });

      // Segundo escaneo del mismo equipo (por ejemplo escaneado por error o re-escaneado)
      await db.insert('escaneos_pendientes', {
        'id': uuid.v4(),
        'auditoria_id': 'aud-dups',
        'activo_id': activoMismo,
        'codigo_qr_escaneado': qrMismo,
        'estado': 'presente',
        'fecha_escaneo': DateTime.now().toUtc().toIso8601String(),
        'sincronizado': 0,
      });

      final rows = await db.query(
        'escaneos_pendientes',
        where: 'codigo_qr_escaneado = ?',
        whereArgs: [qrMismo],
      );

      // Ambos escaneos se guardan con sus IDs propios sin colisión UNIQUE
      expect(rows.length, equals(2));
    });

    test('5. Falla parcial de sincronización: los no confirmados quedan intactos', () async {
      final idExitoso1 = uuid.v4();
      final idExitoso2 = uuid.v4();
      final idFallido = uuid.v4();

      final items = [
        {'id': idExitoso1, 'auditoria_id': 'aud-part', 'codigo_qr_escaneado': 'Q1', 'estado': 'presente'},
        {'id': idExitoso2, 'auditoria_id': 'aud-part', 'codigo_qr_escaneado': 'Q2', 'estado': 'presente'},
        {'id': idFallido, 'auditoria_id': 'aud-part', 'codigo_qr_escaneado': 'Q3', 'estado': 'presente'},
      ];

      for (var item in items) {
        await db.insert('escaneos_pendientes', {
          ...item,
          'activo_id': item['codigo_qr_escaneado'],
          'fecha_escaneo': DateTime.now().toUtc().toIso8601String(),
          'sincronizado': 0,
        });
      }

      // Supongamos que el servidor solo confirma idExitoso1 e idExitoso2
      final confirmadosServidor = [idExitoso1, idExitoso2];

      await db.transaction((txn) async {
        final batch = txn.batch();
        for (var cid in confirmadosServidor) {
          batch.update(
            'escaneos_pendientes',
            {'sincronizado': 1},
            where: 'id = ?',
            whereArgs: [cid],
          );
        }
        await batch.commit(noResult: true);
      });

      // El fallido debe permanecer como pendiente (sincronizado = 0)
      final pendientes = await db.query(
        'escaneos_pendientes',
        where: 'sincronizado = 0',
      );

      expect(pendientes.length, equals(1));
      expect(pendientes.first['id'], equals(idFallido));
    });

    test('6. Purgar escaneos sincronizados con más de 30 días de antigüedad', () async {
      final ahora = DateTime.now().toUtc();
      final fechaAntigua = ahora.subtract(const Duration(days: 45)).toIso8601String();
      final fechaReciente = ahora.subtract(const Duration(days: 5)).toIso8601String();

      // Sincronizado antiguo (> 30 días) -> Debe ser purgado
      await db.insert('escaneos_pendientes', {
        'id': uuid.v4(),
        'auditoria_id': 'aud-old',
        'activo_id': 'act-old',
        'codigo_qr_escaneado': 'Q-OLD',
        'estado': 'presente',
        'fecha_escaneo': fechaAntigua,
        'sincronizado': 1,
      });

      // Sincronizado reciente (< 30 días) -> Debe mantenerse
      await db.insert('escaneos_pendientes', {
        'id': uuid.v4(),
        'auditoria_id': 'aud-recent',
        'activo_id': 'act-rec',
        'codigo_qr_escaneado': 'Q-REC',
        'estado': 'presente',
        'fecha_escaneo': fechaReciente,
        'sincronizado': 1,
      });

      // Pendiente antiguo (> 30 días pero no sincronizado) -> NUNCA debe ser purgado
      final idPendienteAntiguo = uuid.v4();
      await db.insert('escaneos_pendientes', {
        'id': idPendienteAntiguo,
        'auditoria_id': 'aud-old',
        'activo_id': 'act-pend',
        'codigo_qr_escaneado': 'Q-PEND',
        'estado': 'presente',
        'fecha_escaneo': fechaAntigua,
        'sincronizado': 0,
      });

      final limite30Dias = ahora.subtract(const Duration(days: 30)).toIso8601String();

      final borrados = await db.delete(
        'escaneos_pendientes',
        where: 'sincronizado = 1 AND fecha_escaneo < ?',
        whereArgs: [limite30Dias],
      );

      expect(borrados, equals(1));

      final restantes = await db.query('escaneos_pendientes');
      expect(restantes.length, equals(2));

      // Verificar que el pendiente antiguo sigue intacto
      final siguePendiente = restantes.any((r) => r['id'] == idPendienteAntiguo);
      expect(siguePendiente, isTrue);
    });
  });

  group('Pruebas SQLite - Tablas de caché offline (Ambientes y Activos)', () {
    test('7. Cachear y consultar ambientes en SQLite', () async {
      await db.transaction((txn) async {
        await txn.delete('cache_ambientes');
        final batch = txn.batch();
        batch.insert('cache_ambientes', {
          'id': 'amb-1',
          'nombre': 'Laboratorio de Cómputo 1',
          'descripcion': 'Planta Baja',
          'tiene_internet': 1,
          'latitude': -16.5000,
          'longitude': -68.1500,
          'radio_geofence': 50.0,
        });
        batch.insert('cache_ambientes', {
          'id': 'amb-2',
          'nombre': 'Taller de Redes',
          'descripcion': 'Primer Piso',
          'tiene_internet': 0,
          'latitude': -16.5010,
          'longitude': -68.1510,
          'radio_geofence': 30.0,
        });
        await batch.commit(noResult: true);
      });

      final ambientes = await db.query('cache_ambientes', orderBy: 'nombre ASC');
      expect(ambientes.length, equals(2));
      expect(ambientes.first['nombre'], equals('Laboratorio de Cómputo 1'));
      expect(ambientes.last['tiene_internet'], equals(0));
    });

    test('8. Cachear y consultar activos por ambiente en SQLite', () async {
      const ambId = 'amb-1';

      await db.transaction((txn) async {
        await txn.delete('cache_activos', where: 'ambiente_id = ?', whereArgs: [ambId]);
        final batch = txn.batch();
        batch.insert('cache_activos', {
          'id': 'act-1',
          'uuid': 'uuid-1',
          'nombre': 'Monitor Dell 24"',
          'tipo': 'Monitor',
          'marca': 'Dell',
          'modelo': 'P2419H',
          'numero_serie': 'SN12345',
          'estado': 'Activo',
          'ambiente_id': ambId,
          'codigo_activo': '1500101-01',
          'imagen_url': 'http://img.jpg',
          'observaciones': 'Buen estado',
          'numero_correlativo': 1,
        });
        batch.insert('cache_activos', {
          'id': 'act-2',
          'uuid': 'uuid-2',
          'nombre': 'CPU HP ProDesk',
          'tipo': 'CPU',
          'marca': 'HP',
          'modelo': 'G5',
          'numero_serie': 'HP67890',
          'estado': 'Activo',
          'ambiente_id': ambId,
          'codigo_activo': '1500101-02',
          'numero_correlativo': 2,
        });
        await batch.commit(noResult: true);
      });

      final activos = await db.query(
        'cache_activos',
        where: 'ambiente_id = ?',
        whereArgs: [ambId],
      );

      expect(activos.length, equals(2));
      expect(activos.any((a) => a['codigo_activo'] == '1500101-01'), isTrue);
      expect(activos.any((a) => a['codigo_activo'] == '1500101-02'), isTrue);
    });
  });
}
