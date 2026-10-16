const { DataTypes } = require('sequelize');
const { sequelize } = require('../../database');

const Ambiente = sequelize.define('Ambiente', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  nombre: {
    type: DataTypes.STRING(100),
    allowNull: false,
    unique: true,
  },
  codigo: {
    type: DataTypes.INTEGER,
    allowNull: false,
    unique: true,
  },
  ubicacion: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  descripcion: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  latitude: {
    type: DataTypes.DECIMAL(10, 8),
    allowNull: true,
  },
  longitude: {
    type: DataTypes.DECIMAL(11, 8),
    allowNull: true,
  },
  radio_geofence: {
    type: DataTypes.DECIMAL(5, 2),
    defaultValue: 50,
  },
  tiene_internet: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  activo: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  }
}, {
  tableName: 'ambientes',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

module.exports = Ambiente;
