class ActivoModel {
  final String id;
  final String uuid;
  final String nombre;
  final String tipo; // Tipo de activo o nombre de categoría
  final String marca;
  final String modelo;
  final String numeroSerie;
  final String estado; // Activo, Inactivo, Dañado (o activo, mantenimiento, baja)
  final String ambienteId;
  final String? ambienteRegistroId;
  final String qrCodigo; // codigo_activo
  final String? imagenUrl;
  final String? observaciones;
  final int? numeroCorrelativo;

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
    this.ambienteRegistroId,
    required this.qrCodigo,
    this.imagenUrl,
    this.observaciones,
    this.numeroCorrelativo,
  });

  factory ActivoModel.fromJson(Map<String, dynamic> json) {
    // Extraer tipo si viene como objeto { nombre: ... } o string
    String tipoStr = '';
    if (json['tipo'] != null) {
      if (json['tipo'] is Map) {
        tipoStr = json['tipo']['nombre'] ?? '';
      } else {
        tipoStr = json['tipo'].toString();
      }
    }

    return ActivoModel(
      id: json['id'] ?? '',
      uuid: json['uuid'] ?? json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo: tipoStr,
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
      numeroSerie: json['numero_serie'] ?? '',
      estado: json['estado'] ?? 'Activo',
      ambienteId: json['ambiente_id'] ?? '',
      ambienteRegistroId: json['ambiente_registro_id'],
      qrCodigo: json['codigo_activo'] ?? json['qr_codigo'] ?? '',
      imagenUrl: json['imagen_url'] ?? json['imagen'],
      observaciones: json['observaciones'],
      numeroCorrelativo: json['numero_correlativo'] is int ? json['numero_correlativo'] : int.tryParse(json['numero_correlativo']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'nombre': nombre,
      'marca': marca,
      'modelo': modelo,
      'numero_serie': numeroSerie,
      'estado': estado,
      'ambiente_id': ambienteId,
      'codigo_activo': qrCodigo,
      'qr_codigo': qrCodigo,
      'imagen_url': imagenUrl,
      'observaciones': observaciones,
      'tipo': tipo,
    };

    if (uuid.isNotEmpty) {
      json['uuid'] = uuid;
    }
    if (ambienteRegistroId != null && ambienteRegistroId!.isNotEmpty) {
      json['ambiente_registro_id'] = ambienteRegistroId;
    }
    if (id.isNotEmpty) {
      json['id'] = id;
    }

    return json;
  }
}
