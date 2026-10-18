import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/core/theme/app_theme.dart';
import 'package:inventario_qr_app/core/storage/session_manager.dart';
import 'package:inventario_qr_app/models/usuario_model.dart';
import 'package:inventario_qr_app/viewmodel/auth_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/auditoria_viewmodel.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:inventario_qr_app/viewmodel/solicitud_viewmodel.dart';
import 'package:inventario_qr_app/view/screens/main_screen.dart';
import 'package:inventario_qr_app/view/widgets/floating_bottom_nav_bar.dart';
import 'package:inventario_qr_app/view/widgets/error_state.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    // Configurar sesión de prueba con rol admin
    SessionManager.setMockSession(
      token: 'jwt-test-token',
      usuario: UsuarioModel(
        id: 'admin-1',
        email: 'admin@itbm.edu.bo',
        nombreCompleto: 'Administrador ITBM',
        rol: 'admin',
        activo: true,
      ),
    );
  });

  Widget createTestApp({
    double textScaleFactor = 1.0,
    double bottomPadding = 0.0,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => AmbienteViewModel()),
        ChangeNotifierProvider(create: (_) => ActivoViewModel()),
        ChangeNotifierProvider(create: (_) => AuditoriaViewModel()),
        ChangeNotifierProvider(create: (_) => SolicitudViewModel()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScaleFactor),
                padding: EdgeInsets.only(bottom: bottomPadding),
                viewPadding: EdgeInsets.only(bottom: bottomPadding),
              ),
              child: const MainScreen(),
            );
          },
        ),
      ),
    );
  }

  group('FALLA 1: Botón CRUD y Barra Inferior', () {
    testWidgets(
        'El borde inferior del botón CRUD queda por encima del borde superior de la barra (>= 16 dp) en 360x640 con textScaler 1.3',
        (WidgetTester tester) async {
      // Configurar pantalla pequeña de 360x640 dp
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Renderizar app con navegación por gestos (bottomPadding = 24) y texto al 130 %
      await tester.pumpWidget(createTestApp(
        textScaleFactor: 1.3,
        bottomPadding: 24.0,
      ));
      await tester.pumpAndSettle();

      // Navegar a la pestaña 'Gestión' (index 2 para admin)
      final gestionTabFinder = find.bySemanticsLabel('Gestión');
      expect(gestionTabFinder, findsOneWidget);
      await tester.tap(gestionTabFinder);
      await tester.pumpAndSettle();

      // Verificar que el FAB de creación está visible
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      final navBarFinder = find.byType(FloatingBottomNavBar);
      expect(navBarFinder, findsOneWidget);

      // Obtener coordenadas de los rectángulos en pantalla
      final fabRect = tester.getRect(fabFinder);
      final navBarRect = tester.getRect(navBarFinder);

      // Comprobación geométrica estricta:
      // 1. El borde inferior del FAB DEBE quedar por encima del borde superior de la barra
      expect(
        fabRect.bottom < navBarRect.top,
        isTrue,
        reason: 'El FAB (${fabRect.bottom}) no debe solapar la barra (${navBarRect.top})',
      );

      // 2. La separación mínima debe ser de al menos 16 dp
      final separacion = navBarRect.top - fabRect.bottom;
      expect(
        separacion,
        greaterThanOrEqualTo(16.0),
        reason: 'La separación vertical debe ser de al menos 16 dp (actual: $separacion dp)',
      );

      // 3. Verificar etiqueta y color primario #0D47A1
      expect(find.text('Nuevo equipo'), findsOneWidget);
      final fabWidget = tester.widget<FloatingActionButton>(fabFinder);
      expect(fabWidget.backgroundColor, equals(AppColors.primary));
    });

    testWidgets(
        'El botón CRUD respeta la separación de >= 16 dp también con navegación de 3 botones (bottomPadding = 0)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(
        textScaleFactor: 1.0,
        bottomPadding: 0.0, // 3-button navigation
      ));
      await tester.pumpAndSettle();

      // Ir a Gestión
      await tester.tap(find.bySemanticsLabel('Gestión'));
      await tester.pumpAndSettle();

      final fabRect = tester.getRect(find.byType(FloatingActionButton));
      final navBarRect = tester.getRect(find.byType(FloatingBottomNavBar));

      final separacion = navBarRect.top - fabRect.bottom;
      expect(separacion, greaterThanOrEqualTo(16.0));
    });
  });

  group('FALLA 2: Botón Reintentar y Widget ErrorState', () {
    testWidgets(
        'El botón Reintentar no ocupa todo el ancho de pantalla (<= 220 dp, >= 48 dp alto)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: ErrorState(
                titulo: 'Sin conexión',
                error: 'SocketException: Connection refused',
                onRetry: () => retryCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Encontrar el botón Reintentar
      final retryButtonFinder = find.widgetWithText(OutlinedButton, 'Reintentar');
      expect(retryButtonFinder, findsOneWidget);

      final retryRect = tester.getRect(retryButtonFinder);

      // Comprobar que NO ocupa todo el ancho de pantalla (360)
      expect(retryRect.width, lessThan(360.0));
      // Comprobar que está acotado a un máximo de 220 dp
      expect(retryRect.width, lessThanOrEqualTo(220.0));
      // Comprobar altura táctil mínima de 48 dp
      expect(retryRect.height, greaterThanOrEqualTo(48.0));

      // Comprobar que el mensaje muestra la causa real (sin conexión)
      expect(
        find.textContaining('Sin conexión con el servidor'),
        findsOneWidget,
      );

      // Probar tap en reintentar
      await tester.tap(retryButtonFinder);
      expect(retryCalled, isTrue);
    });

    testWidgets('ErrorState muestra causa real de permisos (403 Forbidden)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ErrorState(
              error: 'Error 403: Forbidden - sin permisos',
              onRetry: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No cuentas con los permisos necesarios'),
        findsOneWidget,
      );
    });
  });
}
