import 'package:flutter/foundation.dart';
import 'package:inventario_qr_app/core/storage/session_manager.dart';

class ApiConstants {
  // Configuración del servidor Backend (Node.js/Express)
  // Host dinámico configurable: Por defecto IP de la PC en Wi-Fi (10.10.3.5)
  static String get serverHost => SessionManager.getServerHost();

  static String get baseUrl {
    final host = SessionManager.getServerHost().trim();
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    // Si es una URL pública completa (ej: https://mi-api.onrender.com o https://xxxx.loca.lt)
    if (host.startsWith('http://') || host.startsWith('https://')) {
      final clean = host.endsWith('/') ? host.substring(0, host.length - 1) : host;
      return clean.endsWith('/api') ? clean : '$clean/api';
    }
    // Si contiene puerto explícito (ej: 10.10.3.5:3000)
    if (host.contains(':')) {
      return 'http://$host/api';
    }
    // Host estándar por IP en red local
    return 'http://$host:3000/api';
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
