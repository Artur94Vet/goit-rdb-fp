USE pandemic;
SELECT
	entity_id
    ,year
    ,MAKEDATE(year, 1) AS beg_year
    ,CURDATE() AS date_now
    ,TIMESTAMPDIFF(YEAR, MAKEDATE(Year, 1), CURDATE()) AS years_difference
FROM fact_infectious;