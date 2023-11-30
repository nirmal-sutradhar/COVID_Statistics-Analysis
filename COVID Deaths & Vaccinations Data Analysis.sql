-- COVID DEATHS & VACCINATIONS DATA as of May 04, 2021
-- Data Exploration & Analysis

SELECT *
FROM [Portfolio Project]..Covid_Deaths
ORDER BY 3,4

SELECT *
FROM [Portfolio Project]..Covid_Vaccinations
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..Covid_Deaths
ORDER BY location, date

-- Comparing Total Cases vs Total Deaths
-- Shows likelihood of death on contraction of infection 

SELECT location, date, CAST(total_deaths AS int) AS total_deaths, total_cases, ROUND((ISNULL(CAST(total_deaths AS int), 0)/ISNULL(total_cases, 1))*100, 3) AS Percent_Infection_Deaths
FROM [Portfolio Project]..Covid_Deaths
ORDER BY 1,2

-- Comparing Total Cases vs Population
-- Shows percentage of population contracting infection

SELECT location, date, population, total_cases, CONVERT(decimal(18,8),(total_cases/population)*100) AS Percent_Population_Infected
FROM [Portfolio Project]..Covid_Deaths
ORDER BY 5 DESC

-- Shows countries with Highest Infection Rate respective to Population

SELECT location, MAX(population) AS Total_Population, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases/population)*100) AS Highest_Infection_Percentage
FROM [Portfolio Project]..Covid_Deaths
GROUP BY location
ORDER BY 4 DESC

-- Shows Countries with Total Death Counts respective to Population

SELECT location, MAX(population) AS Total_Population, MAX(CAST(total_deaths AS int)) AS Total_Death_Count
FROM [Portfolio Project]..Covid_Deaths
WHERE continent IS NOT NULL  -- 'Where' condition can also be applied to relevant queries above as well
GROUP BY location
ORDER BY 3 DESC

-- Shows Continents and World with Total Death Counts respective to population

SELECT location, MAX(population) AS Total_Population, MAX(CAST(total_deaths AS int)) AS Total_Death_Count
FROM [Portfolio Project]..Covid_Deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY 3 DESC

-- Shows New Cases, New Deaths and Global Death Percentage respective to each day

SELECT YEAR(date) AS Year, MONTH(date) AS Month, DAY(date) AS Day, SUM(new_cases) AS New_cases, SUM(CAST(new_deaths AS int)) AS New_deaths, ISNULL(ROUND((SUM(CAST(new_deaths AS int)) / SUM(new_cases))*100, 6), 0) AS Global_Death_Percentage
FROM [Portfolio Project]..Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2,3

-- Shows Total Global Cases, Total Global Deaths & Overall Death Percentage

SELECT SUM(new_cases) AS Total_Global_Cases, SUM(CAST(new_deaths AS int)) AS Total_Global_Deaths, ROUND((SUM(CAST(new_deaths AS int)) / SUM(new_cases))*100, 6) AS Overall_Death_Percentage
FROM [Portfolio Project]..Covid_Deaths
WHERE continent IS NOT NULL

-- Shows Rolling Count of Vaccinations Partitioned by Location

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_Count_Vaccinations
FROM [Portfolio Project]..Covid_Deaths AS dea
JOIN [Portfolio Project]..Covid_Vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Comparing Vaccinations to Total Population using a CTE vs a Temp Table
-- Shows Rolling Count Vaccinations Percentage using a CTE

WITH Rolling_Count_Vaccinations_CTE (continent, location, date, population, new_vaccinations, Rolling_Count_Vaccinations) 
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_Count_Vaccinations
FROM [Portfolio Project]..Covid_Deaths AS dea
JOIN [Portfolio Project]..Covid_Vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, ROUND((Rolling_Count_Vaccinations / population)*100, 4) AS Percent_Rolling_Count_Vaccinations
FROM Rolling_Count_Vaccinations_CTE

-- Shows Rolling Count Vaccinations Percentage using a Temp Table

DROP TABLE if exists Percent_Population_Vaccinated
CREATE TABLE Percent_Population_Vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime NOT NULL,
population numeric,
new_vaccinations numeric,
Rolling_Count_Vaccinations numeric
)

INSERT INTO Percent_Population_Vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_Count_Vaccinations
FROM [Portfolio Project]..Covid_Deaths AS dea
JOIN [Portfolio Project]..Covid_Vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, CAST(ROUND((Rolling_Count_Vaccinations / population)*100, 4) as float) AS Percent_Rolling_Count_Vaccinations
FROM Percent_Population_Vaccinated

-- Storing Rolling Vaccination Count as a View for future visualisation

CREATE VIEW Population_Vaccinated_Percentage AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_Count_Vaccinations
FROM [Portfolio Project]..Covid_Deaths AS dea
JOIN [Portfolio Project]..Covid_Vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM Population_Vaccinated_Percentage
