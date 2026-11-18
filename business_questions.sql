SELECT *
FROM [dbo].[vw_AdmissionData];


-- 1. What is the total number of discharges?

SELECT COUNT(*) AS Total_Discharges
FROM [dbo].[vw_AdmissionData]
WHERE OUTCOME = 'DISCHARGE';

-- 2. What is the average daily discharge Rate.
-- The Average Daily Discharge Rate (ADDR) is the average number of patients discharged from a hospital per day over a specified period.
-- Average Daily Discharge Rate is the total discharges divided by the total length of stay.

SELECT
    COUNT(*) AS Total_Discharges,
    SUM(DURATION_OF_STAY) AS Total_Length_of_Stay,

    CAST(
    COUNT(*) * 100.0 / NULLIF(SUM(DURATION_OF_STAY), 0)
    AS DECIMAL(10,2)
) AS Discharge_Percentage
FROM [dbo].[vw_AdmissionData]
WHERE OUTCOME = 'DISCHARGE';

-- 3. What is the average length of stay (ALOS)?
-- it is the total length of stay divided by total discharge

SELECT
    COUNT(*) AS Total_Discharges,
    SUM(DURATION_OF_STAY) AS Total_Length_of_Stay,
    CAST(
        AVG(CAST(DURATION_OF_STAY AS DECIMAL(10,2)))
        AS DECIMAL(10,2)
    ) AS Avg_Length_of_Stay
FROM [dbo].[vw_AdmissionData]
WHERE OUTCOME = 'DISCHARGE';


-- 4. What is the discharge distribution by Age Group?

SELECT
    CASE
        WHEN AGE BETWEEN 0 AND 17 THEN 'Paediatric (0-17)'
        WHEN AGE BETWEEN 18 AND 59 THEN 'Adult (18-59)'
        WHEN AGE >= 60 THEN 'Senior (60+)'
    END AS Age_Group,
    COUNT(*) AS Total_Discharges,
    CAST(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER()
        AS DECIMAL(10,2)
    ) AS Discharge_Percentage
FROM dbo.vw_AdmissionData
WHERE OUTCOME = 'DISCHARGE'
  AND AGE IS NOT NULL
GROUP BY
    CASE
        WHEN AGE BETWEEN 0 AND 17 THEN 'Paediatric (0-17)'
        WHEN AGE BETWEEN 18 AND 59 THEN 'Adult (18-59)'
        WHEN AGE >= 60 THEN 'Senior (60+)'
    END
ORDER BY Total_Discharges DESC;

-- 5. What is the discharge distribution by Gender?

SELECT GENDER, COUNT(*) AS Gender_Distribution,
CAST(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER()
        AS DECIMAL(10,2)
    ) AS Discharge_Percentage
FROM [dbo].[vw_AdmissionData]
WHERE OUTCOME = 'DISCHARGE'
GROUP BY GENDER
ORDER BY COUNT(*) DESC


-- 6. Which days of the week record the highest discharge?

SELECT
    FORMAT(D_O_D, 'ddd') AS Day_of_Week,
    COUNT(*) AS Day_Distribution
FROM [dbo].[vw_AdmissionData]
WHERE OUTCOME = 'DISCHARGE'
    AND D_O_D IS NOT NULL
GROUP BY FORMAT(D_O_D, 'ddd')
ORDER BY COUNT(*) DESC;


-- 7. What is the mortality rate among admitted patients?

SELECT
    COUNT(*) AS Total_Admissions,
    SUM(
        CASE
            WHEN OUTCOME = 'EXPIRY' THEN 1
            ELSE 0
        END
    ) AS Total_Deaths,
    CAST(
        SUM(
            CASE
                WHEN OUTCOME = 'EXPIRY' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*)
        AS DECIMAL(10,2)
    ) AS Mortality_Rate_Percentage
FROM dbo.vw_AdmissionData;


-- 8. What percentage of patients required in ICU admission?

SELECT 
	COUNT(*) AS Total_Admissions,
	SUM(
		CASE
		WHEN duration_of_intensive_unit_stay > 0 THEN 1
		ELSE 0
	END
) AS ICU_Admissions,
CAST(
	SUM(
		CASE
			WHEN duration_of_intensive_unit_stay > 0 THEN 1
			ELSE 0
		END
		) * 100.0 / COUNT(*)
		AS DECIMAL(10,2)
		) AS ICU_Admission_Percentage
FROM [dbo].[vw_AdmissionData];



SELECT *
FROM [dbo].[vw_AdmissionData];


-- 9. What is the average ICU length of stay

SELECT
    COUNT(*) AS Total_ICU_Admissions,
    SUM(
        CAST(duration_of_intensive_unit_stay AS FLOAT)
    ) AS Total_ICU_Days,
    CAST(
        AVG(
            CAST(duration_of_intensive_unit_stay AS FLOAT)
        )
        AS DECIMAL(10,2)
    ) AS Average_ICU_Length_Of_Stay
FROM dbo.vw_AdmissionData
WHERE duration_of_intensive_unit_stay > 0;


-- 10. Which age group has the highest average length of stay?

SELECT
    CASE
        WHEN AGE BETWEEN 0 AND 17 THEN 'Paediatric (0-17)'
        WHEN AGE BETWEEN 18 AND 59 THEN 'Adult (18-59)'
        WHEN AGE >= 60 THEN 'Senior (60+)'
    END AS Age_Group,
    COUNT(*) AS Total_Discharges,
    CAST(
        AVG(CAST([DURATION_OF_STAY] AS FLOAT))
        AS DECIMAL(10,2)
    ) AS Average_Length_Of_Stay
