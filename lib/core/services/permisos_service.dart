class PermisosService {
  // Definir permisos por rol
  static const Map<String, Map<String, bool>> permisosPorRol = {
    'administrador': {
      'ver_equipos': true,
      'crear_equipos': true,
      'editar_equipos': true,
      'eliminar_equipos': true,
      'ver_auditorias': true,
      'crear_auditorias': true,
    },
    'tecnico': {
      'ver_equipos': true,
      'crear_equipos': true,
      'editar_equipos': true,
      'eliminar_equipos': false,
      'ver_auditorias': false,
      'crear_auditorias': false,
    },
    'auditor': {
      'ver_equipos': true,
      'crear_equipos': false,
      'editar_equipos': false,
      'eliminar_equipos': false,
      'ver_auditorias': true,
      'crear_auditorias': true,
    },
  };

  // Verificar si un rol tiene permisos para una acción
  static bool tienePermiso(String rol, String accion) {
    final permisos = permisosPorRol[rol.toLowerCase()];
    if (permisos == null) return false;
    return permisos[accion] ?? false;
  }

  // Obtener todos los permisos de un rol
  static Map<String, bool> obtenerPermisosDelRol(String rol) {
    return permisosPorRol[rol.toLowerCase()] ?? {};
  }
}
