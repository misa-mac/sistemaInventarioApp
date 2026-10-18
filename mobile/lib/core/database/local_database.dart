import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

/// Gestor centralizado y singleton para la base de datos local SQLite (sqflite).
///
/// Implementa un único punto de acceso, esquema versionado (versión 1) y
/// preparación para migraciones futuras mediante [onUpgrade].
class LocalDatabase {
  static const String _dbName = 'inventario_itbm.db';
  static const int _dbVersion = 4;

  // Singleton
  static final LocalDatabase instance = LocalDatabase._internal();
  factory LocalDatabase() => instance;
  LocalDatabase._internal();

  Database? _database;

  /// Retorna la instancia activa de la base de datos o la inicializa.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  /// Permite inyectar una base de datos (por ejemplo en tests con sqflite_common_ffi).
  @visibleForTesting
  void setDatabaseForTesting(Database db) {
    _database = db;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creación inicial del esquema de base de datos.
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('📦 [LocalDatabase] Creando tablas SQLite versión $version...');

    // 1. Tabla de escaneos y auditorías pendientes de sincronizar
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

    // Índice compuesto para acelerar consultas de pendientes por auditoría
    await db.execute('''
      CREATE INDEX idx_escaneos_auditoria_sincronizado 
      ON escaneos_pendientes (auditoria_id, sincronizado);
    ''');

    // 2. Tabla de caché offline para Ambientes
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

    // 3. Tabla de caché offline para Activos por ambiente
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

    // 4. Tabla de solicitudes de cambio pendientes (gobernanza offline)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS solicitudes_pendientes (
        id TEXT PRIMARY KEY,
        tipo TEXT NOT NULL,
        activo_id TEXT,
        datos TEXT NOT NULL,
        motivo TEXT,
        fecha TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_solicitudes_sincronizado
      ON solicitudes_pendientes (sincronizado, fecha DESC);
    ''');

    // 5. Tabla de caché offline para Tipos de Activos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cache_tipos_activos (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        codigo INTEGER NOT NULL,
        descripcion TEXT
      );
    ''');

    debugPrint('✅ [LocalDatabase] Esquema SQLite inicializado con éxito.');
  }

  /// Preparado para futuras migraciones de versión.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 [LocalDatabase] Migrando base de datos de v$oldVersion a v$newVersion...');
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS solicitudes_pendientes (
          id TEXT PRIMARY KEY,
          tipo TEXT NOT NULL,
          activo_id TEXT,
          datos TEXT NOT NULL,
          motivo TEXT,
          fecha TEXT NOT NULL,
          sincronizado INTEGER NOT NULL DEFAULT 0
        );
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_solicitudes_sincronizado
        ON solicitudes_pendientes (sincronizado, fecha DESC);
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_tipos_activos (
          id TEXT PRIMARY KEY,
          nombre TEXT NOT NULL,
          codigo INTEGER NOT NULL,
          descripcion TEXT
        );
      ''');
    }
    if (oldVersion < 4) {
      await db.execute("UPDATE cache_ambientes SET radio_geofence = 18.0, latitude = -16.577738, longitude = -68.196556 WHERE nombre LIKE '%Lab%1%';");
      await db.execute("UPDATE cache_ambientes SET radio_geofence = 17.0, latitude = -16.577660, longitude = -68.196602 WHERE nombre LIKE '%Lab%2%';");
      await db.execute("UPDATE cache_ambientes SET radio_geofence = 22.0, latitude = -16.577892, longitude = -68.196768 WHERE nombre LIKE '%Lab%3%';");
      await db.execute("UPDATE cache_ambientes SET radio_geofence = 18.0, latitude = -16.577840, longitude = -68.196590 WHERE nombre LIKE '%Taller%1%';");
      await db.execute("UPDATE cache_ambientes SET radio_geofence = 18.0, latitude = -16.577850, longitude = -68.196580 WHERE nombre LIKE '%Taller%2%';");
      await db.execute("UPDATE cache_ambientes SET radio_geofence = 15.0, latitude = -16.577785, longitude = -68.196520 WHERE nombre LIKE '%Oficina%';");
    }
  }

  /// Guarda tipos de activos en caché local SQLite
  Future<void> guardarTiposActivos(List<dynamic> tipos) async {
    try {
      final db = await database;
      final batch = db.batch();
      for (final tipo in tipos) {
        batch.insert(
          'cache_tipos_activos',
          {
            'id': tipo.id,
            'nombre': tipo.nombre,
            'codigo': tipo.codigo,
            'descripcion': tipo.descripcion,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Error guardando tipos_activos en SQLite: $e');
    }
  }

  /// Obtiene los tipos de activos cacheados en SQLite
  Future<List<Map<String, dynamic>>> getTiposActivosCache() async {
    try {
      final db = await database;
      return await db.query('cache_tipos_activos', orderBy: 'codigo ASC');
    } catch (e) {
      debugPrint('Error leyendo tipos_activos de SQLite: $e');
      return [];
    }
  }

  /// Limpia la caché temporal de ambientes, activos y tipos.
  Future<void> clearAllCache() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('cache_ambientes');
      await txn.delete('cache_activos');
      await txn.delete('cache_tipos_activos');
    });
    debugPrint('🧹 [LocalDatabase] Tablas de caché limpiadas.');
  }

  /// Cierra la base de datos (útil en teardown de pruebas o reset completo).
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
