-- ====================================================================
-- 04_solicitudes_cambio.sql: Flujo de gobernanza y solicitudes de cambio
-- La web es la autoridad del inventario. La app móvil propone cambios
-- y SOLO la web los confirma (altas, ediciones y bajas).
-- ====================================================================

BEGIN;

-- 1. Tipos ENUM para solicitudes de cambio
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_solicitud') THEN
    CREATE TYPE tipo_solicitud AS ENUM ('alta', 'edicion', 'baja');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_solicitud') THEN
    CREATE TYPE estado_solicitud AS ENUM ('pendiente', 'aprobada', 'rechazada');
  END IF;
END $$;

-- 2. Tabla solicitudes_cambio
CREATE TABLE IF NOT EXISTS solicitudes_cambio (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo                  tipo_solicitud NOT NULL,
  estado                estado_solicitud NOT NULL DEFAULT 'pendiente',
  solicitante_id        UUID NOT NULL REFERENCES usuarios(id),
  activo_id             UUID REFERENCES activos(id),
  datos                 JSONB NOT NULL DEFAULT '{}'::jsonb,
  motivo                TEXT,
  comentario_revision   TEXT,
  revisado_por          UUID REFERENCES usuarios(id),
  fecha_revision        TIMESTAMPTZ,
  activo_resultante_id  UUID REFERENCES activos(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Reglas de integridad
  CHECK (tipo = 'alta' OR activo_id IS NOT NULL),
  CHECK (tipo <> 'baja' OR (motivo IS NOT NULL AND length(btrim(motivo)) > 0)),
  CHECK (estado <> 'rechazada' OR (comentario_revision IS NOT NULL AND length(btrim(comentario_revision)) > 0)),
  CHECK (estado = 'pendiente' OR (revisado_por IS NOT NULL AND fecha_revision IS NOT NULL))
);

-- 3. Trigger updated_at para solicitudes_cambio
DROP TRIGGER IF EXISTS trg_solicitudes_cambio_updated ON solicitudes_cambio;
CREATE TRIGGER trg_solicitudes_cambio_updated
  BEFORE UPDATE ON solicitudes_cambio
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 4. Índices para acelerar consultas y filtros
CREATE INDEX IF NOT EXISTS idx_solicitudes_estado      ON solicitudes_cambio(estado, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_solicitudes_solicitante ON solicitudes_cambio(solicitante_id);
CREATE INDEX IF NOT EXISTS idx_solicitudes_activo      ON solicitudes_cambio(activo_id);
CREATE INDEX IF NOT EXISTS idx_solicitudes_tipo        ON solicitudes_cambio(tipo);

-- 5. Ajuste del trigger de asignación de código para asegurar que la base sea la única fuente de verdad
CREATE OR REPLACE FUNCTION fn_activos_asignar_codigo() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_aa INTEGER;
  v_cc INTEGER;
BEGIN
  IF NEW.ambiente_registro_id IS NULL THEN
    NEW.ambiente_registro_id := NEW.ambiente_id;
  END IF;

  -- Si codigo_activo es nulo o vacío, la base de datos lo genera obligatoriamente
  IF NEW.codigo_activo IS NULL OR btrim(NEW.codigo_activo) = '' THEN
    SELECT codigo INTO v_aa FROM tipo_activos WHERE id = NEW.tipo_activo_id;
    SELECT codigo INTO v_cc FROM ambientes    WHERE id = NEW.ambiente_registro_id;
    IF v_aa IS NULL OR v_cc IS NULL THEN
      RAISE EXCEPTION 'Tipo de activo o ambiente de registro inexistente';
    END IF;

    -- Evita correlativos duplicados con altas simultáneas
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

-- 6. Otorgar permisos al rol app_inventario si existe
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_inventario') THEN
    GRANT SELECT, INSERT, UPDATE ON TABLE solicitudes_cambio TO app_inventario;
  END IF;
END $$;

COMMIT;
