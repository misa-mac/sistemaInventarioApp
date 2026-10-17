import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_qr_app/view/widgets/floating_bottom_nav_bar.dart';

void main() {
  Widget buildTestableWidget({
    required String rol,
    int currentIndex = 0,
    ValueChanged<int>? onTap,
    VoidCallback? onScanTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FloatingBottomNavBar(
            rol: rol,
            currentIndex: currentIndex,
            onTap: onTap ?? (_) {},
            onScanTap: onScanTap ?? () {},
          ),
        ),
      ),
    );
  }

  group('FloatingBottomNavBar Widget Tests', () {
    testWidgets('Destinos para rol "tecnico": Inventario | [Escanear] | Perfil',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(rol: 'tecnico', currentIndex: 0));

      // Items list check
      final items = FloatingBottomNavBar.getItemsForRole('tecnico');
      expect(items.length, equals(2));
      expect(items[0].label, equals('Inventario'));
      expect(items[1].label, equals('Perfil'));

      // In widget tree
      expect(find.text('Inventario'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2), findsOneWidget); // active
      expect(find.byIcon(Icons.person_outline), findsOneWidget); // inactive
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);

      // Verify Reportes and Gestión are NOT present for tecnico
      expect(find.text('Reportes'), findsNothing);
      expect(find.text('Gestión'), findsNothing);
    });

    testWidgets(
        'Destinos para rol "auditor": Inventario, Reportes | [Escanear] | Perfil (sobrante a la derecha)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(rol: 'auditor', currentIndex: 0));

      final items = FloatingBottomNavBar.getItemsForRole('auditor');
      expect(items.length, equals(3));
      expect(items[0].label, equals('Inventario'));
      expect(items[1].label, equals('Reportes'));
      expect(items[2].label, equals('Perfil'));

      // Inventario active
      expect(find.text('Inventario'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
      // Inactive outline icons
      expect(find.byIcon(Icons.assessment_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      // QR button
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);

      // Gestión should NOT be present for auditor
      expect(find.text('Gestión'), findsNothing);
    });

    testWidgets(
        'Destinos para rol "admin": Inventario, Reportes | [Escanear] | Gestión, Perfil',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(rol: 'admin', currentIndex: 0));

      final items = FloatingBottomNavBar.getItemsForRole('admin');
      expect(items.length, equals(4));
      expect(items[0].label, equals('Inventario'));
      expect(items[1].label, equals('Reportes'));
      expect(items[2].label, equals('Gestión'));
      expect(items[3].label, equals('Perfil'));

      expect(find.text('Inventario'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
      expect(find.byIcon(Icons.assessment_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    });

    testWidgets('Tapping on a nav item triggers onTap with correct tab index',
        (WidgetTester tester) async {
      int? selectedTab;

      await tester.pumpWidget(buildTestableWidget(
        rol: 'admin',
        currentIndex: 0,
        onTap: (index) {
          selectedTab = index;
        },
      ));

      // Tap on Reportes (index 1)
      await tester.tap(find.byIcon(Icons.assessment_outlined));
      await tester.pumpAndSettle();

      expect(selectedTab, equals(1));
    });

    testWidgets('Tapping center button triggers onScanTap',
        (WidgetTester tester) async {
      bool scanTapped = false;

      await tester.pumpWidget(buildTestableWidget(
        rol: 'tecnico',
        currentIndex: 0,
        onScanTap: () {
          scanTapped = true;
        },
      ));

      await tester.tap(find.byIcon(Icons.qr_code_scanner_rounded));
      await tester.pumpAndSettle();

      expect(scanTapped, isTrue);
    });
  });
}
