# goit-rdb-fp

## Завдання фінального проєкту:  
1. **Завантажте дані:**  
+ Створіть схему pandemic у базі даних за допомогою SQL-команди.  
+ Оберіть її як схему за замовчуванням за допомогою SQL-команди.  
+ Імпортуйте дані за допомогою Import wizard так, як ви вже робили це у темі 3.  
+ Продивіться дані, щоб бути у контексті.
  
2. **Нормалізуйте таблицю infectious_cases до 3ї нормальної форми. Збережіть у цій же схемі дві таблиці з нормалізованими даними.**  
  
3. **Проаналізуйте дані:**  
+ Для кожної унікальної комбінації Entity та Code або їх id порахуйте середнє, мінімальне, максимальне значення та суму для атрибута Number_rabies.   
+ Результат відсортуйте за порахованим середнім значенням у порядку спадання.  
+ Оберіть тільки 10 рядків для виведення на екран.

4. **Побудуйте колонку різниці в роках.**  
Для оригінальної або нормованої таблиці для колонки Year побудуйте з використанням вбудованих SQL-функцій:  
+ атрибут, що створює дату першого січня відповідного року.  
+ атрибут, що дорівнює поточній даті.  
+ атрибут, що дорівнює різниці в роках двох вищезгаданих колонок.

5. **Побудуйте власну функцію.**  
Створіть і використайте функцію, що будує такий же атрибут, як і в попередньому завданні: функція має приймати на вхід значення року, а повертати різницю в роках між поточною датою та датою, створеною з атрибута року (1996 рік → ‘1996-01-01’).


## **Завдання №1: створення схеми та завантаження даних**  
Створення схеми та вибір її за замовчуванням  
```sql
CREATE SCHEMA IF NOT EXISTS pandemic;
USE pandemic;
```
Завантаження даних реалізував через вбудований інструмент **Table Data Import Wizard**, але під час завантаження по автоматично підібраним параметрам

<img width="1169" height="876" alt="image" src="https://github.com/user-attachments/assets/457464b7-2cb4-4b19-99a8-af06ec8ba0d5" />

але, як видно з логів, при обраних параметрах деякі рядки падають в помилки
<img width="1147" height="860" alt="image" src="https://github.com/user-attachments/assets/6317d98c-bd14-45e7-8624-bc4094078eaa" />  

що зумовило завантаження неповного обєму даних  
<img width="639" height="354" alt="image" src="https://github.com/user-attachments/assets/abcf4879-386f-42f3-b344-b8129bac0682" />  
**7271 з 10521 рядків**  
 
це зумовлено тим, що інструмент сканує не повну таблицю, а лише 200 перших рядків, не опрацьовує пусті значення типу '' тощо  

Тому ідеальним варіантом все завантажити в `TEXT` , а потім обробляти.  

<img width="940" height="911" alt="image" src="https://github.com/user-attachments/assets/5518533f-76b1-420e-9427-3590e4d3b173" />  

як результат, у логах не виявлено жодної помилки  
<img width="943" height="925" alt="image" src="https://github.com/user-attachments/assets/66728398-b6ab-4000-9caa-534d9669e3e2" />  

всі рядки успішно завантажені  
<img width="680" height="303" alt="image" src="https://github.com/user-attachments/assets/bc705d8d-1d24-4480-b35e-e08dc50d3f4c" />  

1е завдання успішно виконане, перетворення типів даних проведемо у завданні № 2.  


## **Завдання №2: Нормалізація 3F**  

Після аналізу в оригінальній таблиці варто виділити дві групи **Entity** та **Code** - перша група та 2 група - всі інші, де буде інформація про рік та діагнози  

Для нормалізації даних створенмо 2 таблиці, які заповнемо з оригінальної  

```sql
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
```


### Примітка  
Для визначення оптимального типу даних під завдання написали процедуру (звісно можна було для усіх числових даних призначити DECIMAL (20,20))  

