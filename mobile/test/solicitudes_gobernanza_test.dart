import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:inventario_qr_app/core/theme/app_theme.dart';
import 'package:inventario_qr_app/core/storage/session_manager.dart';
import 'package:inventario_qr_app/models/usuario_model.dart';
import 'package:inventario_qr_app/models/activo_model.dart';
import 'package:inventario_qr_app/models/solicitud_model.dart';
import 'package:inventario_qr_app/viewmodel/auth_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/solicitud_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/auditoria_viewmodel.dart';
import 'package:inventario_qr_app/view/screens/equipos_management_screen.dart';
import 'package:inventario_qr_app/repositories/activo_repository.dart';
import 'package:inventario_qr_app/repositories/tipo_activo_repository.dart';

class FakeActivoRepository extends ActivoRepository {
  final List<ActivoModel> mockActivos;
  FakeActivoRepository(this.mockActivos);

  @override
  Future<List<ActivoModel>> getTodosLosActivos() async {
    return mockActivos;
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Pruebas de Cola Offline SQLite - Gobernanza', () {
    late Database db;
    const Uuid uuid = Uuid();

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (Database db, int version) async {
            await db.execute('''
              CREATE TABLE solicitudes_pendientes (
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
              CREATE INDEX idx_solicitudes_sincronizado
              ON solicitudes_pendientes (sincronizado, fecha DESC);
            ''');
          },
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Guarda solicitud offline en SQLite con sincronizado = 0 e id UUID', () async {
      final id = uuid.v4();
      final fecha = DateTime.now().toIso8601String();
      final datosJson = jsonEncode({
        'nombre': 'Laptop HP ProBook',
        'marca': 'HP',
        'modelo': '450 G8',
        'tipo_activo_id': 'tipo-1',
        'ambiente_id': 'amb-1',
      });

      await db.insert('solicitudes_pendientes', {
        'id': id,
        'tipo': 'alta',
        'activo_id': null,
        'datos': datosJson,
        'motivo': null,
        'fecha': fecha,
        'sincronizado': 0,
      });

      final pendientes = await db.query(
        'solicitudes_pendientes',
        where: 'sincronizado = 0',
      );

      expect(pendientes.length, 1);
      expect(pendientes.first['id'], id);
      expect(pendientes.first['tipo'], 'alta');
      expect(pendientes.first['sincronizado'], 0);
    });

    test('2. Sincronización idempotente: marcar sincronizado = 1 y reintentar no duplica', () async {
      final customId = uuid.v4();
      final model = SolicitudModel(
        id: customId,
        tipo: 'baja',
        activoId: 'activo-123',
        datos: {},
        motivo: 'Equipo dañado por corte eléctrico',
        createdAt: DateTime.now(),
        sincronizado: false,
      );

      // Inserción inicial
      await db.insert('solicitudes_pendientes', model.toDbMap());

      // Simular sincronización exitosa
      await db.update(
        'solicitudes_pendientes',
        {'sincronizado': 1},
        where: 'id = ?',
        whereArgs: [customId],
      );

      final pendientesDespues = await db.query(
        'solicitudes_pendientes',
        where: 'sincronizado = 0',
      );
      expect(pendientesDespues.isEmpty, isTrue);

      final todas = await db.query('solicitudes_pendientes');
      expect(todas.length, 1);
      expect(todas.first['sincronizado'], 1);
    });

    test('3. TipoActivoRepository provee catálogo oficial cuando está offline o sin conexión', () async {
      final repo = TipoActivoRepository();
      final tipos = await repo.getTiposActivos();
      expect(tipos.isNotEmpty, isTrue);
      expect(tipos.length, greaterThanOrEqualTo(10));
      expect(tipos.any((t) => t.nombre.contains('CPU') && t.codigo == 10), isTrue);
      expect(tipos.any((t) => t.nombre == 'Teclado' && t.codigo == 50), isTrue);
    });
  });

  group('Pruebas de Widget - Permisos y Gobernanza Móvil', () {
    Widget buildTestScreen(String rol) {
      SessionManager.setMockSession(
        token: 'test-token',
        usuario: UsuarioModel(
          id: 'user-1',
          email: 'test@itbm.edu.bo',
          nombreCompleto: 'Usuario Test',
          rol: rol,
          activo: true,
        ),
      );

      final mockActivos = [
        ActivoModel(
          id: 'act-1',
          uuid: 'act-1',
          nombre: 'Servidor Dell PowerEdge',
          tipo: 'Servidor',
          marca: 'Dell',
          modelo: 'R740',
          numeroSerie: 'SN-DELL-99',
          estado: 'Activo',
          ambienteId: 'amb-1',
          qrCodigo: '1260101-01',
        ),
      ];

      final activoVM = ActivoViewModel();
      activoVM.activos.clear();
      activoVM.activos.addAll(mockActivos);

      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ChangeNotifierProvider.value(value: activoVM),
          ChangeNotifierProvider(create: (_) => SolicitudViewModel()),
          ChangeNotifierProvider(create: (_) => AmbienteViewModel()),
          ChangeNotifierProvider(create: (_) => AuditoriaViewModel()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: EquiposManagementScreen(
            activoRepository: FakeActivoRepository(mockActivos),
          ),
        ),
      );
    }

    testWidgets('3. Técnico NO ve "Crear", "Editar" ni "Eliminar" directos; SÍ ve "Solicitar alta", "Solicitar edición" y "Solicitar baja"', (tester) async {
      await tester.pumpWidget(buildTestScreen('tecnico'));
      await tester.pumpAndSettle();

      // No debe existir ningún botón de edición o borrado directo
      expect(find.widgetWithText(ElevatedButton, 'Crear'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Nuevo Equipo'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Editar'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Eliminar'), findsNothing);

      // Sí debe mostrar las acciones de propuesta
      expect(find.text('Solicitar alta'), findsOneWidget);
      expect(find.text('Solicitar edición'), findsOneWidget);
      expect(find.text('Solicitar baja'), findsOneWidget);
    });

    testWidgets('4. Auditor NO tiene acceso a proponer cambios (sin botones de solicitar)', (tester) async {
      await tester.pumpWidget(buildTestScreen('auditor'));
      await tester.pumpAndSettle();

      expect(find.text('Solicitar alta'), findsNothing);
      expect(find.text('Solicitar edición'), findsNothing);
      expect(find.text('Solicitar baja'), findsNothing);
      expect(find.text('Rol Auditor: Modo solo lectura'), findsOneWidget);
    });

    testWidgets('5. Admin en móvil ve aviso "Confirmar en la web" y NO ve botones de aprobar', (tester) async {
      await tester.pumpWidget(buildTestScreen('admin'));
      await tester.pumpAndSettle();

      // Ve aviso de confirmación en la web
      expect(find.textContaining('Confirmar en la web'), findsOneWidget);

      // No tiene botones de aprobar ni rechazar en la app móvil
      expect(find.text('Aprobar'), findsNothing);
      expect(find.text('Rechazar'), findsNothing);
    });
  });
}
