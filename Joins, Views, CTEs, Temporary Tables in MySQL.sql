USE md_water_services;
/*Part 4 Joining Location to visits and to water source*/
SELECT
    loc.province_name,
    loc.town_name,
    vis.visit_count,
    loc.location_id,
    ws.type_of_water_source,
    ws.number_of_people_served
FROM 
	location AS loc
INNER JOIN 
	visits AS vis
ON 
	loc.location_id = vis.location_id
INNER JOIN 
	water_source AS ws
ON 
	ws.source_id = vis.source_id
WHERE 
	vis.visit_count = 1;
/*Removing Location ID and visit count adding location type and time in queue*/
SELECT
    loc.province_name,
    loc.town_name,
    loc.location_type,
    vis.time_in_queue,
    ws.type_of_water_source,
    ws.number_of_people_served
FROM 
	location AS loc
INNER JOIN 
	visits AS vis
ON 
	loc.location_id = vis.location_id
INNER JOIN 
	water_source AS ws
ON 
	ws.source_id = vis.source_id
WHERE 
	vis.visit_count = 1;
/*Joining well pollution table*/
SELECT
    loc.province_name,
    loc.town_name,
    loc.location_type,
    vis.time_in_queue,
    ws.type_of_water_source,
    ws.number_of_people_served,
    wp.results
FROM 
	location AS loc
INNER JOIN 
	visits AS vis
ON 
	loc.location_id = vis.location_id
INNER JOIN 
	water_source AS ws
ON 
	ws.source_id = vis.source_id
LEFT JOIN
	well_pollution AS wp
ON 
	vis.source_id = wp.source_id
WHERE 
	vis.visit_count = 1;
    
/*Creating views*/
CREATE VIEW Combined_analysis As 
(SELECT
    loc.province_name,
    loc.town_name,
    loc.location_type,
    vis.time_in_queue,
    ws.type_of_water_source,
    ws.number_of_people_served,
    wp.results
FROM 
	location AS loc
INNER JOIN 
	visits AS vis
ON 
	loc.location_id = vis.location_id
INNER JOIN 
	water_source AS ws
ON 
	ws.source_id = vis.source_id
LEFT JOIN
	well_pollution AS wp
ON 
	vis.source_id = wp.source_id
WHERE 
	vis.visit_count = 1
);

/* The last analysis #Chidis query code*/
WITH province_totals AS (-- This CTE calculates the population of each province
SELECT
province_name,
SUM(number_of_people_served) AS total_ppl_serv
FROM
combined_analysis
GROUP BY
province_name
)
SELECT
ct.province_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN type_of_water_source = 'well'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
combined_analysis ct
JOIN
province_totals pt 
ON 
ct.province_name = pt.province_name
GROUP BY
ct.province_name
ORDER BY
ct.province_name;

/*AGGREGATING BY TOWNS,
  since there are two Harare towns, one in Akatsi and the other in Kilimani, Amina is another example.
  MYSQL wont know how to aggregate first without grouping by provinces first*/
/*To get around that, we have to group by province first, then by town, 
  so that the duplicate towns are distinct because they are in different towns*/
WITH town_totals AS ( /*--This CTE calculates the population of each town
−− Since there are two Harare towns, we have to group by province_name and town_name*/
SELECT 
	province_name,
    town_name, 
    SUM(number_of_people_served) AS total_ppl_serv
FROM 
	combined_analysis
GROUP BY 
	province_name,
    town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN type_of_water_source = 'well' 
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis AS ct
JOIN /* Since the town names are not unique, we have to join on a composite key*/
	town_totals AS tt 
ON 
	ct.province_name = tt.province_name 
	AND ct.town_name = tt.town_name
GROUP BY /*We group by province first, then by town*/
	ct.province_name,
	ct.town_name
ORDER BY
	ct.town_name;
    
/*Creating temporary tables*/
CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS ( /*--This CTE calculates the population of each town
−− Since there are two Harare towns, we have to group by province_name and town_name*/
SELECT 
	province_name,
    town_name, 
    SUM(number_of_people_served) AS total_ppl_serv
FROM 
	combined_analysis
GROUP BY 
	province_name,
    town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN type_of_water_source = 'well'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis AS ct
JOIN /* Since the town names are not unique, we have to join on a composite key*/
	town_totals AS tt 
ON 
	ct.province_name = tt.province_name 
	AND ct.town_name = tt.town_name
GROUP BY /*We group by province first, then by town*/
	ct.province_name,
	ct.town_name
ORDER BY
	ct.town_name;

    
/* Which town has the highest ratio of people who have taps, but have no running water*/
SELECT
	province_name,
	town_name,
	ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) * 100,0) AS Pct_broken_taps
FROM
	town_aggregated_water_access;


/*A practical plan*/
CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
/* Project_id −− Unique key for sources in case we visit the same
source more than once in the future.
*/
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
/* source_id −− Each of the sources we want to improve should exist,
and should refer to the source table. This ensures data integrity.
*/
Address VARCHAR(50), /*Street address*/
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50), /*What the engineers should do at that place*/
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
/* Source_status −− We want to limit the type of information engineers can give us, so we
limit Source_status.
− By DEFAULT all projects are in the "Backlog" which is like a TODO list.
− CHECK() ensures only those three options will be accepted. This helps to maintain clean data.
*/
Date_of_completion DATE, /*Engineers will add this the day the source has been upgraded*/
Comments TEXT /*Engineers can leave comments. We use a TEXT type that has no limit on char length*/
);

/*Analysis of the practical plan*/
SELECT
    water_source.source_id,
    location.address,
    location.town_name AS Town,
    location.province_name AS Province,
    water_source.type_of_water_source AS source_type,	
    CASE WHEN (type_of_water_source = "well") AND results = "Contaminated: Biological"
    THEN "Install RO filter and UV filter"
    WHEN (type_of_water_source = "well") AND results = "Contaminated: Chemical"
    THEN "Install RO filter" 
	WHEN (type_of_water_source = "river") 
    THEN "Drill well"
    WHEN (type_of_water_source = "shared_tap") AND time_in_queue >=30
    THEN CONCAT("Install", FLOOR(time_in_queue/30), " taps nearby")
    WHEN (type_of_water_source = "tap_in_home_broken") 
    THEN "Diagnose local infrastructure"
    END AS "Improvement" ,
    well_pollution.results AS source_status
FROM
	water_source
LEFT JOIN
	well_pollution 
ON 
	water_source.source_id = well_pollution.source_id
INNER JOIN
	visits 
ON 
	water_source.source_id = visits.source_id
INNER JOIN
	location 
ON 
	location.location_id = visits.location_id
WHERE
    visits.visit_count = 1 /*This must always be true*/
    AND ( /*AND one of the following (OR) options must be true as well.*/
		results != 'Clean'
		OR type_of_water_source IN ('tap_in_home_broken','river')
		OR (type_of_water_source = 'shared_tap' AND time_in_queue >=30));
