-- =====================================================================
-- Sistema de control de inventario QR - Esquema PostgreSQL UNIFICADO (web + app móvil)
-- Fusiona el esquema de Supabase (app) con el del documento/web (código XYZAACC-GG).
-- Ejecutar UNA sola vez sobre una base vacía. Para cambios posteriores usar
-- migraciones (sequelize-cli), no sequelize.sync({ alter: true }).
-- Requiere PostgreSQL 13 o superior (gen_random_uuid() es nativo).
-- =====================================================================
BEGIN;

-- ---------- Tipos ENUM ----------
CREATE TYPE rol_usuario              AS ENUM ('admin', 'tecnico', 'auditor');
CREATE TYPE estado_activo            AS ENUM ('Activo', 'Inactivo', 'Dañado');
CREATE TYPE tipo_evento              AS ENUM ('traslado', 'mantenimiento', 'baja');
CREATE TYPE tipo_notificacion        AS ENUM ('info', 'warning', 'error', 'success');
CREATE TYPE tipo_mantenimiento       AS ENUM ('preventivo', 'correctivo');
CREATE TYPE estado_auditoria         AS ENUM ('presente', 'faltante', 'no_esperado');
CREATE TYPE estado_sesion_auditoria  AS ENUM ('en_progreso', 'completada', 'cancelada');

-- ---------- Funciones auxiliares ----------
-- Mantiene updated_at (DEFAULT now() solo actúa al insertar).
CREATE FUNCTION set_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

-- Impide UPDATE, DELETE y TRUNCATE (se usa en audit_logs).
CREATE FUNCTION fn_bloquear_modificacion() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'La tabla % es de solo inserción (operación % bloqueada)', TG_TABLE_NAME, TG_OP;
END $$;

