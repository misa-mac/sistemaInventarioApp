const AuditLog = require('../models/AuditLog');


//prueba de cambio
exports.create = async (req, res) => {
  try {
    const { usuario_id, accion, recurso, recurso_id, resultado, detalles, ip_address, user_agent } = req.body;
    let normResultado = (resultado || 'exitoso').toString().toLowerCase().trim();
    if (['exito', 'success', 'ok'].includes(normResultado)) {
      normResultado = 'exitoso';
    } else if (['fallo', 'error', 'failed'].includes(normResultado)) {
      normResultado = 'fallido';
    }
    if (!['exitoso', 'fallido'].includes(normResultado)) {
      normResultado = 'exitoso';
    }

    const log = await AuditLog.create({
      usuario_id: usuario_id || req.user?.id || null,
      accion,
      recurso,
      recurso_id,
      resultado: normResultado,
      detalles,
      ip_address: ip_address || req.ip,
      user_agent: user_agent || req.get('User-Agent'),
      fecha_hora: new Date()
    });
    res.status(201).json(log);
  } catch (error) {
    console.error('Error al registrar audit log:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

exports.getAll = async (req, res) => {
  try {
    const { usuario_id, accion, resultado, limit } = req.query;
    const where = {};
    if (usuario_id) where.usuario_id = usuario_id;
    if (accion) where.accion = accion;
    if (resultado) where.resultado = resultado;

    const logs = await AuditLog.findAll({
      where,
      order: [['fecha_hora', 'DESC']],
      limit: limit ? parseInt(limit) : 50
    });
    res.json(logs);
  } catch (error) {
    console.error('Error al listar audit logs:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};
