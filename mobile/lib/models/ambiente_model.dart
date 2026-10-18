import 'package:inventario_qr_app/core/services/location_service.dart';

class AmbienteModel {
  final String id;
  final String nombre;
  final String descripcion;
  final bool tieneInternet;
  final double latitude;
  final double longitude;
  final double radioGeofence;

  AmbienteModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tieneInternet,
    required double latitude,
    required double longitude,
    required double radioGeofence,
  })  : latitude = _resolveLatitude(nombre, latitude),
        longitude = _resolveLongitude(nombre, longitude),
        radioGeofence = _resolveRadius(nombre, radioGeofence);

  static double _resolveRadius(String nombre, double radius) {
    final geo = LocationService.findGeofenceForName(nombre);
    if (geo != null) {
      // Si tiene una geocerca oficial asignada, aplicamos su radio oficial (18m, 17m, 22m, etc.)
      return geo.radius;
    }
    return radius > 0 ? radius : 50.0;
  }

  static double _resolveLatitude(String nombre, double lat) {
    if (lat == 0.0) {
      final geo = LocationService.findGeofenceForName(nombre);
      if (geo != null) return geo.lat;
    }
    return lat;
  }

  static double _resolveLongitude(String nombre, double lng) {
    if (lng == 0.0) {
      final geo = LocationService.findGeofenceForName(nombre);
      if (geo != null) return geo.lng;
    }
    return lng;
  }

  factory AmbienteModel.fromJson(Map<String, dynamic> json) {
    final nombre = json['nombre']?.toString() ?? '';
    final lat = double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0;
    final lng = double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0;
    final radius = double.tryParse(json['radio_geofence']?.toString() ?? '') ?? 0.0;

    return AmbienteModel(
      id: json['id']?.toString() ?? '',
      nombre: nombre,
      descripcion: json['descripcion']?.toString() ?? '',
      tieneInternet: json['tiene_internet'] == null ? true : (json['tiene_internet'] == true || json['tiene_internet'] == 1),
      latitude: lat,
      longitude: lng,
      radioGeofence: radius,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'tiene_internet': tieneInternet,
      'latitude': latitude,
      'longitude': longitude,
      'radio_geofence': radioGeofence,
    };
  }
}

