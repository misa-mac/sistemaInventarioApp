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

-- ---------- 4. ACTIVOS (código real X·CC·TT·AA·NNNN-YY) ----------
-- ambiente_id = ubicación ACTUAL (el código cambia automáticamente con el traslado)
CREATE TABLE activos (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo_activo        VARCHAR(25) NOT NULL CHECK (codigo_activo ~ '^1[0-9]{2}[0-9]{2}[0-9]{2}[0-9]{1,4}-[0-9]{2}$'),
  numero_correlativo   INTEGER     NOT NULL CHECK (numero_correlativo BETWEEN 1 AND 9999),
  tipo_activo_id       UUID        NOT NULL REFERENCES tipo_activos(id),
  ambiente_id          UUID        NOT NULL REFERENCES ambientes(id),
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
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX activos_codigo_activo_uidx 
  ON activos (codigo_activo) 
  WHERE estado <> 'Inactivo';

CREATE UNIQUE INDEX activos_tipo_ambiente_correlativo_uidx 
  ON activos (tipo_activo_id, ambiente_id, numero_correlativo) 
  WHERE estado <> 'Inactivo';

-- Genera el código real X·CC·TT·AA·NNNN-YY (X=1 fijo, CC=50 carrera, TT=tipo, AA=ambiente, NNNN=correlativo 1-4 dígitos sin ceros, YY=año).
CREATE FUNCTION fn_activos_asignar_codigo() RETURNS trigger LANGUAGE plpgsql AS $$
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

-- Control de inmutabilidad y cálculo automático en traslados de ambiente
CREATE FUNCTION fn_activos_identidad_inmutable() RETURNS trigger LANGUAGE plpgsql AS $$
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
