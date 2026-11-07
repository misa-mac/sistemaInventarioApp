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

  // Nuevos campos detallados para la ficha técnica completa
  final String? ambienteNombre;
  final String? ambienteUbicacion;
  final String? ambienteRegistroNombre;
  final String? origen;
  final String? especificacionOrigen;
  final String? descripcion;
  final String? responsable;
  final String? fechaIngreso;
  final double? valor;

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
    this.ambienteNombre,
    this.ambienteUbicacion,
    this.ambienteRegistroNombre,
    this.origen,
    this.especificacionOrigen,
    this.descripcion,
    this.responsable,
    this.fechaIngreso,
    this.valor,
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

    // Extraer datos del ambiente actual
    String ambNombre = '';
    String? ambUbicacion;
    if (json['ambiente'] != null && json['ambiente'] is Map) {
      ambNombre = (json['ambiente']['nombre'] ?? '').toString();
      ambUbicacion = json['ambiente']['ubicacion']?.toString();
    } else if (json['ambiente_nombre'] != null) {
      ambNombre = json['ambiente_nombre'].toString();
      ambUbicacion = json['ambiente_ubicacion']?.toString();
    }

    // Extraer datos del ambiente de registro original
    String? ambRegNombre;
    if (json['ambiente_registro'] != null && json['ambiente_registro'] is Map) {
      ambRegNombre = json['ambiente_registro']['nombre']?.toString();
    } else if (json['ambiente_registro_nombre'] != null) {
      ambRegNombre = json['ambiente_registro_nombre']?.toString();
    }

    // Parsear valor numérico
    double? valorNum;
    if (json['valor'] != null) {
      if (json['valor'] is num) {
        valorNum = (json['valor'] as num).toDouble();
      } else {
        valorNum = double.tryParse(json['valor'].toString());
      }
    }

    return ActivoModel(
      id: (json['id'] ?? '').toString(),
      uuid: (json['uuid'] ?? json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      tipo: tipoStr,
      marca: (json['marca'] ?? '').toString(),
      modelo: (json['modelo'] ?? '').toString(),
      numeroSerie: (json['numero_serie'] ?? '').toString(),
      estado: (json['estado'] ?? 'Activo').toString(),
      ambienteId: (json['ambiente_id'] ?? '').toString(),
      ambienteRegistroId: json['ambiente_registro_id']?.toString(),
      qrCodigo: (json['codigo_activo'] ?? json['qr_codigo'] ?? '').toString(),
      imagenUrl: (json['imagen_url'] ?? json['imagen'])?.toString(),
      observaciones: json['observaciones']?.toString(),
      numeroCorrelativo: json['numero_correlativo'] is int
          ? json['numero_correlativo']
          : int.tryParse(json['numero_correlativo']?.toString() ?? ''),
      ambienteNombre: ambNombre.isNotEmpty ? ambNombre : null,
      ambienteUbicacion: ambUbicacion,
      ambienteRegistroNombre: ambRegNombre,
      origen: json['origen']?.toString(),
      especificacionOrigen: json['especificacion_origen']?.toString(),
      descripcion: json['descripcion']?.toString(),
      responsable: json['responsable']?.toString(),
      fechaIngreso: json['fecha_ingreso']?.toString(),
      valor: valorNum,
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
    if (ambienteNombre != null) {
      json['ambiente_nombre'] = ambienteNombre;
    }
    if (ambienteUbicacion != null) {
      json['ambiente_ubicacion'] = ambienteUbicacion;
    }
    if (ambienteRegistroNombre != null) {
      json['ambiente_registro_nombre'] = ambienteRegistroNombre;
    }
    if (origen != null) {
      json['origen'] = origen;
    }
    if (especificacionOrigen != null) {
      json['especificacion_origen'] = especificacionOrigen;
    }
    if (descripcion != null) {
      json['descripcion'] = descripcion;
    }
    if (responsable != null) {
      json['responsable'] = responsable;
    }
    if (fechaIngreso != null) {
      json['fecha_ingreso'] = fechaIngreso;
    }
    if (valor != null) {
      json['valor'] = valor;
    }

    return json;
  }
}
