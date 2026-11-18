# Healthcare Operations Analysis Using SQL Server

An end-to-end SQL Server analysis of hospital admission and discharge data from the **Hero DMC Heart Institute** (Dayanand Medical College and Hospital, Ludhiana, Punjab, India). The project cleans the raw admissions data, builds a validated view, and answers 15 business questions on discharges, length of stay, patient demographics, ICU use, mortality and admission patterns.

---

## Table of Contents

- [Project Objectives](#project-objectives)
- [Dataset](#dataset)
- [Tools and Skills](#tools-and-skills)
- [Data Cleaning and Validation](#data-cleaning-and-validation)
- [Business Questions and Key Findings](#business-questions-and-key-findings)
- [Sample Queries](#sample-queries)
- [Insights and Recommendations](#insights-and-recommendations)
- [Limitations](#limitations)
- [How to Run](#how-to-run)
- [Repository Structure](#repository-structure)
- [Author](#author)

---

## Project Objectives

1. Clean and prepare the admissions dataset: identify duplicates, handle missing values and ensure data consistency.
2. Calculate key healthcare KPIs: total discharges, average length of stay (ALOS) and discharge rate.
3. Examine discharge distributions across age groups and genders.
4. Analyse discharge patterns by day of the week.
5. Investigate patient outcomes (discharge, death, DAMA) to support operational planning.
6. Translate SQL results into meaningful insights.

## Dataset

- **Source:** [Hospital Admissions Data, Kaggle (HDHI Admission Data)](https://www.kaggle.com/)
- **Period:** 1 April 2017 to 31 March 2019
- **Setting:** Cardiology unit of a tertiary care medical college and hospital
- **Size:** 15,757 raw rows and 56 columns; the study reports 14,845 admissions for 12,238 patients (1,921 patients had multiple admissions)
- **After cleaning:** 14,540 admission records in `vw_AdmissionData`

**Feature groups**

| Group | Examples |
|---|---|
| Identification and demographics | `MRD No`, `AGE`, `GENDER`, `RURAL` (R/U) |
| Admission and stay | `D.O.A`, `D.O.D`, `TYPE OF ADMISSION-EMERGENCY/OPD`, `DURATION OF STAY`, `duration of intensive unit stay`, `OUTCOME` |
| Lifestyle and history | `SMOKING`, `ALCOHOL`, `DM`, `HTN`, `CAD`, `PRIOR CMP`, `CKD` |
| Lab parameters | `HB`, `TLC`, `PLATELETS`, `GLUCOSE`, `UREA`, `CREATININE`, `BNP`, `EF` |
| Cardiac conditions and complications | `ACS`, `STEMI`, `HEART FAILURE`, `HFREF`, `HFNEF`, `AKI`, `AF`, `VT`, `CARDIOGENIC SHOCK`, `PULMONARY EMBOLISM`, and others |

Outcomes recorded: `DISCHARGE`, `EXPIRY` (death in hospital) and `DAMA` (discharged against medical advice).

## Tools and Skills

- **Microsoft SQL Server** and SQL Server Management Studio (SSMS)
- **T-SQL techniques:** CTEs, window functions (`ROW_NUMBER()`, `SUM() OVER()`), `CASE WHEN`, `CROSS APPLY` with `VALUES` (unpivoting), `FULL OUTER JOIN`, `CAST`/`CONVERT`/`TRY_CONVERT`, `FORMAT`, `DATEFROMPARTS`, `NULLIF`, `COALESCE`/`ISNULL`

## Data Cleaning and Validation

| Cleaning operation | SQL technique | Purpose |
|---|---|---|
| Duplicate identification | `ROW_NUMBER()` | Flag repeated admission records |
| Duplicate removal | CTE and filtering | Keep one record per admission combination |
| Missing value identification | `IS NULL` | Find incomplete records |
| Data type conversion | `CAST()`, `CONVERT()` | Make sure columns have appropriate types |
| Data formatting | `CONVERT()`, `FORMAT()` | Prepare admission and discharge dates |
| Age categorisation | `CASE WHEN` | Group patients into age bands |
| Data validation | `COUNT()`, `DISTINCT` | Check record counts and uniqueness |

**Cleaning decisions**

- **Duplicates:** `ROW_NUMBER()` with `PARTITION BY` on *MRD number + date of admission + date of discharge*. A CTE keeps the first occurrence of each combination.
- **Missing values:** records with a missing MRD number were excluded from the cleaned view, since the MRD number is part of the admission identifier.

The cleaned output is exposed as the view `dbo.vw_AdmissionData`, which all queries below use.

**Age groups used**

| Group | Age range |
|---|---|
| Paediatric | 0 to 17 |
| Adult | 18 to 59 |
| Senior | 60+ |

## Business Questions and Key Findings

| # | Question | Result |
|---|---|---|
| 1 | Total discharges | **12,608** |
| 2 | Discharge-to-length-of-stay ratio (see [Limitations](#limitations)) | 12,608 discharges over 82,576 total stay days = **15.27%** |
| 3 | Average length of stay (discharged patients) | **6.55 days** (about 7 days) |
| 4 | Discharges by age group | Senior 7,439 (59.00%), Adult 5,122 (40.63%), Paediatric 47 (0.37%) |
| 5 | Discharges by gender | Male 7,977 (63.27%), Female 4,631 (36.73%) |
| 6 | Busiest discharge days | Wed (1,947), Fri (1,891), Thu (1,880); Sunday is lowest (1,486) |
| 7 | Mortality rate | 1,100 deaths in 14,540 records = **7.57%** |
| 8 | Admissions with an ICU stay | 11,983 of 14,540 = **82.41%** |
| 9 | Average ICU length of stay | **4.59 days** (about 5) across 54,999 ICU days |
| 10 | ALOS by age group | Senior 6.99, Adult 5.92, Paediatric 5.72 days |
| 11 | Monthly admission and discharge trend | Peak in **November 2017**: 713 admissions and 619 discharges |
| 12 | Emergency vs OPD admissions | Emergency 10,106 (69.50%), OPD 4,434 (30.50%) |
| 13 | Most frequent conditions | CAD (9,675), Hypertension (7,043), ACS (5,314), Diabetes (4,820), Heart Failure (4,202) |
| 14 | Outcome by age group | Death rate: Senior 8.93%, Paediatric 5.77%, Adult 5.50% |
| 15 | Outcome distribution | Discharge 12,608, Expiry 1,100, DAMA 832 |

## Sample Queries

**Average length of stay (Q3)**

```sql
SELECT
    COUNT(*) AS Total_Discharges,
    SUM(DURATION_OF_STAY) AS Total_Length_of_Stay,
    CAST(AVG(CAST(DURATION_OF_STAY AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS Avg_Length_of_Stay
FROM [dbo].[vw_AdmissionData]
WHERE OUTCOME = 'DISCHARGE';
```

**Discharge distribution by age group (Q4)**

```sql
SELECT
    CASE
        WHEN AGE BETWEEN 0 AND 17 THEN 'Paediatric (0-17)'
        WHEN AGE BETWEEN 18 AND 59 THEN 'Adult (18-59)'
        WHEN AGE >= 60 THEN 'Senior (60+)'
    END AS Age_Group,
    COUNT(*) AS Total_Discharges,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(10,2)) AS Discharge_Percentage
FROM dbo.vw_AdmissionData
WHERE OUTCOME = 'DISCHARGE' AND AGE IS NOT NULL
GROUP BY
    CASE
        WHEN AGE BETWEEN 0 AND 17 THEN 'Paediatric (0-17)'
        WHEN AGE BETWEEN 18 AND 59 THEN 'Adult (18-59)'
        WHEN AGE >= 60 THEN 'Senior (60+)'
    END
ORDER BY Total_Discharges DESC;
```

**Unpivoting condition flags with `CROSS APPLY` (Q13)**

```sql
SELECT Condition_Name, COUNT(*) AS Number_Of_Records
FROM dbo.vw_AdmissionData
CROSS APPLY (VALUES
    ('CAD', [CAD]),
    ('Hypertension', [HTN]),
    ('Acute Coronary Syndrome', [ACS])
    -- ...remaining condition columns
) AS Conditions(Condition_Name, Condition_Value)
WHERE TRY_CONVERT(INT, Condition_Value) = 1
GROUP BY Condition_Name
ORDER BY Number_Of_Records DESC;
```

**Monthly admissions vs discharges (Q11)** uses two CTEs (`MonthlyAdmissions`, `MonthlyDischarges`) built with `DATEFROMPARTS(YEAR(), MONTH(), 1)` and combined with a `FULL OUTER JOIN` so months that appear on only one side are not lost.

## Insights and Recommendations

- **Older patients drive demand.** Seniors account for about 59% of discharges, stay the longest (6.99 days) and have the highest mortality (8.93%). Bed planning and nursing capacity should be weighted toward this group.
- **Emergency-led workload.** About 70% of admissions are emergencies, so capacity needs to absorb unscheduled demand.
- **Weekend dip in discharges.** Sunday has the fewest discharges (1,486) against a peak of 1,947 on Wednesday. Improving weekend discharge processes could free beds earlier in the week.
- **Heavy ICU use.** More than 8 in 10 admission records include an ICU stay, averaging about 4.6 days, which points to high critical-care demand in a cardiac unit.
- **Cardiovascular burden.** CAD, hypertension and ACS are the most frequently recorded conditions. Patients can have several conditions, so these counts overlap.
- **Seasonal peak.** November 2017 was the busiest month; staffing and bed capacity could be reviewed ahead of comparable periods.

## Limitations

- The "average daily discharge rate" in Q2 is computed as `discharges / total stay days x 100`, which is effectively the inverse of ALOS (1 / 6.55). It is a ratio, not a true daily discharge rate. A true rate would divide discharges by the number of calendar days in the period (about 730 days, roughly 17 discharges per day).
- The monthly trend (Q11) includes months outside the stated study window (Jan to Mar 2017 and Apr to Dec 2019), mostly with low counts. These likely reflect date-entry or parsing issues and should be reviewed.
- Condition counts are not mutually exclusive; one patient can appear under several conditions.
- Mortality and ICU figures are based on admission records, not unique patients (1,921 patients had multiple admissions).
- The paediatric group is very small (47 discharges), so percentages for that group are unstable.
- Findings are descriptive and do not establish causation. This is a single-hospital dataset and may not generalise.

## How to Run

1. Download the HDHI Admission Data CSV from Kaggle.
2. Import it into SQL Server (SSMS: *Tasks > Import Flat File*) as a raw table.
3. Run the cleaning script to create `dbo.vw_AdmissionData` (de-duplication with `ROW_NUMBER()` in a CTE, removal of records with a missing MRD number).
4. Run the business-question queries in order and compare outputs with the results above.

## Repository Structure

```
.
├── README.md
├── data/                      # raw dataset (or link to Kaggle)
├── sql/
│   ├── 01_data_cleaning.sql   # duplicate handling, view creation
│   └── 02_business_questions.sql
└── report/
    └── HEALTHCARE_OPERATIONS_ANALYSIS_Report.pdf
```

## Author

**Mosaku Habeeb Ayobami**
[LinkedIn](https://www.linkedin.com/in/habeebmosaku3108)
