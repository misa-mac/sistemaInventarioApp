const { DataTypes } = require('sequelize');
const { sequelize } = require('../../database');
const Ambiente = require('./Ambiente');

const EstacionTrabajo = sequelize.define('EstacionTrabajo', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  codigo_estacion: {
    type: DataTypes.STRING(50),
    unique: true,
    allowNull: false,
    validate: {
      notEmpty: true,
    }
  },
  ambiente_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: Ambiente,
      key: 'id'
    }
  },
  descripcion: {
    type: DataTypes.STRING(255),
    allowNull: true,
  }
}, {
  tableName: 'estaciones_trabajo',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

EstacionTrabajo.belongsTo(Ambiente, { foreignKey: 'ambiente_id', as: 'ambiente' });
Ambiente.hasMany(EstacionTrabajo, { foreignKey: 'ambiente_id', as: 'estaciones' });

module.exports = EstacionTrabajo;

