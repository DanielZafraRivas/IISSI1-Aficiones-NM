-- 
-- Autor: David Ruiz
-- Fecha: Octubre de 2026
-- Descripción: Tests negativos para la BD de Aficiones Dinámicas
-- 
USE hobbies_nm_db;

-- =============================================================
-- TABLA DE RESULTADOS
-- =============================================================
CREATE OR REPLACE TABLE test_results (
    test_id VARCHAR(20) PRIMARY KEY,
    test_name VARCHAR(200) NOT NULL,
    test_message VARCHAR(500) NOT NULL,
    test_status ENUM('PASS','FAIL') NOT NULL,
    execution_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================
-- PROCEDIMIENTO AUXILIAR
-- =============================================================
DELIMITER //
CREATE OR REPLACE PROCEDURE p_log_test(
    IN p_test_id VARCHAR(20),
    IN p_message VARCHAR(500),
    IN p_status ENUM('PASS','FAIL')
)
BEGIN
    INSERT INTO test_results(test_id, test_name, test_message, test_status)
    VALUES (p_test_id, SUBSTRING_INDEX(p_message, ':', 1), p_message, p_status);
END //
DELIMITER ;

-- =============================================================
-- TESTS (RN01 - RN03)
-- =============================================================

DELIMITER //
CREATE OR REPLACE PROCEDURE p_test_rn01_age_adult()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        CALL p_log_test('RN01', 'RN01: Edad mínima 18 años', 'PASS');

    CALL p_populate();

    INSERT INTO users (full_name, gender, age, email)
        VALUES ('Usuario Menor', 'MASCULINO', 17, 'menor@ejemplo.com');

    CALL p_log_test('RN01', 'ERROR: Se permitió un usuario menor de edad', 'FAIL');
END //
DELIMITER ;

DELIMITER //
CREATE OR REPLACE PROCEDURE p_test_rn02_unique_email()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        CALL p_log_test('RN02', 'RN02: Email debe ser único', 'PASS');

    CALL p_populate();

    INSERT INTO users (full_name, gender, age, email)
        VALUES ('Correo Duplicado', 'FEMENINO', 30, 'druiz@us.es');

    CALL p_log_test('RN02', 'ERROR: Se permitió duplicar un email', 'FAIL');
END //
DELIMITER ;

DELIMITER //
CREATE OR REPLACE PROCEDURE p_test_rn03_unique_hobby_per_user()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        CALL p_log_test('RN03', 'RN03: No se pueden repetir aficiones por usuario', 'PASS');

    CALL p_populate();

    INSERT INTO users_hobbies (user_id, hobby_id) VALUES (1, 3);

    CALL p_log_test('RN03', 'ERROR: Se permitió repetir afición para el mismo usuario', 'FAIL');
END //
DELIMITER ;

-- =============================================================
-- TESTS (RA01 - RA04) (manual) 
-- =============================================================
CALL p_populate();
-- RA01: (horas actividad entre 1 y 20) 
INSERT INTO users_hobbies (user_id, hobby_id, nivel, horas_semana) VALUES (6,4, 'EXPERTO', 21);

-- RA02: solo se es EXPERTO en una afición a la que se le dedican mas de 5 horas
INSERT INTO users_hobbies (user_id, hobby_id, nivel, horas_semana) VALUES (1,1, 'EXPERTO', 3);

-- RA03: Un usuario no dedica más de 30 horas a la semana al total de sus aficiones
INSERT INTO users_hobbies (user_id, hobby_id, nivel, horas_semana) VALUES (1,5, 'EXPERTO', 30);

-- RA04: Un usuario no es EXPERTO en más de dos aficiones
INSERT INTO users_hobbies (user_id, hobby_id, nivel, horas_semana) VALUES (6,5, 'EXPERTO', 6);
INSERT INTO users_hobbies (user_id, hobby_id, nivel, horas_semana) VALUES (6,1, 'EXPERTO', 5);

-- =============================================================
-- ORQUESTADOR
-- =============================================================
DELIMITER //
CREATE OR REPLACE PROCEDURE p_run_tests()
BEGIN
    DELETE FROM test_results;

    CALL p_test_rn01_age_adult();
    CALL p_test_rn02_unique_email();
    CALL p_test_rn03_unique_hobby_per_user();

    SELECT * FROM test_results ORDER BY execution_time, test_id;
    SELECT test_status, COUNT(*) AS total FROM test_results GROUP BY test_status;
END //
DELIMITER ;

CALL p_run_tests();
