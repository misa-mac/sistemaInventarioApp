-- =====================================================================
-- MIGRACIÓN 05: SISTEMA HÍBRIDO DE QR - ESTACIONES DE TRABAJO (MESAS)
-- =====================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS estaciones_trabajo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo_estacion VARCHAR(50) NOT NULL UNIQUE,
    ambiente_id UUID NOT NULL REFERENCES ambientes(id) ON DELETE RESTRICT,
    descripcion VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Agregar estacion_id a activos si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'activos' AND column_name = 'estacion_id'
    ) THEN
        ALTER TABLE activos 
        ADD COLUMN estacion_id UUID NULL 
        REFERENCES estaciones_trabajo(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Índice para acelerar búsquedas de componentes por estación
CREATE INDEX IF NOT EXISTS idx_activos_estacion_id ON activos(estacion_id);
CREATE INDEX IF NOT EXISTS idx_estaciones_ambiente_id ON estaciones_trabajo(ambiente_id);

COMMIT;

