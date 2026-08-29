--create a backup/clean copy from original table
SELECT *
INTO dbo.fake_employee_weekly_performance_clean
FROM dbo.fake_employee_weekly_performance;
--==fix employee name, checking white space in name
SELECT
    '[' + Employee_Name + ']' AS Employee_Name_Check,
    COUNT(*) AS Row_Count
FROM dbo.fake_employee_weekly_performance_clean
GROUP BY Employee_Name
ORDER BY Employee_Name;
--apply trim 
SELECT
    Employee_Name AS Original_Name,
    TRIM(Employee_Name) AS Cleaned_Name
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name <> TRIM(Employee_Name);
--apply REPLACE to name
SELECT
    Employee_Name AS Original_Name,
    REPLACE(Employee_Name, '  ', ' ') AS Cleaned_Name
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name LIKE 'Olivia%';
--find out how many distinct Olivia values exist
SELECT
    '[' + Employee_Name + ']' AS Employee_Name_Check,
    LEN(Employee_Name) AS Name_Length,
    DATALENGTH(Employee_Name) AS Data_Length,
    COUNT(*) AS Row_Count
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name LIKE 'Olivia%'
GROUP BY
    Employee_Name,
    LEN(Employee_Name),
    DATALENGTH(Employee_Name)
ORDER BY
    Employee_Name;
--apply transformation to clean copy 
UPDATE dbo.fake_employee_weekly_performance_clean
SET Employee_Name = REPLACE(Employee_Name, '  ', ' ')
WHERE Employee_Name LIKE 'Olivia%';
--re verify name Olivia as one name not 2
SELECT
    Employee_Name,
    COUNT(*) AS Row_Count
FROM dbo.fake_employee_weekly_performance_clean
GROUP BY Employee_Name
ORDER BY Employee_Name;
--check employee + week grain or row
SELECT
    Employee_Name,
    Week,
    COUNT(*) AS Row_Count
FROM dbo.fake_employee_weekly_performance_clean
GROUP BY
    Employee_Name,
    Week
HAVING COUNT(*) > 1
ORDER BY
    Employee_Name,
    Week;--has 2 rows for nora and oliva week 4 and week1
--checking which duplicate row is the actual duplicate
SELECT *
FROM dbo.fake_employee_weekly_performance_clean
WHERE (Employee_Name = 'Nora Anderson' AND Week = 'Week 4')
   OR (Employee_Name = 'Olivia Chen' AND Week = 'Week 1')
ORDER BY Employee_Name, Week;
--check to see which row is first or second
SELECT
    *,
    ROW_NUMBER() OVER (
        PARTITION BY Employee_Name, Week
        ORDER BY Employee_Name
    ) AS Duplicate_Number
FROM dbo.fake_employee_weekly_performance_clean
WHERE (Employee_Name = 'Nora Anderson' AND Week = 'Week 4')
   OR (Employee_Name = 'Olivia Chen' AND Week = 'Week 1');
--establish missing weeks
SELECT
    Employee_Name,
    COUNT(DISTINCT Week) AS Unique_Weeks
FROM dbo.fake_employee_weekly_performance_clean
GROUP BY Employee_Name
HAVING COUNT(DISTINCT Week) < 4
ORDER BY Employee_Name;
--look at the actual missing weeks
SELECT
    Employee_Name,
    Week
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name IN ('Ava Martinez', 'Grace Thompson')
ORDER BY Employee_Name, Week;--ava missing week 4 and grace missing week 1
--so far problems: olivia 1 dup, nora 1 dup, ava missing 1 week, grace missing 1 week
--=verify the total number of unique employee-week combinations
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT Employee_Name + '|' + Week) AS Unique_Employee_Weeks
FROM dbo.fake_employee_weekly_performance_clean;
--separate employee name and week as separate columns
SELECT
    COUNT(*) AS Unique_Employee_Weeks
FROM
(
    SELECT DISTINCT
        Employee_Name,
        Week
    FROM dbo.fake_employee_weekly_performance_clean
) AS Unique_Combinations;
--check to see if every combo occurs more than once
SELECT
    Employee_Name,
    Week,
    COUNT(*) AS Row_Count
FROM dbo.fake_employee_weekly_performance_clean
GROUP BY
    Employee_Name,
    Week
HAVING COUNT(*) > 1
ORDER BY
    Employee_Name,
    Week;
--review which row should be removed
WITH DuplicateRows AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY Employee_Name, Week
            ORDER BY Employee_Name
        ) AS rn
    FROM dbo.fake_employee_weekly_performance_clean
)
SELECT *
FROM DuplicateRows
WHERE rn > 1;
--flag duplicate rows as review instead of deleting since they have different metrics
SELECT
    Employee_Name,
    Week,
    CASE
        WHEN COUNT(*) OVER (
            PARTITION BY Employee_Name, Week
        ) > 1
        THEN 'Duplicate - Review'
        ELSE 'Unique'
    END AS Record_Status
