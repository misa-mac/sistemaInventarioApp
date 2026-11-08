import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:inventario_qr_app/core/constants/api_constants.dart';
import 'package:inventario_qr_app/core/database/local_database.dart';
import 'package:inventario_qr_app/repositories/auditoria_repository.dart';
import 'package:inventario_qr_app/repositories/solicitud_repository.dart';

/// Estados posibles de la barra de conectividad y sincronización
enum ConnectivityBannerStatus {
  /// Oculto: Conectado a la red y sin actividad visible de sincronización
  hidden,

  /// Offline: Sin conexión a internet o al servidor
  offline,

  /// Actualizando: Internet restablecido o sincronizando cambios pendientes
  updating,

  /// Completado: Notifica al usuario que la actualización finalizó con éxito
  completed,
}

/// Servicio de conectividad de red e indicador de sincronización offline -> online
class NetworkConnectivityService extends ChangeNotifier {
  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();

  factory NetworkConnectivityService() => _instance;

  NetworkConnectivityService._internal() {
    _startMonitoring();
  }

  bool _isConnected = true;
  bool _isSyncing = false;
  bool _isChecking = false;
  int _pendingCount = 0;
  ConnectivityBannerStatus _bannerStatus = ConnectivityBannerStatus.hidden;
  String? _statusMessage;

  Timer? _timer;
  Timer? _dismissTimer;

  @visibleForTesting
  bool? mockConnectionCheckResult;

  bool get isConnected => _isConnected;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  ConnectivityBannerStatus get bannerStatus => _bannerStatus;
  String? get statusMessage => _statusMessage;

  /// Consulta SQLite y actualiza el conteo global de pendientes offline
  Future<void> refreshPendingCount() async {
    try {
      final count = await LocalDatabase.instance.getTotalPendientesCount();
      if (_pendingCount != count) {
        _pendingCount = count;
        notifyListeners();
      }
    } catch (_) {}
  }

  void updatePendingCount(int count) {
    if (_pendingCount != count) {
      _pendingCount = count;
      notifyListeners();
    }
  }

  void setSyncing(bool syncing) {
    if (syncing) {
      _dismissTimer?.cancel();
      _isSyncing = true;
      _bannerStatus = ConnectivityBannerStatus.updating;
      _statusMessage = 'Actualizando datos...';
      notifyListeners();
    } else {
      _isSyncing = false;
      _bannerStatus = ConnectivityBannerStatus.completed;
      _statusMessage = '¡Actualización completada!';
      notifyListeners();
      _scheduleDismiss();
    }
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    _dismissTimer?.cancel();
    _dismissTimer = null;
  }

