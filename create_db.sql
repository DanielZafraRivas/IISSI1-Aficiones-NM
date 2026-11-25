--
-- Autor: David Ruiz
-- Fecha: Octubre de 2026
-- Descripción: Script para crear la BD de Aficiones Dinámicas
--

DROP DATABASE IF EXISTS hobbies_nm_db;
CREATE DATABASE hobbies_nm_db;
USE hobbies_nm_db;

-- =============================================================
-- Se eliminan las tablas previas
-- =============================================================
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS users_hobbies;
DROP TABLE IF EXISTS hobbies;
DROP TABLE IF EXISTS users;
DROP TABLE if EXISTS practica;
SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================
-- Tabla: users
-- =============================================================
CREATE TABLE users (
    user_id INT AUTO_INCREMENT,
    full_name VARCHAR(64) NOT NULL,
    gender ENUM('MASCULINO','FEMENINO','OTRO') NULL,
    age TINYINT NOT NULL,
    email VARCHAR(255) NOT NULL,
    PRIMARY KEY (user_id),
    CONSTRAINT ck_users_rn01_adult_age CHECK (age >= 18),
    CONSTRAINT uq_users_rn02_email UNIQUE (email)
);

-- =============================================================
-- Tabla: hobbies
-- =============================================================
CREATE TABLE hobbies (
    hobby_id INT AUTO_INCREMENT,
    hobby_name VARCHAR(128) NOT NULL,
    PRIMARY KEY (hobby_id)
);

-- =============================================================
-- Tabla: users_hobbies
-- =============================================================
CREATE TABLE users_hobbies (
    user_hobby_id INT AUTO_INCREMENT,
    user_id INT NOT NULL,
    hobby_id INT NOT NULL,
    nivel VARCHAR(20) NOT NULL,
    horas_semana INT NOT NULL,
    PRIMARY KEY (user_hobby_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (hobby_id) REFERENCES hobbies(hobby_id),
    CONSTRAINT uq_users_hobbies_rn03 UNIQUE (user_id, hobby_id),
    CONSTRAINT rn_nivel_tipos CHECK (nivel IN ('PRINCIPIANTE', 'INTERMEDIO', 'EXPERTO')),
    CONSTRAINT ra01_practica_horas CHECK (horas_semana BETWEEN 1 AND 20),
);

-- --------------------------------------------------------------------------------------------
-- RA02: solo se es experto en una afición a la que se le dedican mas de 5 horas
-- --------------------------------------------------------------------------------------------
DELIMITER //
CREATE OR REPLACE TRIGGER t_biu_practica_ra02 
BEFORE INSERT OR UPDATE ON users_hobbies
FOR EACH ROW 
BEGIN 
	DECLARE v_horas INT;
	
	IF NEW.nivel = 'EXPERTO' THEN
		SELECT horas_semana INTO v_horas FROM users_hobbies WHERE user_hobby_id = NEW.user_hobby_id;
		IF v_horas < 5 THEN
			SIGNAL SQLSTATE '45000'
				SET MESSAGE_TEXT = 'RA02: No se puede ser EXPERTO en una afición si no le dedicas más de 5 horas semanales';
		END IF;
	END IF;
END //
DELIMITER ;
				

	