FROM dbo.fake_employee_weekly_performance_clean
ORDER BY Employee_Name, Week;
--investigate the invalid on que value
--identify the exact record with over 100
SELECT
    Week,
    Manager_Name,
    Employee_Name,
    On_Que
FROM dbo.fake_employee_weekly_performance_clean
WHERE On_Que < 0
   OR On_Que > 100;
--==check caleb's other weeks to see if 105 is anomaly
SELECT
    Employee_Name,
    Week,
    On_Que
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name = 'Caleb Wilson'
ORDER BY Week;
--==preview correction before using average to replace 105
SELECT
    Employee_Name,
    Week,
    On_Que AS Original_On_Que,
    CAST(
        (
            SELECT AVG(On_Que)
            FROM dbo.fake_employee_weekly_performance_clean AS c2
            WHERE c2.Employee_Name = c1.Employee_Name
              AND c2.On_Que BETWEEN 0 AND 100
        ) AS DECIMAL(5,2)
    ) AS Replacement_On_Que
FROM dbo.fake_employee_weekly_performance_clean AS c1
WHERE On_Que < 0
   OR On_Que > 100;
--update the invalid value to the clean copy
UPDATE dbo.fake_employee_weekly_performance_clean
SET On_Que = 92.50
WHERE Employee_Name = 'Caleb Wilson'
  AND Week = 'Week 3'
  AND On_Que = 105;
--verify the update
SELECT
    Employee_Name,
    Week,
    On_Que
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name = 'Caleb Wilson'
ORDER BY Week;--should update 105 to the new avg
--recheck the entire column
SELECT
    MIN(On_Que) AS Min_On_Que,
    MAX(On_Que) AS Max_On_Que,
    AVG(On_Que) AS Avg_On_Que
FROM dbo.fake_employee_weekly_performance_clean;
--===check make sure nothing is outside of 0 to 100
SELECT *
FROM dbo.fake_employee_weekly_performance_clean
WHERE On_Que < 0
   OR On_Que > 100;
--fix NULL in project time
--locate the missing value
SELECT
    Week,
    Manager_Name,
    Employee_Name,
    Projected_Time
FROM dbo.fake_employee_weekly_performance_clean
WHERE Projected_Time IS NULL;--week 4 olivia has null projected time
--check olivia's other weeks
SELECT
    Employee_Name,
    Week,
    Projected_Time
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name = 'Olivia Chen'
ORDER BY Week;
--check avg for olivia
SELECT
    AVG(Projected_Time) AS Olivia_Avg_Project_Time
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name = 'Olivia Chen'
  AND Projected_Time IS NOT NULL;
--preview the replacement 
SELECT
    Employee_Name,
    Week,
    Projected_Time AS Original_Project_Time,
    CAST(
        (
            SELECT AVG(Projected_Time)
            FROM dbo.fake_employee_weekly_performance_clean AS p2
            WHERE p2.Employee_Name = p1.Employee_Name
              AND p2.Projected_Time IS NOT NULL
        ) AS DECIMAL(5,2)
    ) AS Replacement_Project_Time
FROM dbo.fake_employee_weekly_performance_clean AS p1
WHERE Employee_Name = 'Olivia Chen'
  AND Projected_Time IS NULL;
--apply to clean copy
UPDATE dbo.fake_employee_weekly_performance_clean
SET Projected_Time = 0.67
WHERE Employee_Name = 'Olivia Chen'
  AND Week = 'Week 4'
  AND Projected_Time IS NULL;
--verify the record to make sure week for has 0.67 instead of null
SELECT
    Employee_Name,
    Week,
    Projected_Time
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name = 'Olivia Chen'
  AND Week = 'Week 4';
--check entire column for NULLs
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Projected_Time) AS Not_NULL,
    COUNT(*) - COUNT(Projected_Time) AS Missing
FROM dbo.fake_employee_weekly_performance_clean;--CLEANED
--=Check extended day supply
SELECT
    MIN(Extended_Day_Supply) AS Min_Extended_Day_Supply,
    MAX(Extended_Day_Supply) AS Max_Extended_Day_Supply,
    AVG(Extended_Day_Supply) AS Avg_Extended_Day_Supply
FROM dbo.fake_employee_weekly_performance_clean;
--check for nulls
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Extended_Day_Supply) AS Not_NULL,
    COUNT(*) - COUNT(Extended_Day_Supply) AS Missing
FROM dbo.fake_employee_weekly_performance_clean;--has 1 missing
--check for invalid percentages
SELECT *
FROM dbo.fake_employee_weekly_performance_clean
WHERE Extended_Day_Supply < 0
   OR Extended_Day_Supply > 100;
--find the exact record of null
SELECT
    Week,
    Manager_Name,
    Employee_Name,
    Extended_Day_Supply
