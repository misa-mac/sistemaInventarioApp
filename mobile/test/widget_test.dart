import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_qr_app/view/widgets/floating_bottom_nav_bar.dart';

void main() {
  testWidgets('App smoke test: roles and nav items', (WidgetTester tester) async {
    final tecnicoItems = FloatingBottomNavBar.getItemsForRole('tecnico');
    expect(tecnicoItems.length, equals(2));

    final auditorItems = FloatingBottomNavBar.getItemsForRole('auditor');
    expect(auditorItems.length, equals(3));

    final adminItems = FloatingBottomNavBar.getItemsForRole('admin');
    expect(adminItems.length, equals(4));
  });
}
