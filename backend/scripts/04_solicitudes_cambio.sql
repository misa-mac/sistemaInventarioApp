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

-- 5. Generador automático del código institucional real X·CC·TT·AA·NNNN-YY
CREATE OR REPLACE FUNCTION fn_activos_asignar_codigo() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_tt INTEGER;
  v_aa INTEGER;
  v_yy TEXT;
BEGIN
  SELECT codigo INTO v_tt FROM tipo_activos WHERE id = NEW.tipo_activo_id;
  SELECT codigo INTO v_aa FROM ambientes    WHERE id = NEW.ambiente_id;

  IF v_tt IS NULL OR v_aa IS NULL THEN
    RAISE EXCEPTION 'Tipo de activo o ambiente inexistente al asignar código';
  END IF;

  -- Bloqueo transaccional consultivo para evitar colisiones en altas concurrentes
  PERFORM pg_advisory_xact_lock(
    hashtextextended('50' || NEW.tipo_activo_id::text || NEW.ambiente_id::text, 0)
  );

  -- Asigna el siguiente al máximo existente en esa carrera+tipo+ambiente (solo activos no dados de baja)
  IF NEW.numero_correlativo IS NULL THEN
    SELECT COALESCE(MAX(numero_correlativo), 0) + 1
      INTO NEW.numero_correlativo
      FROM activos
     WHERE tipo_activo_id = NEW.tipo_activo_id
       AND ambiente_id = NEW.ambiente_id
       AND estado <> 'Inactivo';
  END IF;

  IF NEW.numero_correlativo > 9999 OR NEW.numero_correlativo < 1 THEN
    RAISE EXCEPTION 'El correlativo debe estar entre 1 y 9999 (máx. 9999 agotado para este tipo en este ambiente)';
  END IF;

  v_yy := to_char(COALESCE(NEW.fecha_ingreso, CURRENT_DATE), 'YY');
  NEW.codigo_activo := '150'
    || lpad(v_tt::text, 2, '0')
    || lpad(v_aa::text, 2, '0')
    || NEW.numero_correlativo::text
    || '-' || v_yy;

  -- Nombre descriptivo por defecto si viene vacío
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
