-- Створюємо схему 
CREATE SCHEMA IF NOT EXISTS pandemic;
-- Використовуємо схему pandemic по замовчуванню
USE pandemic;
-- завантажуємо csv файл. Враховуємо помилки вбудованого інструменту і завантажуємо брудні дані через наявні пропуски
SELECT
	`Entity`
	,`Code`
	,`Year`
	,`Number_yaws`
	,`polio_cases`
	,`cases_guinea_worm`
	,`Number_rabies`
	,`Number_malaria`
	,`Number_hiv`
	,`Number_tuberculosis`
	,`Number_smallpox`
	,`Number_cholera_cases`
FROM infectious_cases;
--------------------------


-- Створюємо таблицю довідник з `entity` та `Code` (в рамках нормалізації)
CREATE TABLE IF NOT EXISTS dim_entity (
    entity_id INT AUTO_INCREMENT PRIMARY KEY,
    entity_name VARCHAR(255) NOT NULL,
    entity_code VARCHAR(8),
    UNIQUE (entity_name, entity_code)
);
-- Створюємо таблицю фактів з інших атрибутів (в рамках нормалізації)
-- На цьому етапі регулюємо типи даних (попередньо запустивши процедуру)
CREATE TABLE IF NOT EXISTS fact_infectious (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    entity_id INT NOT NULL,
    year YEAR,
    number_yaws INT,
    polio_cases INT,
    cases_guinea_worm INT,
    number_rabies DECIMAL (17,12),
    number_malaria DECIMAL (18,9),
    number_hiv DECIMAL (16,9),
    number_tuberculosis DECIMAL (15,8),
    number_smallpox INT,
    number_cholera_cases INT,
    FOREIGN KEY (entity_id) REFERENCES dim_entity(entity_id)
);
-- Вставляємо унікальні значення в новостворений каталок 'dim_entity'
-- відпрацьовуємо за комбінацією 2х ключів (хоча попередній аналіз показав, що орієнтуватися достатньо на 'Entity'
INSERT IGNORE INTO dim_entity (entity_name, entity_code)
SELECT DISTINCT
    Entity
    ,Code
FROM infectious_cases
WHERE Entity IS NOT NULL;

-- Превіряємо
SELECT * FROM dim_entity;

-- Копіюємо в таблицю фактів атрибути, з врахуванням типів даних, та ключем з таблицею dim_entity
INSERT INTO fact_infectious (
    entity_id
    ,year
    ,number_yaws
    ,polio_cases
    ,cases_guinea_worm
    ,number_rabies
    ,number_malaria
    ,number_hiv
    ,number_tuberculosis
    ,number_smallpox
    ,number_cholera_cases
)
SELECT 
    d.entity_id
    ,r.Year
    ,NULLIF(r.number_yaws, '')
    ,NULLIF(r.polio_cases, '')
    ,NULLIF(r.cases_guinea_worm, '')
    ,NULLIF(r.Number_rabies, '')
    ,NULLIF(r.Number_malaria, '')
    ,NULLIF(r.Number_hiv, '')
    ,NULLIF(r.Number_tuberculosis, '')
    ,NULLIF(r.Number_smallpox, '')
    ,NULLIF(r.Number_cholera_cases, '')
FROM infectious_cases r
JOIN dim_entity d 
    ON d.entity_name = r.Entity
    AND d.entity_code = r.Code;

-- перевіряємо таблицю чи все коректно
SELECT * FROM fact_infectious;

-- Виконуємо 3є завдання
SELECT 
	en.entity_name
    ,en.entity_code
	,inf.entity_id
    ,AVG(inf.number_rabies) AS avg_n_rabies
    ,MIN(inf.number_rabies) AS min_n_rabies
    ,MAX(inf.number_rabies) AS max_n_rabies
    ,SUM(inf.number_rabies) AS sum_n_rabies
FROM fact_infectious AS inf
LEFT JOIN dim_entity AS en ON en.entity_id=inf.entity_id
WHERE inf.number_rabies IS NOT NULL
GROUP BY
	en.entity_name
    ,en.entity_code
	,inf.entity_id
ORDER BY
	avg_n_rabies DESC
LIMIT 10;

-- Виконуємо 4е завдання
SELECT
	entity_id
    ,year
    ,MAKEDATE(year, 1) AS beg_year
    ,CURDATE() AS date_now
    ,TIMESTAMPDIFF(YEAR, MAKEDATE(Year, 1), CURDATE()) AS years_difference
FROM fact_infectious;



DELIMITER //

DROP FUNCTION IF EXISTS YearDifference //

CREATE FUNCTION YearDifference(input_year INT) 
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE start_date DATE;
    SET start_date = MAKEDATE(input_year, 1);
    RETURN TIMESTAMPDIFF(YEAR, start_date, CURDATE());
END //

DELIMITER ;

SELECT 
    entity_id
    ,Year
	,MAKEDATE(year, 1) AS beg_year
    ,CURDATE() AS date_now
    ,YearDifference(Year) AS Years_Ago
FROM fact_infectious;