FROM dbo.fake_employee_weekly_performance_clean
WHERE Extended_Day_Supply IS NULL;--ethan has week 3 as null
--check other weeks for nulls
SELECT
    Employee_Name,
    Week,
    Extended_Day_Supply
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name = 'Ethan Brooks'
ORDER BY Week;--no null in other weeks
--calculate avg to replace null with
SELECT
    AVG(Extended_Day_Supply) AS Ethan_Avg_Extended_Day_Supply
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name = 'Ethan Brooks'
  AND Extended_Day_Supply IS NOT NULL;
--preview the replacement
SELECT
    Employee_Name,
    Week,
    Extended_Day_Supply AS Original_Extended_Day_Supply,
    CAST(
        (
            SELECT AVG(Extended_Day_Supply)
            FROM dbo.fake_employee_weekly_performance_clean AS e2
            WHERE e2.Employee_Name = e1.Employee_Name
              AND e2.Extended_Day_Supply IS NOT NULL
        ) AS DECIMAL(5,2)
    ) AS Replacement_Extended_Day_Supply
FROM dbo.fake_employee_weekly_performance_clean AS e1
WHERE Employee_Name = 'Ethan Brooks'
  AND Extended_Day_Supply IS NULL;
--=apply the fix to clean copy
UPDATE dbo.fake_employee_weekly_performance_clean
SET Extended_Day_Supply = 85.83
WHERE Employee_Name = 'Ethan Brooks'
  AND Week = 'Week 3'
  AND Extended_Day_Supply IS NULL;
--verify record
SELECT
    Employee_Name,
    Week,
    Extended_Day_Supply
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name = 'Ethan Brooks'
  AND Week = 'Week 3';
--check the entire column
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Extended_Day_Supply) AS Not_NULL,
    COUNT(*) - COUNT(Extended_Day_Supply) AS Missing
FROM dbo.fake_employee_weekly_performance_clean;--done it is cleaned
--validate the numeric range
SELECT
    MIN(Extended_Day_Supply) AS Min_Extended_Day_Supply,
    MAX(Extended_Day_Supply) AS Max_Extended_Day_Supply,
    AVG(Extended_Day_Supply) AS Avg_Extended_Day_Supply
FROM dbo.fake_employee_weekly_performance_clean;

SELECT *
FROM dbo.fake_employee_weekly_performance_clean
WHERE Extended_Day_Supply < 0
   OR Extended_Day_Supply > 100;--cleaned and validated
--=====validated claim daily
--check max,min, avg
SELECT
    MIN(Validated_Claims_Daily) AS Min_Validated_Claims,
    MAX(Validated_Claims_Daily) AS Max_Validated_Claims,
    AVG(Validated_Claims_Daily) AS Avg_Validated_Claims
FROM dbo.fake_employee_weekly_performance_clean;
--check for neg
SELECT *
FROM dbo.fake_employee_weekly_performance_clean
WHERE Validated_Claims_Daily < 0;
--check for nulls
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Validated_Claims_Daily) AS Not_NULL,
    COUNT(*) - COUNT(Validated_Claims_Daily) AS Missing
FROM dbo.fake_employee_weekly_performance_clean;--CLEANED AND VALIDATED
--==CHECK composite assessment daily
--find min, max, avg
SELECT
    MIN(Composite_Assessments_Daily) AS Min_Composite,
    MAX(Composite_Assessments_Daily) AS Max_Composite,
    AVG(Composite_Assessments_Daily) AS Avg_Composite
FROM dbo.fake_employee_weekly_performance_clean;
--check for neg value
SELECT *
FROM dbo.fake_employee_weekly_performance_clean
WHERE Composite_Assessments_Daily < 0;
--check for nulls
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Composite_Assessments_Daily) AS Not_NULL,
    COUNT(*) - COUNT(Composite_Assessments_Daily) AS Missing
FROM dbo.fake_employee_weekly_performance_clean;--CLEANED AND VALIDATED
--==CMR assessment count
--find min, max, avg
SELECT
    MIN(CMR_Assessment_Count) AS Min_CMR,
    MAX(CMR_Assessment_Count) AS Max_CMR,
    AVG(CMR_Assessment_Count) AS Avg_CMR
FROM dbo.fake_employee_weekly_performance_clean;
--find neg value
SELECT *
FROM dbo.fake_employee_weekly_performance_clean
WHERE CMR_Assessment_Count < 0;
--check nulls
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(CMR_Assessment_Count) AS Not_NULL,
    COUNT(*) - COUNT(CMR_Assessment_Count) AS Missing
FROM dbo.fake_employee_weekly_performance_clean;--cleaned and validated
--==check coa functional
--find max, min, avg
SELECT
    MIN(COA_Functional_Assessment_Count) AS Min_COA,
    MAX(COA_Functional_Assessment_Count) AS Max_COA,
    AVG(COA_Functional_Assessment_Count) AS Avg_COA
