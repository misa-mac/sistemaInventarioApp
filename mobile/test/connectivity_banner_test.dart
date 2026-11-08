import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_qr_app/core/theme/app_theme.dart';
import 'package:inventario_qr_app/core/services/network_connectivity_service.dart';
import 'package:inventario_qr_app/view/widgets/connectivity_banner.dart';

void main() {
  setUp(() {
    NetworkConnectivityService().stopMonitoring();
    NetworkConnectivityService().dismissBannerImmediate();
  });

  tearDown(() {
    NetworkConnectivityService().dismissBannerImmediate();
  });

  Widget buildTestBanner() {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: ConnectivityBanner(),
        ),
      ),
    );
  }

  group('ConnectivityBanner - Estados de barra Offline y Sincronización', () {
    testWidgets('1. Por defecto en estado online la barra está oculta', (tester) async {
      NetworkConnectivityService().dismissBannerImmediate();

      await tester.pumpWidget(buildTestBanner());
      await tester.pumpAndSettle();

      // Debe estar oculta (SizedBox con clave banner_hidden o altura 0)
      expect(find.byKey(const ValueKey('banner_hidden')), findsOneWidget);
      expect(find.textContaining('Sin conexión'), findsNothing);
      expect(find.textContaining('Actualizando'), findsNothing);
      expect(find.textContaining('completada'), findsNothing);
    });

    testWidgets('2. En modo offline muestra "Sin conexión · Modo offline" y botón de refrescar', (tester) async {
      final service = NetworkConnectivityService();
      service.setStatusForTesting(ConnectivityBannerStatus.offline, pendingCount: 0);

      await tester.pumpWidget(buildTestBanner());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('banner_ConnectivityBannerStatus.offline')), findsOneWidget);
      expect(find.text('Sin conexión · Modo offline'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.byKey(const Key('btn_comprobar_conexion')), findsOneWidget);
    });

    testWidgets('3. En modo offline con pendientes muestra cantidad de pendientes', (tester) async {
      final service = NetworkConnectivityService();
      service.setStatusForTesting(ConnectivityBannerStatus.offline, pendingCount: 4);

      await tester.pumpWidget(buildTestBanner());
      await tester.pumpAndSettle();

      expect(find.text('Sin conexión · 4 pendientes'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('4. Al volver el internet cambia a "Actualizando datos..." con spinner', (tester) async {
      final service = NetworkConnectivityService();
      service.setStatusForTesting(ConnectivityBannerStatus.updating);

      await tester.pumpWidget(buildTestBanner());
      await tester.pump();

      expect(find.byKey(const ValueKey('banner_ConnectivityBannerStatus.updating')), findsOneWidget);
      expect(find.textContaining('Actualizando datos'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('5. Al finalizar muestra "¡Actualización completada!" con ícono check', (tester) async {
      final service = NetworkConnectivityService();
      service.setStatusForTesting(ConnectivityBannerStatus.completed);

      await tester.pumpWidget(buildTestBanner());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('banner_ConnectivityBannerStatus.completed')), findsOneWidget);
      expect(find.text('¡Actualización completada!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('6. Desaparición automática tras completarse', (tester) async {
      final service = NetworkConnectivityService();

      await tester.pumpWidget(buildTestBanner());
      await tester.pumpAndSettle();

      // Cambiar a completado mediante setSyncing(false) que programa la desaparición
      service.setSyncing(false);
      await tester.pump();

      expect(find.text('¡Actualización completada!'), findsOneWidget);

      // Avanzar el tiempo 2.6 segundos para que expire el temporizador de cierre
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pumpAndSettle();

      // Ahora debe haber desaparecido y vuelto a estar oculta
      expect(find.byKey(const ValueKey('banner_hidden')), findsOneWidget);
      expect(find.text('¡Actualización completada!'), findsNothing);
    });
  });
}

