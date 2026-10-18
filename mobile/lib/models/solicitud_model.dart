import 'dart:convert';

class SolicitudModel {
  final String id;
  final String tipo; // 'alta', 'edicion', 'baja'
  final String estado; // 'pendiente', 'aprobada', 'rechazada'
  final String? solicitanteId;
  final String? solicitanteNombre;
  final String? solicitanteEmail;
  final String? activoId;
  final String? activoNombre;
  final String? activoCodigo;
  final Map<String, dynamic> datos;
  final String? motivo;
  final String? comentarioRevision;
  final String? revisorNombre;
  final DateTime? revisadoAt;
  final String? activoResultanteId;
  final String? activoResultanteCodigo;
  final DateTime createdAt;
  final bool sincronizado;

  SolicitudModel({
    required this.id,
    required this.tipo,
    this.estado = 'pendiente',
    this.solicitanteId,
    this.solicitanteNombre,
    this.solicitanteEmail,
    this.activoId,
    this.activoNombre,
    this.activoCodigo,
    required this.datos,
    this.motivo,
    this.comentarioRevision,
    this.revisorNombre,
    this.revisadoAt,
    this.activoResultanteId,
    this.activoResultanteCodigo,
    required this.createdAt,
    this.sincronizado = true,
  });

  factory SolicitudModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedDatos = {};
    if (json['datos'] != null) {
      if (json['datos'] is String) {
        try {
          parsedDatos = jsonDecode(json['datos']);
        } catch (_) {}
      } else if (json['datos'] is Map) {
        parsedDatos = Map<String, dynamic>.from(json['datos']);
      }
    }

    final solicitante = json['solicitante'];
    final revisor = json['revisor'];
    final activo = json['activo'];
    final activoRes = json['activo_resultante'];

    return SolicitudModel(
      id: json['id']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'alta',
      estado: json['estado']?.toString() ?? 'pendiente',
      solicitanteId: json['solicitante_id']?.toString(),
      solicitanteNombre: solicitante != null && solicitante is Map ? solicitante['nombre_completo']?.toString() : null,
      solicitanteEmail: solicitante != null && solicitante is Map ? solicitante['email']?.toString() : null,
      activoId: json['activo_id']?.toString(),
      activoNombre: activo != null && activo is Map ? activo['nombre']?.toString() : null,
      activoCodigo: activo != null && activo is Map ? activo['codigo_activo']?.toString() : null,
      datos: parsedDatos,
      motivo: json['motivo']?.toString(),
      comentarioRevision: json['comentario_revision']?.toString(),
      revisorNombre: revisor != null && revisor is Map ? revisor['nombre_completo']?.toString() : null,
      revisadoAt: json['revisado_at'] != null ? DateTime.tryParse(json['revisado_at'].toString()) : null,
      activoResultanteId: json['activo_resultante_id']?.toString(),
      activoResultanteCodigo: activoRes != null && activoRes is Map ? activoRes['codigo_activo']?.toString() : null,
      createdAt: json['created_at'] != null ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()) : DateTime.now(),
      sincronizado: true,
    );
  }

  factory SolicitudModel.fromDbMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedDatos = {};
    if (map['datos'] != null) {
      try {
        parsedDatos = jsonDecode(map['datos'].toString());
      } catch (_) {}
    }

    return SolicitudModel(
      id: map['id']?.toString() ?? '',
      tipo: map['tipo']?.toString() ?? 'alta',
      estado: 'pendiente',
      activoId: map['activo_id']?.toString(),
      datos: parsedDatos,
      motivo: map['motivo']?.toString(),
      createdAt: map['fecha'] != null ? (DateTime.tryParse(map['fecha'].toString()) ?? DateTime.now()) : DateTime.now(),
      sincronizado: (map['sincronizado'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'tipo': tipo,
      'activo_id': activoId,
      'datos': jsonEncode(datos),
      'motivo': motivo,
      'fecha': createdAt.toIso8601String(),
      'sincronizado': sincronizado ? 1 : 0,
    };
  }

  Map<String, dynamic> toApiBody() {
    final body = <String, dynamic>{
      'id': id,
      'tipo': tipo,
      'datos': datos,
    };
    if (activoId != null && activoId!.isNotEmpty) {
      body['activo_id'] = activoId;
    }
    if (motivo != null && motivo!.isNotEmpty) {
      body['motivo'] = motivo;
    }
    return body;
  }
}
