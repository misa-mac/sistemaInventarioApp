const { sequelize } = require('../database');

async function setupSecurityRole() {
  console.log('🔒 Configurando rol app_inventario y permisos según 03_seguridad.sql...');
  
  try {
    await sequelize.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_inventario') THEN
          CREATE ROLE app_inventario WITH LOGIN PASSWORD 'app_inventario_secret_2026';
        ELSE
          ALTER ROLE app_inventario WITH LOGIN PASSWORD 'app_inventario_secret_2026';
        END IF;
      END $$;
    `);

    await sequelize.query(`GRANT CONNECT ON DATABASE inventario_db TO app_inventario;`);
    await sequelize.query(`GRANT USAGE ON SCHEMA public TO app_inventario;`);

    // 8 tablas de negocio con CRUD completo
    const businessTables = [
      'usuarios',
      'tipo_activos',
      'ambientes',
      'activos',
      'movimientos',
      'notificaciones',
      'auditorias',
      'detalle_auditoria'
    ];

    for (const table of businessTables) {
      await sequelize.query(`GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE ${table} TO app_inventario;`);
      console.log(`  ✓ Privilegios SELECT, INSERT, UPDATE, DELETE otorgados en: ${table}`);
    }

    // audit_logs es de SOLO INSERCIÓN y LECTURA
    await sequelize.query(`REVOKE ALL ON TABLE audit_logs FROM app_inventario;`);
    await sequelize.query(`GRANT SELECT, INSERT ON TABLE audit_logs TO app_inventario;`);
    console.log('  ✓ Privilegios SELECT, INSERT (sin UPDATE ni DELETE) otorgados en: audit_logs');

    // Secuencias
    await sequelize.query(`GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_inventario;`);
    console.log('  ✓ Privilegios en secuencias otorgados.');

    console.log('✅ Rol app_inventario configurado exitosamente.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error configurando rol app_inventario:', error);
    process.exit(1);
  }
}

setupSecurityRole();
