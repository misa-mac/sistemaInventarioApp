/**
 * Matriz Central de Permisos (Fuente Única de Verdad - RBAC)
 * Roles del sistema (PostgreSQL ENUM 'rol_usuario'): 'admin', 'tecnico', 'auditor'
 */

const PERMISSIONS = {
  // 1. Activos Fijos (Inventario)
  // GET /api/activos, GET /api/activos/:id-o-codigo
  'activos:listar': ['admin', 'tecnico', 'auditor'],
  'activos:ver': ['admin', 'tecnico', 'auditor'],
  // POST /api/activos, PUT /api/activos/:id
  'activos:crear': ['admin'],
  'activos:editar': ['admin'],
  // DELETE /api/activos/:id (solo baja lógica, sin borrado físico)
  'activos:eliminar': ['admin', 'tecnico'],

  // 2. Movimientos (Traslados, Mantenimientos y Bajas)
  // GET /api/movimientos
  'movimientos:listar': ['admin', 'tecnico', 'auditor'],
  // POST /api/movimientos (inferido)
  'movimientos:crear': ['admin', 'tecnico'],
  // POST /api/movimientos/:id/revertir (inferido)
  'movimientos:revertir': ['admin'],

  // 3. Ambientes
  // GET /api/ambientes
  'ambientes:listar': ['admin', 'tecnico', 'auditor'],
  'ambientes:ver': ['admin', 'tecnico', 'auditor'],
  // POST /api/ambientes, PUT /api/ambientes/:id, DELETE /api/ambientes/:id (inferido)
  'ambientes:crear': ['admin'],
  'ambientes:editar': ['admin'],
  'ambientes:eliminar': ['admin'],

  // 4. Tipos de Activos (Catálogos)
  // GET /api/tipos-activos (inferido)
  'tipos:listar': ['admin', 'tecnico', 'auditor'],
  'tipos:ver': ['admin', 'tecnico', 'auditor'],
  // POST/PUT/DELETE (inferido)
  'tipos:crear': ['admin'],
  'tipos:editar': ['admin'],
  'tipos:eliminar': ['admin'],

  // 5. Gestión de Usuarios y Roles
  // /api/usuarios (inferido)
  'usuarios:gestionar': ['admin'],

  // 6. Auditorías Físicas (App Móvil / Web)
  // POST /api/auditorias
  'auditorias:iniciar': ['admin', 'auditor'],
  // GET /api/auditorias (inferido)
  'auditorias:listar': ['admin', 'auditor'],
  'auditorias:ver': ['admin', 'auditor'],
  // POST /api/auditorias/:id/detalle, PATCH /api/auditorias/:id/finalizar, POST /api/auditorias/sync
  // (auditor solo en auditorías propias)
  'auditorias:detalle': ['admin', 'auditor'],
  'auditorias:finalizar': ['admin', 'auditor'],
  'auditorias:sync': ['admin', 'auditor'],

  // 7. Reportes (PDF y Excel)
  // GET /api/reportes (o /api/reports)
  'reportes:ver': ['admin', 'auditor'],

  // 8. Notificaciones
  // /api/notificaciones (inferido)
  'notificaciones:ver': ['admin', 'tecnico', 'auditor'],
  'notificaciones:marcar': ['admin', 'tecnico', 'auditor'],

  // 9. Registro de Acciones (audit_logs - OWASP A09)
  // GET /api/audit-logs (inferido)
  'audit_logs:listar': ['admin'],
  'audit_logs:crear': ['admin', 'tecnico', 'auditor']
};

module.exports = { PERMISSIONS };
