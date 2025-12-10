USE pandemic;
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