```sql
DELIMITER //

DROP PROCEDURE IF EXISTS AnalyzeAllColumns;

CREATE PROCEDURE AnalyzeAllColumns(IN dbName VARCHAR(64), IN tableName VARCHAR(64))
BEGIN
    -- Вимикаємо безпечний режим всередині процедури
    SET @old_safe_updates = @@SQL_SAFE_UPDATES;
    SET SQL_SAFE_UPDATES = 0;

    BEGIN
        DECLARE done INT DEFAULT FALSE;
        DECLARE colName VARCHAR(255);
        DECLARE sqlQuery TEXT;
        
        DECLARE colCursor CURSOR FOR 
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_schema = dbName 
              AND table_name = tableName
              AND column_name NOT IN ('id', 'Entity', 'Code', 'Year'); 

        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

        DROP TEMPORARY TABLE IF EXISTS TempAnalysis;
        CREATE TEMPORARY TABLE TempAnalysis (
            Column_Name VARCHAR(255),
            Int_Part INT,
            Dec_Part INT,
            Suggested_Type VARCHAR(50)
        );

        OPEN colCursor;

        read_loop: LOOP
            FETCH colCursor INTO colName;
            IF done THEN
                LEAVE read_loop;
            END IF;

            SET @sqlText = CONCAT(
                'INSERT INTO TempAnalysis (Column_Name, Int_Part, Dec_Part) ',
                'SELECT "', colName, '", ',
                'MAX(CHAR_LENGTH(SUBSTRING_INDEX(NULLIF(`', colName, '`, ""), ".", 1))), ',
                'MAX(IF(LOCATE(".", `', colName, '`) > 0, CHAR_LENGTH(SUBSTRING_INDEX(NULLIF(`', colName, '`, ""), ".", -1)), 0)) ',
                'FROM `', dbName, '`.`', tableName, '`'
            );

            PREPARE stmt FROM @sqlText;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
            
        END LOOP;

        CLOSE colCursor;

        UPDATE TempAnalysis
        SET Suggested_Type = CASE
            -- Якщо немає дробової частини (0 знаків після коми)
            WHEN Dec_Part = 0 THEN 
                CASE 
                    -- Якщо число вміщується в стандартний INT (до 10 цифр)
                    WHEN Int_Part <= 9 THEN 'INT'
                    -- Якщо число величезне -> BIGINT
                    ELSE 'BIGINT'
                END
            -- Якщо є дробова частина -> DECIMAL
            ELSE CONCAT('DECIMAL(', Int_Part + Dec_Part, ', ', Dec_Part, ')')
        END;

        SELECT * FROM TempAnalysis;
        
        DROP TEMPORARY TABLE TempAnalysis;
    END;

    SET SQL_SAFE_UPDATES = @old_safe_updates;
END //

DELIMITER ;

CALL AnalyzeAllColumns('pandemic', 'infectious_cases');
```

Результат процедури:  
<img width="404" height="191" alt="image" src="https://github.com/user-attachments/assets/d7d81280-6aa1-4bfd-b6ac-d083ffd445b8" />  

Оскільки таблиці створені з оптимальними типами даних, тепер наповнимо їх данимии з оригінальної таблиці  
Наповнення dim_entity  
```sql
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
```
<img width="803" height="645" alt="image" src="https://github.com/user-attachments/assets/ddd34c63-c0b1-469d-b6a2-e4bd3914d3ed" />  
Повернуло 245 записів  

Наповнюємо таблицю fact_infectious  
```sql
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
```
Тут варто відмітити використання NULLIF, що дозволило коректно скопіювати дані, при цьому NULL - дані відсутні (дослідження не проводилися), 0 - дослідження були, зафіксовано нуль випадків  

<img width="839" height="620" alt="image" src="https://github.com/user-attachments/assets/81752b0f-d809-4417-94a8-e981320732e1" />  
Повернуло 10521 запис з логічними ключами та зв'язком з сутністю dim_entity  

Отже, дані нормалізовані до третьої форми, янаслідок на основі "брудних" даних створено дві нові сутності  
Завдання можна вважати виконаним)

## **Завдання №3: Аналіз даних**  

```sql
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
```
Результат запиту:  
<img width="887" height="252" alt="image" src="https://github.com/user-attachments/assets/e26b8e99-23a7-4f8c-8f6f-8cde954efefe" />

## **Завдання №4: Різниця в роках**  

```sql
SELECT
	entity_id
    ,year
    ,MAKEDATE(year, 1) AS beg_year
    ,CURDATE() AS date_now
    ,TIMESTAMPDIFF(YEAR, MAKEDATE(Year, 1), CURDATE()) AS years_difference
FROM fact_infectious;
```

Результат запиту:  
<img width="378" height="522" alt="image" src="https://github.com/user-attachments/assets/aa6d93e8-cb10-46c7-823e-eec11b6c9204" />  

## **Завдання №5: Функція**  

```sql
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
```

Результат:  
<img width="396" height="537" alt="image" src="https://github.com/user-attachments/assets/6b8d5aed-d477-4f1d-9bdb-2c8ac23c8681" />












