const { DataTypes } = require('sequelize');
const { sequelize } = require('../../database');
const Auditoria = require('./Auditoria');
const Activo = require('./Activo');

const DetalleAuditoria = sequelize.define('DetalleAuditoria', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  auditoria_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: Auditoria, key: 'id' }
  },
  activo_id: {
    type: DataTypes.UUID,
    allowNull: true,
    references: { model: Activo, key: 'id' }
  },
  codigo_qr_escaneado: {
    type: DataTypes.STRING(50),
    allowNull: true,
  },
  estado: {
    type: DataTypes.ENUM('presente', 'faltante', 'no_esperado'),
    allowNull: false,
  },
  observacion: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  fecha_escaneo: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
  sincronizado: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  }
}, {
  tableName: 'detalle_auditoria',
  timestamps: false
});

DetalleAuditoria.belongsTo(Auditoria, { foreignKey: 'auditoria_id', as: 'auditoria' });
Auditoria.hasMany(DetalleAuditoria, { foreignKey: 'auditoria_id', as: 'detalles' });

DetalleAuditoria.belongsTo(Activo, { foreignKey: 'activo_id', as: 'activo' });
Activo.hasMany(DetalleAuditoria, { foreignKey: 'activo_id', as: 'auditorias_detalle' });

module.exports = DetalleAuditoria;
