ALTER TABLE usuarios
MODIFY usu_estado ENUM('activo', 'inactivo', 'bloqueado') DEFAULT 'activo';

ALTER TABLE empleados
MODIFY emp_estado ENUM('activo', 'inactivo', 'bloqueado') DEFAULT 'activo';
