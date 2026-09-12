class ActivoModel {
  final String id;
  final String uuid;
  final String nombre;
  final String tipo; // CPU, monitor, teclado, RAM, disco, etc
  final String marca;
  final String modelo;
  final String numeroSerie;
  final String estado; // activo, mantenimiento, baja, no_esperado
  final String ambienteId;
  final String qrCodigo;
  final String? imagenUrl;
  final String? observaciones;

  ActivoModel({
    required this.id,
    required this.uuid,
    required this.nombre,
    required this.tipo,
    required this.marca,
    required this.modelo,
    required this.numeroSerie,
    required this.estado,
    required this.ambienteId,
    required this.qrCodigo,
    this.imagenUrl,
    this.observaciones,
  });

  factory ActivoModel.fromJson(Map<String, dynamic> json) {
    return ActivoModel(
      id: json['id'] ?? '',
      uuid: json['uuid'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? '',
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
      numeroSerie: json['numero_serie'] ?? '',
      estado: json['estado'] ?? 'activo',
      ambienteId: json['ambiente_id'] ?? '',
      qrCodigo: json['qr_codigo'] ?? '',
      imagenUrl: json['imagen_url'],
      observaciones: json['observaciones'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'nombre': nombre,
      'tipo': tipo,
      'marca': marca,
      'modelo': modelo,
      'numero_serie': numeroSerie,
      'estado': estado,
      'ambiente_id': ambienteId,
      'qr_codigo': qrCodigo,
      'imagen_url': imagenUrl,
      'observaciones': observaciones,
    };
  }
}
