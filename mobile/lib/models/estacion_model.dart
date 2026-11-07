import 'dart:convert';
import 'activo_model.dart';

class EstacionModel {
  final String id;
  final String codigoEstacion;
  final String ambienteId;
  final String? ambienteNombre;
  final String? ambienteUbicacion;
  final String? descripcion;
  final List<ActivoModel> componentes;

  EstacionModel({
    required this.id,
    required this.codigoEstacion,
    required this.ambienteId,
    this.ambienteNombre,
    this.ambienteUbicacion,
    this.descripcion,
    this.componentes = const [],
  });

  factory EstacionModel.fromJson(Map<String, dynamic> json) {
    String? ambNom;
    String? ambUbic;
    if (json['ambiente'] != null && json['ambiente'] is Map) {
      ambNom = json['ambiente']['nombre'];
      ambUbic = json['ambiente']['ubicacion'];
    } else {
      ambNom = json['ambiente_nombre'] ?? json['ambienteNombre'];
      ambUbic = json['ambiente_ubicacion'] ?? json['ambienteUbicacion'];
    }

    List<ActivoModel> comps = [];
    final rawComps = json['activos'] ?? json['componentes'];
    if (rawComps is List) {
      comps = rawComps.map((c) => ActivoModel.fromJson(c as Map<String, dynamic>)).toList();
    } else if (json['activos_json'] != null && json['activos_json'] is String) {
      try {
        final decoded = jsonDecode(json['activos_json']);
        if (decoded is List) {
          comps = decoded.map((c) => ActivoModel.fromJson(c as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
    }

    return EstacionModel(
      id: json['id']?.toString() ?? '',
      codigoEstacion: json['codigo_estacion']?.toString() ?? json['codigoEstacion']?.toString() ?? '',
      ambienteId: json['ambiente_id']?.toString() ?? json['ambienteId']?.toString() ?? '',
      ambienteNombre: ambNom,
      ambienteUbicacion: ambUbic,
      descripcion: json['descripcion']?.toString(),
      componentes: comps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_estacion': codigoEstacion,
      'ambiente_id': ambienteId,
      'ambiente_nombre': ambienteNombre,
      'ambiente_ubicacion': ambienteUbicacion,
      'descripcion': descripcion,
      'activos': componentes.map((c) => c.toJson()).toList(),
    };
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'codigo_estacion': codigoEstacion,
      'ambiente_id': ambienteId,
      'ambiente_nombre': ambienteNombre,
      'ambiente_ubicacion': ambienteUbicacion,
      'descripcion': descripcion,
      'activos_json': jsonEncode(componentes.map((c) => c.toJson()).toList()),
    };
  }
}

