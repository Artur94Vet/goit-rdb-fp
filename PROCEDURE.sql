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

CALL AnalyzeAllColumns('final_project', 'infectious_cases');

