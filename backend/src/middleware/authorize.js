const { PERMISSIONS } = require('../config/permissions');
const AuditLog = require('../models/AuditLog');
const Auditoria = require('../models/Auditoria');

/**
 * Registra denegación en la tabla inmutable audit_logs (Regla 6 - OWASP A09)
 * Sin registrar tokens ni contraseñas.
 */
const logAccessDenial = async (req, accion, recursoId, razon) => {
  try {
    const recursoPath = req.baseUrl ? `${req.baseUrl}${req.path}` : req.path;
    await AuditLog.create({
      usuario_id: req.user?.id || null,
      accion: 'ACCESO_DENEGADO',
      recurso: recursoPath || 'api',
      recurso_id: recursoId ? String(recursoId) : (req.params?.id || null),
      resultado: 'fallido',
      detalles: razon,
      ip_address: req.ip || req.connection?.remoteAddress || '127.0.0.1',
      user_agent: req.get('User-Agent') || 'Desconocido',
      fecha_hora: new Date()
    });
  } catch (err) {
    console.error('Error al registrar denegación en audit_logs:', err.message);
  }
};

/**
 * Middleware de Autorización RBAC (Regla 1 y 2)
 * @param {string} action - Clave definida en PERMISSIONS
 */
const authorize = (action) => {
  if (!action || !PERMISSIONS[action]) {
    throw new Error(`[SEGURIDAD CRÍTICA] La acción '${action}' no está registrada en PERMISSIONS. Denegado por defecto.`);
  }

  const allowedRoles = PERMISSIONS[action];

  const middleware = async (req, res, next) => {
    // Si req.user no existe, auth middleware no se ejecutó o falló
    if (!req.user) {
      return res.status(401).json({ message: 'Acceso no autenticado.' });
    }

    // Normalizar rol a minúsculas conforme al ENUM ('admin', 'tecnico', 'auditor')
    let userRole = (req.user.rol || '').toLowerCase().trim();
    if (userRole === 'administrador') {
      userRole = 'admin';
    }

    // Regla de Rol Admin: acceso total a todas las operaciones del sistema
    if (userRole === 'admin') {
      return next();
    }

    // Verificar si el rol está permitido para esta acción
    if (!allowedRoles.includes(userRole)) {
      await logAccessDenial(
        req,
        action,
        req.params?.id || null,
        `Rol '${userRole}' no tiene permiso para la acción '${action}'`
      );
      return res.status(403).json({ message: 'Acceso denegado. Permisos insuficientes.' });
    }

    // Regla 5: Propiedad del recurso para el rol Auditor
    // "un auditor solo puede registrar detalle, finalizar y sincronizar auditorías cuyo auditor_id sea el suyo. El admin puede con todas."
    if (userRole === 'auditor' && ['auditorias:detalle', 'auditorias:finalizar', 'auditorias:sync'].includes(action)) {
      let auditoriaId = req.params?.id;
      if (!auditoriaId && action === 'auditorias:sync') {
        auditoriaId = req.body?.auditoria_id || (Array.isArray(req.body) ? req.body[0]?.auditoria_id : null) || (req.body?.detalles && req.body.detalles[0]?.auditoria_id);
      }
      if (!auditoriaId && req.params?.detalleId) {
        try {
          const DetalleAuditoria = require('../models/DetalleAuditoria');
          const detalle = await DetalleAuditoria.findByPk(req.params.detalleId);
          if (detalle) auditoriaId = detalle.auditoria_id;
        } catch (_) {}
      }

      if (auditoriaId) {
        try {
          const auditoria = await Auditoria.findByPk(auditoriaId);
          if (!auditoria) {
            return res.status(404).json({ message: 'Auditoría no encontrada.' });
          }

          if (auditoria.auditor_id !== req.user.id) {
            await logAccessDenial(
              req,
              action,
              auditoriaId,
              `Auditor '${req.user.id}' intentó modificar auditoría ajena '${auditoriaId}' (pertenece a '${auditoria.auditor_id}')`
            );
            return res.status(403).json({ message: 'Acceso denegado. Solo puede operar sobre auditorías propias.' });
          }

          // Guardar referencia en req para optimizar consultas en el controlador
          req.auditoria = auditoria;
        } catch (dbErr) {
          console.error('Error validando propiedad de auditoría:', dbErr);
          return res.status(500).json({ message: 'Error interno verificando permisos de auditoría.' });
        }
      }
    }

    next();
  };

  middleware._isAuthorize = true;
  middleware._action = action; // Marca identificadora para el validador de deny-by-default
  return middleware;
};

module.exports = authorize;
