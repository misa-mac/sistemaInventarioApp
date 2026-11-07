const { sequelize } = require('../database');

async function migrate() {
  const t = await sequelize.transaction();
  try {
    console.log('🔄 Iniciando migración a formato real X·CC·TT·AA·NNNN-YY y reglas de ciclo de vida...');

    // 1. Asegurar catálogo de tipo_activos con códigos oficiales:
    // 10 CPU, 20 RAK, 30 Estabilizador, 40 Router, 45 Switch, 50 Teclado, 60 Mouse, 80 Monitor, 90 Mesa, 95 Silla
    const tipos = [
      { codigo: 10, nombre: 'CPU' },
      { codigo: 20, nombre: 'RAK' },
      { codigo: 30, nombre: 'Estabilizador' },
      { codigo: 40, nombre: 'Router' },
      { codigo: 45, nombre: 'Switch' },
      { codigo: 50, nombre: 'Teclado' },
      { codigo: 60, nombre: 'Mouse' },
      { codigo: 80, nombre: 'Monitor' },
      { codigo: 90, nombre: 'Mesa' },
      { codigo: 95, nombre: 'Silla' }
    ];

    for (const tipo of tipos) {
      await sequelize.query(`
        INSERT INTO tipo_activos (id, nombre, codigo, activo, created_at, updated_at)
        VALUES (gen_random_uuid(), :nombre, :codigo, true, now(), now())
        ON CONFLICT (codigo) DO UPDATE 
        SET nombre = EXCLUDED.nombre, activo = true, updated_at = now()
      `, { replacements: { nombre: tipo.nombre, codigo: tipo.codigo }, transaction: t });
    }
    console.log('✅ Catálogo tipo_activos actualizado con códigos oficiales.');

    // 2. Eliminar triggers y constraints antiguas que chocan con la migración
    await sequelize.query(`
      DROP TRIGGER IF EXISTS trg_activos_identidad ON activos;
      DROP TRIGGER IF EXISTS trg_activos_codigo ON activos;
      ALTER TABLE activos DROP CONSTRAINT IF EXISTS activos_codigo_activo_check;
      ALTER TABLE activos DROP CONSTRAINT IF EXISTS activos_numero_correlativo_check;
      ALTER TABLE activos DROP CONSTRAINT IF EXISTS activos_codigo_activo_key;
      ALTER TABLE activos DROP CONSTRAINT IF EXISTS activos_tipo_activo_id_ambiente_registro_id_numero_correlat_key;
    `, { transaction: t });
    console.log('✅ Triggers y restricciones antiguas eliminadas temporalmente.');

    // 3. Migrar registros existentes al nuevo formato 150TTAANNNN-YY
    await sequelize.query(`
      UPDATE activos a
      SET codigo_activo = '150'
        || lpad(t.codigo::text, 2, '0')
        || lpad(amb.codigo::text, 2, '0')
        || a.numero_correlativo::text
        || '-' || to_char(COALESCE(a.fecha_ingreso, CURRENT_DATE), 'YY')
      FROM tipo_activos t, ambientes amb
      WHERE a.tipo_activo_id = t.id AND a.ambiente_id = amb.id;
    `, { transaction: t });
    console.log('✅ Activos existentes actualizados al formato real institucional.');

    // 4. Eliminar columna ambiente_registro_id si existe
    await sequelize.query(`
      ALTER TABLE activos DROP COLUMN IF EXISTS ambiente_registro_id CASCADE;
    `, { transaction: t });
    console.log('✅ Columna ambiente_registro_id eliminada (el código ahora usa ambiente actual).');

    // 5. Aplicar nuevos CHECKs
    await sequelize.query(`
      ALTER TABLE activos ADD CONSTRAINT activos_codigo_activo_check 
        CHECK (codigo_activo ~ '^1[0-9]{2}[0-9]{2}[0-9]{2}[0-9]{1,4}-[0-9]{2}$');

      ALTER TABLE activos ADD CONSTRAINT activos_numero_correlativo_check 
        CHECK (numero_correlativo BETWEEN 1 AND 9999);
    `, { transaction: t });
    console.log('✅ Restricciones CHECK aplicadas (regex 150TTAANNNN-YY y correlativo 1..9999).');

    // 6. Aplicar índices UNIQUE parciales (liberan correlativo en Inactivo)
    await sequelize.query(`
      DROP INDEX IF EXISTS activos_codigo_activo_uidx;
      DROP INDEX IF EXISTS activos_tipo_ambiente_correlativo_uidx;

      CREATE UNIQUE INDEX activos_codigo_activo_uidx 
        ON activos (codigo_activo) 
        WHERE estado <> 'Inactivo';

      CREATE UNIQUE INDEX activos_tipo_ambiente_correlativo_uidx 
        ON activos (tipo_activo_id, ambiente_id, numero_correlativo) 
        WHERE estado <> 'Inactivo';
    `, { transaction: t });
    console.log('✅ Índices UNIQUE parciales creados.');

    // 7. Crear/Reemplazar fn_activos_asignar_codigo() para INSERT
    await sequelize.query(`
      CREATE OR REPLACE FUNCTION fn_activos_asignar_codigo() RETURNS trigger LANGUAGE plpgsql AS $$
      DECLARE
        v_tt INTEGER;
        v_aa INTEGER;
        v_yy TEXT;
      BEGIN
        SELECT codigo INTO v_tt FROM tipo_activos WHERE id = NEW.tipo_activo_id;
        SELECT codigo INTO v_aa FROM ambientes    WHERE id = NEW.ambiente_id;
        IF v_tt IS NULL OR v_aa IS NULL THEN
          RAISE EXCEPTION 'Tipo de activo o ambiente inexistente';
        END IF;

        -- Bloqueo consultivo de transacción para evitar duplicados concurrentes en la misma carrera+tipo+ambiente
        PERFORM pg_advisory_xact_lock(
          hashtextextended('50' || NEW.tipo_activo_id::text || NEW.ambiente_id::text, 0));

        IF NEW.numero_correlativo IS NULL THEN
          SELECT COALESCE(MAX(numero_correlativo), 0) + 1
            INTO NEW.numero_correlativo
            FROM activos
           WHERE tipo_activo_id = NEW.tipo_activo_id
             AND ambiente_id = NEW.ambiente_id
             AND estado <> 'Inactivo';
        END IF;

        IF NEW.numero_correlativo > 9999 OR NEW.numero_correlativo < 1 THEN
          RAISE EXCEPTION 'El correlativo debe estar entre 1 y 9999 para este tipo en este ambiente';
        END IF;

        v_yy := to_char(COALESCE(NEW.fecha_ingreso, CURRENT_DATE), 'YY');
        NEW.codigo_activo := '150'
          || lpad(v_tt::text, 2, '0')
          || lpad(v_aa::text, 2, '0')
          || NEW.numero_correlativo::text
          || '-' || v_yy;

        IF NEW.nombre IS NULL OR btrim(NEW.nombre) = '' THEN
          NEW.nombre := COALESCE((SELECT nombre FROM tipo_activos WHERE id = NEW.tipo_activo_id), 'Activo')
                        || ' ' || NEW.codigo_activo;
        END IF;

        RETURN NEW;
      END $$;
    `, { transaction: t });
    console.log('✅ Trigger function fn_activos_asignar_codigo actualizada.');

    // 8. Crear/Reemplazar fn_activos_identidad_inmutable() para UPDATE (permite cambio en traslado)
    await sequelize.query(`
      CREATE OR REPLACE FUNCTION fn_activos_identidad_inmutable() RETURNS trigger LANGUAGE plpgsql AS $$
      DECLARE
        v_tt INTEGER;
        v_aa INTEGER;
        v_yy TEXT;
        v_colision BOOLEAN;
      BEGIN
        -- Caso traslado de ambiente (UPDATE de ambiente_id)
        IF NEW.ambiente_id IS DISTINCT FROM OLD.ambiente_id THEN
          SELECT codigo INTO v_tt FROM tipo_activos WHERE id = NEW.tipo_activo_id;
          SELECT codigo INTO v_aa FROM ambientes    WHERE id = NEW.ambiente_id;
          IF v_tt IS NULL OR v_aa IS NULL THEN
            RAISE EXCEPTION 'Tipo de activo o ambiente destino inexistente';
          END IF;

          -- Bloqueo consultivo en el ambiente destino
          PERFORM pg_advisory_xact_lock(
            hashtextextended('50' || NEW.tipo_activo_id::text || NEW.ambiente_id::text, 0));

          -- Regla de traslado: Si el correlativo actual no existe en el destino, puede conservarlo;
          -- si ya existe (colisión), toma el siguiente al máximo del destino.
          SELECT EXISTS (
            SELECT 1 FROM activos
             WHERE ambiente_id = NEW.ambiente_id
               AND tipo_activo_id = NEW.tipo_activo_id
               AND numero_correlativo = OLD.numero_correlativo
               AND estado <> 'Inactivo'
               AND id <> OLD.id
          ) INTO v_colision;

          IF NOT v_colision THEN
            NEW.numero_correlativo := OLD.numero_correlativo;
          ELSE
            SELECT COALESCE(MAX(numero_correlativo), 0) + 1
              INTO NEW.numero_correlativo
              FROM activos
             WHERE ambiente_id = NEW.ambiente_id
               AND tipo_activo_id = NEW.tipo_activo_id
               AND estado <> 'Inactivo'
               AND id <> OLD.id;
          END IF;

          IF NEW.numero_correlativo > 9999 OR NEW.numero_correlativo < 1 THEN
            RAISE EXCEPTION 'El correlativo debe estar entre 1 y 9999 en el ambiente de destino';
          END IF;

          v_yy := to_char(COALESCE(NEW.fecha_ingreso, OLD.fecha_ingreso, CURRENT_DATE), 'YY');
          NEW.codigo_activo := '150'
            || lpad(v_tt::text, 2, '0')
            || lpad(v_aa::text, 2, '0')
            || NEW.numero_correlativo::text
            || '-' || v_yy;

        ELSE
          -- Si no hubo cambio de ambiente, el cliente no puede alterar codigo_activo ni numero_correlativo
          IF NEW.codigo_activo IS DISTINCT FROM OLD.codigo_activo
          OR NEW.numero_correlativo IS DISTINCT FROM OLD.numero_correlativo THEN
            RAISE EXCEPTION 'La identidad del activo (código y correlativo) solo puede cambiar automáticamente en traslados de ambiente';
          END IF;
        END IF;

        -- El tipo de activo es inmutable
        IF NEW.tipo_activo_id IS DISTINCT FROM OLD.tipo_activo_id THEN
          RAISE EXCEPTION 'El tipo de activo es inmutable';
        END IF;

        RETURN NEW;
      END $$;
    `, { transaction: t });
    console.log('✅ Trigger function fn_activos_identidad_inmutable actualizada.');

    // 9. Asegurar triggers en la tabla
    await sequelize.query(`
      DROP TRIGGER IF EXISTS trg_activos_codigo ON activos;
      CREATE TRIGGER trg_activos_codigo 
        BEFORE INSERT ON activos 
        FOR EACH ROW EXECUTE FUNCTION fn_activos_asignar_codigo();

      DROP TRIGGER IF EXISTS trg_activos_identidad ON activos;
      CREATE TRIGGER trg_activos_identidad 
        BEFORE UPDATE ON activos 
        FOR EACH ROW EXECUTE FUNCTION fn_activos_identidad_inmutable();
    `, { transaction: t });
    console.log('✅ Triggers trg_activos_codigo y trg_activos_identidad rearmados correctamente.');

    await t.commit();
    console.log('🚀 ¡MIGRACIÓN COMPLETADA CON ÉXITO!');
    process.exit(0);
  } catch (err) {
    await t.rollback();
    console.error('❌ Error en la migración:', err);
    process.exit(1);
  }
}

migrate();
