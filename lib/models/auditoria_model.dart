class AuditoriaModel {
  final String id;
  final String ambienteId;
  final String tecnicoId;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final int totalEsperados;
  final int totalEncontrados;
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
    this.observaciones,
    this.detalles = const [],
  });

  factory AuditoriaModel.fromJson(Map<String, dynamic> json) {
    return AuditoriaModel(
      id: json['id'] ?? '',
      ambienteId: json['ambiente_id'] ?? '',
      tecnicoId: json['tecnico_id'] ?? '',
      fechaInicio: DateTime.tryParse(json['fecha_inicio'] ?? '') ?? DateTime.now(),
      fechaFin: json['fecha_fin'] != null ? DateTime.tryParse(json['fecha_fin']) : null,
      totalEsperados: json['total_esperados'] ?? 0,
      totalEncontrados: json['total_encontrados'] ?? 0,
      observaciones: json['observaciones'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      // NO incluir 'id' si está vacío - dejar que Supabase lo genere
      'ambiente_id': ambienteId,
      'tecnico_id': tecnicoId,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'total_esperados': totalEsperados,
      'total_encontrados': totalEncontrados,
      'observaciones': observaciones,
    };
    
    // Solo incluir 'id' si no está vacío
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
  final String estado; // presente, faltante, no_esperado
  final String? observacion;
  final DateTime fechaEscaneo;

  DetalleAuditoriaModel({
    required this.id,
    required this.auditoriaId,
    required this.activoId,
    required this.estado,
    this.observacion,
    required this.fechaEscaneo,
  });

  factory DetalleAuditoriaModel.fromJson(Map<String, dynamic> json) {
    return DetalleAuditoriaModel(
      id: json['id'] ?? '',
      auditoriaId: json['auditoria_id'] ?? '',
      activoId: json['activo_id'] ?? '',
      estado: json['estado'] ?? 'presente',
      observacion: json['observacion'],
      fechaEscaneo: DateTime.tryParse(json['fecha_escaneo'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'auditoria_id': auditoriaId,
      'activo_id': activoId,
      'estado': estado,
      'observacion': observacion,
      'fecha_escaneo': fechaEscaneo.toIso8601String(),
    };
    
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }
}
