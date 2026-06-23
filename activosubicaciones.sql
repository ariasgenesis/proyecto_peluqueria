-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Versión del servidor:         8.4.3 - MySQL Community Server - GPL
-- SO del servidor:              Win64
-- HeidiSQL Versión:             12.8.0.6908
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Volcando estructura para tabla gestiondb.bloqueos_horarios
CREATE TABLE IF NOT EXISTS `bloqueos_horarios` (
  `blo_id` int NOT NULL AUTO_INCREMENT,
  `blo_empleado_id` int NOT NULL,
  `blo_fecha` date NOT NULL,
  `blo_hora_inicio` time NOT NULL,
  `blo_hora_fin` time NOT NULL,
  `blo_motivo` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`blo_id`),
  KEY `blo_empleado_id` (`blo_empleado_id`),
  CONSTRAINT `bloqueos_horarios_ibfk_1` FOREIGN KEY (`blo_empleado_id`) REFERENCES `empleados` (`emp_id`) ON DELETE CASCADE,
  CONSTRAINT `bloqueos_horarios_chk_1` CHECK ((`blo_hora_inicio` < `blo_hora_fin`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla gestiondb.bloqueos_horarios: ~0 rows (aproximadamente)

-- Volcando estructura para tabla gestiondb.citas
CREATE TABLE IF NOT EXISTS `citas` (
  `cit_id` int NOT NULL AUTO_INCREMENT,
  `cit_cliente_id` int NOT NULL,
  `cit_empleado_id` int NOT NULL,
  `cit_fecha` date NOT NULL,
  `cit_hora` time NOT NULL,
  `cit_origen` enum('dashboard','web') COLLATE utf8mb4_unicode_ci DEFAULT 'dashboard',
  `cit_estado` enum('pendiente','confirmada','cancelada','completada') COLLATE utf8mb4_unicode_ci DEFAULT 'pendiente',
  `cit_creado_por` int DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`cit_id`),
  UNIQUE KEY `cit_empleado_id` (`cit_empleado_id`,`cit_fecha`,`cit_hora`),
  KEY `cit_cliente_id` (`cit_cliente_id`),
  KEY `cit_creado_por` (`cit_creado_por`),
  KEY `idx_citas_fecha_hora` (`cit_fecha`,`cit_hora`),
  CONSTRAINT `citas_ibfk_1` FOREIGN KEY (`cit_cliente_id`) REFERENCES `clientes` (`cli_id`),
  CONSTRAINT `citas_ibfk_2` FOREIGN KEY (`cit_empleado_id`) REFERENCES `empleados` (`emp_id`),
  CONSTRAINT `citas_ibfk_3` FOREIGN KEY (`cit_creado_por`) REFERENCES `usuarios` (`usu_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla gestiondb.citas: ~0 rows (aproximadamente)
REPLACE INTO `citas` (`cit_id`, `cit_cliente_id`, `cit_empleado_id`, `cit_fecha`, `cit_hora`, `cit_origen`, `cit_estado`, `cit_creado_por`, `created_at`, `updated_at`) VALUES
	(1, 2, 1, '2026-06-20', '14:38:00', 'dashboard', 'completada', 1, '2026-06-20 18:38:08', '2026-06-22 23:03:19'),
	(2, 3, 1, '2026-06-23', '12:49:00', 'dashboard', 'confirmada', 8, '2026-06-22 22:49:50', '2026-06-22 22:49:50');

-- Volcando estructura para tabla gestiondb.clientes
CREATE TABLE IF NOT EXISTS `clientes` (
  `cli_id` int NOT NULL AUTO_INCREMENT,
  `cli_usuario_id` int NOT NULL,
  `cli_documento` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cli_nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cli_apellido` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cli_telefono` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cli_direccion` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cli_estado` enum('activo','inactivo') COLLATE utf8mb4_unicode_ci DEFAULT 'activo',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`cli_id`),
  UNIQUE KEY `cli_usuario_id` (`cli_usuario_id`),
  UNIQUE KEY `cli_documento` (`cli_documento`),
  CONSTRAINT `clientes_ibfk_1` FOREIGN KEY (`cli_usuario_id`) REFERENCES `usuarios` (`usu_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla gestiondb.clientes: ~0 rows (aproximadamente)
REPLACE INTO `clientes` (`cli_id`, `cli_usuario_id`, `cli_documento`, `cli_nombre`, `cli_apellido`, `cli_telefono`, `cli_direccion`, `cli_estado`, `created_at`, `updated_at`) VALUES
	(1, 3, '50607080', 'Juan', 'Perez', '3009876543', 'Calle 123', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(2, 7, '1047033333', 'Carolina', 'Cxr', '300123456', 'calle 366', 'activo', '2026-06-20 17:25:31', '2026-06-20 17:25:31'),
	(3, 10, '123123123', 'shanon', 'shanon', '300123456', NULL, 'activo', '2026-06-22 22:01:44', '2026-06-22 22:01:44');

-- Volcando estructura para tabla gestiondb.detalle_citas
CREATE TABLE IF NOT EXISTS `detalle_citas` (
  `dci_id` int NOT NULL AUTO_INCREMENT,
  `dci_cita_id` int NOT NULL,
  `dci_servicio_id` int NOT NULL,
  `dci_precio` decimal(10,2) NOT NULL,
  PRIMARY KEY (`dci_id`),
  KEY `dci_cita_id` (`dci_cita_id`),
  KEY `dci_servicio_id` (`dci_servicio_id`),
  CONSTRAINT `detalle_citas_ibfk_1` FOREIGN KEY (`dci_cita_id`) REFERENCES `citas` (`cit_id`) ON DELETE CASCADE,
  CONSTRAINT `detalle_citas_ibfk_2` FOREIGN KEY (`dci_servicio_id`) REFERENCES `servicios` (`ser_id`),
  CONSTRAINT `detalle_citas_chk_1` CHECK ((`dci_precio` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla gestiondb.detalle_citas: ~0 rows (aproximadamente)

-- Volcando estructura para tabla gestiondb.detalle_reservas_web
CREATE TABLE IF NOT EXISTS `detalle_reservas_web` (
  `drv_id` int NOT NULL AUTO_INCREMENT,
  `drv_reserva_id` int NOT NULL,
  `drv_servicio_id` int NOT NULL,
  `drv_precio` decimal(10,2) NOT NULL,
  PRIMARY KEY (`drv_id`),
  UNIQUE KEY `drv_reserva_id` (`drv_reserva_id`,`drv_servicio_id`),
  KEY `drv_servicio_id` (`drv_servicio_id`),
  CONSTRAINT `detalle_reservas_web_ibfk_1` FOREIGN KEY (`drv_reserva_id`) REFERENCES `reservas_web` (`res_id`) ON DELETE CASCADE,
  CONSTRAINT `detalle_reservas_web_ibfk_2` FOREIGN KEY (`drv_servicio_id`) REFERENCES `servicios` (`ser_id`),
  CONSTRAINT `detalle_reservas_web_chk_1` CHECK ((`drv_precio` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla gestiondb.detalle_reservas_web: ~0 rows (aproximadamente)
REPLACE INTO `detalle_reservas_web` (`drv_id`, `drv_reserva_id`, `drv_servicio_id`, `drv_precio`) VALUES
	(1, 1, 11, 40000.00),
	(2, 2, 11, 40000.00),
	(3, 3, 11, 40000.00),
	(4, 4, 9, 45000.00),
	(5, 4, 10, 80000.00),
	(6, 4, 11, 40000.00),
	(7, 5, 10, 80000.00),
	(8, 5, 11, 40000.00),
	(9, 6, 7, 50000.00),
	(10, 6, 8, 25000.00),
	(11, 6, 9, 45000.00),
	(12, 6, 10, 80000.00),
	(13, 6, 11, 40000.00),
	(14, 7, 8, 25000.00),
	(15, 7, 10, 80000.00),
	(16, 7, 11, 40000.00),
	(17, 8, 10, 80000.00),
	(18, 8, 11, 40000.00),
	(19, 9, 10, 80000.00),
	(20, 9, 11, 40000.00);

-- Volcando estructura para tabla gestiondb.empleados
CREATE TABLE IF NOT EXISTS `empleados` (
  `emp_id` int NOT NULL AUTO_INCREMENT,
  `emp_usuario_id` int NOT NULL,
  `emp_documento` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `emp_nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `emp_apellido` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `emp_telefono` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `emp_cargo` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `emp_especialidad` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `emp_pin` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `emp_estado` enum('activo','inactivo') COLLATE utf8mb4_unicode_ci DEFAULT 'activo',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`emp_id`),
  UNIQUE KEY `emp_usuario_id` (`emp_usuario_id`),
  UNIQUE KEY `emp_documento` (`emp_documento`),
  CONSTRAINT `empleados_ibfk_1` FOREIGN KEY (`emp_usuario_id`) REFERENCES `usuarios` (`usu_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla gestiondb.empleados: ~0 rows (aproximadamente)
REPLACE INTO `empleados` (`emp_id`, `emp_usuario_id`, `emp_documento`, `emp_nombre`, `emp_apellido`, `emp_telefono`, `emp_cargo`, `emp_especialidad`, `emp_pin`, `emp_estado`, `created_at`, `updated_at`) VALUES
	(1, 2, '10203040', 'Ana', 'Lopez', '3001234567', 'Estilista', 'Corte y peinado', '$2b$12$8LhOY4NIEljb.QhdyJA77OKwySA5M20zWb8bDXTlsa4FfDvVZjx.S', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(2, 8, '1047035036', 'Jesús Manuel', 'Cabarca Sanchez', '+573014022553', 'colorista', NULL, '$2b$12$8GtNA/tuceLtqNWqpJ2apuQ3ElzJ6bjix5iSU/7wcnfcITG2wz2L.', 'activo', '2026-06-20 18:51:55', '2026-06-20 18:51:55');

-- Volcando estructura para tabla gestiondb.facturas
CREATE TABLE IF NOT EXISTS `facturas` (
  `fac_id` int NOT NULL AUTO_INCREMENT,
  `fac_cita_id` int DEFAULT NULL,
  `fac_reserva_id` int DEFAULT NULL,
  `fac_fecha` date NOT NULL,
  `fac_total` decimal(10,2) NOT NULL DEFAULT '0.00',
  `fac_anticipo` decimal(10,2) DEFAULT '0.00',
  `fac_saldo_pendiente` decimal(10,2) DEFAULT '0.00',
  `fac_tipo` enum('anticipo','servicio') COLLATE utf8mb4_unicode_ci NOT NULL,
  `fac_estado` enum('pendiente','parcial','pagada','cancelada') COLLATE utf8mb4_unicode_ci DEFAULT 'pendiente',
  `fac_inventario_procesado` tinyint(1) DEFAULT '0',
  `fac_generada_por` int NOT NULL,
  `fac_modificada_por` int DEFAULT NULL,
  `fac_fecha_modificacion` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`fac_id`),
  KEY `fac_cita_id` (`fac_cita_id`),
  KEY `fac_reserva_id` (`fac_reserva_id`),
  KEY `fac_generada_por` (`fac_generada_por`),
  KEY `fac_modificada_por` (`fac_modificada_por`),
  KEY `idx_facturas_estado` (`fac_estado`),
  KEY `idx_facturas_tipo` (`fac_tipo`),
  KEY `idx_facturas_estado_inv` (`fac_estado`,`fac_inventario_procesado`),
  CONSTRAINT `facturas_ibfk_1` FOREIGN KEY (`fac_cita_id`) REFERENCES `citas` (`cit_id`),
  CONSTRAINT `facturas_ibfk_2` FOREIGN KEY (`fac_reserva_id`) REFERENCES `reservas_web` (`res_id`),
  CONSTRAINT `facturas_ibfk_3` FOREIGN KEY (`fac_generada_por`) REFERENCES `usuarios` (`usu_id`),
  CONSTRAINT `facturas_ibfk_4` FOREIGN KEY (`fac_modificada_por`) REFERENCES `usuarios` (`usu_id`),
  CONSTRAINT `facturas_chk_1` CHECK ((`fac_total` >= 0)),
  CONSTRAINT `facturas_chk_2` CHECK ((`fac_anticipo` >= 0)),
  CONSTRAINT `facturas_chk_3` CHECK ((`fac_saldo_pendiente` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla gestiondb.facturas: ~1 rows (aproximadamente)
REPLACE INTO `facturas` (`fac_id`, `fac_cita_id`, `fac_reserva_id`, `fac_fecha`, `fac_total`, `fac_anticipo`, `fac_saldo_pendiente`, `fac_tipo`, `fac_estado`, `fac_inventario_procesado`, `fac_generada_por`, `fac_modificada_por`, `fac_fecha_modificacion`, `created_at`, `updated_at`) VALUES
	(1, NULL, NULL, '2026-06-21', 1200000.00, 80000.00, 1120000.00, 'servicio', 'parcial', 0, 2, 2, '2026-06-20 19:11:33', '2026-06-20 19:00:46', '2026-06-20 19:11:33');

-- Volcando estructura para tabla gestiondb.horarios
CREATE TABLE IF NOT EXISTS `horarios` (
  `hor_id` int NOT NULL AUTO_INCREMENT,
  `hor_empleado_id` int NOT NULL,
  `hor_dia_semana` enum('lunes','martes','miercoles','jueves','viernes','sabado','domingo') COLLATE utf8mb4_unicode_ci NOT NULL,
  `hor_hora_inicio` time NOT NULL,
  `hor_hora_fin` time NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`hor_id`),
  KEY `hor_empleado_id` (`hor_empleado_id`),
  CONSTRAINT `horarios_ibfk_1` FOREIGN KEY (`hor_empleado_id`) REFERENCES `empleados` (`emp_id`) ON DELETE CASCADE,
  CONSTRAINT `horarios_chk_1` CHECK ((`hor_hora_inicio` < `hor_hora_fin`))
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla gestiondb.horarios: ~6 rows (aproximadamente)
REPLACE INTO `horarios` (`hor_id`, `hor_empleado_id`, `hor_dia_semana`, `hor_hora_inicio`, `hor_hora_fin`, `created_at`) VALUES
	(1, 1, 'lunes', '09:00:00', '18:00:00', '2026-06-19 23:28:57'),
	(2, 1, 'martes', '09:00:00', '18:00:00', '2026-06-19 23:28:57'),
	(3, 1, 'miercoles', '09:00:00', '18:00:00', '2026-06-19 23:28:57'),
	(4, 1, 'jueves', '09:00:00', '18:00:00', '2026-06-19 23:28:57'),
	(5, 1, 'viernes', '09:00:00', '18:00:00', '2026-06-19 23:28:57'),
	(6, 1, 'sabado', '09:00:00', '18:00:00', '2026-06-19 23:28:57'),
	(7, 2, 'lunes', '09:00:00', '18:00:00', '2026-06-22 22:04:02'),
	(8, 2, 'martes', '09:00:00', '18:00:00', '2026-06-22 22:04:02'),
	(9, 2, 'miercoles', '09:00:00', '18:00:00', '2026-06-22 22:04:02'),
	(10, 2, 'jueves', '09:00:00', '18:00:00', '2026-06-22 22:04:02'),
	(11, 2, 'viernes', '09:00:00', '18:00:00', '2026-06-22 22:04:02'),
	(12, 2, 'sabado', '09:00:00', '18:00:00', '2026-06-22 22:04:02');

-- Volcando estructura para tabla gestiondb.movimientos
CREATE TABLE IF NOT EXISTS `movimientos` (
  `mov_id` int NOT NULL AUTO_INCREMENT,
  `mov_usuario_id` int NOT NULL,
  `mov_tipo` enum('crear_factura','editar_factura','eliminar_factura','crear_cita','cancelar_cita','agregar_stock','descontar_stock','editar_producto','crear_reserva_web','cancelar_reserva_web','confirmar_pago_wompi') COLLATE utf8mb4_unicode_ci NOT NULL,
  `mov_descripcion` text COLLATE utf8mb4_unicode_ci,
  `mov_fecha` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`mov_id`),
  KEY `mov_usuario_id` (`mov_usuario_id`),
  CONSTRAINT `movimientos_ibfk_1` FOREIGN KEY (`mov_usuario_id`) REFERENCES `usuarios` (`usu_id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla gestiondb.movimientos: ~6 rows (aproximadamente)
REPLACE INTO `movimientos` (`mov_id`, `mov_usuario_id`, `mov_tipo`, `mov_descripcion`, `mov_fecha`) VALUES
	(1, 1, 'crear_cita', 'Cita #1 creada', '2026-06-20 18:38:08'),
	(6, 2, 'agregar_stock', 'Se agregaron 4 unidades al producto #18', '2026-06-20 18:59:00'),
	(7, 2, 'agregar_stock', 'Se agregaron 4 unidades al producto #17', '2026-06-20 19:00:19'),
	(8, 2, 'crear_factura', 'Factura #1 creada', '2026-06-20 19:00:46'),
	(9, 2, 'editar_factura', 'Factura #1 editada', '2026-06-20 19:08:07'),
	(10, 2, 'editar_factura', 'Factura #1 editada', '2026-06-20 19:11:33'),
	(11, 10, 'crear_reserva_web', 'Reserva web #3 creada', '2026-06-22 22:07:20'),
	(12, 10, 'crear_reserva_web', 'Reserva web #4 creada', '2026-06-22 22:20:31'),
	(13, 10, 'crear_reserva_web', 'Reserva web #5 creada', '2026-06-22 22:21:32'),
	(14, 10, 'crear_reserva_web', 'Reserva web #6 creada', '2026-06-22 22:22:23'),
	(15, 10, 'crear_reserva_web', 'Reserva web #7 creada', '2026-06-22 22:33:47'),
	(16, 8, 'crear_cita', 'Cita #2 creada', '2026-06-22 22:49:50'),
	(17, 10, 'crear_reserva_web', 'Reserva web #8 creada', '2026-06-22 22:55:13'),
	(18, 10, 'crear_reserva_web', 'Reserva web #9 creada', '2026-06-22 23:18:16');

-- Volcando estructura para tabla gestiondb.movimientos_inventario
CREATE TABLE IF NOT EXISTS `movimientos_inventario` (
  `moi_id` int NOT NULL AUTO_INCREMENT,
  `moi_producto_id` int NOT NULL,
  `moi_usuario_id` int NOT NULL,
  `moi_factura_id` int DEFAULT NULL,
  `moi_servicio_id` int DEFAULT NULL,
  `moi_tipo` enum('entrada','salida','ajuste') COLLATE utf8mb4_unicode_ci NOT NULL,
  `moi_cantidad` int NOT NULL,
  `moi_descripcion` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`moi_id`),
  KEY `moi_usuario_id` (`moi_usuario_id`),
  KEY `moi_factura_id` (`moi_factura_id`),
  KEY `moi_servicio_id` (`moi_servicio_id`),
  KEY `idx_movimientos_inv_prod` (`moi_producto_id`),
  CONSTRAINT `movimientos_inventario_ibfk_1` FOREIGN KEY (`moi_producto_id`) REFERENCES `productos` (`pro_id`) ON DELETE CASCADE,
  CONSTRAINT `movimientos_inventario_ibfk_2` FOREIGN KEY (`moi_usuario_id`) REFERENCES `usuarios` (`usu_id`),
  CONSTRAINT `movimientos_inventario_ibfk_3` FOREIGN KEY (`moi_factura_id`) REFERENCES `facturas` (`fac_id`),
  CONSTRAINT `movimientos_inventario_ibfk_4` FOREIGN KEY (`moi_servicio_id`) REFERENCES `servicios` (`ser_id`),
  CONSTRAINT `movimientos_inventario_chk_1` CHECK ((`moi_cantidad` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla gestiondb.movimientos_inventario: ~2 rows (aproximadamente)
REPLACE INTO `movimientos_inventario` (`moi_id`, `moi_producto_id`, `moi_usuario_id`, `moi_factura_id`, `moi_servicio_id`, `moi_tipo`, `moi_cantidad`, `moi_descripcion`, `created_at`) VALUES
	(1, 18, 2, NULL, NULL, 'entrada', 4, 'Se agregaron 4 unidades al producto #18', '2026-06-20 18:59:00'),
	(2, 17, 2, NULL, NULL, 'entrada', 4, 'Se agregaron 4 unidades al producto #17', '2026-06-20 19:00:19');

-- Volcando estructura para tabla gestiondb.pagos
CREATE TABLE IF NOT EXISTS `pagos` (
  `pag_id` int NOT NULL AUTO_INCREMENT,
  `pag_factura_id` int NOT NULL,
  `pag_metodo` enum('efectivo','transferencia','tarjeta','wompi') COLLATE utf8mb4_unicode_ci NOT NULL,
  `pag_estado` enum('pendiente','completado','cancelado') COLLATE utf8mb4_unicode_ci DEFAULT 'completado',
  `pag_fecha` date NOT NULL,
  `pag_monto` decimal(10,2) NOT NULL,
  `pag_referencia` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pag_transaccion_id` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`pag_id`),
  KEY `pag_factura_id` (`pag_factura_id`),
  CONSTRAINT `pagos_ibfk_1` FOREIGN KEY (`pag_factura_id`) REFERENCES `facturas` (`fac_id`) ON DELETE CASCADE,
  CONSTRAINT `pagos_chk_1` CHECK ((`pag_monto` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla gestiondb.pagos: ~0 rows (aproximadamente)

-- Volcando estructura para tabla gestiondb.productos
CREATE TABLE IF NOT EXISTS `productos` (
  `pro_id` int NOT NULL AUTO_INCREMENT,
  `pro_nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pro_precio` decimal(10,2) NOT NULL,
  `pro_stock` int NOT NULL DEFAULT '0',
  `pro_stock_minimo` int DEFAULT '5',
  `pro_tipo_control` enum('unitario','manual') COLLATE utf8mb4_unicode_ci DEFAULT 'manual',
  `pro_estado` enum('activo','inactivo') COLLATE utf8mb4_unicode_ci DEFAULT 'activo',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`pro_id`),
  KEY `idx_productos_stock` (`pro_stock`),
  CONSTRAINT `productos_chk_1` CHECK ((`pro_precio` >= 0)),
  CONSTRAINT `productos_chk_2` CHECK ((`pro_stock` >= 0)),
  CONSTRAINT `productos_chk_3` CHECK ((`pro_stock_minimo` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla gestiondb.productos: ~18 rows (aproximadamente)
REPLACE INTO `productos` (`pro_id`, `pro_nombre`, `pro_precio`, `pro_stock`, `pro_stock_minimo`, `pro_tipo_control`, `pro_estado`, `created_at`, `updated_at`) VALUES
	(1, 'Tinte Negro Profesional', 18000.00, 30, 5, 'unitario', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(2, 'Tinte Rubio Profesional', 18000.00, 25, 5, 'unitario', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(3, 'Tinte Castaño Profesional', 18000.00, 25, 5, 'unitario', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(4, 'Sobre Decolorante', 8000.00, 40, 10, 'unitario', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(5, 'Ampolla Hidratante', 6000.00, 50, 10, 'unitario', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(6, 'Kit Alisado Keratina', 45000.00, 20, 5, 'unitario', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(7, 'Set Uñas Acrílicas', 12000.00, 60, 10, 'unitario', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(8, 'Pestañas Postizas Premium', 9000.00, 40, 10, 'unitario', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(9, 'Shampoo Profesional', 35000.00, 15, 3, 'manual', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(10, 'Acondicionador Profesional', 32000.00, 15, 3, 'manual', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(11, 'Mascarilla Capilar', 28000.00, 12, 3, 'manual', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(12, 'Protector Térmico', 22000.00, 10, 2, 'manual', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(13, 'Spray Fijador', 18000.00, 10, 2, 'manual', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(14, 'Gel Capilar', 15000.00, 12, 3, 'manual', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(15, 'Aceite Reparador', 25000.00, 8, 2, 'manual', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(16, 'Esmalte Transparente', 10000.00, 25, 5, 'manual', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(17, 'Esmalte Rojo', 10000.00, 24, 5, 'manual', 'activo', '2026-06-19 23:28:57', '2026-06-20 19:00:19'),
	(18, 'Esmalte Nude', 10000.00, 24, 5, 'manual', 'activo', '2026-06-19 23:28:57', '2026-06-20 18:59:00');

-- Volcando estructura para tabla gestiondb.reservas_web
CREATE TABLE IF NOT EXISTS `reservas_web` (
  `res_id` int NOT NULL AUTO_INCREMENT,
  `res_cliente_id` int NOT NULL,
  `res_empleado_id` int DEFAULT NULL,
  `res_fecha` date NOT NULL,
  `res_hora` time NOT NULL,
  `res_anticipo` decimal(10,2) NOT NULL DEFAULT '0.00',
  `res_estado` enum('pendiente','pagada','cancelada') COLLATE utf8mb4_unicode_ci DEFAULT 'pendiente',
  `res_referencia_pago` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `res_transaccion_id` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`res_id`),
  KEY `res_empleado_id` (`res_empleado_id`),
  KEY `idx_reservas_cliente` (`res_cliente_id`),
  CONSTRAINT `reservas_web_ibfk_1` FOREIGN KEY (`res_cliente_id`) REFERENCES `clientes` (`cli_id`),
  CONSTRAINT `reservas_web_ibfk_2` FOREIGN KEY (`res_empleado_id`) REFERENCES `empleados` (`emp_id`),
  CONSTRAINT `reservas_web_chk_1` CHECK ((`res_anticipo` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla gestiondb.reservas_web: ~0 rows (aproximadamente)
REPLACE INTO `reservas_web` (`res_id`, `res_cliente_id`, `res_empleado_id`, `res_fecha`, `res_hora`, `res_anticipo`, `res_estado`, `res_referencia_pago`, `res_transaccion_id`, `created_at`) VALUES
	(1, 3, 2, '2026-06-24', '09:00:00', 12000.00, 'pendiente', 'RESERVA-1', NULL, '2026-06-22 22:03:43'),
	(2, 3, 1, '2026-06-24', '09:00:00', 12000.00, 'pendiente', 'RESERVA-2', NULL, '2026-06-22 22:04:41'),
	(3, 3, 1, '2026-06-24', '10:00:00', 12000.00, 'pendiente', 'RESERVA-3', NULL, '2026-06-22 22:07:20'),
	(4, 3, 2, '2026-06-24', '10:00:00', 49500.00, 'pendiente', 'RESERVA-4', NULL, '2026-06-22 22:20:31'),
	(5, 3, 2, '2026-06-24', '14:00:00', 36000.00, 'pendiente', 'RESERVA-5', NULL, '2026-06-22 22:21:32'),
	(6, 3, 1, '2026-06-24', '11:00:00', 72000.00, 'pendiente', 'RESERVA-6', NULL, '2026-06-22 22:22:23'),
	(7, 3, 1, '2026-06-27', '12:00:00', 43500.00, 'pendiente', 'RESERVA-7', NULL, '2026-06-22 22:33:47'),
	(8, 3, 1, '2026-06-30', '12:00:00', 36000.00, 'pendiente', 'RESERVA-8', NULL, '2026-06-22 22:55:13'),
	(9, 3, 2, '2026-06-26', '12:00:00', 36000.00, 'pendiente', 'RESERVA-9', NULL, '2026-06-22 23:18:16');

-- Volcando estructura para tabla gestiondb.servicios
CREATE TABLE IF NOT EXISTS `servicios` (
  `ser_id` int NOT NULL AUTO_INCREMENT,
  `ser_nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ser_descripcion` text COLLATE utf8mb4_unicode_ci,
  `ser_imagen` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ser_precio` decimal(10,2) NOT NULL,
  `ser_duracion` int NOT NULL COMMENT 'Duración en minutos',
  `ser_estado` enum('activo','inactivo') COLLATE utf8mb4_unicode_ci DEFAULT 'activo',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ser_id`),
  CONSTRAINT `servicios_chk_1` CHECK ((`ser_precio` >= 0)),
  CONSTRAINT `servicios_chk_2` CHECK ((`ser_duracion` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla gestiondb.servicios: ~11 rows (aproximadamente)
REPLACE INTO `servicios` (`ser_id`, `ser_nombre`, `ser_descripcion`, `ser_imagen`, `ser_precio`, `ser_duracion`, `ser_estado`, `created_at`, `updated_at`) VALUES
	(1, 'Corte Masculino', 'Corte de cabello para caballero', 'corte_masculino.jpg', 20000.00, 30, 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(2, 'Corte Femenino', 'Corte de cabello para dama', 'corte_femenino.jpg', 30000.00, 45, 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(3, 'Lavado y Peinado', 'Lavado profesional y peinado básico', 'lavado_peinado.jpg', 25000.00, 40, 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(4, 'Tinte Completo', 'Aplicación completa de color', 'tinte.jpg', 90000.00, 120, 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(5, 'Decoloración', 'Proceso de aclarado profesional', 'decoloracion.jpg', 120000.00, 180, 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(6, 'Alisado con Keratina', 'Tratamiento de alisado y nutrición', 'alisado.jpg', 180000.00, 240, 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(7, 'Hidratación Capilar', 'Tratamiento reparador profundo', 'hidratacion.jpg', 50000.00, 60, 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(8, 'Manicure Tradicional', 'Limpieza y esmaltado de uñas', 'manicure.jpg', 25000.00, 45, 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(9, 'Manicure Semipermanente', 'Esmaltado de larga duración', 'manicure_semi.jpg', 45000.00, 60, 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(10, 'Uñas Acrílicas', 'Aplicación completa de uñas acrílicas', 'acrilicas.jpg', 80000.00, 120, 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(11, 'Pedicure Spa', 'Pedicure con exfoliación y masaje', 'pedicure.jpg', 40000.00, 60, 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57');

-- Volcando estructura para tabla gestiondb.servicios_productos
CREATE TABLE IF NOT EXISTS `servicios_productos` (
  `sep_id` int NOT NULL AUTO_INCREMENT,
  `sep_servicio_id` int NOT NULL,
  `sep_producto_id` int NOT NULL,
  `sep_cantidad` int NOT NULL,
  PRIMARY KEY (`sep_id`),
  UNIQUE KEY `sep_servicio_id` (`sep_servicio_id`,`sep_producto_id`),
  KEY `sep_producto_id` (`sep_producto_id`),
  CONSTRAINT `servicios_productos_ibfk_1` FOREIGN KEY (`sep_servicio_id`) REFERENCES `servicios` (`ser_id`) ON DELETE CASCADE,
  CONSTRAINT `servicios_productos_ibfk_2` FOREIGN KEY (`sep_producto_id`) REFERENCES `productos` (`pro_id`) ON DELETE CASCADE,
  CONSTRAINT `servicios_productos_chk_1` CHECK ((`sep_cantidad` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla gestiondb.servicios_productos: ~20 rows (aproximadamente)
REPLACE INTO `servicios_productos` (`sep_id`, `sep_servicio_id`, `sep_producto_id`, `sep_cantidad`) VALUES
	(1, 3, 9, 1),
	(2, 3, 10, 1),
	(3, 3, 13, 1),
	(4, 4, 1, 1),
	(5, 4, 9, 1),
	(6, 4, 10, 1),
	(7, 5, 4, 2),
	(8, 5, 9, 1),
	(9, 5, 10, 1),
	(10, 6, 6, 1),
	(11, 6, 9, 1),
	(12, 6, 10, 1),
	(13, 7, 5, 1),
	(14, 7, 11, 1),
	(15, 8, 16, 1),
	(16, 9, 17, 1),
	(17, 10, 7, 1),
	(18, 10, 18, 1),
	(19, 11, 16, 1);

-- Volcando estructura para tabla gestiondb.usuarios
CREATE TABLE IF NOT EXISTS `usuarios` (
  `usu_id` int NOT NULL AUTO_INCREMENT,
  `usu_username` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `usu_password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `usu_email` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `usu_rol` enum('admin','empleado','cliente') COLLATE utf8mb4_unicode_ci NOT NULL,
  `usu_estado` enum('activo','inactivo') COLLATE utf8mb4_unicode_ci DEFAULT 'activo',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`usu_id`),
  UNIQUE KEY `usu_username` (`usu_username`),
  UNIQUE KEY `usu_email` (`usu_email`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla gestiondb.usuarios: ~4 rows (aproximadamente)
REPLACE INTO `usuarios` (`usu_id`, `usu_username`, `usu_password`, `usu_email`, `usu_rol`, `usu_estado`, `created_at`, `updated_at`) VALUES
	(1, 'admin', '$2b$12$QOiLFycz.3t7Kdd8fDBKtO8onC/yYtzUgsRoWYD8i2NJ7L3pzYB8i', 'admin@test.com', 'admin', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(2, 'empleado1', '$2b$12$QOiLFycz.3t7Kdd8fDBKtO8onC/yYtzUgsRoWYD8i2NJ7L3pzYB8i', 'empleado@test.com', 'empleado', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(3, 'cliente1', '$2b$12$QOiLFycz.3t7Kdd8fDBKtO8onC/yYtzUgsRoWYD8i2NJ7L3pzYB8i', 'cliente@test.com', 'cliente', 'activo', '2026-06-19 23:28:57', '2026-06-19 23:28:57'),
	(7, 'carolina.cxr_48061f0e', '$2b$12$7ntUzcV3NAsMHHOS8F9YO.dk//tZwzCG1MWUyh72TzVI383PBMLNS', 'carolina.cxr_48061f0e@clientes.local', 'cliente', 'activo', '2026-06-20 17:25:31', '2026-06-20 17:25:31'),
	(8, '1047035036', '$2b$12$8GtNA/tuceLtqNWqpJ2apuQ3ElzJ6bjix5iSU/7wcnfcITG2wz2L.', 'cabarcayisus@gmail.com', 'empleado', 'activo', '2026-06-20 18:51:55', '2026-06-20 18:51:55'),
	(10, 'shanonisus', '$2b$12$X1eOJ0cOfcqj.KpQHBdjVeucuJVXQFHs8pStnxxJ5lxbf8QkeXqp.', 'shanonisus@gmail.com', 'cliente', 'activo', '2026-06-22 22:01:44', '2026-06-22 22:01:44');

-- Volcando estructura para disparador gestiondb.trg_validar_stock_negativo
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `trg_validar_stock_negativo` BEFORE UPDATE ON `productos` FOR EACH ROW BEGIN
    IF NEW.pro_stock < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El stock no puede ser negativo.';
    END IF;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
