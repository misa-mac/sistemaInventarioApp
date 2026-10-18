const { DataTypes } = require('sequelize');
const { sequelize } = require('../../database');
const Ambiente = require('./Ambiente');
const TipoActivo = require('./TipoActivo');

const Activo = sequelize.define('Activo', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  codigo_activo: {
    type: DataTypes.STRING(20),
    unique: true,
    allowNull: true, // Asignado por el trigger de base de datos fn_activos_asignar_codigo
  },
  numero_correlativo: {
    type: DataTypes.INTEGER,
    allowNull: true, // Asignado por el trigger de base de datos fn_activos_asignar_codigo
  },
  tipo_activo_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: TipoActivo,
      key: 'id'
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
  ambiente_registro_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: Ambiente,
      key: 'id'
    }
  },
  nombre: {
    type: DataTypes.STRING(150),
    allowNull: false,
  },
  marca: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },
  modelo: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },
  numero_serie: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },
  origen: {
    type: DataTypes.STRING(150),
    allowNull: true,
  },
  especificacion_origen: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  descripcion: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  responsable: {
    type: DataTypes.STRING(150),
    allowNull: true,
  },
  fecha_ingreso: {
    type: DataTypes.DATEONLY,
    allowNull: true,
    defaultValue: DataTypes.NOW,
  },
  valor: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
  },
  imagen_url: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  estado: {
    type: DataTypes.ENUM('Activo', 'Inactivo', 'Dañado'),
    defaultValue: 'Activo',
  },
  observaciones: {
    type: DataTypes.TEXT,
    allowNull: true,
  }
}, {
  tableName: 'activos',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

Activo.belongsTo(Ambiente, { foreignKey: 'ambiente_id', as: 'ambiente' });
Ambiente.hasMany(Activo, { foreignKey: 'ambiente_id', as: 'activos_actuales' });

Activo.belongsTo(Ambiente, { foreignKey: 'ambiente_registro_id', as: 'ambiente_registro' });
Ambiente.hasMany(Activo, { foreignKey: 'ambiente_registro_id', as: 'activos_registrados' });

Activo.belongsTo(TipoActivo, { foreignKey: 'tipo_activo_id', as: 'tipo' });
TipoActivo.hasMany(Activo, { foreignKey: 'tipo_activo_id', as: 'activos' });

module.exports = Activo;
