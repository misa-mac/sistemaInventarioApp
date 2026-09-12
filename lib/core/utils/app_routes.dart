import 'package:flutter/material.dart';
import 'package:inventario_qr_app/view/screens/login_screen.dart';
import 'package:inventario_qr_app/view/screens/home_screen.dart';
import 'package:inventario_qr_app/view/screens/auditoria_screen.dart';
import 'package:inventario_qr_app/view/screens/qr_scan_screen.dart';
import 'package:inventario_qr_app/view/screens/resultados_auditoria_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String auditoria = '/auditoria';
  static const String qrScan = '/qr-scan';
  static const String resultadosAuditoria = '/resultados-auditoria';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case auditoria:
        return MaterialPageRoute(builder: (_) => const AuditoriaScreen());
      case qrScan:
        return MaterialPageRoute(builder: (_) => const QrScanScreen());
      case resultadosAuditoria:
        return MaterialPageRoute(builder: (_) => const ResultadosAuditoriaScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Ruta no encontrada')),
          ),
        );
    }
  }
}
