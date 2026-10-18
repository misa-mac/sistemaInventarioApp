const { DataTypes } = require('sequelize');
const { sequelize } = require('../../database');
const Usuario = require('./Usuario');
const Activo = require('./Activo');

const SolicitudCambio = sequelize.define('SolicitudCambio', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  tipo: {
    type: DataTypes.ENUM('alta', 'edicion', 'baja'),
    allowNull: false,
  },
  estado: {
    type: DataTypes.ENUM('pendiente', 'aprobada', 'rechazada'),
    defaultValue: 'pendiente',
    allowNull: false,
  },
  solicitante_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: Usuario, key: 'id' }
  },
  activo_id: {
    type: DataTypes.UUID,
    allowNull: true,
    references: { model: Activo, key: 'id' }
  },
  datos: {
    type: DataTypes.JSONB,
    allowNull: false,
    defaultValue: {},
  },
  motivo: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  comentario_revision: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  revisor_id: {
    type: DataTypes.UUID,
    allowNull: true,
    references: { model: Usuario, key: 'id' }
  },
  revisado_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  activo_resultante_id: {
    type: DataTypes.UUID,
    allowNull: true,
    references: { model: Activo, key: 'id' }
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  }
}, {
  tableName: 'solicitudes_cambio',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false,
});

SolicitudCambio.belongsTo(Usuario, { foreignKey: 'solicitante_id', as: 'solicitante' });
SolicitudCambio.belongsTo(Usuario, { foreignKey: 'revisor_id', as: 'revisor' });
SolicitudCambio.belongsTo(Activo, { foreignKey: 'activo_id', as: 'activo' });
SolicitudCambio.belongsTo(Activo, { foreignKey: 'activo_resultante_id', as: 'activo_resultante' });

module.exports = SolicitudCambio;
