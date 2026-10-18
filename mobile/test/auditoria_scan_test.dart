import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:inventario_qr_app/core/database/local_database.dart';
import 'package:inventario_qr_app/viewmodel/auditoria_viewmodel.dart';
import 'package:inventario_qr_app/models/auditoria_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late AuditoriaViewModel auditoriaVM;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
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
        },
      ),
    );
    LocalDatabase.instance.setDatabaseForTesting(db);
    auditoriaVM = AuditoriaViewModel();
  });

  tearDown(() async {
    await db.close();
  });

  group('Auditoría - Control de duplicados y tiempo de espera', () {
    test('isActivoAuditado detecta correctamente si un activo ya fue registrado en la sesión', () async {
      // Simular auditoría activa en el ViewModel
      auditoriaVM.setAuditoriaActualForTesting(AuditoriaModel(
        id: 'auditoria-test-123',
        ambienteId: 'ambiente-lab-1',
        tecnicoId: 'user-admin-1',
        totalEsperados: 10,
        totalEncontrados: 0,
        totalFaltantes: 10,
        totalNoEsperados: 0,
        estado: 'en_progreso',
        fechaInicio: DateTime.now(),
      ));

      expect(auditoriaVM.isActivoAuditado('activo-cpu-01'), isFalse);
      expect(auditoriaVM.activosAuditadosIds.length, equals(0));

      // Registrar escaneo de 'activo-cpu-01'
      final success = await auditoriaVM.registrarEscaneo('activo-cpu-01', 'presente', null);
      expect(success, isTrue);
      expect(auditoriaVM.escaneosCont, equals(1));
      expect(auditoriaVM.isActivoAuditado('activo-cpu-01'), isTrue);

      // Verificar que el ID queda memorizado en el conjunto de activos auditados
      expect(auditoriaVM.activosAuditadosIds.contains('activo-cpu-01'), isTrue);
      expect(auditoriaVM.isActivoAuditado('activo-cpu-02'), isFalse);

      // Si la UI consulta antes de registrar, puede evitar incrementar el contador indebidamente
      if (!auditoriaVM.isActivoAuditado('activo-cpu-01')) {
        await auditoriaVM.registrarEscaneo('activo-cpu-01', 'presente', null);
      }
      expect(auditoriaVM.escaneosCont, equals(1)); // No incrementó
    });

    test('iniciarAuditoria reinicia los activos auditados y el contador a cero', () async {
      auditoriaVM.setAuditoriaActualForTesting(AuditoriaModel(
        id: 'auditoria-test-123',
        ambienteId: 'ambiente-lab-1',
        tecnicoId: 'user-admin-1',
        totalEsperados: 5,
        totalEncontrados: 0,
        totalFaltantes: 5,
        totalNoEsperados: 0,
        estado: 'en_progreso',
        fechaInicio: DateTime.now(),
      ));

      await auditoriaVM.registrarEscaneo('activo-01', 'presente', null);
      await auditoriaVM.registrarEscaneo('activo-02', 'presente', null);
      expect(auditoriaVM.escaneosCont, equals(2));
      expect(auditoriaVM.activosAuditadosIds.length, equals(2));

      // Al limpiar o iniciar nueva auditoría
      auditoriaVM.reiniciarSesionForTesting();
      expect(auditoriaVM.escaneosCont, equals(0));
      expect(auditoriaVM.activosAuditadosIds.isEmpty, isTrue);
      expect(auditoriaVM.isActivoAuditado('activo-01'), isFalse);
    });
  });
}
