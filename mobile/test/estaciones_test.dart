import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:inventario_qr_app/models/estacion_model.dart';
import 'package:inventario_qr_app/models/activo_model.dart';
import 'package:inventario_qr_app/viewmodel/auditoria_viewmodel.dart';
import 'package:inventario_qr_app/core/database/local_database.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Sistema Híbrido de QR - Pruebas Estación de Trabajo (Mesa)', () {
    test('1. Deserialización de EstacionModel con 4 componentes asociados', () {
      final json = {
        'id': 'est-001',
        'codigo_estacion': 'EST-LAB1-05',
        'ambiente_id': 'amb-lab1',
        'descripcion': 'Mesa 5 Laboratorio 1',
        'ambiente': {
          'id': 'amb-lab1',
          'nombre': 'Laboratorio 1',
          'ubicacion': 'Bloque A',
        },
        'activos': [
          {
            'id': 'cpu-1',
            'codigo_activo': '1261020-01',
            'nombre': 'CPU HP ProDesk',
            'tipo': 'CPU',
            'marca': 'HP',
            'modelo': 'ProDesk 600',
            'numero_serie': 'SN-001',
            'estado': 'Activo',
            'ambiente_id': 'amb-lab1',
          },
          {
            'id': 'mon-1',
            'codigo_activo': '1262020-01',
            'nombre': 'Monitor Samsung 24',
            'tipo': 'Monitor',
            'marca': 'Samsung',
            'modelo': 'T350',
            'numero_serie': 'SN-002',
            'estado': 'Activo',
            'ambiente_id': 'amb-lab1',
          },
          {
            'id': 'tec-1',
            'codigo_activo': '1263020-01',
            'nombre': 'Teclado Genius USB',
            'tipo': 'Teclado',
            'marca': 'Genius',
            'modelo': 'KB-101',
            'numero_serie': 'SN-003',
            'estado': 'Activo',
            'ambiente_id': 'amb-lab1',
          },
          {
            'id': 'mou-1',
            'codigo_activo': '1264020-01',
            'nombre': 'Mouse Óptico Logitech',
            'tipo': 'Mouse',
            'marca': 'Logitech',
            'modelo': 'M90',
            'numero_serie': 'SN-004',
            'estado': 'Activo',
            'ambiente_id': 'amb-lab1',
          },
        ]
      };

      final estacion = EstacionModel.fromJson(json);

      expect(estacion.id, 'est-001');
      expect(estacion.codigoEstacion, 'EST-LAB1-05');
      expect(estacion.ambienteNombre, 'Laboratorio 1');
      expect(estacion.componentes.length, 4);
      expect(estacion.componentes[0].nombre, 'CPU HP ProDesk');
      expect(estacion.componentes[1].tipo, 'Monitor');
      expect(estacion.componentes[2].marca, 'Genius');
      expect(estacion.componentes[3].qrCodigo, '1264020-01');
    });

    test('2. Guardar y recuperar estación en SQLite offline (cache_estaciones)', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 5,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE cache_estaciones (
              id TEXT PRIMARY KEY,
              codigo_estacion TEXT NOT NULL UNIQUE,
              ambiente_id TEXT NOT NULL,
              ambiente_nombre TEXT,
              ambiente_ubicacion TEXT,
              descripcion TEXT,
              activos_json TEXT
            );
          ''');
        },
      );

      final localDb = LocalDatabase.instance;
      localDb.setDatabaseForTesting(db);

      final estacion = EstacionModel(
        id: 'est-offline-99',
        codigoEstacion: 'EST-LAB2-12',
        ambienteId: 'amb-lab2',
        ambienteNombre: 'Laboratorio 2',
        descripcion: 'Mesa 12 redes',
        componentes: [
          ActivoModel(
            id: 'act-1',
            uuid: 'act-1',
            nombre: 'CPU Dell',
            tipo: 'CPU',
            marca: 'Dell',
            modelo: 'OptiPlex',
            numeroSerie: 'SN-999',
            estado: 'Activo',
            ambienteId: 'amb-lab2',
            qrCodigo: '1261021-01',
          ),
        ],
      );

      // Guardar
      await localDb.guardarEstaciones([estacion.toSqliteMap()]);

      // Consultar por código (case insensitive)
      final encontrado = await localDb.getEstacionPorCodigo('est-lab2-12');
      expect(encontrado, isNotNull);
      expect(encontrado!['codigo_estacion'], 'EST-LAB2-12');
      expect(encontrado['ambiente_nombre'], 'Laboratorio 2');

      final recuperada = EstacionModel.fromJson(encontrado);
      expect(recuperada.componentes.length, 1);
      expect(recuperada.componentes.first.nombre, 'CPU Dell');

      await db.close();
    });

    test('3. AuditoriaViewModel: Configuración de conteo (+4 vs +1)', () {
      final vm = AuditoriaViewModel();

      // Por defecto suma por componentes (+4)
      expect(vm.contarPorComponentes, isTrue);

      vm.setModoConteoEstacion(porComponentes: false);
      expect(vm.contarPorComponentes, isFalse);

      vm.setModoConteoEstacion(porComponentes: true);
      expect(vm.contarPorComponentes, isTrue);
    });
  });
}

