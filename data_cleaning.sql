-- Database to Use
USE HealthCareDB
GO;

-- Displaying all the table records

SELECT *
FROM [dbo].[HDHI Admission data]

-- Data cleaning
-- Identifying the duplicates in the data

SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY MRD_No, D_O_A, D_O_D 
		ORDER BY MRD_No) AS DUP_NO
FROM [dbo].[HDHI Admission data]
ORDER BY MRD_No;

-- Identifying the duplicates records

WITH DuplicateRecords AS
(
	SELECT *,
		ROW_NUMBER() OVER(
			PARTITION BY MRD_No, D_O_A, D_O_D 
			ORDER BY MRD_No) AS DUP_NO
FROM [dbo].[HDHI Admission data]
)
SELECT *
FROM DuplicateRecords
WHERE DUP_NO > 1
ORDER BY MRD_No;

-- Selecting the non-duplicate records

WITH DuplicateRecords AS
(
	SELECT *,
		ROW_NUMBER() OVER(
			PARTITION BY MRD_No, D_O_A, D_O_D 
			ORDER BY MRD_No) AS DUP_NO
FROM [dbo].[HDHI Admission data]
)
SELECT *
FROM DuplicateRecords
WHERE DUP_NO = 1 AND MRD_No IS NOT NULL
ORDER BY MRD_No;

SELECT *
FROM [dbo].[HDHI Admission data]
WHERE MRD_No IS NULL;

-- Storing the cleaned datasets

CREATE OR ALTER VIEW vw_AdmissionData AS
WITH DuplicateRecords AS
(
	SELECT *,
		ROW_NUMBER() OVER(
			PARTITION BY MRD_No, D_O_A, D_O_D 
			ORDER BY MRD_No) AS DUP_NO
FROM [dbo].[HDHI Admission data]
)
SELECT *
FROM DuplicateRecords
WHERE DUP_NO = 1 
AND MRD_No IS NOT NULL;

SELECT *
FROM [dbo].[vw_AdmissionData]

