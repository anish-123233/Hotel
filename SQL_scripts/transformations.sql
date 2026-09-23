-- ============================================================
-- DATA TRANSFORMATIONS
-- ============================================================
-- Purpose:
-- Apply date-related transformations required for analysis.

-- 1. Convert timestamp columns across the public schema to
--    DATE format to remove the time component where only the
--    calendar date is required.

-- 2. Classify Friday and Saturday as weekends and all other
--    days as weekdays in the dim_date table.
-- ============================================================

-- ============================================================
-- TIMESTAMP TO DATE TRANSFORMATION
-- ============================================================
-- Purpose:
-- Convert all timestamp columns in the public schema to DATE.
--
-- This removes the time component where only the calendar date
-- is required for analysis.
--
-- The transformation is applied dynamically to every column
-- whose data type is:
--   - timestamp without time zone
--   - timestamp with time zone
-- ============================================================


DO $$
DECLARE 
    col RECORD;
BEGIN 
    -- Identify all timestamp columns in the public schema
    FOR COL IN 
        SELECT 
            table_schema,
            table_name,
            column_name,
            data_type
        from information_schema.columns
        where table_schema = 'public'
            AND data_type in (
                'timestamp without time zone',
                'timestamp with time zone'
            )
    LOOP 

        -- Convert each identified timestamp column to DATE
        -- using the existing column value cast to DATE.

        EXECUTE format(
            'ALTER TABLE %I.%I
             ALTER COLUMN %I TYPE DATE
             USING %I::DATE',
             col.table_schema,
             col.table_name,
             col.column_name,
             col.column_name
        );

    END LOOP;
END $$;

-- ============================================================
-- DATE DIMENSION TRANSFORMATION
-- ============================================================
-- Purpose:
-- Update day_type based on ISO weekday numbering.
-- Friday and Saturday are treated as weekends for this dataset's business calendar.
-- ============================================================

UPDATE dim_date
SET day_type = 
    CASE 
        WHEN EXTRACT(ISODOW FROM date) IN (5,6) THEN 'weekend'
        ELSE 'weekday'
    END;