FROM dbo.fake_employee_weekly_performance_clean;
--find neg value
SELECT *
FROM dbo.fake_employee_weekly_performance_clean
WHERE COA_Functional_Assessment_Count < 0;
--check nulls
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(COA_Functional_Assessment_Count) AS Not_NULL,
    COUNT(*) - COUNT(COA_Functional_Assessment_Count) AS Missing
FROM dbo.fake_employee_weekly_performance_clean;--CLEANED AND VALIDATED
--=Check total care questions completed
--find max, min, avg
SELECT
    MIN(Total_Care_Questions_Completed) AS Min_Care_Questions,
    MAX(Total_Care_Questions_Completed) AS Max_Care_Questions,
    AVG(Total_Care_Questions_Completed) AS Avg_Care_Questions
FROM dbo.fake_employee_weekly_performance_clean;
--find neg value
SELECT *
FROM dbo.fake_employee_weekly_performance_clean
WHERE Total_Care_Questions_Completed < 0;
--check nulls
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Total_Care_Questions_Completed) AS Not_NULL,
    COUNT(*) - COUNT(Total_Care_Questions_Completed) AS Missing
FROM dbo.fake_employee_weekly_performance_clean;--CLEANED AND VALIDATED
--==calls day
--find max, min, avg
SELECT
    MIN(Calls_Day) AS Min_Calls_Day,
    MAX(Calls_Day) AS Max_Calls_Day,
    AVG(Calls_Day) AS Avg_Calls_Day
FROM dbo.fake_employee_weekly_performance_clean;
--find neg value
SELECT *
FROM dbo.fake_employee_weekly_performance_clean
WHERE Calls_Day < 0;
--find nulls
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Calls_Day) AS Not_NULL,
    COUNT(*) - COUNT(Calls_Day) AS Missing
FROM dbo.fake_employee_weekly_performance_clean;--cleaned and validated
--==ahd warm transfer
--find max, min, avg
SELECT
    MIN(AHD_Warm_Transfer_Count) AS Min_AHD_Warm_Transfer,
    MAX(AHD_Warm_Transfer_Count) AS Max_AHD_Warm_Transfer,
    AVG(AHD_Warm_Transfer_Count) AS Avg_AHD_Warm_Transfer
FROM dbo.fake_employee_weekly_performance_clean;
--find neg value
SELECT *
FROM dbo.fake_employee_weekly_performance_clean
WHERE AHD_Warm_Transfer_Count < 0;
--find nulls
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(AHD_Warm_Transfer_Count) AS Not_NULL,
    COUNT(*) - COUNT(AHD_Warm_Transfer_Count) AS Missing
FROM dbo.fake_employee_weekly_performance_clean;--cleaned and validated
--check hip referral
--find max, min, avg
SELECT
    MIN(HIP_Referral_Count) AS Min_HIP_Referral,
    MAX(HIP_Referral_Count) AS Max_HIP_Referral,
    AVG(HIP_Referral_Count) AS Avg_HIP_Referral
FROM dbo.fake_employee_weekly_performance_clean;
--find neg value
SELECT *
FROM dbo.fake_employee_weekly_performance_clean
WHERE HIP_Referral_Count < 0;
--check nulls
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(HIP_Referral_Count) AS Not_NULL,
    COUNT(*) - COUNT(HIP_Referral_Count) AS Missing
FROM dbo.fake_employee_weekly_performance_clean;--has a nvarchar error
--check to confirm data type
SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'fake_employee_weekly_performance_clean'
  AND COLUMN_NAME = 'HIP_Referral_Count';
  --check whether all values can be converted to numbers
SELECT
    HIP_Referral_Count
FROM dbo.fake_employee_weekly_performance_clean
WHERE TRY_CONVERT(INT, HIP_Referral_Count) IS NULL
  AND HIP_Referral_Count IS NOT NULL;
--calculate the statistics correctly, convert to number
SELECT
    MIN(TRY_CONVERT(INT, HIP_Referral_Count)) AS Min_HIP_Referral,
    MAX(TRY_CONVERT(INT, HIP_Referral_Count)) AS Max_HIP_Referral,
    AVG(TRY_CONVERT(DECIMAL(10,2), HIP_Referral_Count)) AS Avg_HIP_Referral
FROM dbo.fake_employee_weekly_performance_clean;
--check neg
SELECT *
FROM dbo.fake_employee_weekly_performance_clean
WHERE TRY_CONVERT(INT, HIP_Referral_Count) < 0;
--check nulls
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(HIP_Referral_Count) AS Not_NULL,
    COUNT(*) - COUNT(HIP_Referral_Count) AS Missing
