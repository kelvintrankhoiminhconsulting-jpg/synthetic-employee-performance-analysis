--STEP 1: data profiling stage
SELECT TOP 10 *
FROM dbo.fake_employee_weekly_performance;
--investigate the grain, see employees with how many rows each
SELECT
    Employee_Name,
    COUNT(*) AS row_count
FROM dbo.fake_employee_weekly_performance
GROUP BY Employee_Name
ORDER BY row_count DESC;
--========count total rows
SELECT COUNT(*) AS total_rows
FROM dbo.fake_employee_weekly_performance;
--===check for duplicate rows with employee/week combination
SELECT
    Employee_Name,
    Week,
    COUNT(*) AS row_count
FROM dbo.fake_employee_weekly_performance
GROUP BY
    Employee_Name,
    Week
HAVING COUNT(*) > 1;
--check employees to see number or rows per employees should be 4 rows per employee
SELECT
    Employee_Name,
    COUNT(*) AS row_count
FROM dbo.fake_employee_weekly_performance
GROUP BY Employee_Name
ORDER BY Employee_Name;
--STEP 2: check structure and data types
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'fake_employee_weekly_performance'
ORDER BY ORDINAL_POSITION;
--=checking for NULLS--project time has 47 not null
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Employee_Name) AS Employee_Name_Not_Null,
    COUNT(Manager_Name) AS Manager_Name_Not_Null,
    COUNT(Projected_Time) AS Projected_Time_Not_Null,
    COUNT(On_Que) AS On_Que_Percent_Not_Null
FROM dbo.fake_employee_weekly_performance;
--STEP 3: finding the null in project time
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Projected_Time) AS Non_NULL_Project_Time,
    COUNT(*) - COUNT(Projected_Time) AS Missing_Project_Time
FROM dbo.fake_employee_weekly_performance;
--=check categorical values
SELECT
    Manager_Name,
    COUNT(*) AS row_count
FROM dbo.fake_employee_weekly_performance
GROUP BY Manager_Name
ORDER BY Manager_Name;
--check week and row count per week, should be 48 rows
SELECT
    Week,
    COUNT(*) AS row_count
FROM dbo.fake_employee_weekly_performance
GROUP BY Week
ORDER BY Week;
--==check numerical ranges
SELECT
    MIN(Extended_Day_Supply) AS Min_Value,
    MAX(Extended_Day_Supply) AS Max_Value,
    AVG(Extended_Day_Supply) AS Avg_Value
FROM dbo.fake_employee_weekly_performance;
--==check if over 100 %
SELECT *
FROM dbo.fake_employee_weekly_performance
WHERE Extended_Day_Supply < 0
   OR Extended_Day_Supply> 100;
--profile NULLS across the table
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Week) AS Week_Not_NULL,
    COUNT(Manager_Name) AS Manager_Not_NULL,
    COUNT(Employee_Name) AS Employee_Not_NULL,
    COUNT(Composite_Assessments_Daily) AS Composite_Not_NULL,
    COUNT(Validated_Claims_Daily) AS Claims_Not_NULL,
    COUNT(Extended_Day_Supply) AS Day_Supply_Not_NULL,
    COUNT(CMR_Assessment_Count) AS CMR_Not_NULL,
    COUNT(COA_Functional_Assessment_Count) AS COA_Not_NULL,
    COUNT(Total_Care_Questions_Completed) AS Care_Questions_Not_NULL,
    COUNT(Projected_Time) AS Projected_Time_Not_NULL,
    COUNT(On_Que) AS On_Que_Not_NULL,
    COUNT(Calls_Day) AS Calls_Not_NULL,
    COUNT(AHD_Warm_Transfer_Count) AS AHD_Transfer_Not_NULL,
    COUNT(HIP_Referral_Count) AS HIP_Referral_Not_NULL
FROM dbo.fake_employee_weekly_performance;
--=check which manage and which week has missing value
SELECT
    Week,
    Manager_Name,
    Employee_Name,
    Projected_Time
FROM dbo.fake_employee_weekly_performance
WHERE Projected_Time IS NULL;
--STEP 4: checking categorical values, look for inconsistent values n columns like week, employee_name, manager_name, etc..
--check manager name
SELECT
    Manager_Name,
    COUNT(*) AS row_count
FROM dbo.fake_employee_weekly_performance
GROUP BY Manager_Name
ORDER BY Manager_Name;
--the following check manager and how many or if any is missing
SELECT COUNT(DISTINCT Manager_Name) AS Unique_Managers
FROM dbo.fake_employee_weekly_performance;

