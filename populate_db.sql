--
-- Autor: David Ruiz
-- Fecha: Octubre de 2026
-- Descripción: Procedimiento para poblar la BD de Aficiones Dinámicas
--
USE hobbies_nm_db;

DELIMITER //
CREATE OR REPLACE PROCEDURE p_populate()
BEGIN
    DELETE FROM users_hobbies;
    DELETE FROM hobbies;
    DELETE FROM users;

    ALTER TABLE users AUTO_INCREMENT = 1;
    INSERT INTO users (full_name, gender, age, email) VALUES
        ('David Ruiz', 'MASCULINO', 45, 'druiz@us.es'),
        ('Carlos Arévalo', 'MASCULINO', 58, 'carevalo@us.es'),
        ('Margarita Cruz', 'FEMENINO', 58, 'mcruz@us.es'),
        ('Inma Hernández', 'FEMENINO', 35, 'inmahernandez@us.es'),
        ('Alfonso Márquez', 'MASCULINO', 35, 'amarquez@us.es'),
        ('Daniel Ayala', 'MASCULINO', 28, 'dayala1@us.es'),
        ('Raquel Sampedro', 'FEMENINO', 55, 'rsampedro@gmail.com'),
        ('Marta López', 'FEMENINO', 18, 'mlopez@mail.com'),
        ('David Ruiz', 'MASCULINO', 25, 'druiz@mail.com');

    INSERT INTO users (full_name, age, email)
        VALUES ('Andrea Gómez', 27, 'agomez@mail.es');

    INSERT INTO users (full_name, gender, age, email)
        VALUES ('Ernesto Murillo', 'OTRO', 55, 'emurillo@correo.es');

    ALTER TABLE hobbies AUTO_INCREMENT = 1;
    INSERT INTO hobbies (hobby_name) VALUES
        ('Cine'),
        ('Deporte'),
        ('Jugar al fútbol'),
        ('Hacer senderismo'),
        ('Montar a caballo');

    ALTER TABLE users_hobbies AUTO_INCREMENT = 1;
    INSERT INTO users_hobbies (user_id, hobby_id, nivel, horas_semana) VALUES
        (1,3, 'EXPERTO', 6), (1,4, 'INTERMEDIO', 4),
        (2,3, 'INTERMEDIO', 6), (2,1, 'EXPERTO', 7), (2,2, 'PRINCIPIANTE', 2),
        (4,4, 'PRINCIPIANTE', 1), (4,2, 'EXPERTO', 9), (4,1, 'INTERMEDIO', 4),
        (5,3, 'EXPERTO', 10),
        (6,2, 'EXPERTO', 6),
        (8,3, 'PRINCIPIANTE', 2), (8,4, 'EXPERTO', 7), (8,1, 'INTERMEDIO', 6), (8,2, 'INTERMEDIO', 4),
        (9,3, 'EXPERTO', 7), (9,1, 'PRINCIPIANTE', 4), (9,2, 'INTERMEDIO', 6),
        (10,4, 'INTERMEDIO', 5),
        (11,5, 'EXPERTO', 6),
        (8,5, 'PRINCIPIANTE', 3);
END //
DELIMITER ;

CALL p_populate();
