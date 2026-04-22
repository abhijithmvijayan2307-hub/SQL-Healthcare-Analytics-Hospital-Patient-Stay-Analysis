CREATE DATABASE healthcare_db;
USE healthcare_db;
CREATE TABLE train_data (
  case_id                  INT,
  Hospital_code            INT,
  Hospital_type_code       VARCHAR(5),
  City_Code_Hospital       INT,
  Hospital_region_code     VARCHAR(5),
  Available_Extra_Rooms    INT,
  Department               VARCHAR(50),
  Ward_Type                VARCHAR(5),
  Ward_Facility_Code       VARCHAR(5),
  Bed_Grade                FLOAT,
  patientid                INT,
  City_Code_Patient        FLOAT,
  Type_of_Admission        VARCHAR(20),
  Severity_of_Illness      VARCHAR(20),
  Visitors_with_Patient    INT,
  Age                      VARCHAR(10),
  Admission_Deposit        FLOAT,
  Stay                     VARCHAR(20)
);
SHOW VARIABLES LIKE 'secure_file_priv';
TRUNCATE TABLE train_data;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/train_data.csv'
IGNORE INTO TABLE train_data
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
SELECT COUNT(*) FROM train_data;
SELECT * FROM train_data LIMIT 10;
-- Which department has the longest patient stays?
SELECT Department,
       COUNT(*) AS total_patients,
       SUM(CASE WHEN Stay = 'More than 100 Days' THEN 1 ELSE 0 END) AS extreme_stays,
       ROUND(SUM(CASE WHEN Stay IN ('51-60','61-70','71-80','81-90','91-100','More than 100 Days') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS long_stay_pct
FROM train_data
GROUP BY Department
ORDER BY long_stay_pct DESC;
-- 2. Severity of illness vs average deposit amount
SELECT Severity_of_Illness,
       COUNT(*) AS total_patients,
       ROUND(AVG(Admission_Deposit), 2) AS avg_deposit,
       ROUND(MIN(Admission_Deposit), 2) AS min_deposit,
       ROUND(MAX(Admission_Deposit), 2) AS max_deposit
FROM train_data
GROUP BY Severity_of_Illness
ORDER BY avg_deposit DESC;
-- 3. Which age group has the most extreme stays?
SELECT Age,
       COUNT(*) AS total_patients,
       SUM(CASE WHEN Stay = 'More than 100 Days' THEN 1 ELSE 0 END) AS over_100_days,
       RANK() OVER (ORDER BY SUM(CASE WHEN Stay = 'More than 100 Days' THEN 1 ELSE 0 END) DESC) AS risk_rank
FROM train_data
GROUP BY Age
ORDER BY risk_rank;
-- 4. Emergency vs Trauma vs Urgent admissions breakdown
SELECT Type_of_Admission,
       Severity_of_Illness,
       COUNT(*) AS total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY Type_of_Admission), 2) AS pct_within_type
FROM train_data
GROUP BY Type_of_Admission, Severity_of_Illness
ORDER BY Type_of_Admission, pct_within_type DESC;
-- 5. Hospital type with highest patient load and long stays
SELECT Hospital_type_code,
       COUNT(*) AS total_patients,
       ROUND(AVG(Visitors_with_Patient), 1) AS avg_visitors,
       SUM(CASE WHEN Stay IN ('51-60','61-70','71-80','81-90','91-100','More than 100 Days') THEN 1 ELSE 0 END) AS long_stays,
       ROUND(SUM(CASE WHEN Stay IN ('51-60','61-70','71-80','81-90','91-100','More than 100 Days') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS long_stay_pct
FROM train_data
GROUP BY Hospital_type_code
ORDER BY long_stay_pct DESC;
-- 6. Ward type effect on length of stay
SELECT Ward_Type,
       COUNT(*) AS total_patients,
       SUM(CASE WHEN Stay = '0-10' THEN 1 ELSE 0 END) AS short_stays,
       SUM(CASE WHEN Stay = 'More than 100 Days' THEN 1 ELSE 0 END) AS extreme_stays,
       ROUND(SUM(CASE WHEN Stay = 'More than 100 Days' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS extreme_pct
FROM train_data
GROUP BY Ward_Type
ORDER BY extreme_pct DESC;
-- 7. Top 10 hospitals by long stay burden
SELECT Hospital_code,
       COUNT(*) AS total_patients,
       SUM(CASE WHEN Stay IN ('51-60','61-70','71-80','81-90','91-100','More than 100 Days') THEN 1 ELSE 0 END) AS long_stays,
       ROUND(SUM(CASE WHEN Stay IN ('51-60','61-70','71-80','81-90','91-100','More than 100 Days') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS long_stay_pct
FROM train_data
GROUP BY Hospital_code
ORDER BY long_stay_pct DESC
LIMIT 10;
-- 8. Patient volume trend by admission deposit range (binning)
SELECT 
  CASE 
    WHEN Admission_Deposit < 2000 THEN 'Under 2000'
    WHEN Admission_Deposit < 4000 THEN '2000-3999'
    WHEN Admission_Deposit < 6000 THEN '4000-5999'
    WHEN Admission_Deposit < 8000 THEN '6000-7999'
    ELSE 'Above 8000'
  END AS deposit_range,
  COUNT(*) AS total_patients,
  ROUND(AVG(Visitors_with_Patient), 1) AS avg_visitors,
  SUM(CASE WHEN Severity_of_Illness = 'Extreme' THEN 1 ELSE 0 END) AS extreme_cases
FROM train_data
GROUP BY deposit_range
ORDER BY total_patients DESC;