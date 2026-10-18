const AuditLog = require('../models/AuditLog');

/**
 * Middleware para restringir acciones críticas cuando la petición proviene de la app móvil.
 * Si la petición incluye la cabecera 'X-Client: mobile' en endpoints de aprobación, rechazo
 * o escrituras directas de activos, responde 403 con 'Esta acción se confirma en la web'.
 */
const blockMobileClient = async (req, res, next) => {
  const clientHeader = req.get('X-Client');
  if (clientHeader && clientHeader.toLowerCase() === 'mobile') {
    try {
      const rawRecurso = req.baseUrl ? `${req.baseUrl}${req.path}` : (req.path || 'api');
      const recursoPath = rawRecurso.length > 50 ? rawRecurso.substring(0, 50) : rawRecurso;
      await AuditLog.create({
        usuario_id: req.user?.id || null,
        accion: 'ACCESO_DENEGADO_MOVIL',
        recurso: recursoPath,
        recurso_id: req.params?.id ? String(req.params.id) : null,
        resultado: 'fallido',
        detalles: 'Esta acción se confirma en la web',
        ip_address: req.ip || req.connection?.remoteAddress || '127.0.0.1',
        user_agent: req.get('User-Agent') || 'Desconocido',
        fecha_hora: new Date()
      });
    } catch (err) {
      console.error('Error registrando denegación X-Client en audit_logs:', err.message);
    }
    return res.status(403).json({ message: 'Esta acción se confirma en la web' });
  }
  next();
};

module.exports = blockMobileClient;
