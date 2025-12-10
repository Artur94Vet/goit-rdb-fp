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