FROM dbo.fake_employee_weekly_performance_clean;--cleaned but the nvarchar will be addressed during transformation
--=structural audit--check how many rows for each manager
SELECT
    Manager_Name,
    COUNT(*) AS Row_Count
FROM dbo.fake_employee_weekly_performance_clean
GROUP BY Manager_Name
ORDER BY Manager_Name;--48 rows
--check how many employees/manager
SELECT
    Manager_Name,
    COUNT(DISTINCT Employee_Name) AS Employee_Count
FROM dbo.fake_employee_weekly_performance_clean
GROUP BY Manager_Name
ORDER BY Manager_Name;--ok
--check each employee belongs only to one manager
SELECT
    Employee_Name,
    COUNT(DISTINCT Manager_Name) AS Manager_Count
FROM dbo.fake_employee_weekly_performance_clean
GROUP BY Employee_Name
HAVING COUNT(DISTINCT Manager_Name) > 1;
--ready for transformation for tableau
--inspect the data types of every column
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'fake_employee_weekly_performance_clean'
ORDER BY ORDINAL_POSITION;
--===check if every non-null can become an integer
SELECT
    HIP_Referral_Count
FROM dbo.fake_employee_weekly_performance_clean
WHERE TRY_CONVERT(INT, HIP_Referral_Count) IS NULL
  AND HIP_Referral_Count IS NOT NULL;
--===change data type in hip referral column
ALTER TABLE dbo.fake_employee_weekly_performance_clean
ALTER COLUMN HIP_Referral_Count INT;
--verify the data type changed from nvarchar to int for hip referral
SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'fake_employee_weekly_performance_clean'
  AND COLUMN_NAME = 'HIP_Referral_Count';
--test calculation from previously failed
SELECT
    MIN(HIP_Referral_Count) AS Min_HIP_Referral,
    MAX(HIP_Referral_Count) AS Max_HIP_Referral,
    AVG(HIP_Referral_Count) AS Avg_HIP_Referral
FROM dbo.fake_employee_weekly_performance_clean;
--test hip referral to make sure the numbers work
SELECT
    MIN(HIP_Referral_Count) AS Min_HIP_Referral,
    MAX(HIP_Referral_Count) AS Max_HIP_Referral,
    AVG(HIP_Referral_Count) AS Avg_HIP_Referral
FROM dbo.fake_employee_weekly_performance_clean;--CLEAN AND CORRECTED DATA TYPE
--adding a Week_Number column to store integer as number for week
ALTER TABLE dbo.fake_employee_weekly_performance_clean
ADD Week_Number INT;
--populate and change the column
UPDATE dbo.fake_employee_weekly_performance_clean
SET Week_Number =
    TRY_CONVERT(
        INT,
        REPLACE(Week, 'Week ', '')
    );
--verify or check
SELECT DISTINCT
    Week,
    Week_Number
FROM dbo.fake_employee_weekly_performance_clean
ORDER BY Week_Number;
--do a final structural check
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT Employee_Name) AS Unique_Employees,
    COUNT(DISTINCT Manager_Name) AS Unique_Managers,
    COUNT(DISTINCT Week) AS Unique_Weeks
FROM dbo.fake_employee_weekly_performance_clean;---has total rows, unique employees, unique managers, unique weeks
--===check for 46 unique employee weeks
SELECT
    COUNT(*) AS Unique_Employee_Weeks
FROM
(
    SELECT DISTINCT
        Employee_Name,
        Week
    FROM dbo.fake_employee_weekly_performance_clean
) AS x;--has 46
--run check on duplicates that have different metrics
SELECT *
FROM dbo.fake_employee_weekly_performance_clean
WHERE (Employee_Name = 'Nora Anderson' AND Week = 'Week 4')
   OR (Employee_Name = 'Olivia Chen' AND Week = 'Week 1')
ORDER BY Employee_Name, Week;--these are possibly not duplicates. They can be different weeks with different metrics numbers
--inspect duplicate number 
SELECT
    Employee_Name,
    Week,
    Manager_Name,
    Composite_Assessments_Daily,
    Validated_Claims_Daily,
    Extended_Day_Supply,
    CMR_Assessment_Count,
    COA_Functional_Assessment_Count,
    Total_Care_Questions_Completed,
    Projected_Time,
    On_Que,
    Calls_Day,
    AHD_Warm_Transfer_Count,
    HIP_Referral_Count
FROM dbo.fake_employee_weekly_performance_clean
WHERE (Employee_Name = 'Nora Anderson' AND Week = 'Week 4')
   OR (Employee_Name = 'Olivia Chen' AND Week = 'Week 1')
ORDER BY Employee_Name;
--check original table
SELECT
    Employee_Name,
    Week,
    COUNT(*) AS Row_Count
FROM dbo.fake_employee_weekly_performance
WHERE (Employee_Name = 'Nora Anderson' AND Week = 'Week 4')
   OR (Employee_Name = 'Olivia Chen' AND Week = 'Week 1')
