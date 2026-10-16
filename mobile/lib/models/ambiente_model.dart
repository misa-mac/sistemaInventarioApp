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
    required this.latitude,
    required this.longitude,
    required this.radioGeofence,
  });

  factory AmbienteModel.fromJson(Map<String, dynamic> json) {
    return AmbienteModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      tieneInternet: json['tiene_internet'] ?? true,
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      radioGeofence: double.tryParse(json['radio_geofence'].toString()) ?? 50.0,
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
