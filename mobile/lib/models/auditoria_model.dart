class AuditoriaModel {
  final String id;
  final String ambienteId;
  final String tecnicoId; // En el esquema unificado se llama auditor_id
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final int totalEsperados;
  final int totalEncontrados;
  final int totalFaltantes;
  final int totalNoEsperados;
  final String estado; // en_progreso, completada, cancelada
  final String? observaciones;
  final List<DetalleAuditoriaModel> detalles;

  AuditoriaModel({
    required this.id,
    required this.ambienteId,
    required this.tecnicoId,
    required this.fechaInicio,
    this.fechaFin,
    required this.totalEsperados,
    required this.totalEncontrados,
    this.totalFaltantes = 0,
    this.totalNoEsperados = 0,
    this.estado = 'en_progreso',
    this.observaciones,
    this.detalles = const [],
  });

  factory AuditoriaModel.fromJson(Map<String, dynamic> json) {
    return AuditoriaModel(
      id: json['id'] ?? '',
      ambienteId: json['ambiente_id'] ?? '',
      tecnicoId: json['auditor_id'] ?? json['tecnico_id'] ?? '',
      fechaInicio: DateTime.tryParse(json['fecha_inicio'] ?? '') ?? DateTime.now(),
      fechaFin: json['fecha_fin'] != null ? DateTime.tryParse(json['fecha_fin']) : null,
      totalEsperados: json['total_esperados'] ?? 0,
      totalEncontrados: json['total_encontrados'] ?? 0,
      totalFaltantes: json['total_faltantes'] ?? 0,
      totalNoEsperados: json['total_no_esperados'] ?? 0,
      estado: json['estado'] ?? 'en_progreso',
      observaciones: json['observaciones'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'ambiente_id': ambienteId,
      'auditor_id': tecnicoId,
      'tecnico_id': tecnicoId,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'total_esperados': totalEsperados,
      'total_encontrados': totalEncontrados,
      'total_faltantes': totalFaltantes,
      'total_no_esperados': totalNoEsperados,
      'estado': estado,
      'observaciones': observaciones,
    };
    
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }
}

class DetalleAuditoriaModel {
  final String id;
  final String auditoriaId;
  final String activoId;
  final String? codigoQrEscaneado;
  final String estado; // presente, faltante, no_esperado
  final String? observacion;
  final DateTime fechaEscaneo;
  final bool sincronizado;

  DetalleAuditoriaModel({
    required this.id,
    required this.auditoriaId,
    required this.activoId,
    this.codigoQrEscaneado,
    required this.estado,
    this.observacion,
    required this.fechaEscaneo,
    this.sincronizado = true,
  });

  factory DetalleAuditoriaModel.fromJson(Map<String, dynamic> json) {
    return DetalleAuditoriaModel(
      id: json['id'] ?? '',
      auditoriaId: json['auditoria_id'] ?? '',
      activoId: json['activo_id'] ?? '',
      codigoQrEscaneado: json['codigo_qr_escaneado'],
      estado: json['estado'] ?? 'presente',
      observacion: json['observacion'],
      fechaEscaneo: DateTime.tryParse(json['fecha_escaneo'] ?? '') ?? DateTime.now(),
      sincronizado: json['sincronizado'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'auditoria_id': auditoriaId,
      'activo_id': activoId,
      'estado': estado,
      'observacion': observacion,
      'fecha_escaneo': fechaEscaneo.toIso8601String(),
      'sincronizado': sincronizado,
    };
    
    if (codigoQrEscaneado != null && codigoQrEscaneado!.isNotEmpty) {
      json['codigo_qr_escaneado'] = codigoQrEscaneado;
    }
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }
}