SELECT *
FROM dbo.fake_employee_weekly_performance
WHERE Manager_Name IS NULL;
--check week to make sure each has 12 row count
SELECT
    Week,
    COUNT(*) AS row_count
FROM dbo.fake_employee_weekly_performance
GROUP BY Week
ORDER BY Week;

--check employees, should be 12 with 4 rows
SELECT
    Employee_Name,
    COUNT(*) AS row_count
FROM dbo.fake_employee_weekly_performance
GROUP BY Employee_Name
ORDER BY Employee_Name;
--confirm 12 unique employees with 4 rows per employee, no spelling spacing differences
--but has 13 employees and row count is different for employees
SELECT
    Employee_Name,
    COUNT(*) AS row_count
FROM dbo.fake_employee_weekly_performance
GROUP BY Employee_Name
ORDER BY Employee_Name;
--find the extra employee
SELECT
    Employee_Name,
    COUNT(*) AS row_count
FROM dbo.fake_employee_weekly_performance
GROUP BY Employee_Name
ORDER BY Employee_Name;
--find the spaces using brackets
SELECT
    '[' + Employee_Name + ']' AS Employee_Name_Check,
    COUNT(*) AS row_count
FROM dbo.fake_employee_weekly_performance
GROUP BY Employee_Name
ORDER BY Employee_Name;
--check length of employee names
--olivia chen has different lengths and entered as 2x
SELECT
    Employee_Name,
    LEN(Employee_Name) AS Name_Length,
    COUNT(*) AS row_count
FROM dbo.fake_employee_weekly_performance
GROUP BY Employee_Name
ORDER BY Employee_Name;
--run this code to check for name length, data length and row count for affected employees name
SELECT
    Employee_Name,
    LEN(Employee_Name) AS Name_Length,
    DATALENGTH(Employee_Name) AS Data_Length,
    COUNT(*) AS Row_Count
FROM dbo.fake_employee_weekly_performance
WHERE Employee_Name LIKE 'Olivia%'
GROUP BY
    Employee_Name,
    LEN(Employee_Name),
    DATALENGTH(Employee_Name);
--check number of row inconsistency for nora, ava and grace, with 5, 3 and 3
--issue: some have missing a week or extra week or duplicate week
SELECT
    Employee_Name,
    Week
FROM dbo.fake_employee_weekly_performance
WHERE Employee_Name IN (
    'Ava Martinez',
    'Grace Thompson',
    'Nora Anderson'
)
ORDER BY
    Employee_Name,
    Week;
    --=check whether any other employee/week combos are duplicated
    SELECT
    Employee_Name,
    Week,
    COUNT(*) AS row_count
FROM dbo.fake_employee_weekly_performance
GROUP BY
    Employee_Name,
    Week
HAVING COUNT(*) > 1;
SELECT
    Employee_Name,
    Week,
    COUNT(*) AS row_count
FROM dbo.fake_employee_weekly_performance
GROUP BY
    Employee_Name,
    Week
HAVING COUNT(*) > 1;
/* issues so far, 1 NULL Project_time, employee_name has 13 distinct values instead of expected
12, Ava Martinez missing week 4, Grace Thompson missing week 1, Nora Anderson has duplicated week 4,
Olivia Chen has inconsistent name formatting like extra space in name
*/
--count the combiation after accounting for duplicates
SELECT COUNT(*) AS Unique_Employee_Week_Combinations
FROM (
    SELECT DISTINCT
        Employee_Name,
        Week
    FROM dbo.fake_employee_weekly_performance
) AS x; --it only has 47 instead of 48*
/*run count distinct week to find out the issue, everyone else has 4 weeks but others have 3 weeks or 1 week, all 
should be 4 weeks and nora anderson has 4 weeks but 5 rows*/
SELECT
    Employee_Name,
    COUNT(DISTINCT Week) AS Unique_Weeks
FROM dbo.fake_employee_weekly_performance
GROUP BY Employee_Name
ORDER BY Unique_Weeks, Employee_Name;
--check profiling numeric columns
--check project time to make sure it is between 0 and 1 and it has 1 NULL value
SELECT
    MIN(Projected_Time) AS Min_Project_Time,
    MAX(Projected_Time) AS Max_Project_Time,
    ROUND(AVG(Projected_Time),2) AS Avg_Project_Time
