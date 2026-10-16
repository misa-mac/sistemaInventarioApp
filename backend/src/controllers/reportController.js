const Activo = require('../models/Activo');
const Ambiente = require('../models/Ambiente');
const TipoActivo = require('../models/TipoActivo');
const { sequelize } = require('../../database');

exports.getSummary = async (req, res) => {
  try {
    // Basic counts
    const totalActivos = await Activo.count();
    
    // Status breakdown
    const porEstado = await Activo.findAll({
      attributes: ['estado', [sequelize.fn('COUNT', sequelize.col('id')), 'cantidad']],
      group: ['estado'],
      raw: true
    });

    // By Environment
    const porAmbiente = await Activo.findAll({
      attributes: [
        [sequelize.col('ambiente.nombre'), 'ambiente'],
        [sequelize.fn('COUNT', sequelize.col('Activo.id')), 'cantidad']
      ],
      include: [{ model: Ambiente, as: 'ambiente', attributes: [] }],
      group: ['ambiente.id', 'ambiente.nombre'],
      raw: true
    });

    // By Type
    const porTipo = await Activo.findAll({
      attributes: [
        [sequelize.col('tipo.nombre'), 'tipo'],
        [sequelize.fn('COUNT', sequelize.col('Activo.id')), 'cantidad']
      ],
      include: [{ model: TipoActivo, as: 'tipo', attributes: [] }],
      group: ['tipo.id', 'tipo.nombre'],
      raw: true
    });

    // Total Value
    const totalValor = await Activo.sum('valor');

    res.json({
      totalActivos,
      totalValor: totalValor || 0,
      porEstado,
      porAmbiente,
      porTipo
    });
  } catch (error) {
    console.error('Error fetching report summary:', error);
    res.status(500).json({ message: 'Error interno obteniendo resumen de reportes' });
  }
};
