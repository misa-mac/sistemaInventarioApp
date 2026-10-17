import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Servicio de conectividad de red e indicador de sincronización
/// implementado con la biblioteca estándar de Dart (sin añadir dependencias externas).
class NetworkConnectivityService extends ChangeNotifier {
  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();

  factory NetworkConnectivityService() => _instance;

  NetworkConnectivityService._internal() {
    _startMonitoring();
  }

  bool _isConnected = true;
  bool _isSyncing = false;
  int _pendingCount = 0;
  Timer? _timer;

  bool get isConnected => _isConnected;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;

  void updatePendingCount(int count) {
    if (_pendingCount != count) {
      _pendingCount = count;
      notifyListeners();
    }
  }

  void setSyncing(bool syncing) {
    if (_isSyncing != syncing) {
      _isSyncing = syncing;
      notifyListeners();
    }
  }

  void _startMonitoring() {
    checkConnection();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      checkConnection();
    });
  }

  Future<void> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      final connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (_isConnected != connected) {
        _isConnected = connected;
        notifyListeners();
      }
    } catch (_) {
      if (_isConnected) {
        _isConnected = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
