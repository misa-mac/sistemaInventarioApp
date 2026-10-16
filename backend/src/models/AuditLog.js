const { DataTypes } = require('sequelize');
const { sequelize } = require('../../database');
const Usuario = require('./Usuario');

const AuditLog = sequelize.define('AuditLog', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  usuario_id: {
    type: DataTypes.UUID,
    allowNull: true,
    references: { model: Usuario, key: 'id' }
  },
  accion: {
    type: DataTypes.STRING(100),
    allowNull: false,
  },
  recurso: {
    type: DataTypes.STRING(50),
    allowNull: false,
  },
  recurso_id: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },
  resultado: {
    type: DataTypes.STRING(20),
    allowNull: false,
  },
  detalles: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  ip_address: {
    type: DataTypes.STRING(45),
    allowNull: true,
  },
  user_agent: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  fecha_hora: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  }
}, {
  tableName: 'audit_logs',
  timestamps: false
});

AuditLog.belongsTo(Usuario, { foreignKey: 'usuario_id', as: 'usuario' });

module.exports = AuditLog;