FROM dbo.fake_employee_weekly_performance;
--check On_Que to be sure between 0 and 100%
--THERE IS A MAX OF 105%
--finding, On_Que: Values range from 82.7 to 105. One value exceeds the valid percentage range of 0–100 and requires investigation.
SELECT
    MIN(On_Que) AS Min_On_Que,
    MAX(On_Que) AS Max_On_Que,
    ROUND(AVG(On_Que),2) AS Avg_On_Que
FROM dbo.fake_employee_weekly_performance;
--check for any value outside of 0 to 100
SELECT *
FROM dbo.fake_employee_weekly_performance
WHERE On_Que < 0
   OR On_Que > 100;
--run this query to find the employee with on que of 105%
SELECT
    Week,
    Manager_Name,
    Employee_Name,
    On_Que
FROM dbo.fake_employee_weekly_performance
WHERE On_Que < 0
   OR On_Que > 100;
--check Extended_Day_Supply for min, max and avg
SELECT
    MIN(Extended_Day_Supply) AS Min_Extended_Day_Supply,
    MAX(Extended_Day_Supply) AS Max_Extended_Day_Supply,
    ROUND(AVG(Extended_Day_Supply),2) AS Avg_Extended_Day_Supply
FROM dbo.fake_employee_weekly_performance;
--check to see anyone outside of 0 to 100
SELECT *
FROM dbo.fake_employee_weekly_performance
WHERE Extended_Day_Supply < 0
   OR Extended_Day_Supply > 100;
  --check extended day supply for NULLS
  --has 1 NULL
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Extended_Day_Supply) AS Not_NULL,
    COUNT(*) - COUNT(Extended_Day_Supply) AS Missing
FROM dbo.fake_employee_weekly_performance;
--find employee with extended day supply with NULL in week 3
SELECT
    Week,
    Manager_Name,
    Employee_Name,
    Extended_Day_Supply
FROM dbo.fake_employee_weekly_performance
WHERE Extended_Day_Supply IS NULL;
--CMR_Assessment_Count
SELECT
    MIN(CMR_Assessment_Count) AS Min_CMR,
    MAX(CMR_Assessment_Count) AS Max_CMR,
    AVG(CMR_Assessment_Count) AS Avg_CMR
FROM dbo.fake_employee_weekly_performance;
--check for negative counts
SELECT *
FROM dbo.fake_employee_weekly_performance
WHERE CMR_Assessment_Count < 0;
--check for NULLS
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(CMR_Assessment_Count) AS Not_NULL,
    COUNT(*) - COUNT(CMR_Assessment_Count) AS Missing
FROM dbo.fake_employee_weekly_performance;
--look for Max, Min, Avg for CMR Assessment count
SELECT
    MIN(CMR_Assessment_Count) AS Min_CMR_Assessment_Count,
    MAX(CMR_Assessment_Count) AS MaxCMR_Assessment_Count,
    ROUND(AVG(CMR_Assessment_Count),2) AS Avg_CMR_Assessment_Count
FROM dbo.fake_employee_weekly_performance; --NO ISSUES FOUND WITH CMR ASSESSMENT, NO NULLS
--check COA_Functional_Assessment_Count
SELECT
    MIN(COA_Functional_Assessment_Count) AS Min_COA,
    MAX(COA_Functional_Assessment_Count) AS Max_COA,
    AVG(COA_Functional_Assessment_Count) AS Avg_COA
FROM dbo.fake_employee_weekly_performance;
--check negative values and NULLS
SELECT *
FROM dbo.fake_employee_weekly_performance
WHERE COA_Functional_Assessment_Count < 0;

SELECT
    COUNT(*) AS Total_Rows,
    COUNT(COA_Functional_Assessment_Count) AS Not_NULL,
    COUNT(*) - COUNT(COA_Functional_Assessment_Count) AS Missing
FROM dbo.fake_employee_weekly_performance;--NO ISSUES FOUND WITH COA AND NO NULLS
--Next check Total_Care_Questions_Completed column
SELECT
    MIN(Total_Care_Questions_Completed) AS Min_Care_Questions,
    MAX(Total_Care_Questions_Completed) AS Max_Care_Questions,
    AVG(Total_Care_Questions_Completed) AS Avg_Care_Questions
FROM dbo.fake_employee_weekly_performance;
--check for negative values for total care question completed
SELECT *
FROM dbo.fake_employee_weekly_performance
WHERE Total_Care_Questions_Completed < 0;
--check for NULLS for total care question
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Total_Care_Questions_Completed) AS Not_NULL,
    COUNT(*) - COUNT(Total_Care_Questions_Completed) AS Missing