GROUP BY
    Employee_Name,
    Week;
--compare original records
SELECT *
FROM dbo.fake_employee_weekly_performance
WHERE (Employee_Name = 'Nora Anderson' AND Week = 'Week 4')
   OR (Employee_Name = 'Olivia Chen' AND Week = 'Week 1');
--check the duplicate rows in the clean table
SELECT *
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name = 'Olivia Chen'
  AND Week = 'Week 1'
  AND Composite_Assessments_Daily = 25
  AND Validated_Claims_Daily = 22
  AND Extended_Day_Supply = 94.8
  AND CMR_Assessment_Count = 3
  AND COA_Functional_Assessment_Count = 7
  AND Total_Care_Questions_Completed = 37
  AND Projected_Time = 0.84;

--==check if previous command added an extra row
SELECT
    COUNT(*) AS Original_Rows
FROM dbo.fake_employee_weekly_performance;
SELECT
    COUNT(*) AS Clean_Rows
FROM dbo.fake_employee_weekly_performance_clean;
--=check to see rows exist in the clean table but do not exist in original table
SELECT
    Employee_Name,
    Week,
    Manager_Name,
    Composite_Assessments_Daily,
    Validated_Claims_Daily,
    Extended_Day_Supply,
    CMR_Assessment_Count,
    COA_Functional_Assessment_Count,
    Total_Care_Questions_Completed,
    Projected_Time,
    On_Que,
    Calls_Day,
    AHD_Warm_Transfer_Count,
    HIP_Referral_Count
FROM dbo.fake_employee_weekly_performance_clean

EXCEPT

SELECT
    Employee_Name,
    Week,
    Manager_Name,
    Composite_Assessments_Daily,
    Validated_Claims_Daily,
    Extended_Day_Supply,
    CMR_Assessment_Count,
    COA_Functional_Assessment_Count,
    Total_Care_Questions_Completed,
    Projected_Time,
    On_Que,
    Calls_Day,
    AHD_Warm_Transfer_Count,
    HIP_Referral_Count
FROM dbo.fake_employee_weekly_performance;
--==check total rows vs unique employee weeks shoud be 48 in original
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT Employee_Name + '|' + Week) AS Unique_Employee_Weeks
FROM dbo.fake_employee_weekly_performance;
--==now check the rows and unique employee weeks in the clean table
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT Employee_Name + '|' + Week) AS Unique_Employee_Weeks
FROM dbo.fake_employee_weekly_performance_clean;
--identify the duplicate key
SELECT
    Employee_Name,
    Week,
    COUNT(*) AS Row_Count
FROM dbo.fake_employee_weekly_performance_clean
GROUP BY
    Employee_Name,
    Week
HAVING COUNT(*) > 1;
--==verify duplicate
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT Employee_Name + '|' + Week) AS Unique_Employee_Weeks,
    COUNT(*) - COUNT(DISTINCT Employee_Name + '|' + Week) AS Duplicate_Row_Count
FROM dbo.fake_employee_weekly_performance_clean;

SELECT
    Employee_Name,
    Week,
    COUNT(*) AS Row_Count
FROM dbo.fake_employee_weekly_performance_clean
GROUP BY Employee_Name, Week
HAVING COUNT(*) > 1
ORDER BY Employee_Name, Week;
--==check if null any where in the clean table
SELECT
    *
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name IS NULL
   OR Week IS NULL;--NONE REPORTED
--==Count in the clean table the unique employee weeks should be 46
SELECT COUNT(*) AS Unique_Employee_Weeks
FROM
(
    SELECT
        Employee_Name,
        Week
    FROM dbo.fake_employee_weekly_performance_clean
    GROUP BY
        Employee_Name,
        Week
) AS x;--got 46
--check the origianl to see where the duplicates are
SELECT
    Employee_Name,
    Week,
    COUNT(*) AS Row_Count
FROM dbo.fake_employee_weekly_performance
GROUP BY
    Employee_Name,
    Week
HAVING COUNT(*) > 1
ORDER BY Employee_Name, Week;
--==recheck for missing combination
SELECT
    Employee_Name,
    COUNT(DISTINCT Week) AS Weeks_Present
FROM dbo.fake_employee_weekly_performance_clean
GROUP BY Employee_Name
HAVING COUNT(DISTINCT Week) < 4
ORDER BY Employee_Name;

SELECT
    Employee_Name,
    Week
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name IN ('Ava Martinez', 'Grace Thompson')
ORDER BY Employee_Name, Week;
--check for row count per week should be 48 total
SELECT
    '[' + Week + ']' AS Week_Check,
    COUNT(*) AS Row_Count
FROM dbo.fake_employee_weekly_performance_clean
GROUP BY Week
ORDER BY Week;
--check manager name
SELECT
    '[' + Manager_Name + ']' AS Manager_Name_Check,
    LEN(Manager_Name) AS Name_Length,
    DATALENGTH(Manager_Name) AS Data_Length,
    COUNT(*) AS Row_Count
