USE hobbies_nm_db;

-- ===============================================================================================================================================================
-- Solucion ej: f_get_hobby_id que devuelve el id de una afición a partir de su nombre
-- ===============================================================================================================================================================
DELIMITER //
CREATE OR REPLACE FUNCTION f_get_hobby_id(
	p_hobby_name VARCHAR(128)
) RETURNS INT
READS SQL DATA
BEGIN 
	DECLARE v_hobby_id INT;
	
	SELECT MIN(h.hobby_id) INTO v_hobby_id
	FROM hobbies h
	WHERE h.hobby_name = p_hobby_name;
	
	RETURN v_hobby_id;
END // 
DELIMITER ;

-- Prueba:
SELECT f_get_hobby_id('Deporte') AS deporte;
SELECT f_get_hobby_id('Jugar al fútbol') AS jugar_al_futbol;

-- ===============================================================================================================================================================
-- procedimiento p_add_hobby_to_user que añada una afición a un usuario existente: si la afición ya está en el catálogo, se reutiliza; 
-- si no, se crea. Si el usuario ya tiene esa afición (RN03), debe lanzar un error. Hazlo en una transacción.
-- ===============================================================================================================================================================

-- (NO TRANSACCIONAL)
DELIMITER // 
CREATE OR REPLACE PROCEDURE p_add_hobby_to_user(
	in p_user_id INT,
	in p_hobby_name VARCHAR(128)
) 
BEGIN 
		
	DECLARE v_hobby_id INT;
	
	SET v_hobby_id = f_get_hobby_id(p_hobby_name);

	IF EXISTS (
		SELECT * FROM users_hobbies uh
		WHERE uh.user_Id = p_user_id AND uh.hobby_id = v_hobby_id
	) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'RN03: El usuario ya tiene esta afición';
	END IF;
	
	IF v_hobby_id IS NULL then 
		INSERT INTO hobbies(hobby_name) VALUES (p_hobby_name);
		SET v_hobby_id = LAST_INSERT_ID();  -- (Hay que hacerlo para ponerle el ID correspondiente)
	END IF;
	
	INSERT INTO users_hobbies(user_id, hobby_id) VALUES (p_user_id, v_hobby_id);
END // 
DELIMITER ;

-- Para probarlo: (para comprobar la restriccion RN03, simplemente vuelvo a ejecutarlo sin ejecutar el p_populate)
CALL p_populate();

SELECT uh.user_id, h.hobby_name, COUNT(h.hobby_id) AS hobbies_totales_usuario FROM users_hobbies uh
JOIN hobbies h ON  h.hobby_id = uh.hobby_id
WHERE uh.user_id = 1;
SELECT COUNT(*) AS hobbies_totales
FROM hobbies;

CALL p_add_hobby_to_user(1, 'Pintar');

SELECT uh.user_id, h.hobby_name, COUNT(h.hobby_id) AS hobbies_totales_usuario FROM users_hobbies uh
JOIN hobbies h ON  h.hobby_id = uh.hobby_id
WHERE uh.user_id = 1;

SELECT COUNT(*) AS hobbies_totales
FROM hobbies;
	
-- LO CONVERTIMOS EN PROCEDIMIENTO TRANSACCIONAL
DELIMITER // 
CREATE OR REPLACE PROCEDURE p_add_hobby_to_user_transactional(
	in p_user_id INT,
	in p_hobby_name VARCHAR(128)
) 
BEGIN 
	
	BEGIN     -- (CATCH)
		DECLARE exit handler FOR SQLEXCEPTION
			ROLLBACK;
			RESIGNAL; 
	END;
	
	START TRANSACTION; -- (TRY)
	
		CALL p_add_hobby_to_user(p_user_id, p_hobby_name);
	
	COMMIT;
END // 
DELIMITER ;

-- PRUEBA (reutilizando el codigo anterior)
CALL p_populate();

