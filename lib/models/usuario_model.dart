class UsuarioModel {
  final String id;
  final String email;
  final String nombreCompleto;
  final String rol; // 'administrador', 'tecnico', 'auditor'
  final bool activo;

  UsuarioModel({
    required this.id,
    required this.email,
    required this.nombreCompleto,
    required this.rol,
    required this.activo,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      rol: json['rol'] ?? 'tecnico',
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre_completo': nombreCompleto,
      'rol': rol,
      'activo': activo,
    };
  }
}
