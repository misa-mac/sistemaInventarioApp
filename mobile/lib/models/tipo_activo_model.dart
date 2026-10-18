class TipoActivoModel {
  final String id;
  final String nombre;
  final int codigo;
  final String? descripcion;

  TipoActivoModel({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.descripcion,
  });

  factory TipoActivoModel.fromJson(Map<String, dynamic> json) {
    return TipoActivoModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      codigo: json['codigo'] is int 
          ? json['codigo'] 
          : int.tryParse(json['codigo']?.toString() ?? '0') ?? 0,
      descripcion: json['descripcion']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'descripcion': descripcion,
    };
  }
}
