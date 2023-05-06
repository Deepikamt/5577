-------Create statements
CREATE TABLE Accident_table (
  Accident_ID varchar(255) primary key,
  Location_ID int foreign key,
  Time time,
  Date date,
  Latitude float(9),
  Longitude float(9),
  Distance float(6),
  Description varchar(100),
  Street varchar(40),
  City char(40),
  County char(40),
  State char (3),
  Zipcode varchar(11),
  Severity int
);


CREATE TABLE factors (
  Accident_ID varchar(255) primary key,
  Location_ID int,
  Amenity bool,
  Bump bool,
  Crossing bool,
  Give_Way bool,
  Junction bool,
  No_Exit bool,
  Railway bool,
  Roundabout bool,
  Stop bool,
  Traffic_Signal bool
);

CREATE TABLE new_accident_factors ( 
  Location_ID int foreign key, 
  Accident_ID varchar(255) primary key, 
  Temperature float(6), 
  Wind_Chill float(4), 
  Humidity int, 
  Pressure float(5), 
  Visibility int, 
  Wind_Direction char(15), 
  Wind_Speed float(3), 
  Weather_Condition char(50) 
);


CREATE TABLE Accident_locations (
  gid serial primary key,
  location_id int foreign key,
  geoid varchar(5),
  geom geometry(MultiPolygon, 26915)
);




----calculates the number of accidents and the average severity for each street, as well as the number of accidents and the average severity for each county. The results are then ordered by the rank of the counties based on the number of accidents.
WITH accident_counts AS (
  SELECT 
    counties.name, 
    COUNT(accidents.*) AS num_accidents
  FROM 
    accident_locations AS accidents
    JOIN mn_counties AS counties
    ON ST_Intersects(accidents.geom, counties.geom)
  GROUP BY counties.name
),
top_counties AS (
  SELECT 
    name, 
    num_accidents, 
    ROW_NUMBER() OVER (ORDER BY num_accidents DESC) AS rank
  FROM accident_counts
),
top_severity AS (
  SELECT 
    c.name AS county_name,
    AVG(a.severity) as avg_severity
  FROM 
    accident_table a
    JOIN accident_locations l ON a.location_id = a.location_id 
    JOIN mn_counties c ON ST_Intersects(l.geom, c.geom) AND ST_Intersects(c.geom, l.geom)
  GROUP BY c.name
),
overall_avg_severity AS (
  SELECT AVG(a.severity) AS avg_severity FROM accident_table a
)
SELECT 
  top_counties.name AS county_name, 
  top_counties.num_accidents, 
  top_severity.avg_severity AS county_avg_severity,
  overall_avg_severity.avg_severity AS overall_avg_severity
FROM 
  top_counties
  JOIN mn_counties AS counties ON top_counties.name = counties.name
  LEFT JOIN top_severity ON top_counties.name = top_severity.county_name
  CROSS JOIN overall_avg_severity
ORDER BY top_counties.rank;


------------SELECT accidents.*, counties.*
SELECT accidents.*, counties.*
FROM accident_points AS accidents
JOIN mn_counties AS counties
ON ST_Intersects(accidents.geom, counties.geom);



----------------Calculate the percentage of accidents that occur during rush hour (defined as 7-9am and 4-6pm on weekdays)
WITH rush_hour_accidents AS (
  SELECT 
    Location_ID,
    Date,
    CASE 
      WHEN DATE_PART('hour', Time) >= 7 AND DATE_PART('hour', Time) <= 9 AND DATE_PART('dow', Date) >= 1 AND DATE_PART('dow', Date) <= 5
        OR DATE_PART('hour', Time) >= 16 AND DATE_PART('hour', Time) <= 18 AND DATE_PART('dow', Date) >= 1 AND DATE_PART('dow', Date) <= 5
      THEN 1
      ELSE 0
    END AS rush_hour
  FROM Accident_table
)
SELECT 
  Date,
  COUNT(*) AS total_accidents,
  SUM(rush_hour) AS rush_hour_accidents,
  100.0 * SUM(rush_hour) / COUNT(*) AS percentage_rush_hour_accidents
FROM rush_hour_accidents
GROUP BY Date
ORDER BY Date;


------Countywise accidents
SELECT c.name, COUNT(*) AS num_accidents
FROM accident_points ap
JOIN mn_counties c
ON ST_Contains(c.geom, ap.geom)
GROUP BY c.name
ORDER BY num_accidents DESC;


-----visualise number of accidents happened at a point
SELECT 
EXTRACT(YEAR FROM a.Date) AS year,
EXTRACT(MONTH FROM a.Date) AS month,
  ST_SetSRID(ST_MakePoint(a.Longitude, a.Latitude), 4326) AS geom,
  COUNT(*) AS num_accidents
FROM Accident_table a
WHERE a.Date >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '5' YEAR
GROUP BY year, month, geom
ORDER BY year, month, num_accidents DESC;


--------Calculate the total number of accidents and the average severity of accidents for each month over the past 5 years:
SELECT 
  DATE_PART('year', Date) as year,
  DATE_PART('month', Date) as month,
  COUNT(*) as num_accidents,
  AVG(Severity) as avg_severity
FROM Accident_table
WHERE Date >= CURRENT_DATE - INTERVAL '5 years'
GROUP BY DATE_PART('year', Date), DATE_PART('month', Date)
ORDER BY year, month;






