import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GeofenceParam {
  final String name;
  final double lat;
  final double lng;
  final double radius;

  const GeofenceParam({
    required this.name,
    required this.lat,
    required this.lng,
    required this.radius,
  });
}

class GeofenceCheckResult {
  final bool isInside;
  final double distanceMeters;
  final double radiusMeters;
  final double accuracyMeters;
  final bool accuracyValid;
  final String message;

  const GeofenceCheckResult({
    required this.isInside,
    required this.distanceMeters,
    required this.radiusMeters,
    required this.accuracyMeters,
    required this.accuracyValid,
    required this.message,
  });
}

class LocationService {
  // Regla de validación: If GPS accuracy > 30 meters, ignore and retry.
  static const double maxAccuracyMeters = 30.0;
  static const int defaultMaxRetries = 3;
  static const Duration defaultRetryDelay = Duration(milliseconds: 1000);

  // Parámetros oficiales de geocercas
  static const List<GeofenceParam> officialGeofences = [
    GeofenceParam(name: "Lab 1", lat: -16.577738, lng: -68.196556, radius: 18),
    GeofenceParam(name: "Lab 2", lat: -16.577660, lng: -68.196602, radius: 17),
    GeofenceParam(name: "Lab 3", lat: -16.577892, lng: -68.196768, radius: 22),
    GeofenceParam(name: "Taller 1", lat: -16.577840, lng: -68.196590, radius: 18),
    GeofenceParam(name: "Taller 2", lat: -16.577850, lng: -68.196580, radius: 18),
    GeofenceParam(name: "Oficina", lat: -16.577785, lng: -68.196520, radius: 15),
  ];

  /// Busca la configuración de geocerca por nombre de ambiente (coincidencia flexible)
  static GeofenceParam? findGeofenceForName(String nombre) {
    final lower = nombre.toLowerCase().trim();
    for (final g in officialGeofences) {
      final gLower = g.name.toLowerCase();
      if (lower == gLower || lower.contains(gLower)) {
        return g;
      }
      // Equivalencias de nombres: "Lab 1" <-> "Laboratorio 1"
      if (gLower.startsWith('lab ') && lower.contains('laboratorio ${gLower.substring(4)}')) {
        return g;
      }
      if (gLower == 'oficina' && lower.contains('oficina')) {
        return g;
      }
    }
    return null;
  }

  /// Obtiene la ubicación GPS con verificación estricta de precisión.
  /// Regla: "If GPS accuracy > 30 meters, ignore and retry."
  Future<Position?> getCurrentLocation({
    int maxAttempts = defaultMaxRetries,
    Duration retryDelay = defaultRetryDelay,
  }) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('⚠️ [LocationService] El servicio GPS está deshabilitado.');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('⚠️ [LocationService] Permisos de ubicación denegados.');
      return null;
    }

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 5),
        );

        debugPrint(
          '📍 [LocationService] Intento $attempt/$maxAttempts -> '
          'Lat: ${position.latitude}, Lng: ${position.longitude}, Precisión: ${position.accuracy.toStringAsFixed(1)}m',
        );

        // Validación de regla: si precisión <= 30m, la posición es válida
        if (position.accuracy <= maxAccuracyMeters) {
          debugPrint('✅ [LocationService] Precisión GPS óptima: ${position.accuracy.toStringAsFixed(1)}m <= ${maxAccuracyMeters}m.');
          return position;
        }

        // Si la precisión es mayor a 30 metros, se ignora y se reintenta
        debugPrint(
          '⚠️ [LocationService] Precisión ${position.accuracy.toStringAsFixed(1)}m > ${maxAccuracyMeters}m. '
          'Ignorando lectura y reintentando (intento $attempt de $maxAttempts)...',
        );

        if (attempt < maxAttempts) {
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        debugPrint('⚠️ [LocationService] Excepción en intento $attempt: $e');
        if (attempt < maxAttempts) {
          await Future.delayed(retryDelay);
        }
      }
    }

    debugPrint('❌ [LocationService] No se logró precisión <= ${maxAccuracyMeters}m tras $maxAttempts intentos.');
    return null;
  }

  /// Calcula la distancia entre dos coordenadas en metros
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Comprueba si las coordenadas del usuario están dentro del radio de la geocerca
  bool isInGeofence(double userLat, double userLon, double labLat, double labLon, double radiusMeters) {
    double distance = calculateDistance(userLat, userLon, labLat, labLon);
    return distance <= radiusMeters;
  }

  /// Evaluación completa con precisión y mensaje diagnóstico
  GeofenceCheckResult evaluateGeofence({
    required Position position,
    required double targetLat,
    required double targetLon,
    required double radiusMeters,
    String? ambienteNombre,
  }) {
    final accuracyValid = position.accuracy <= maxAccuracyMeters;
    final distance = calculateDistance(position.latitude, position.longitude, targetLat, targetLon);
    final isInside = distance <= radiusMeters && accuracyValid;

    String message;
    if (!accuracyValid) {
      message = 'Precisión GPS insuficiente (${position.accuracy.toStringAsFixed(1)}m > ${maxAccuracyMeters}m). Acérquese a un área despejada.';
    } else if (isInside) {
      message = 'Dentro de ${ambienteNombre ?? "el ambiente"} (a ${distance.toStringAsFixed(1)}m, radio: ${radiusMeters.toStringAsFixed(0)}m).';
    } else {
      message = 'Fuera de ${ambienteNombre ?? "el ambiente"} (a ${distance.toStringAsFixed(1)}m, radio: ${radiusMeters.toStringAsFixed(0)}m).';
    }

    return GeofenceCheckResult(
      isInside: isInside,
      distanceMeters: distance,
      radiusMeters: radiusMeters,
      accuracyMeters: position.accuracy,
      accuracyValid: accuracyValid,
      message: message,
    );
  }
}
