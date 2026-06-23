-- =====================================================
-- catalogo.sql — productos, servicios y su relación
-- Fuente: insertsproductos.txt
-- IMPORTANTE: el orden fija los IDs (productos 1..18, servicios 1..12);
-- servicios_productos referencia esos IDs por posición. No reordenar.
-- =====================================================

INSERT INTO productos (pro_nombre, pro_precio, pro_stock, pro_stock_minimo, pro_tipo_control) VALUES
('Tinte Negro Profesional', 18000, 30, 5, 'unitario'),
('Tinte Rubio Profesional', 18000, 25, 5, 'unitario'),
('Tinte Castaño Profesional', 18000, 25, 5, 'unitario'),
('Sobre Decolorante', 8000, 40, 10, 'unitario'),
('Ampolla Hidratante', 6000, 50, 10, 'unitario'),
('Kit Alisado Keratina', 45000, 20, 5, 'unitario'),
('Set Uñas Acrílicas', 12000, 60, 10, 'unitario'),
('Pestañas Postizas Premium', 9000, 40, 10, 'unitario'),
('Shampoo Profesional', 35000, 15, 3, 'manual'),
('Acondicionador Profesional', 32000, 15, 3, 'manual'),
('Mascarilla Capilar', 28000, 12, 3, 'manual'),
('Protector Térmico', 22000, 10, 2, 'manual'),
('Spray Fijador', 18000, 10, 2, 'manual'),
('Gel Capilar', 15000, 12, 3, 'manual'),
('Aceite Reparador', 25000, 8, 2, 'manual'),
('Esmalte Transparente', 10000, 25, 5, 'manual'),
('Esmalte Rojo', 10000, 20, 5, 'manual'),
('Esmalte Nude', 10000, 20, 5, 'manual');

INSERT INTO servicios (ser_nombre, ser_descripcion, ser_imagen, ser_precio, ser_duracion) VALUES
('Corte Masculino', 'Corte de cabello para caballero', 'corte_masculino.jpg', 20000, 30),
('Corte Femenino', 'Corte de cabello para dama', 'corte_femenino.jpg', 30000, 45),
('Lavado y Peinado', 'Lavado profesional y peinado básico', 'lavado_peinado.jpg', 25000, 40),
('Tinte Completo', 'Aplicación completa de color', 'tinte.jpg', 90000, 120),
('Decoloración', 'Proceso de aclarado profesional', 'decoloracion.jpg', 120000, 180),
('Alisado con Keratina', 'Tratamiento de alisado y nutrición', 'alisado.jpg', 180000, 240),
('Hidratación Capilar', 'Tratamiento reparador profundo', 'hidratacion.jpg', 50000, 60),
('Manicure Tradicional', 'Limpieza y esmaltado de uñas', 'manicure.jpg', 25000, 45),
('Manicure Semipermanente', 'Esmaltado de larga duración', 'manicure_semi.jpg', 45000, 60),
('Uñas Acrílicas', 'Aplicación completa de uñas acrílicas', 'acrilicas.jpg', 80000, 120),
('Pedicure Spa', 'Pedicure con exfoliación y masaje', 'pedicure.jpg', 40000, 60),
('Pestañas Pelo a Pelo', 'Extensión de pestañas profesional', 'pestanas.jpg', 100000, 120);

-- Servicios del home público (IDs 13-17)
INSERT INTO servicios (ser_nombre, ser_descripcion, ser_imagen, ser_precio, ser_duracion) VALUES
('Color & corte',     'Transformación completa: coloración personalizada con técnica de balayage o tinte plano, más corte y brushing. Incluye tratamiento de brillo y keratina ligera.', '/img/s1.webp', 250000, 105),
('Brushing & peinado','Peinado profesional con brushing y volumen. Ideal para el día a día o para una ocasión especial. Incluye masaje capilar reconfortante.',                           '/img/s2.webp',  45000,  45),
('Manicura premium',  'Manicura completa con esmaltado semipermanente de larga duración. Incluye limado, cutículas, exfoliación de manos y base nutritiva.',                          '/img/s3.webp',  55000,  50),
('Facial luminoso',   'Tratamiento facial con limpieza profunda, exfoliación enzimática y mascarilla hidratante de vitamina C. Tu piel, radiante en una hora.',                      '/img/s4.webp',  90000,  60),
('Uñas acrílicas',    'Uñas acrílicas de alta durabilidad con diseño personalizado. El servicio incluye moldeado, capa base, color y acabado tipo gel brillante.',                   '/img/741a3d2bff42456470ed060de3a9cd89.jpg', 80000, 120);

INSERT INTO servicios_productos (sep_servicio_id, sep_producto_id, sep_cantidad) VALUES
(3, 9, 1),
(3, 10, 1),
(3, 13, 1),
(4, 1, 1),
(4, 9, 1),
(4, 10, 1),
(5, 4, 2),
(5, 9, 1),
(5, 10, 1),
(6, 6, 1),
(6, 9, 1),
(6, 10, 1),
(7, 5, 1),
(7, 11, 1),
(8, 16, 1),
(9, 17, 1),
(10, 7, 1),
(10, 18, 1),
(11, 16, 1),
(12, 8, 1);
