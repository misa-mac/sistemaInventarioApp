const { sequelize } = require('../database');

async function migrate() {
  console.log('🚀 INICIANDO MIGRACIÓN AL ESQUEMA UNIFICADO EN POSTGRESQL...');
  const t = await sequelize.transaction();

  try {
    // 1. Tipos ENUM requeridos
    console.log('📌 Creando/verificando tipos ENUM...');
    await sequelize.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'rol_usuario') THEN
          CREATE TYPE rol_usuario AS ENUM ('admin', 'tecnico', 'auditor');
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_activo') THEN
          CREATE TYPE estado_activo AS ENUM ('Activo', 'Inactivo', 'Dañado');
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_evento') THEN
          CREATE TYPE tipo_evento AS ENUM ('traslado', 'mantenimiento', 'baja');
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_notificacion') THEN
          CREATE TYPE tipo_notificacion AS ENUM ('info', 'warning', 'error', 'success');
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_mantenimiento') THEN
          CREATE TYPE tipo_mantenimiento AS ENUM ('preventivo', 'correctivo');
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_auditoria') THEN
          CREATE TYPE estado_auditoria AS ENUM ('presente', 'faltante', 'no_esperado');
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_sesion_auditoria') THEN
          CREATE TYPE estado_sesion_auditoria AS ENUM ('en_progreso', 'completada', 'cancelada');
        END IF;
      END$$;
    `, { transaction: t });

    // 2. Funciones auxiliares
    console.log('📌 Creando/verificando funciones auxiliares...');
    await sequelize.query(`
      CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
      BEGIN
        NEW.updated_at := now();
        RETURN NEW;
      END $$;

      CREATE OR REPLACE FUNCTION fn_bloquear_modificacion() RETURNS trigger LANGUAGE plpgsql AS $$
      BEGIN
        RAISE EXCEPTION 'La tabla % es de solo inserción (operación % bloqueada)', TG_TABLE_NAME, TG_OP;
      END $$;
    `, { transaction: t });

    // 3. Tabla usuarios
    console.log('📌 Migrando tabla usuarios...');
    await sequelize.query(`
      ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS nombre_completo VARCHAR(150);
      ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS email VARCHAR(150);
      ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);
      ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS activo BOOLEAN NOT NULL DEFAULT true;
      ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();
      ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
      
      -- Asegurar lowercase en emails existentes
      UPDATE usuarios SET email = lower(email) WHERE email <> lower(email);
      
      -- Constraint email lowercase
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'usuarios_email_check') THEN
          ALTER TABLE usuarios ADD CONSTRAINT usuarios_email_check CHECK (email = lower(email));
        END IF;
      END$$;
    `, { transaction: t });

    // 4. Tabla tipo_activos
    console.log('📌 Migrando tabla tipo_activos...');
    await sequelize.query(`
      CREATE TABLE IF NOT EXISTS tipo_activos (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        nombre VARCHAR(100) NOT NULL UNIQUE,
        codigo INTEGER NOT NULL UNIQUE CHECK (codigo BETWEEN 0 AND 99),
        descripcion TEXT,
        activo BOOLEAN NOT NULL DEFAULT true,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );

      ALTER TABLE tipo_activos ADD COLUMN IF NOT EXISTS codigo INTEGER;
      ALTER TABLE tipo_activos ADD COLUMN IF NOT EXISTS nombre VARCHAR(100);
      ALTER TABLE tipo_activos ADD COLUMN IF NOT EXISTS descripcion TEXT;
      ALTER TABLE tipo_activos ADD COLUMN IF NOT EXISTS activo BOOLEAN NOT NULL DEFAULT true;
      ALTER TABLE tipo_activos ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();
      ALTER TABLE tipo_activos ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
      
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tipo_activos_codigo_check') THEN
          ALTER TABLE tipo_activos ADD CONSTRAINT tipo_activos_codigo_check CHECK (codigo BETWEEN 0 AND 99);
        END IF;
      END$$;
    `, { transaction: t });

    // 5. Tabla ambientes
    console.log('📌 Migrando tabla ambientes...');
    await sequelize.query(`
      ALTER TABLE ambientes ADD COLUMN IF NOT EXISTS ubicacion VARCHAR(255);
      ALTER TABLE ambientes ADD COLUMN IF NOT EXISTS descripcion TEXT;
      ALTER TABLE ambientes ADD COLUMN IF NOT EXISTS radio_geofence NUMERIC(5,2) NOT NULL DEFAULT 50;
      ALTER TABLE ambientes ADD COLUMN IF NOT EXISTS tiene_internet BOOLEAN NOT NULL DEFAULT true;
      ALTER TABLE ambientes ADD COLUMN IF NOT EXISTS activo BOOLEAN NOT NULL DEFAULT true;
      ALTER TABLE ambientes ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
      ALTER TABLE ambientes ALTER COLUMN codigo SET NOT NULL;

      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ambientes_codigo_check') THEN
          ALTER TABLE ambientes ADD CONSTRAINT ambientes_codigo_check CHECK (codigo BETWEEN 0 AND 99);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ambientes_radio_geofence_check') THEN
          ALTER TABLE ambientes ADD CONSTRAINT ambientes_radio_geofence_check CHECK (radio_geofence > 0);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ambientes_coordenadas_check') THEN
          ALTER TABLE ambientes ADD CONSTRAINT ambientes_coordenadas_check CHECK ((latitude IS NULL) = (longitude IS NULL));
        END IF;
      END$$;
    `, { transaction: t });

    // 6. Tabla activos
    console.log('📌 Migrando tabla activos...');
    await sequelize.query(`
      ALTER TABLE activos ADD COLUMN IF NOT EXISTS nombre VARCHAR(150);
      ALTER TABLE activos ADD COLUMN IF NOT EXISTS marca VARCHAR(100);
      ALTER TABLE activos ADD COLUMN IF NOT EXISTS modelo VARCHAR(100);
      ALTER TABLE activos ADD COLUMN IF NOT EXISTS numero_serie VARCHAR(100);
      ALTER TABLE activos ADD COLUMN IF NOT EXISTS ambiente_registro_id UUID REFERENCES ambientes(id);
      ALTER TABLE activos ADD COLUMN IF NOT EXISTS imagen_url TEXT;
      ALTER TABLE activos ADD COLUMN IF NOT EXISTS observaciones TEXT;
      
      -- Asegurar que origen sea nullable según schema
      ALTER TABLE activos ALTER COLUMN origen DROP NOT NULL;
      ALTER TABLE activos ALTER COLUMN fecha_ingreso TYPE DATE USING fecha_ingreso::date;
      ALTER TABLE activos ALTER COLUMN fecha_ingreso DROP NOT NULL;

      -- Vincular ambiente_registro_id si faltaba
      UPDATE activos SET ambiente_registro_id = ambiente_id WHERE ambiente_registro_id IS NULL;
      ALTER TABLE activos ALTER COLUMN ambiente_registro_id SET NOT NULL;

      -- Función y trigger de asignación de código
      CREATE OR REPLACE FUNCTION fn_activos_asignar_codigo() RETURNS trigger LANGUAGE plpgsql AS $$
      DECLARE
        v_aa INTEGER;
        v_cc INTEGER;
      BEGIN
        IF NEW.ambiente_registro_id IS NULL THEN
          NEW.ambiente_registro_id := NEW.ambiente_id;
        END IF;

        IF NEW.codigo_activo IS NULL THEN
          SELECT codigo INTO v_aa FROM tipo_activos WHERE id = NEW.tipo_activo_id;
          SELECT codigo INTO v_cc FROM ambientes    WHERE id = NEW.ambiente_registro_id;
          IF v_aa IS NULL OR v_cc IS NULL THEN
            RAISE EXCEPTION 'Tipo de activo o ambiente de registro inexistente';
          END IF;

          PERFORM pg_advisory_xact_lock(
            hashtextextended(NEW.tipo_activo_id::text || NEW.ambiente_registro_id::text, 0));

          IF NEW.numero_correlativo IS NULL THEN
            SELECT COALESCE(MAX(numero_correlativo), 0) + 1
              INTO NEW.numero_correlativo
              FROM activos
             WHERE tipo_activo_id = NEW.tipo_activo_id
               AND ambiente_registro_id = NEW.ambiente_registro_id;
          END IF;

          IF NEW.numero_correlativo > 99 THEN
            RAISE EXCEPTION 'Se agotó el correlativo (máx. 99) para este tipo en este ambiente';
          END IF;

          NEW.codigo_activo := '1'
            || to_char(COALESCE(NEW.fecha_ingreso, CURRENT_DATE), 'YY')
            || lpad(v_aa::text, 2, '0')
            || lpad(v_cc::text, 2, '0')
            || '-' || lpad(NEW.numero_correlativo::text, 2, '0');
        END IF;

        IF NEW.nombre IS NULL OR btrim(NEW.nombre) = '' THEN
          NEW.nombre := COALESCE((SELECT nombre FROM tipo_activos WHERE id = NEW.tipo_activo_id), 'Activo')
                        || ' ' || NEW.codigo_activo;
        END IF;
        RETURN NEW;
      END $$;

      CREATE OR REPLACE FUNCTION fn_activos_identidad_inmutable() RETURNS trigger LANGUAGE plpgsql AS $$
      BEGIN
        IF NEW.codigo_activo        IS DISTINCT FROM OLD.codigo_activo
        OR NEW.numero_correlativo   IS DISTINCT FROM OLD.numero_correlativo
        OR NEW.tipo_activo_id       IS DISTINCT FROM OLD.tipo_activo_id
        OR NEW.ambiente_registro_id IS DISTINCT FROM OLD.ambiente_registro_id THEN
          RAISE EXCEPTION 'La identidad del activo (código, tipo y ambiente de registro) es inmutable';
        END IF;
        RETURN NEW;
      END $$;

      DROP TRIGGER IF EXISTS trg_activos_codigo ON activos;
      CREATE TRIGGER trg_activos_codigo BEFORE INSERT ON activos
        FOR EACH ROW EXECUTE FUNCTION fn_activos_asignar_codigo();

      DROP TRIGGER IF EXISTS trg_activos_identidad ON activos;
      CREATE TRIGGER trg_activos_identidad BEFORE UPDATE ON activos
        FOR EACH ROW EXECUTE FUNCTION fn_activos_identidad_inmutable();
    `, { transaction: t });

    // 7. Tabla movimientos
    console.log('📌 Migrando tabla movimientos...');
    await sequelize.query(`
      ALTER TABLE movimientos ADD COLUMN IF NOT EXISTS tipo_mantenimiento tipo_mantenimiento;
      ALTER TABLE movimientos ADD COLUMN IF NOT EXISTS piezas_reemplazadas TEXT;
      ALTER TABLE movimientos ADD COLUMN IF NOT EXISTS costo_mantenimiento NUMERIC(10,2);
      ALTER TABLE movimientos ADD COLUMN IF NOT EXISTS observaciones TEXT;

      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'movimientos_check') THEN
          ALTER TABLE movimientos ADD CONSTRAINT movimientos_check CHECK (
            tipo_evento = 'mantenimiento'
            OR (tipo_mantenimiento IS NULL AND piezas_reemplazadas IS NULL AND costo_mantenimiento IS NULL)
          );
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'movimientos_obs_check') THEN
          ALTER TABLE movimientos ADD CONSTRAINT movimientos_obs_check CHECK (
            tipo_evento <> 'mantenimiento' OR length(btrim(COALESCE(observaciones, ''))) > 0
          );
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'movimientos_traslado_check') THEN
          ALTER TABLE movimientos ADD CONSTRAINT movimientos_traslado_check CHECK (
            tipo_evento <> 'traslado'
            OR (ambiente_origen_id IS NOT NULL AND ambiente_destino_id IS NOT NULL AND ambiente_origen_id <> ambiente_destino_id)
          );
        END IF;
      END$$;
    `, { transaction: t });

    // 8. Tabla notificaciones
    console.log('📌 Migrando tabla notificaciones...');
    await sequelize.query(`
      CREATE TABLE IF NOT EXISTS notificaciones (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        usuario_id UUID REFERENCES usuarios(id),
        titulo VARCHAR(200) NOT NULL,
        mensaje TEXT NOT NULL,
        tipo tipo_notificacion NOT NULL DEFAULT 'info',
        leida BOOLEAN NOT NULL DEFAULT false,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );
    `, { transaction: t });

    // 9. Tabla auditorias y detalle_auditoria
    console.log('📌 Migrando tablas de auditoría...');
    await sequelize.query(`
      CREATE TABLE IF NOT EXISTS auditorias (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        ambiente_id UUID NOT NULL REFERENCES ambientes(id),
        auditor_id UUID NOT NULL REFERENCES usuarios(id),
        fecha_inicio TIMESTAMPTZ NOT NULL DEFAULT now(),
        fecha_fin TIMESTAMPTZ,
        total_esperados INTEGER NOT NULL DEFAULT 0 CHECK (total_esperados >= 0),
        total_encontrados INTEGER NOT NULL DEFAULT 0 CHECK (total_encontrados >= 0),
        total_faltantes INTEGER NOT NULL DEFAULT 0 CHECK (total_faltantes >= 0),
        total_no_esperados INTEGER NOT NULL DEFAULT 0 CHECK (total_no_esperados >= 0),
        estado estado_sesion_auditoria NOT NULL DEFAULT 'en_progreso',
        observaciones TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
      );

      CREATE TABLE IF NOT EXISTS detalle_auditoria (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        auditoria_id UUID NOT NULL REFERENCES auditorias(id) ON DELETE CASCADE,
        activo_id UUID REFERENCES activos(id),
        codigo_qr_escaneado VARCHAR(50),
        estado estado_auditoria NOT NULL,
        observacion TEXT,
        fecha_escaneo TIMESTAMPTZ NOT NULL DEFAULT now(),
        sincronizado BOOLEAN NOT NULL DEFAULT true,
        CHECK (estado = 'no_esperado' OR activo_id IS NOT NULL),
        CHECK (estado = 'faltante' OR codigo_qr_escaneado IS NOT NULL)
      );
    `, { transaction: t });

    // 10. Tabla audit_logs
    console.log('📌 Migrando tabla audit_logs...');
    await sequelize.query(`
      CREATE TABLE IF NOT EXISTS audit_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        usuario_id UUID REFERENCES usuarios(id),
        accion VARCHAR(100) NOT NULL,
        recurso VARCHAR(50) NOT NULL,
        recurso_id VARCHAR(100),
        resultado VARCHAR(20) NOT NULL CHECK (resultado IN ('exitoso', 'fallido')),
        detalles TEXT,
        ip_address VARCHAR(45),
        user_agent TEXT,
        fecha_hora TIMESTAMPTZ NOT NULL DEFAULT now()
      );

      DROP TRIGGER IF EXISTS trg_audit_logs_inmutable ON audit_logs;
      CREATE TRIGGER trg_audit_logs_inmutable BEFORE UPDATE OR DELETE ON audit_logs
        FOR EACH ROW EXECUTE FUNCTION fn_bloquear_modificacion();

      DROP TRIGGER IF EXISTS trg_audit_logs_no_truncate ON audit_logs;
      CREATE TRIGGER trg_audit_logs_no_truncate BEFORE TRUNCATE ON audit_logs
        FOR EACH STATEMENT EXECUTE FUNCTION fn_bloquear_modificacion();
    `, { transaction: t });

    // 11. Triggers de updated_at
    console.log('📌 Configurando triggers de updated_at e índices...');
    await sequelize.query(`
      DROP TRIGGER IF EXISTS trg_usuarios_updated ON usuarios;
      CREATE TRIGGER trg_usuarios_updated BEFORE UPDATE ON usuarios FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      DROP TRIGGER IF EXISTS trg_tipo_activos_updated ON tipo_activos;
      CREATE TRIGGER trg_tipo_activos_updated BEFORE UPDATE ON tipo_activos FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      DROP TRIGGER IF EXISTS trg_ambientes_updated ON ambientes;
      CREATE TRIGGER trg_ambientes_updated BEFORE UPDATE ON ambientes FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      DROP TRIGGER IF EXISTS trg_activos_updated ON activos;
      CREATE TRIGGER trg_activos_updated BEFORE UPDATE ON activos FOR EACH ROW EXECUTE FUNCTION set_updated_at();

      CREATE INDEX IF NOT EXISTS idx_activos_ambiente ON activos(ambiente_id);
      CREATE INDEX IF NOT EXISTS idx_activos_tipo ON activos(tipo_activo_id);
      CREATE INDEX IF NOT EXISTS idx_activos_serie ON activos(numero_serie) WHERE numero_serie IS NOT NULL;
      CREATE INDEX IF NOT EXISTS idx_movimientos_activo ON movimientos(activo_id, created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_movimientos_usuario ON movimientos(usuario_id);
      CREATE INDEX IF NOT EXISTS idx_auditorias_ambiente ON auditorias(ambiente_id);
      CREATE INDEX IF NOT EXISTS idx_auditorias_auditor ON auditorias(auditor_id);
      CREATE INDEX IF NOT EXISTS idx_detalle_auditoria ON detalle_auditoria(auditoria_id);
      CREATE INDEX IF NOT EXISTS idx_detalle_activo ON detalle_auditoria(activo_id);
      CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario ON notificaciones(usuario_id, leida);
      CREATE INDEX IF NOT EXISTS idx_audit_logs_fecha ON audit_logs(fecha_hora);
      CREATE INDEX IF NOT EXISTS idx_audit_logs_usuario ON audit_logs(usuario_id);
    `, { transaction: t });

    await t.commit();
    console.log('✅ MIGRACIÓN APLICADA EXITOSAMENTE EN POSTGRESQL.');
    process.exit(0);
  } catch (err) {
    await t.rollback();
    console.error('❌ ERROR DURANTE LA MIGRACIÓN:', err);
    process.exit(1);
  }
}

migrate();
