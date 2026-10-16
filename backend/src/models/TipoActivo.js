const { DataTypes } = require('sequelize');
const { sequelize } = require('../../database');

const TipoActivo = sequelize.define('TipoActivo', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  codigo: {
    type: DataTypes.INTEGER,
    allowNull: false,
    unique: true,
  },
  nombre: {
    type: DataTypes.STRING(100),
    allowNull: false,
    unique: true,
  },
  descripcion: {
    type: DataTypes.TEXT,
  },
  activo: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  }
}, {
  tableName: 'tipo_activos',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

module.exports = TipoActivo;