FROM dbo.fake_employee_weekly_performance_clean
GROUP BY
    Manager_Name,
    LEN(Manager_Name),
    DATALENGTH(Manager_Name)
ORDER BY Manager_Name;
--check employee name
SELECT
    '[' + Employee_Name + ']' AS Employee_Name_Check,
    LEN(Employee_Name) AS Name_Length,
    DATALENGTH(Employee_Name) AS Data_Length,
    COUNT(*) AS Row_Count
FROM dbo.fake_employee_weekly_performance_clean
GROUP BY
    Employee_Name,
    LEN(Employee_Name),
    DATALENGTH(Employee_Name)
ORDER BY Employee_Name;
--fix nora trailing space
SELECT
    Employee_Name AS Original_Name,
    '[' + Employee_Name + ']' AS Name_Check,
    TRIM(Employee_Name) AS Cleaned_Name,
    Week
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name <> TRIM(Employee_Name);
--check the actual character name
SELECT
    Employee_Name,
    '[' + Employee_Name + ']' AS Name_Check,
    LEN(Employee_Name) AS Name_Length,
    DATALENGTH(Employee_Name) AS Data_Length,
    UNICODE(RIGHT(Employee_Name, 1)) AS Last_Character_Code
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name LIKE 'Nora%';
--clean up nora space in name
UPDATE dbo.fake_employee_weekly_performance_clean
SET Employee_Name = TRIM(Employee_Name)
WHERE Employee_Name LIKE 'Nora%';
--verify nora name
SELECT
    '[' + Employee_Name + ']' AS Employee_Name_Check,
    LEN(Employee_Name) AS Name_Length,
    DATALENGTH(Employee_Name) AS Data_Length,
    COUNT(*) AS Row_Count
FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name LIKE 'Nora%'
GROUP BY
    Employee_Name,
    LEN(Employee_Name),
    DATALENGTH(Employee_Name)
ORDER BY Employee_Name;
--checking on olivia
SELECT
    Employee_Name,
    Week,
    COUNT(*) AS Row_Count
FROM dbo.fake_employee_weekly_performance_clean
GROUP BY Employee_Name, Week
HAVING COUNT(*) > 1
ORDER BY Employee_Name, Week;
--inspect the duplicate group, nora and oliva
SELECT
    Employee_Name,
    Week,
    Manager_Name,
    Composite_Assessments_Daily,
    Validated_Claims_Daily,
    Extended_Day_Supply,
    CMR_Assessment_Count,
    COA_Functional_Assessment_Count,
    Total_Care_Questions_Completed,
    Projected_Time,
    On_Que,
    Calls_Day,
    AHD_Warm_Transfer_Count,
    HIP_Referral_Count
FROM dbo.fake_employee_weekly_performance_clean
WHERE (Employee_Name = 'Nora Anderson' AND Week = 'Week 4')
   OR (Employee_Name = 'Olivia Chen' AND Week = 'Week 1')
ORDER BY Employee_Name, Week;
--check if there is an employee or another column haven't considered
SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'fake_employee_weekly_performance_clean'
ORDER BY ORDINAL_POSITION;
--CREATE A BACK UP OF CURRENT CLEAN TABLE
SELECT *
INTO dbo.fake_employee_weekly_performance_clean_before_dedup
FROM dbo.fake_employee_weekly_performance_clean;
--verfiy back up
SELECT COUNT(*) AS Backup_Rows
FROM dbo.fake_employee_weekly_performance_clean_before_dedup;
--deleting 2 selected duplicate records for olivia and nora
DELETE FROM dbo.fake_employee_weekly_performance_clean
WHERE
    Employee_Name = 'Nora Anderson'
    AND Week = 'Week 4'
    AND Composite_Assessments_Daily = 27
    AND Validated_Claims_Daily = 28
    AND Extended_Day_Supply = 89.9
    AND CMR_Assessment_Count = 12
    AND COA_Functional_Assessment_Count = 9
    AND Total_Care_Questions_Completed = 40
    AND Projected_Time = 0.85
    AND On_Que = 94.8
    AND Calls_Day = 54
    AND AHD_Warm_Transfer_Count = 5
    AND HIP_Referral_Count = 5;

DELETE FROM dbo.fake_employee_weekly_performance_clean
WHERE
    Employee_Name = 'Olivia Chen'
    AND Week = 'Week 1'
    AND Composite_Assessments_Daily = 20
    AND Validated_Claims_Daily = 19
    AND Extended_Day_Supply = 95.4
    AND CMR_Assessment_Count = 9
    AND COA_Functional_Assessment_Count = 8
    AND Total_Care_Questions_Completed = 64
    AND Projected_Time = 0.71
    AND On_Que = 88.2
    AND Calls_Day = 58
    AND AHD_Warm_Transfer_Count = 5
    AND HIP_Referral_Count = 7;
