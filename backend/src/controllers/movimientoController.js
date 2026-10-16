const Movimiento = require('../models/Movimiento');
const Activo = require('../models/Activo');
const Ambiente = require('../models/Ambiente');
const Usuario = require('../models/Usuario');
const notificacionController = require('./notificacionController');

exports.getAll = async (req, res) => {
  try {
    const eventos = await Movimiento.findAll({
      include: [
        { model: Activo, as: 'activo', attributes: ['id', 'codigo_activo', 'nombre', 'estado'] },
        { model: Ambiente, as: 'origen', attributes: ['id', 'nombre', 'codigo'] },
        { model: Ambiente, as: 'destino', attributes: ['id', 'nombre', 'codigo'] },
        { model: Usuario, as: 'usuario', attributes: ['id', 'nombre_completo', 'email'] }
      ],
      order: [['created_at', 'DESC']]
    });
    res.json(eventos);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al obtener historial' });
  }
};

exports.getByActivo = async (req, res) => {
  try {
    const { activoId } = req.params;
    const eventos = await Movimiento.findAll({
      where: { activo_id: activoId },
      include: [
        { model: Ambiente, as: 'origen', attributes: ['id', 'nombre', 'codigo'] },
        { model: Ambiente, as: 'destino', attributes: ['id', 'nombre', 'codigo'] },
        { model: Usuario, as: 'usuario', attributes: ['id', 'nombre_completo'] }
      ],
      order: [['created_at', 'DESC']]
    });
    res.json(eventos);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al obtener eventos del activo' });
  }
};

exports.create = async (req, res) => {
  try {
    const { 
      activo_id, 
      tipo_evento, 
      ambiente_destino_id, 
      estado_nuevo, 
      tipo_mantenimiento,
      piezas_reemplazadas,
      costo_mantenimiento, 
      observaciones 
    } = req.body;
    
    const usuario_id = req.user.id;

    // Buscar el activo actual
    const activo = await Activo.findByPk(activo_id);
    if (!activo) return res.status(404).json({ message: 'Activo no encontrado' });

    const ambiente_origen_id = activo.ambiente_id;
    const estado_anterior = activo.estado;
    
    // Preparar objeto para cumplir con las CHECK constraints de PostgreSQL
    const movimientoData = {
      tipo_evento,
      activo_id,
      usuario_id,
      estado_anterior,
      observaciones: observaciones || null
    };

    let estado_final = estado_nuevo || estado_anterior;

    if (tipo_evento === 'traslado') {
      if (!ambiente_destino_id) {
        return res.status(400).json({ message: 'Para un traslado se requiere especificar el ambiente de destino.' });
      }
      if (ambiente_destino_id === ambiente_origen_id) {
        return res.status(400).json({ message: 'El ambiente de destino debe ser diferente al ambiente de origen actual.' });
      }
      movimientoData.ambiente_origen_id = ambiente_origen_id;
      movimientoData.ambiente_destino_id = ambiente_destino_id;
      movimientoData.estado_nuevo = estado_final;
      // En traslado, campos de mantenimiento deben ser nulos
      movimientoData.tipo_mantenimiento = null;
      movimientoData.piezas_reemplazadas = null;
      movimientoData.costo_mantenimiento = null;
    } else if (tipo_evento === 'mantenimiento') {
      if (!observaciones || observaciones.trim().length === 0) {
        return res.status(400).json({ message: 'La descripción del trabajo en observaciones es obligatoria para mantenimiento.' });
      }
      movimientoData.ambiente_origen_id = null;
      movimientoData.ambiente_destino_id = null;
      movimientoData.estado_nuevo = estado_final;
      movimientoData.tipo_mantenimiento = tipo_mantenimiento || null;
      movimientoData.piezas_reemplazadas = piezas_reemplazadas || null;
      movimientoData.costo_mantenimiento = costo_mantenimiento !== undefined && costo_mantenimiento !== '' ? costo_mantenimiento : null;
    } else if (tipo_evento === 'baja') {
      estado_final = 'Inactivo';
      movimientoData.ambiente_origen_id = null;
      movimientoData.ambiente_destino_id = null;
      movimientoData.estado_nuevo = 'Inactivo';
      movimientoData.tipo_mantenimiento = null;
      movimientoData.piezas_reemplazadas = null;
      movimientoData.costo_mantenimiento = null;
    } else {
      return res.status(400).json({ message: 'Tipo de evento no válido. Use: traslado, mantenimiento o baja.' });
    }

    // Registrar el evento en la BD
    const nuevoEvento = await Movimiento.create(movimientoData);

    // Actualizar el activo según el evento
    const updateData = {};
    if (tipo_evento === 'traslado' && ambiente_destino_id) {
      updateData.ambiente_id = ambiente_destino_id;
    }
    if (estado_final && estado_final !== estado_anterior) {
      updateData.estado = estado_final;
    }

    if (Object.keys(updateData).length > 0) {
      await activo.update(updateData);
    }
    
    // Generar Notificación del sistema
    let titulo_alerta = 'Nuevo Evento Registrado';
    let mensaje_alerta = `Se registró un ${tipo_evento} para el equipo ${activo.codigo_activo}.`;
    let tipo_alerta = 'info';
    
    if (tipo_evento === 'baja') {
      titulo_alerta = 'Equipo Dado de Baja';
      tipo_alerta = 'error';
    } else if (tipo_evento === 'mantenimiento' && estado_final === 'Dañado') {
      titulo_alerta = 'Equipo Dañado Registrado';
      tipo_alerta = 'warning';
    } else if (tipo_evento === 'traslado') {
      titulo_alerta = 'Traslado de Equipo';
    }
    
    await notificacionController.crearNotificacionSistema(titulo_alerta, mensaje_alerta, tipo_alerta, null);

    res.status(201).json(nuevoEvento);
  } catch (error) {
    console.error('Error al registrar movimiento:', error);
    res.status(500).json({ message: 'Error al registrar el evento: ' + error.message });
  }
};

