USE pandemic

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