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
