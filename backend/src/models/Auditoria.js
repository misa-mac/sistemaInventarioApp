const { DataTypes } = require('sequelize');
const { sequelize } = require('../../database');
const Ambiente = require('./Ambiente');
const Usuario = require('./Usuario');

const Auditoria = sequelize.define('Auditoria', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  ambiente_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: Ambiente, key: 'id' }
  },
  auditor_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: Usuario, key: 'id' }
  },
  fecha_inicio: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
  fecha_fin: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  total_esperados: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  total_encontrados: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  total_faltantes: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  total_no_esperados: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  estado: {
    type: DataTypes.ENUM('en_progreso', 'completada', 'cancelada'),
    allowNull: false,
    defaultValue: 'en_progreso',
  },
  observaciones: {
    type: DataTypes.TEXT,
    allowNull: true,
  }
}, {
  tableName: 'auditorias',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false
});

Auditoria.belongsTo(Ambiente, { foreignKey: 'ambiente_id', as: 'ambiente' });
Auditoria.belongsTo(Usuario, { foreignKey: 'auditor_id', as: 'auditor' });

module.exports = Auditoria;
