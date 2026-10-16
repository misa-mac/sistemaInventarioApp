const { DataTypes } = require('sequelize');
const { sequelize } = require('../../database');
const Activo = require('./Activo');
const Ambiente = require('./Ambiente');
const Usuario = require('./Usuario');

const Movimiento = sequelize.define('Movimiento', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  tipo_evento: {
    type: DataTypes.ENUM('traslado', 'mantenimiento', 'baja'),
    allowNull: false,
  },
  activo_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: Activo, key: 'id' }
  },
  usuario_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: Usuario, key: 'id' }
  },
  ambiente_origen_id: {
    type: DataTypes.UUID,
    allowNull: true,
    references: { model: Ambiente, key: 'id' }
  },
  ambiente_destino_id: {
    type: DataTypes.UUID,
    allowNull: true,
    references: { model: Ambiente, key: 'id' }
  },
  estado_anterior: {
    type: DataTypes.ENUM('Activo', 'Inactivo', 'Dañado'),
    allowNull: true,
  },
  estado_nuevo: {
    type: DataTypes.ENUM('Activo', 'Inactivo', 'Dañado'),
    allowNull: true,
  },
  tipo_mantenimiento: {
    type: DataTypes.ENUM('preventivo', 'correctivo'),
    allowNull: true,
  },
  piezas_reemplazadas: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  costo_mantenimiento: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
  },
  observaciones: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
}, {
  tableName: 'movimientos',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false
});

Movimiento.belongsTo(Activo, { foreignKey: 'activo_id', as: 'activo' });
Movimiento.belongsTo(Ambiente, { as: 'origen', foreignKey: 'ambiente_origen_id' });
Movimiento.belongsTo(Ambiente, { as: 'destino', foreignKey: 'ambiente_destino_id' });
Movimiento.belongsTo(Usuario, { foreignKey: 'usuario_id', as: 'usuario' });

module.exports = Movimiento;
