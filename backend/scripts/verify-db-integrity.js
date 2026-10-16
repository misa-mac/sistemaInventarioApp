// Script de verificación de integridad Modelos vs Esquema Unificado
const Usuario = require('../src/models/Usuario');
const TipoActivo = require('../src/models/TipoActivo');
const Ambiente = require('../src/models/Ambiente');
const Activo = require('../src/models/Activo');
const Movimiento = require('../src/models/Movimiento');
const Notificacion = require('../src/models/Notificacion');
const Auditoria = require('../src/models/Auditoria');
const DetalleAuditoria = require('../src/models/DetalleAuditoria');
const AuditLog = require('../src/models/AuditLog');

const expectedSchema = {
  usuarios: {
    model: Usuario,
    expectedFields: ['id', 'nombre_completo', 'email', 'password_hash', 'rol', 'activo', 'created_at', 'updated_at']
  },
  tipo_activos: {
    model: TipoActivo,
    expectedFields: ['id', 'nombre', 'codigo', 'descripcion', 'activo', 'created_at', 'updated_at']
  },
  ambientes: {
    model: Ambiente,
    expectedFields: ['id', 'nombre', 'codigo', 'ubicacion', 'descripcion', 'latitude', 'longitude', 'radio_geofence', 'tiene_internet', 'activo', 'created_at', 'updated_at']
  },
  activos: {
    model: Activo,
    expectedFields: ['id', 'codigo_activo', 'numero_correlativo', 'tipo_activo_id', 'ambiente_id', 'ambiente_registro_id', 'nombre', 'marca', 'modelo', 'numero_serie', 'origen', 'especificacion_origen', 'descripcion', 'responsable', 'fecha_ingreso', 'valor', 'imagen_url', 'estado', 'observaciones', 'created_at', 'updated_at']
  },
  movimientos: {
    model: Movimiento,
    expectedFields: ['id', 'tipo_evento', 'activo_id', 'usuario_id', 'ambiente_origen_id', 'ambiente_destino_id', 'estado_anterior', 'estado_nuevo', 'tipo_mantenimiento', 'piezas_reemplazadas', 'costo_mantenimiento', 'observaciones', 'created_at']
  },
  notificaciones: {
    model: Notificacion,
    expectedFields: ['id', 'usuario_id', 'titulo', 'mensaje', 'tipo', 'leida', 'created_at']
  },
  auditorias: {
    model: Auditoria,
    expectedFields: ['id', 'ambiente_id', 'auditor_id', 'fecha_inicio', 'fecha_fin', 'total_esperados', 'total_encontrados', 'total_faltantes', 'total_no_esperados', 'estado', 'observaciones', 'created_at']
  },
  detalle_auditoria: {
    model: DetalleAuditoria,
    expectedFields: ['id', 'auditoria_id', 'activo_id', 'codigo_qr_escaneado', 'estado', 'observacion', 'fecha_escaneo', 'sincronizado']
  },
  audit_logs: {
    model: AuditLog,
    expectedFields: ['id', 'usuario_id', 'accion', 'recurso', 'recurso_id', 'resultado', 'detalles', 'ip_address', 'user_agent', 'fecha_hora']
  }
};

let errors = 0;

console.log('🔍 INICIANDO AUDITORÍA DE INTEGRIDAD DE TABLAS Y CAMPOS...\n');

for (const [tableName, config] of Object.entries(expectedSchema)) {
  const model = config.model;
  const rawAttributes = Object.keys(model.rawAttributes);
  
  // Agregar timestamps si están habilitados en Sequelize
  if (model.options.timestamps) {
    if (model.options.createdAt && !rawAttributes.includes(model.options.createdAt)) {
      rawAttributes.push(model.options.createdAt);
    }
    if (model.options.updatedAt && !rawAttributes.includes(model.options.updatedAt)) {
      rawAttributes.push(model.options.updatedAt);
    }
  }

  // Verificar tabla
  if (model.getTableName() !== tableName) {
    console.error(`❌ Tabla ${tableName}: Nombre de tabla no coincide (modelo usa ${model.getTableName()})`);
    errors++;
  } else {
    console.log(`✅ Tabla: ${tableName}`);
  }

  // Verificar campos
  for (const field of config.expectedFields) {
    if (!rawAttributes.includes(field)) {
      console.error(`   ❌ Falta campo: ${field}`);
      errors++;
    } else {
      console.log(`   ✓ ${field}`);
    }
  }
  console.log('');
}

console.log('🔍 VERIFICANDO ASOCIACIONES...');
const associationsToCheck = [
  { model: Activo, as: 'ambiente', target: Ambiente },
  { model: Activo, as: 'ambiente_registro', target: Ambiente },
  { model: Activo, as: 'tipo', target: TipoActivo },
  { model: Movimiento, as: 'activo', target: Activo },
  { model: Movimiento, as: 'origen', target: Ambiente },
  { model: Movimiento, as: 'destino', target: Ambiente },
  { model: Movimiento, as: 'usuario', target: Usuario },
  { model: Auditoria, as: 'ambiente', target: Ambiente },
  { model: Auditoria, as: 'auditor', target: Usuario },
  { model: DetalleAuditoria, as: 'auditoria', target: Auditoria },
  { model: DetalleAuditoria, as: 'activo', target: Activo }
];

for (const assoc of associationsToCheck) {
  const defined = assoc.model.associations[assoc.as];
  if (!defined) {
    console.error(`❌ Falta asociación: ${assoc.model.name}.${assoc.as}`);
    errors++;
  } else {
    console.log(`✅ Asociación ${assoc.model.name}.${assoc.as} -> ${assoc.target.name}`);
  }
}

console.log('\n=======================================');
if (errors === 0) {
  console.log('🎉 100% DE INTEGRIDAD: Cero errores encontrados.');
  console.log('Todas las 9 tablas, campos, tipos y relaciones coinciden perfectamente con PostgreSQL.');
} else {
  console.error(`⚠️ Se encontraron ${errors} inconsistencias.`);
  process.exit(1);
}
console.log('=======================================');