--valid and check the table
SELECT
    COUNT(*) AS Total_Rows
FROM dbo.fake_employee_weekly_performance_clean;

SELECT
    COUNT(*) AS Unique_Employee_Weeks
FROM
(
    SELECT
        Employee_Name,
        Week
    FROM dbo.fake_employee_weekly_performance_clean
    GROUP BY Employee_Name, Week
) AS x;
--check the rows to see why it was not removed
SELECT
    Employee_Name,
    Week,
    Composite_Assessments_Daily,
    Validated_Claims_Daily,
    Extended_Day_Supply,
    CMR_Assessment_Count,
    COA_Functional_Assessment_Count,
    Total_Care_Questions_Completed,
    Projected_Time,
    On_Que,
    Calls_Day,
    AHD_Warm_Transfer_Count,
    HIP_Referral_Count
FROM dbo.fake_employee_weekly_performance_clean
WHERE (Employee_Name = 'Nora Anderson' AND Week = 'Week 4')
   OR (Employee_Name = 'Olivia Chen' AND Week = 'Week 1')
ORDER BY Employee_Name;
--redo delete with proper hip referral count for olivia and nora
DELETE FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name = 'Nora Anderson'
  AND Week = 'Week 4'
  AND Composite_Assessments_Daily = 27
  AND Validated_Claims_Daily = 28
  AND Extended_Day_Supply = 89.9
  AND CMR_Assessment_Count = 12
  AND COA_Functional_Assessment_Count = 9
  AND Total_Care_Questions_Completed = 40
  AND Projected_Time = 0.85
  AND On_Que = 94.8
  AND Calls_Day = 54
  AND AHD_Warm_Transfer_Count = 5
  AND HIP_Referral_Count = 4;

DELETE FROM dbo.fake_employee_weekly_performance_clean
WHERE Employee_Name = 'Olivia Chen'
  AND Week = 'Week 1'
  AND Composite_Assessments_Daily = 20
  AND Validated_Claims_Daily = 19
  AND Extended_Day_Supply = 95.4
  AND CMR_Assessment_Count = 9
  AND COA_Functional_Assessment_Count = 8
  AND Total_Care_Questions_Completed = 64
  AND Projected_Time = 0.71
  AND On_Que = 88.2
  AND Calls_Day = 58
  AND HIP_Referral_Count = 4;
  --recheck the row count
  SELECT COUNT(*) AS Total_Rows
FROM dbo.fake_employee_weekly_performance_clean;
--final grain check before tableau
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT Employee_Name) AS Unique_Employees,
    COUNT(DISTINCT Manager_Name) AS Unique_Managers,
    COUNT(DISTINCT Week) AS Unique_Weeks
FROM dbo.fake_employee_weekly_performance_clean;

SELECT
    COUNT(*) AS Unique_Employee_Weeks
FROM
(
    SELECT
        Employee_Name,
        Week
    FROM dbo.fake_employee_weekly_performance_clean
    GROUP BY Employee_Name, Week
) AS x;
--final NULL check before tableau
SELECT
    COUNT(*) AS Total_Rows,
    SUM(CASE WHEN Composite_Assessments_Daily IS NULL THEN 1 ELSE 0 END) AS Missing_Composite,
    SUM(CASE WHEN Validated_Claims_Daily IS NULL THEN 1 ELSE 0 END) AS Missing_Claims,
    SUM(CASE WHEN Extended_Day_Supply IS NULL THEN 1 ELSE 0 END) AS Missing_EDS,
    SUM(CASE WHEN CMR_Assessment_Count IS NULL THEN 1 ELSE 0 END) AS Missing_CMR,
    SUM(CASE WHEN COA_Functional_Assessment_Count IS NULL THEN 1 ELSE 0 END) AS Missing_COA,
    SUM(CASE WHEN Total_Care_Questions_Completed IS NULL THEN 1 ELSE 0 END) AS Missing_Care,
    SUM(CASE WHEN Projected_Time IS NULL THEN 1 ELSE 0 END) AS Missing_Projected_Time,
    SUM(CASE WHEN On_Que IS NULL THEN 1 ELSE 0 END) AS Missing_On_Que,
    SUM(CASE WHEN Calls_Day IS NULL THEN 1 ELSE 0 END) AS Missing_Calls,
    SUM(CASE WHEN AHD_Warm_Transfer_Count IS NULL THEN 1 ELSE 0 END) AS Missing_AHD,
    SUM(CASE WHEN HIP_Referral_Count IS NULL THEN 1 ELSE 0 END) AS Missing_HIP
FROM dbo.fake_employee_weekly_performance_clean;--CLEANED AND READY FOR TABLEAU
--
