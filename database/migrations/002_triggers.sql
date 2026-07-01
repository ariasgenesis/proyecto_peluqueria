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

-- @stmt
DROP TRIGGER IF EXISTS trg_sincronizar_servicios_por_stock;

-- @stmt
CREATE TRIGGER trg_sincronizar_servicios_por_stock
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
    IF NEW.pro_stock <> OLD.pro_stock
        OR NEW.pro_stock_minimo <> OLD.pro_stock_minimo
        OR NEW.pro_estado <> OLD.pro_estado THEN
        UPDATE servicios s
        SET s.ser_estado = CASE
            WHEN EXISTS (
                SELECT 1
                FROM servicios_productos sp2
                INNER JOIN productos p2 ON p2.pro_id = sp2.sep_producto_id
                WHERE sp2.sep_servicio_id = s.ser_id
                  AND (p2.pro_estado <> 'activo' OR p2.pro_stock <= p2.pro_stock_minimo)
            ) THEN 'inactivo'
            ELSE 'activo'
        END
        WHERE s.ser_id IN (
            SELECT sp.sep_servicio_id
            FROM servicios_productos sp
            WHERE sp.sep_producto_id = NEW.pro_id
        );
    END IF;
END