-- ---------- 1. USUARIOS ----------
CREATE TABLE usuarios (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre_completo VARCHAR(150) NOT NULL,
  email           VARCHAR(150) NOT NULL UNIQUE CHECK (email = lower(email)),
  password_hash   VARCHAR(255) NOT NULL,           -- bcrypt, nunca texto plano
  rol             rol_usuario  NOT NULL DEFAULT 'tecnico',
  activo          BOOLEAN      NOT NULL DEFAULT true,  -- baja lógica, no se borran usuarios
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ---------- 2. TIPO_ACTIVOS (código AA) ----------
CREATE TABLE tipo_activos (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre      VARCHAR(100) NOT NULL UNIQUE,
  codigo      INTEGER      NOT NULL UNIQUE CHECK (codigo BETWEEN 0 AND 99),
  descripcion TEXT,
  activo      BOOLEAN      NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ---------- 3. AMBIENTES (código CC + geofence) ----------
CREATE TABLE ambientes (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre         VARCHAR(100)  NOT NULL UNIQUE,
  codigo         INTEGER       NOT NULL UNIQUE CHECK (codigo BETWEEN 0 AND 99),
  ubicacion      VARCHAR(255),
  descripcion    TEXT,
  latitude       NUMERIC(10,8) CHECK (latitude  BETWEEN -90  AND 90),
  longitude      NUMERIC(11,8) CHECK (longitude BETWEEN -180 AND 180),
  radio_geofence NUMERIC(5,2)  NOT NULL DEFAULT 50 CHECK (radio_geofence > 0),  -- metros
  tiene_internet BOOLEAN       NOT NULL DEFAULT true,   -- indica si el ambiente dispone de conexión a internet
  activo         BOOLEAN       NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
  CHECK ((latitude IS NULL) = (longitude IS NULL))   -- ambas coordenadas o ninguna
);

-- ---------- 4. ACTIVOS (código XYZAACC-GG) ----------
-- ambiente_id          = ubicación ACTUAL (cambia con los traslados)
-- ambiente_registro_id = ambiente donde se etiquetó (bloque CC del código), no cambia
CREATE TABLE activos (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_activo        VARCHAR(20) NOT NULL UNIQUE CHECK (codigo_activo ~ '^[0-9]{7}-[0-9]{2}$'),
  numero_correlativo   INTEGER     NOT NULL CHECK (numero_correlativo BETWEEN 1 AND 99),
  tipo_activo_id       UUID        NOT NULL REFERENCES tipo_activos(id),
  ambiente_id          UUID        NOT NULL REFERENCES ambientes(id),
  ambiente_registro_id UUID        NOT NULL REFERENCES ambientes(id),
  nombre               VARCHAR(150) NOT NULL,   -- si no se envía, el trigger lo arma (tipo + código)
  marca                VARCHAR(100),
  modelo               VARCHAR(100),
  numero_serie         VARCHAR(100),
  origen               VARCHAR(150),
  especificacion_origen VARCHAR(255),
  descripcion          TEXT,
  responsable          VARCHAR(150),
  fecha_ingreso        DATE,
  valor                NUMERIC(10,2) CHECK (valor >= 0),
  imagen_url           TEXT,                    -- ruta (/uploads/...) o URL; la entrega la API
  estado               estado_activo NOT NULL DEFAULT 'Activo',
  observaciones        TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tipo_activo_id, ambiente_registro_id, numero_correlativo)
);

-- Genera el código XYZAACC-GG si no se envía (X=1 fijo, YZ=año, AA=tipo, CC=ambiente, GG=correlativo).
CREATE FUNCTION fn_activos_asignar_codigo() RETURNS trigger LANGUAGE plpgsql AS $$
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

    -- Evita correlativos duplicados con altas simultáneas.
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

-- La identidad del activo (lo que está impreso en el QR) no puede cambiar.
CREATE FUNCTION fn_activos_identidad_inmutable() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.codigo_activo        IS DISTINCT FROM OLD.codigo_activo
  OR NEW.numero_correlativo   IS DISTINCT FROM OLD.numero_correlativo
  OR NEW.tipo_activo_id       IS DISTINCT FROM OLD.tipo_activo_id
  OR NEW.ambiente_registro_id IS DISTINCT FROM OLD.ambiente_registro_id THEN
    RAISE EXCEPTION 'La identidad del activo (código, tipo y ambiente de registro) es inmutable';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_activos_codigo   BEFORE INSERT ON activos
  FOR EACH ROW EXECUTE FUNCTION fn_activos_asignar_codigo();
CREATE TRIGGER trg_activos_identidad BEFORE UPDATE ON activos
  FOR EACH ROW EXECUTE FUNCTION fn_activos_identidad_inmutable();

-- ---------- 5. MOVIMIENTOS (traslados, mantenimientos, bajas) ----------
CREATE TABLE movimientos (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo_evento        tipo_evento NOT NULL,
  activo_id          UUID NOT NULL REFERENCES activos(id),
  usuario_id         UUID NOT NULL REFERENCES usuarios(id),
  ambiente_origen_id  UUID REFERENCES ambientes(id),
  ambiente_destino_id UUID REFERENCES ambientes(id),
  estado_anterior    estado_activo,
  estado_nuevo       estado_activo,
  tipo_mantenimiento tipo_mantenimiento,        -- solo si tipo_evento = 'mantenimiento'
  piezas_reemplazadas TEXT,                     -- solo si tipo_evento = 'mantenimiento'
  costo_mantenimiento NUMERIC(10,2) CHECK (costo_mantenimiento >= 0),
  observaciones      TEXT,                      -- descripción del trabajo (obligatoria en mantenimiento)
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (tipo_evento = 'mantenimiento'
         OR (tipo_mantenimiento IS NULL AND piezas_reemplazadas IS NULL AND costo_mantenimiento IS NULL)),
  CHECK (tipo_evento <> 'mantenimiento' OR length(btrim(COALESCE(observaciones, ''))) > 0),
  CHECK (tipo_evento <> 'traslado'
         OR (ambiente_origen_id IS NOT NULL
             AND ambiente_destino_id IS NOT NULL
             AND ambiente_origen_id <> ambiente_destino_id))
);

-- ---------- 6. NOTIFICACIONES ----------
CREATE TABLE notificaciones (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES usuarios(id),       -- NULL = para todos los administradores
  titulo     VARCHAR(200) NOT NULL,
  mensaje    TEXT NOT NULL,
  tipo       tipo_notificacion NOT NULL DEFAULT 'info',
  leida      BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- 7. AUDITORIAS (sesiones desde la app móvil) ----------
CREATE TABLE auditorias (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ambiente_id       UUID NOT NULL REFERENCES ambientes(id),
  auditor_id        UUID NOT NULL REFERENCES usuarios(id),   -- quien ejecuta la auditoría (el rol lo controla la API)
  fecha_inicio      TIMESTAMPTZ NOT NULL DEFAULT now(),
  fecha_fin         TIMESTAMPTZ,
  total_esperados   INTEGER NOT NULL DEFAULT 0 CHECK (total_esperados   >= 0),
  total_encontrados INTEGER NOT NULL DEFAULT 0 CHECK (total_encontrados >= 0),
  total_faltantes   INTEGER NOT NULL DEFAULT 0 CHECK (total_faltantes   >= 0),
  total_no_esperados INTEGER NOT NULL DEFAULT 0 CHECK (total_no_esperados >= 0),
  estado            estado_sesion_auditoria NOT NULL DEFAULT 'en_progreso',
  observaciones     TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

-- ---------- 8. DETALLE_AUDITORIA (un escaneo) ----------
CREATE TABLE detalle_auditoria (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auditoria_id        UUID NOT NULL REFERENCES auditorias(id) ON DELETE CASCADE,
  activo_id           UUID REFERENCES activos(id),
  codigo_qr_escaneado VARCHAR(50),
  estado              estado_auditoria NOT NULL,
  observacion         TEXT,
  fecha_escaneo       TIMESTAMPTZ NOT NULL DEFAULT now(),   -- hora del dispositivo
  sincronizado        BOOLEAN NOT NULL DEFAULT true,
  CHECK (estado = 'no_esperado' OR activo_id IS NOT NULL),
  CHECK (estado = 'faltante'    OR codigo_qr_escaneado IS NOT NULL)
);

-- ---------- 9. AUDIT_LOGS (solo inserción, OWASP A09) ----------
CREATE TABLE audit_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id  UUID REFERENCES usuarios(id),
  accion      VARCHAR(100) NOT NULL,
  recurso     VARCHAR(50)  NOT NULL,
  recurso_id  VARCHAR(100),
  resultado   VARCHAR(20)  NOT NULL CHECK (resultado IN ('exitoso', 'fallido')),
  detalles    TEXT,
  ip_address  VARCHAR(45),
  user_agent  TEXT,
  fecha_hora  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_audit_logs_inmutable BEFORE UPDATE OR DELETE ON audit_logs
  FOR EACH ROW EXECUTE FUNCTION fn_bloquear_modificacion();
CREATE TRIGGER trg_audit_logs_no_truncate BEFORE TRUNCATE ON audit_logs
  FOR EACH STATEMENT EXECUTE FUNCTION fn_bloquear_modificacion();

-- ---------- Triggers de updated_at ----------
CREATE TRIGGER trg_usuarios_updated     BEFORE UPDATE ON usuarios     FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_tipo_activos_updated BEFORE UPDATE ON tipo_activos FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_ambientes_updated    BEFORE UPDATE ON ambientes    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_activos_updated      BEFORE UPDATE ON activos      FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------- Índices ----------
CREATE INDEX idx_activos_ambiente       ON activos(ambiente_id);
CREATE INDEX idx_activos_tipo           ON activos(tipo_activo_id);
CREATE INDEX idx_activos_serie          ON activos(numero_serie) WHERE numero_serie IS NOT NULL;
CREATE INDEX idx_movimientos_activo     ON movimientos(activo_id, created_at DESC);
CREATE INDEX idx_movimientos_usuario    ON movimientos(usuario_id);
CREATE INDEX idx_auditorias_ambiente    ON auditorias(ambiente_id);
CREATE INDEX idx_auditorias_auditor     ON auditorias(auditor_id);
CREATE INDEX idx_detalle_auditoria      ON detalle_auditoria(auditoria_id);
CREATE INDEX idx_detalle_activo         ON detalle_auditoria(activo_id);
CREATE INDEX idx_notificaciones_usuario ON notificaciones(usuario_id, leida);
CREATE INDEX idx_audit_logs_fecha       ON audit_logs(fecha_hora);
CREATE INDEX idx_audit_logs_usuario     ON audit_logs(usuario_id);

COMMIT;