  void _startMonitoring() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    checkConnection();
    // Sondeo rápido cada 2.5 segundos para reaccionar inmediatamente si el usuario apaga Wi-Fi/Datos
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      checkConnection();
    });
  }

  /// Prueba real de conexión a la red mediante sockets TCP directos (no usa DNS lookup falso)
  Future<bool> _probeNetwork() async {
    // 1. Probar conexión TCP a DNS público (8.8.8.8 o 1.1.1.1 en puerto 53)
    // El puerto 53 responde de inmediato. Al ser IP directa sin nombre, NO usa la caché DNS del SO.
    // Si el usuario apagó el Wi-Fi o datos móviles, el kernel de Android rechaza el socket en < 50ms.
    try {
      final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 2));
      socket.destroy();
      return true;
    } catch (_) {}

    try {
      final socket = await Socket.connect('1.1.1.1', 53, timeout: const Duration(seconds: 2));
      socket.destroy();
      return true;
    } catch (_) {}

    // 2. Si fallaron los DNS públicos (ej. en una red local privada/intranet sin salida a internet),
    // probamos el socket TCP directo al servidor backend configurado:
    try {
      final uri = Uri.parse(ApiConstants.baseUrl);
      final host = uri.host;
      final port = uri.port > 0 ? uri.port : 3000;
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 2));
      socket.destroy();
      return true;
    } catch (_) {}

    return false;
  }

  /// Verifica la conexión con el exterior o con el host configurado
  Future<void> checkConnection() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      bool connected = false;
      if (mockConnectionCheckResult != null) {
        connected = mockConnectionCheckResult!;
      } else {
        connected = await _probeNetwork();
      }

      await applyConnectionStatus(connected);
    } finally {
      _isChecking = false;
    }
  }

  /// Aplica el cambio de estado de conexión manejando el ciclo offline -> actualizando -> terminado -> oculto
  Future<void> applyConnectionStatus(bool connected) async {
    final wasOffline = !_isConnected;

    if (!connected) {
      if (_isConnected || _bannerStatus != ConnectivityBannerStatus.offline) {
        _isConnected = false;
        _isSyncing = false;
        _dismissTimer?.cancel();
        _dismissTimer = null;
        _bannerStatus = ConnectivityBannerStatus.offline;
        _statusMessage = 'Modo offline';
        await refreshPendingCount();
        notifyListeners();
      }
      return;
    }

    // Está conectado
    _isConnected = true;
    if (wasOffline || _bannerStatus == ConnectivityBannerStatus.offline) {
      // Regresó el internet: la barra cambia a actualizando hasta que termina y desaparece
      await _performAutoUpdateAndDismiss();
    }
  }

  /// Ejecuta la sincronización al volver el internet, muestra el estado de terminado y programa la desaparición
  Future<void> _performAutoUpdateAndDismiss() async {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    _isSyncing = true;
    _bannerStatus = ConnectivityBannerStatus.updating;
    _statusMessage = 'Conexión restablecida · Actualizando datos...';
    notifyListeners();

    int sincronizados = 0;
    try {
      final results = await Future.wait([
        AuditoriaRepository().sincronizarPendientes().catchError((e) {
          debugPrint('⚠️ Error al sincronizar auditorías: $e');
          return 0;
        }),
        SolicitudRepository().sincronizarPendientes().catchError((e) {
          debugPrint('⚠️ Error al sincronizar solicitudes: $e');
          return 0;
        }),
      ]);
      sincronizados = results[0] + results[1];

      // Esperar brevemente para que el usuario pueda apreciar visualmente la transición
      await Future.delayed(const Duration(milliseconds: 1400));
    } catch (e) {
      debugPrint('⚠️ Error durante la actualización automática: $e');
    }

    // Si durante la sincronización volvió a perder conexión, se respeta el nuevo estado offline
    if (!_isConnected) return;

    await refreshPendingCount();

    // Notificar que la actualización terminó
    _isSyncing = false;
    _bannerStatus = ConnectivityBannerStatus.completed;
    _statusMessage = sincronizados > 0
        ? '¡Actualización completada! ($sincronizados cambios)'
        : '¡Actualización completada!';
    notifyListeners();

    // Programar desaparición automática de la barra tras 2.5 segundos
    _scheduleDismiss();
  }

  void _scheduleDismiss({Duration duration = const Duration(milliseconds: 2500)}) {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(duration, () {
      if (_isConnected && _bannerStatus == ConnectivityBannerStatus.completed) {
        _bannerStatus = ConnectivityBannerStatus.hidden;
        _statusMessage = null;
        notifyListeners();
      }
    });
  }

  @visibleForTesting
  void setStatusForTesting(ConnectivityBannerStatus status, {int? pendingCount, String? message}) {
    _dismissTimer?.cancel();
    _bannerStatus = status;
    if (pendingCount != null) _pendingCount = pendingCount;
    if (message != null) _statusMessage = message;

    switch (status) {
      case ConnectivityBannerStatus.hidden:
        _isConnected = true;
        _isSyncing = false;
        _statusMessage = null;
        break;
      case ConnectivityBannerStatus.offline:
        _isConnected = false;
        _isSyncing = false;
        _statusMessage = 'Modo offline';
        break;
      case ConnectivityBannerStatus.updating:
        _isConnected = true;
        _isSyncing = true;
        _statusMessage ??= 'Conexión restablecida · Actualizando datos...';
        break;
      case ConnectivityBannerStatus.completed:
        _isConnected = true;
        _isSyncing = false;
        _statusMessage ??= '¡Actualización completada!';
        break;
    }
    notifyListeners();
  }

  @visibleForTesting
  void dismissBannerImmediate() {
    _dismissTimer?.cancel();
    _bannerStatus = ConnectivityBannerStatus.hidden;
    _statusMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }
}