SELECT uh.user_id, h.hobby_name, COUNT(h.hobby_id) AS hobbies_totales_usuario FROM users_hobbies uh
JOIN hobbies h ON  h.hobby_id = uh.hobby_id
WHERE uh.user_id = 1;
SELECT COUNT(*) AS hobbies_totales
FROM hobbies;

CALL p_add_hobby_to_user_transactional(1, 'Pintar');

SELECT uh.user_id, h.hobby_name, COUNT(h.hobby_id) AS hobbies_totales_usuario FROM users_hobbies uh
JOIN hobbies h ON  h.hobby_id = uh.hobby_id
WHERE uh.user_id = 1;

SELECT COUNT(*) AS hobbies_totales
FROM hobbies;

-- ===============================================================================================================================================================
-- función f_hobby_users que devuelva cuántos usuarios tienen una afición 
-- ===============================================================================================================================================================
DELIMITER //
CREATE OR REPLACE FUNCTION f_hobby_users(p_hobby_id INT)
RETURNS INT
READS SQL DATA
BEGIN
	DECLARE v_users INT;
	
	SELECT COUNT(*) INTO v_users
	FROM users_hobbies u
	WHERE u.hobby_id = p_hobby_id;
	
	RETURN v_users;
END //
DELIMITER ;

-- COMPROBAMOS
SELECT f_hobby_users(1) AS usuarios_cine;
SELECT f_hobby_users(2) AS usuarios_deporte;

-- ===============================================================================================================================================================
-- Procedimiento p_merge_hobbies que fusione dos aficiones del catálogo: los usuarios de la primera pasan a la segunda sin repetirla, y la primera se borra
-- ===============================================================================================================================================================
-- NO TRANSACCIONAL:
DELIMITER //
CREATE OR REPLACE PROCEDURE p_merge_hobbies(
	IN p_hobby_viejo_id INT,
	IN p_hobby_nuevo_id INT
)
BEGIN 
	 -- 1ro ponemos las reglas de negocio correspondientes
	IF p_hobby_viejo_id = p_hobby_nuevo_id THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'RN010: No se puede fusionar un hobby consigo mismo';
	END IF;
	
	IF NOT EXISTS (SELECT * FROM hobbies h WHERE h.hobby_id = p_hobby_viejo_id) OR NOT EXISTS (SELECT * FROM hobbies h WHERE h.hobby_id = p_hobby_nuevo_id) THEN
			SIGNAL SQLSTATE '45000'
				SET MESSAGE_TEXT = 'R10: Las dos aficiones deben estar en el catálogo.';
	END IF;
	
	DELETE FROM users_hobbies 
	WHERE hobby_id = p_hobby_viejo_id AND user_id IN (SELECT uh.user_id FROM users_hobbies uh WHERE uh.hobby_id = p_hobby_nuevo_id);
	
	UPDATE users_hobbies SET hobby_id = p_hobby_nuevo_id WHERE hobby_id = p_hobby_viejo_id;
END//
DELIMITER ;


-- TRANSACCIONAL: 
DELIMITER //
CREATE OR REPLACE PROCEDURE p_merge_hobbies_transactional(
	IN p_hobby_viejo_id INT,
	IN p_hobby_nuevo_id INT
)
BEGIN 
	
	DECLARE exit handler FOR SQLEXCEPTION
	BEGIN 
		ROLLBACK;
		RESIGNAL;
	END;
	
	START TRANSACTION;
	
	CALL p_merge_hobbies(p_hobby_viejo_id, p_hobby_nuevo_id);
	
	COMMIT;
END// 
DELIMITER ;	
																
-- PRUEBA: 
CALL p_populate();

SELECT h.hobby_id, h.hobby_name, f_hobby_users(h.hobby_id) AS users
FROM hobbies h
ORDER BY users DESC, h.hobby_id;

CALL p_merge_hobbies_transactional(3,1);

SELECT h.hobby_id, h.hobby_name, f_hobby_users(h.hobby_id) AS users
FROM hobbies h
ORDER BY users DESC, h.hobby_id;