exports.delete = async (req, res) => {
  try {
    const { id } = req.params;
    const evento = await Movimiento.findByPk(id);
    if (!evento) return res.status(404).json({ message: 'Evento no encontrado' });
    
    await evento.destroy();
    res.json({ message: 'Evento eliminado del historial' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error al eliminar evento' });
  }
};

exports.revertir = async (req, res) => {
  try {
    const { id } = req.params;
    const evento = await Movimiento.findByPk(id);
    if (!evento) return res.status(404).json({ message: 'Evento no encontrado' });

    const activo = await Activo.findByPk(evento.activo_id);
    if (!activo) return res.status(404).json({ message: 'Activo asociado no encontrado' });

    // Revertir según el tipo de evento
    if (evento.tipo_evento === 'traslado' && evento.ambiente_origen_id) {
      await activo.update({ ambiente_id: evento.ambiente_origen_id });
    }

    if (evento.estado_anterior) {
      await activo.update({ estado: evento.estado_anterior });
    }

    const AuditLog = require('../models/AuditLog');
    await AuditLog.create({
      usuario_id: req.user.id,
      accion: 'MOVIMIENTO_REVERTIDO',
      recurso: 'movimientos',
      recurso_id: evento.id,
      resultado: 'exitoso',
      detalles: `Revertido evento ${evento.tipo_evento} del activo ${activo.codigo_activo}`,
      ip_address: req.ip || '127.0.0.1',
      user_agent: req.get('User-Agent') || 'Desconocido',
      fecha_hora: new Date()
    });

    await evento.destroy();
    res.json({ message: 'Evento revertido exitosamente y estado del activo restaurado', activo });
  } catch (error) {
    console.error('Error al revertir evento:', error);
    res.status(500).json({ message: 'Error al revertir evento: ' + error.message });
  }
};
