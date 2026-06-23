-- =====================================================
-- 001_schema.sql — DDL del sistema (tablas, índices)
-- La base de datos la crea/selecciona el runner (migrate.py)
-- usando MYSQL_DB del .env, para evitar el desajuste gestiondb/gestionbd.
-- Reejecutable: hace DROP de todo antes de crear.
-- =====================================================

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS movimientos_inventario;
DROP TABLE IF EXISTS movimientos;
DROP TABLE IF EXISTS pagos;
DROP TABLE IF EXISTS facturas;
DROP TABLE IF EXISTS detalle_citas;
DROP TABLE IF EXISTS citas;
DROP TABLE IF EXISTS detalle_reservas_web;
DROP TABLE IF EXISTS reservas_web;
DROP TABLE IF EXISTS servicios_productos;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS servicios;
DROP TABLE IF EXISTS bloqueos_horarios;
DROP TABLE IF EXISTS horarios;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS empleados;
DROP TABLE IF EXISTS usuarios;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE usuarios (
    usu_id INT AUTO_INCREMENT PRIMARY KEY,
    usu_username VARCHAR(50) UNIQUE NOT NULL,
    usu_password VARCHAR(255) NOT NULL,
    usu_email VARCHAR(100) UNIQUE NOT NULL,
    usu_rol ENUM('admin', 'empleado', 'cliente') NOT NULL,
    usu_estado ENUM('activo', 'inactivo') DEFAULT 'activo',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE empleados (
    emp_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_usuario_id INT UNIQUE NOT NULL,
    emp_documento VARCHAR(20) UNIQUE NOT NULL,
    emp_nombre VARCHAR(50) NOT NULL,
    emp_apellido VARCHAR(50) NOT NULL,
    emp_telefono VARCHAR(20),
    emp_cargo VARCHAR(50),
    emp_especialidad VARCHAR(100),
    emp_pin VARCHAR(255) NOT NULL,
    emp_estado ENUM('activo', 'inactivo') DEFAULT 'activo',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (emp_usuario_id) REFERENCES usuarios(usu_id) ON DELETE CASCADE
);

CREATE TABLE clientes (
    cli_id INT AUTO_INCREMENT PRIMARY KEY,
    cli_usuario_id INT UNIQUE NOT NULL,
    cli_documento VARCHAR(20) UNIQUE NOT NULL,
    cli_nombre VARCHAR(50) NOT NULL,
    cli_apellido VARCHAR(50) NOT NULL,
    cli_telefono VARCHAR(20),
    cli_direccion VARCHAR(150),
    cli_estado ENUM('activo', 'inactivo') DEFAULT 'activo',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (cli_usuario_id) REFERENCES usuarios(usu_id) ON DELETE CASCADE
);

CREATE TABLE horarios (
    hor_id INT AUTO_INCREMENT PRIMARY KEY,
    hor_empleado_id INT NOT NULL,
    hor_dia_semana ENUM('lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo') NOT NULL,
    hor_hora_inicio TIME NOT NULL,
    hor_hora_fin TIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (hor_empleado_id) REFERENCES empleados(emp_id) ON DELETE CASCADE,
    CHECK (hor_hora_inicio < hor_hora_fin)
);

CREATE TABLE bloqueos_horarios (
    blo_id INT AUTO_INCREMENT PRIMARY KEY,
    blo_empleado_id INT NOT NULL,
    blo_fecha DATE NOT NULL,
    blo_hora_inicio TIME NOT NULL,
    blo_hora_fin TIME NOT NULL,
    blo_motivo VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (blo_empleado_id) REFERENCES empleados(emp_id) ON DELETE CASCADE,
    CHECK (blo_hora_inicio < blo_hora_fin)
);

CREATE TABLE servicios (
    ser_id INT AUTO_INCREMENT PRIMARY KEY,
    ser_nombre VARCHAR(100) NOT NULL,
    ser_descripcion TEXT,
    ser_imagen VARCHAR(255) NULL,
    ser_precio DECIMAL(10,2) NOT NULL CHECK (ser_precio >= 0),
    ser_duracion INT NOT NULL CHECK (ser_duracion > 0) COMMENT 'Duración en minutos',
    ser_estado ENUM('activo', 'inactivo') DEFAULT 'activo',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE productos (
    pro_id INT AUTO_INCREMENT PRIMARY KEY,
    pro_nombre VARCHAR(100) NOT NULL,
    pro_precio DECIMAL(10,2) NOT NULL CHECK (pro_precio >= 0),
    pro_stock INT NOT NULL DEFAULT 0 CHECK (pro_stock >= 0),
    pro_stock_minimo INT DEFAULT 5 CHECK (pro_stock_minimo >= 0),
    pro_tipo_control ENUM('unitario', 'manual') DEFAULT 'manual',
    pro_estado ENUM('activo', 'inactivo') DEFAULT 'activo',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE servicios_productos (
    sep_id INT AUTO_INCREMENT PRIMARY KEY,
    sep_servicio_id INT NOT NULL,
    sep_producto_id INT NOT NULL,
    sep_cantidad INT NOT NULL CHECK (sep_cantidad > 0),
    FOREIGN KEY (sep_servicio_id) REFERENCES servicios(ser_id) ON DELETE CASCADE,
    FOREIGN KEY (sep_producto_id) REFERENCES productos(pro_id) ON DELETE CASCADE,
    UNIQUE (sep_servicio_id, sep_producto_id)
);

CREATE TABLE reservas_web (
    res_id INT AUTO_INCREMENT PRIMARY KEY,
    res_cliente_id INT NOT NULL,
    res_empleado_id INT NULL,
    res_fecha DATE NOT NULL,
    res_hora TIME NOT NULL,
    res_anticipo DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (res_anticipo >= 0),
    res_estado ENUM('pendiente', 'pagada', 'cancelada') DEFAULT 'pendiente',
    res_referencia_pago VARCHAR(255),
    res_transaccion_id VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (res_cliente_id) REFERENCES clientes(cli_id),
    FOREIGN KEY (res_empleado_id) REFERENCES empleados(emp_id)
);

CREATE TABLE detalle_reservas_web (
    drv_id INT AUTO_INCREMENT PRIMARY KEY,
    drv_reserva_id INT NOT NULL,
    drv_servicio_id INT NOT NULL,
    drv_precio DECIMAL(10,2) NOT NULL CHECK (drv_precio >= 0),
    FOREIGN KEY (drv_reserva_id) REFERENCES reservas_web(res_id) ON DELETE CASCADE,
    FOREIGN KEY (drv_servicio_id) REFERENCES servicios(ser_id),
    UNIQUE (drv_reserva_id, drv_servicio_id)
);

CREATE TABLE citas (
    cit_id INT AUTO_INCREMENT PRIMARY KEY,
    cit_cliente_id INT NOT NULL,
    cit_empleado_id INT NOT NULL,
    cit_fecha DATE NOT NULL,
    cit_hora TIME NOT NULL,
    cit_origen ENUM('dashboard', 'web') DEFAULT 'dashboard',
    cit_estado ENUM('pendiente', 'confirmada', 'cancelada', 'completada') DEFAULT 'pendiente',
    cit_creado_por INT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (cit_cliente_id) REFERENCES clientes(cli_id),
    FOREIGN KEY (cit_empleado_id) REFERENCES empleados(emp_id),
    FOREIGN KEY (cit_creado_por) REFERENCES usuarios(usu_id),
    UNIQUE (cit_empleado_id, cit_fecha, cit_hora)
);

CREATE TABLE detalle_citas (
    dci_id INT AUTO_INCREMENT PRIMARY KEY,
    dci_cita_id INT NOT NULL,
    dci_servicio_id INT NOT NULL,
    dci_precio DECIMAL(10,2) NOT NULL CHECK (dci_precio >= 0),
    FOREIGN KEY (dci_cita_id) REFERENCES citas(cit_id) ON DELETE CASCADE,
    FOREIGN KEY (dci_servicio_id) REFERENCES servicios(ser_id)
);

CREATE TABLE facturas (
    fac_id INT AUTO_INCREMENT PRIMARY KEY,
    fac_cita_id INT NULL,
    fac_reserva_id INT NULL,
    fac_fecha DATE NOT NULL,
    fac_total DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (fac_total >= 0),
    fac_anticipo DECIMAL(10,2) DEFAULT 0 CHECK (fac_anticipo >= 0),
    fac_saldo_pendiente DECIMAL(10,2) DEFAULT 0 CHECK (fac_saldo_pendiente >= 0),
    fac_tipo ENUM('anticipo', 'servicio') NOT NULL,
    fac_estado ENUM('pendiente', 'parcial', 'pagada', 'cancelada') DEFAULT 'pendiente',
    fac_inventario_procesado TINYINT(1) DEFAULT 0,
    fac_generada_por INT NOT NULL,
    fac_modificada_por INT NULL,
    fac_fecha_modificacion DATETIME NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (fac_cita_id) REFERENCES citas(cit_id),
    FOREIGN KEY (fac_reserva_id) REFERENCES reservas_web(res_id),
    FOREIGN KEY (fac_generada_por) REFERENCES usuarios(usu_id),
    FOREIGN KEY (fac_modificada_por) REFERENCES usuarios(usu_id)
);

CREATE TABLE pagos (
    pag_id INT AUTO_INCREMENT PRIMARY KEY,
    pag_factura_id INT NOT NULL,
    pag_metodo ENUM('efectivo', 'transferencia', 'tarjeta', 'wompi') NOT NULL,
    pag_estado ENUM('pendiente', 'completado', 'cancelado') DEFAULT 'completado',
    pag_fecha DATE NOT NULL,
    pag_monto DECIMAL(10,2) NOT NULL CHECK (pag_monto > 0),
    pag_referencia VARCHAR(255),
    pag_transaccion_id VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pag_factura_id) REFERENCES facturas(fac_id) ON DELETE CASCADE
);

CREATE TABLE movimientos (
    mov_id INT AUTO_INCREMENT PRIMARY KEY,
    mov_usuario_id INT NOT NULL,
    mov_tipo ENUM('crear_factura', 'editar_factura', 'eliminar_factura', 'crear_cita', 'cancelar_cita', 'agregar_stock', 'descontar_stock', 'editar_producto', 'crear_reserva_web', 'cancelar_reserva_web', 'confirmar_pago_wompi') NOT NULL,
    mov_descripcion TEXT,
    mov_fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (mov_usuario_id) REFERENCES usuarios(usu_id)
);

CREATE TABLE movimientos_inventario (
    moi_id INT AUTO_INCREMENT PRIMARY KEY,
    moi_producto_id INT NOT NULL,
    moi_usuario_id INT NOT NULL,
    moi_factura_id INT NULL,
    moi_servicio_id INT NULL,
    moi_tipo ENUM('entrada', 'salida', 'ajuste') NOT NULL,
    moi_cantidad INT NOT NULL CHECK (moi_cantidad > 0),
    moi_descripcion TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (moi_producto_id) REFERENCES productos(pro_id) ON DELETE CASCADE,
    FOREIGN KEY (moi_usuario_id) REFERENCES usuarios(usu_id),
    FOREIGN KEY (moi_factura_id) REFERENCES facturas(fac_id),
    FOREIGN KEY (moi_servicio_id) REFERENCES servicios(ser_id)
);

CREATE INDEX idx_citas_fecha_hora ON citas(cit_fecha, cit_hora);
CREATE INDEX idx_facturas_estado ON facturas(fac_estado);
CREATE INDEX idx_facturas_tipo ON facturas(fac_tipo);
CREATE INDEX idx_productos_stock ON productos(pro_stock);
CREATE INDEX idx_reservas_cliente ON reservas_web(res_cliente_id);
CREATE INDEX idx_movimientos_inv_prod ON movimientos_inventario(moi_producto_id);
CREATE INDEX idx_facturas_estado_inv ON facturas(fac_estado, fac_inventario_procesado);
