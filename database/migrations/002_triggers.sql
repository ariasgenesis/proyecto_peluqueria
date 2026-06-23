-- =====================================================
-- 002_triggers.sql — triggers
-- Sin sentencias DELIMITER. El runner separa cada bloque por el
-- marcador de linea de abajo (ver migrate.py).
-- =====================================================

-- @stmt
DROP TRIGGER IF EXISTS trg_validar_stock_negativo;

-- @stmt
CREATE TRIGGER trg_validar_stock_negativo
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
    IF NEW.pro_stock < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El stock no puede ser negativo.';
    END IF;
END
