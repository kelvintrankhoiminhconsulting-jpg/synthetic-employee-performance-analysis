

# synthetic-employee-performance-analysis

Employee performance analysis using SQL and Tableau with a synthetic dataset

## Project Overview

This project analyzes employee productivity, availability, workload, and performance trends using a synthetic employee operations dataset.

The analysis was developed using SQL for data exploration and Tableau for interactive data visualization. The goal is to understand differences in employee and manager performance while avoiding conclusions based on a single metric.

> **Note:** The dataset used in this project is synthetic and was created for analytical and visualization practice. It does not represent real employees, customers, or company operations.
>
> ## Business Questions

This analysis explores the following questions:

- Which manager demonstrates the strongest overall observed performance?
- How do employees compare in validated-claim productivity and On-Queue availability?
- Are employee performance patterns consistent across multiple weeks?
- How does workload, measured by average Calls/Day, provide context for employee outcomes?
- What additional information would be needed to make more definitive performance assessments?

## Dataset & Metrics

This project uses a synthetic employee operations dataset designed for analytical practice.

### Key Dimensions

- Employee Name
- Manager Name
- Week

### Key Metrics

- **Validated Claims** — total claim outcomes
- **Validated Claims Daily** — daily validated-claim productivity
- **Composite Assessments** — total completed assessments
- **Care Questions** — total care-related questions
- **On-Queue %** — employee availability
- **Calls/Day** — average daily call volume used as a workload context measure

The analysis uses these metrics together rather than relying on a single measure of employee performance.

## Tools & Analysis Approach

### Tools

- **SQL Server** — data exploration and analysis
- **Tableau Public** — interactive dashboards and data visualization
- **GitHub** — project documentation and portfolio presentation

### Analysis Approach

The analysis followed these steps:

1. Explored the dataset structure and available fields.
2. Examined employee and manager-level outcomes.
3. Compared managers across Validated Claims, Composite Assessments, and Care Questions.
4. Compared employees using Validated Claims Daily and On-Queue %.
5. Added Calls/Day as workload context for employee comparisons.
6. Examined weekly validated-claim trends across the four-week period.
7. Identified performance patterns and considered limitations.

## Key Findings

### 1. Manager Performance

Alicia demonstrated the strongest overall observed performance across the three outcome measures. She had the highest number of Composite Assessments (461) and Care Questions (1,002), while remaining very close to Brian in Validated Claims (321 vs. 326). Brian had the highest Validated Claims total, but his advantage over Alicia was only five claims. Danielle recorded the lowest results across all three measures.

Each manager has four employees, so the teams are equal in size, making the comparison of totals reasonable within this dataset.

### 2. Employee Performance

The employee benchmark analysis shows that performance varies across availability and validated-claim productivity.

Ava and Grace were above the team average on both measures, representing the strongest balanced performance profile.

Jordan, Liam, Marcus, and Nora had above-average On-Queue availability but below-average validated-claim productivity.

Ethan, Sofia, and Olivia had above-average validated-claim productivity but below-average On-Queue availability.

Noah was below the team average on both measures.

These results demonstrate that employee performance varies by dimension and should not be evaluated using a single metric.

### 3. Workload Context

Average Calls/Day was included as an additional workload indicator. This provides context when comparing employees with different validated-claim results and helps avoid interpreting output without considering activity levels.

### 4. Weekly Trend

Validated-claim productivity fluctuated considerably across the four-week period. Employees experienced increases and decreases from week to week, with no clear overall upward or downward trend.

This suggests that performance can vary over short periods, making a multi-week view more useful than evaluating an employee based on a single week's results.

## Recommendations

- Evaluate employee and manager performance using multiple metrics rather than relying on a single KPI.
- Use On-Queue % and Calls/Day as context when interpreting validated-claim productivity.
- Investigate employees with different availability and productivity profiles before making performance-related decisions.
- In a real-world environment, incorporate call-level information such as call type, call disposition, and opportunity eligibility to better understand differences in outcomes.
- Monitor performance across multiple weeks rather than relying on a single week's results.

## Limitations

- This analysis is based on a synthetic dataset created for analytical and visualization practice and should not be interpreted as representing actual employee performance.
- The dataset does not contain call-level information such as call type, call disposition, or whether a call represented an opportunity to generate a validated claim.
- As a result, differences in validated-claim productivity cannot be attributed solely to employee effectiveness.
- The analysis identifies patterns and relationships in the available data but does not establish causation.
- The analysis covers only a four-week period, so longer-term performance patterns cannot be determined.

## Tableau Dashboard

The Tableau dashboard provides an interactive view of employee and manager performance, including key performance indicators, weekly trends, manager-level outcomes, and employee-level performance comparisons.

### Dashboard Preview

<img width="1917" height="1037" alt="employee_dashboard" src="https://github.com/user-attachments/assets/2b86fe4e-5909-41d3-ab58-7fbbac52599f" />

### Employee Availability vs. Validated Claim Productivity

The scatter plot compares average validated claims per day with average On-Queue availability. Employee color identifies each employee, while dot size represents average Calls/Day as a workload indicator.

<img width="1911" height="1040" alt="employee_performance_benchmark" src="https://github.com/user-attachments/assets/4edcb803-82c5-4afb-b074-67d5f07fc80d" />

### Weekly Validated Claims Trend

The weekly trend shows changes in validated-claim productivity across the four-week period for all employees.

<img width="1907" height="1040" alt="employee_weekly_validated_claims_trends" src="https://github.com/user-attachments/assets/e2735956-dfe1-4342-a246-7e1d4903037f" />

### Tableau Public

[View the interactive Employee Performance Dashboard](https://public.tableau.com/views/Employee_Performance_Dashboard/EmployeePerformanceDashboard)




  

