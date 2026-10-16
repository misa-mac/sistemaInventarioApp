import 'package:flutter/foundation.dart';

class ApiConstants {
  // Configuración del servidor Backend (Node.js/Express)
  // 1. Teléfono físico por USB: 'localhost' (con 'adb reverse tcp:3000 tcp:3000')
  // 2. Teléfono físico por Wi-Fi: '10.10.3.5' (IP local de la PC)
  // 3. Emulador oficial: '10.0.2.2'
  static const String serverHost = 'localhost';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    return 'http://$serverHost:3000/api';
  }

  // Endpoints oficiales del servidor
  static const String authLoginEndpoint = '/auth/login';
  static const String usuariosEndpoint = '/usuarios';
  static const String activosEndpoint = '/inventory';
  static const String ambientesEndpoint = '/ambientes';
  static const String auditoriasEndpoint = '/auditorias';
  static const String detalleAuditoriaEndpoint = '/auditorias/detalles';
  static const String movimientosEndpoint = '/movimientos';
}