FROM dbo.vw_AdmissionData
WHERE OUTCOME = 'DISCHARGE'
  AND AGE IS NOT NULL
  AND [DURATION_OF_STAY] IS NOT NULL
GROUP BY
    CASE
        WHEN AGE BETWEEN 0 AND 17 THEN 'Paediatric (0-17)'
        WHEN AGE BETWEEN 18 AND 59 THEN 'Adult (18-59)'
        WHEN AGE >= 60 THEN 'Senior (60+)'
    END
ORDER BY Average_Length_Of_Stay DESC;


-- 11. What is the monthly admission and discharge trend?

WITH MonthlyAdmissions AS
(
    SELECT
        DATEFROMPARTS(YEAR(D_O_A), MONTH(D_O_A), 1) AS Month_Year,
        COUNT(*) AS Total_Admissions
    FROM dbo.vw_AdmissionData
    WHERE D_O_A IS NOT NULL
    GROUP BY
        YEAR(D_O_A),
        MONTH(D_O_A)
),

MonthlyDischarges AS
(
    SELECT
        DATEFROMPARTS(YEAR(D_O_D), MONTH(D_O_D), 1) AS Month_Year,
        COUNT(*) AS Total_Discharges
    FROM dbo.vw_AdmissionData
    WHERE D_O_D IS NOT NULL
      AND OUTCOME = 'DISCHARGE'
    GROUP BY
        YEAR(D_O_D),
        MONTH(D_O_D)
)

SELECT
    COALESCE(A.Month_Year, D.Month_Year) AS Month_Year,
    ISNULL(A.Total_Admissions, 0) AS Total_Admissions,
    ISNULL(D.Total_Discharges, 0) AS Total_Discharges
FROM MonthlyAdmissions A
FULL OUTER JOIN MonthlyDischarges D
    ON A.Month_Year = D.Month_Year
ORDER BY Month_Year;


-- 12. What is the distribution of emergency and OPD admissions?

SELECT
    TYPE_OF_ADMISSION_EMERGENCY_OPD AS Admission_Type,
    COUNT(*) AS Total_Admissions,
    CAST(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER()
        AS DECIMAL(10,2)
    ) AS Admission_Percentage
FROM dbo.vw_AdmissionData
GROUP BY TYPE_OF_ADMISSION_EMERGENCY_OPD
ORDER BY Total_Admissions DESC;


-- 13. Which medical condtions are most frequently recorded?

SELECT
    Condition_Name,
    COUNT(*) AS Number_Of_Records
FROM dbo.vw_AdmissionData
CROSS APPLY
(
    VALUES
        ('CAD', [CAD]),
        ('Hypertension', [HTN]),
        ('Acute Coronary Syndrome', [ACS]),
        ('Diabetes Mellitus', [DM]),
        ('Heart Failure', [HEART_FAILURE]),
        ('Acute Kidney Injury', [AKI]),
        ('Raised Cardiac Enzymes', [RAISED_CARDIAC_ENZYMES]),
        ('Anaemia', [ANAEMIA]),
        ('Prior Cardiomyopathy', [PRIOR_CMP]),
        ('Heart Failure with Reduced EF', [HFREF]),
        ('STEMI', [STEMI]),
        ('Heart Failure with Normal EF', [HFNEF]),
        ('Chronic Kidney Disease', [CKD]),
        ('Stable Angina', [STABLE_ANGINA]),
        ('Urinary Tract Infection', [UTI]),
        ('Atrial Fibrillation', [AF]),
        ('Cardiogenic Shock', [CARDIOGENIC_SHOCK]),
        ('Smoking', [SMOKING]),
        ('Alcohol', [ALCOHOL]),
        ('Shock', [SHOCK]),
        ('Ventricular Tachycardia', [VT])
) AS Conditions(Condition_Name, Condition_Value)
WHERE TRY_CONVERT(INT, Condition_Value) = 1
GROUP BY Condition_Name
ORDER BY Number_Of_Records DESC;


-- 14. What is the relationship between patient age and hospital outcomes?

SELECT
    CASE
        WHEN AGE BETWEEN 0 AND 17 THEN 'Paediatric (0-17)'
        WHEN AGE BETWEEN 18 AND 59 THEN 'Adult (18-59)'
        WHEN AGE >= 60 THEN 'Senior (60+)'
    END AS Age_Group,

    OUTCOME,

    COUNT(*) AS Total_Patients,

    CAST(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER
        (
            PARTITION BY
                CASE
                    WHEN AGE BETWEEN 0 AND 17 THEN 'Paediatric (0-17)'
                    WHEN AGE BETWEEN 18 AND 59 THEN 'Adult (18-59)'
                    WHEN AGE >= 60 THEN 'Senior (60+)'
                END
        )
        AS DECIMAL(10,2)
    ) AS Outcome_Percentage

FROM dbo.vw_AdmissionData
WHERE AGE IS NOT NULL
GROUP BY
    CASE
        WHEN AGE BETWEEN 0 AND 17 THEN 'Paediatric (0-17)'
        WHEN AGE BETWEEN 18 AND 59 THEN 'Adult (18-59)'
        WHEN AGE >= 60 THEN 'Senior (60+)'
    END,
    OUTCOME
ORDER BY Age_Group, Total_Patients DESC;


-- 15. What is the distribution of patients by hospital outcome?

SELECT
    OUTCOME,
    COUNT(*) AS Total_Patients
FROM dbo.vw_AdmissionData
GROUP BY OUTCOME
ORDER BY Total_Patients DESC;