FROM dbo.fake_employee_weekly_performance;--NO ISSUES REPORTED, NO NULLS
--check Validated claim daily column
--check the range and average
SELECT
    MIN(Validated_Claims_Daily) AS Min_Validated_Claims,
    MAX(Validated_Claims_Daily) AS Max_Validated_Claims,
    AVG(Validated_Claims_Daily) AS Avg_Validated_Claims
FROM dbo.fake_employee_weekly_performance;
--check for negative values
SELECT *
FROM dbo.fake_employee_weekly_performance
WHERE Validated_Claims_Daily < 0;
--check for nulls
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Validated_Claims_Daily) AS Not_NULL,
    COUNT(*) - COUNT(Validated_Claims_Daily) AS Missing
FROM dbo.fake_employee_weekly_performance;--NO ISSUES FOUND
--check composite assessment daily column
--check range and avg
SELECT
    MIN(Composite_Assessments_Daily) AS Min_Composite,
    MAX(Composite_Assessments_Daily) AS Max_Composite,
    AVG(Composite_Assessments_Daily) AS Avg_Composite
FROM dbo.fake_employee_weekly_performance;
--check neg values
SELECT *
FROM dbo.fake_employee_weekly_performance
WHERE Composite_Assessments_Daily < 0;
--check NULLS
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Composite_Assessments_Daily) AS Not_NULL,
    COUNT(*) - COUNT(Composite_Assessments_Daily) AS Missing
FROM dbo.fake_employee_weekly_performance;--NO ISSUES FOUND
--check calls_day column
--check max, min, avg
SELECT
    MIN(Calls_Day) AS Min_Calls_Day,
    MAX(Calls_Day) AS Max_Calls_Day,
    AVG(Calls_Day) AS Avg_Calls_Day
FROM dbo.fake_employee_weekly_performance;
--check neg values
SELECT *
FROM dbo.fake_employee_weekly_performance
WHERE Calls_Day < 0;
--check nulls
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Calls_Day) AS Not_NULL,
    COUNT(*) - COUNT(Calls_Day) AS Missing
FROM dbo.fake_employee_weekly_performance;--NO ISSUES FOUND
--=check ahd warm transfer count
--check min max, avg
SELECT
    MIN(AHD_Warm_Transfer_Count) AS Min_AHD,
    MAX(AHD_Warm_Transfer_Count) AS Max_AHD,
    AVG(AHD_Warm_Transfer_Count) AS Avg_AHD
FROM dbo.fake_employee_weekly_performance;
--check for neg values
SELECT *
FROM dbo.fake_employee_weekly_performance
WHERE AHD_Warm_Transfer_Count < 0;
--check for NULLs
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(AHD_Warm_Transfer_Count) AS Not_NULL,
    COUNT(*) - COUNT(AHD_Warm_Transfer_Count) AS Missing
FROM dbo.fake_employee_weekly_performance;

--=check hip referral count
--check min max, avg
SELECT
    MIN(HIP_Referral_Count) AS Min_HIP,
    MAX(HIP_Referral_Count) AS Max_HIP,
    AVG(HIP_Referral_Count) AS Avg_HIP
FROM dbo.fake_employee_weekly_performance;
--check for neg values
SELECT *
FROM dbo.fake_employee_weekly_performance
WHERE HIP_Referral_Count < 0;
--check for NULLs
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(HIP_Referral_Count) AS Not_NULL,
    COUNT(*) - COUNT(HIP_Referral_Count) AS Missing
FROM dbo.fake_employee_weekly_performance;--has a data type error for hip referral count as nvarcha
--==check for data type in hip referral coun
SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'fake_employee_weekly_performance'
  AND COLUMN_NAME = 'HIP_Referral_Count';
  --==fix varchar to conver to int and decimal
SELECT
    MIN(CAST(HIP_Referral_Count AS INT)) AS Min_HIP,
    MAX(CAST(HIP_Referral_Count AS INT)) AS Max_HIP,
    AVG(CAST(HIP_Referral_Count AS DECIMAL(10,2))) AS Avg_HIP
FROM dbo.fake_employee_weekly_performance;
--==check neg value convert from varchar
SELECT *
FROM dbo.fake_employee_weekly_performance
WHERE TRY_CAST(HIP_Referral_Count AS INT) < 0;
--==check nulls
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(HIP_Referral_Count) AS Not_NULL,
    COUNT(*) - COUNT(HIP_Referral_Count) AS Missing
FROM dbo.fake_employee_weekly_performance;



















