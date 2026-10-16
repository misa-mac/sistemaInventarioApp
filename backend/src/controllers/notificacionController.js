const Notificacion = require('../models/Notificacion');
const Activo = require('../models/Activo');
const { Op } = require('sequelize');

exports.getMisNotificaciones = async (req, res) => {
  try {
    const usuarioId = req.user.id;
    
    // Primero, vamos a crear notificaciones dinámicas del sistema si hay equipos dañados
    // Esto es un generador automático de alertas
    const dañados = await Activo.count({ where: { estado: 'Dañado' } });
    
    if (dañados > 0) {
      // Verificar si ya le mostramos esta alerta hoy (podríamos buscar por título)
      const alertaExistente = await Notificacion.findOne({
        where: {
          usuario_id: usuarioId,
          titulo: 'Equipos Requieren Mantenimiento',
          leida: false
        }
      });
      
      if (!alertaExistente) {
        await Notificacion.create({
          usuario_id: usuarioId,
          titulo: 'Equipos Requieren Mantenimiento',
          mensaje: `Atención: Existen ${dañados} equipos registrados con estado "Dañado". Por favor, programe un mantenimiento en el módulo de Historial.`,
          tipo: 'warning',
          leida: false
        });
      }
    }

    // Traer todas las notificaciones no leídas
    const notificaciones = await Notificacion.findAll({
      where: {
        [Op.or]: [
          { usuario_id: usuarioId },
          { usuario_id: null }
        ],
        leida: false
      },
      order: [['created_at', 'DESC']],
      limit: 20
    });

    res.json(notificaciones);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al obtener notificaciones' });
  }
};

exports.marcarLeidas = async (req, res) => {
  try {
    const usuarioId = req.user.id;
    
    await Notificacion.update(
      { leida: true },
      { where: { usuario_id: usuarioId, leida: false } }
    );
    
    res.json({ message: 'Notificaciones marcadas como leídas' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al actualizar notificaciones' });
  }
};

// Se puede llamar desde otros controladores para crear notificaciones
exports.crearNotificacionSistema = async (titulo, mensaje, tipo, usuario_id = null) => {
  try {
    await Notificacion.create({
      titulo,
      mensaje,
      tipo,
      usuario_id
    });
  } catch (err) {
    console.error('Error creando notificación del sistema:', err);
  }
};
