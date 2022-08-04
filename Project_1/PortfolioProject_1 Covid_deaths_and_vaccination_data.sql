-- Select Data that we are going to be using 

SELECT location, date, total_cases, new_cases, total_deaths, population FROM coviddeaths;


-- Looking at Total Cases vs Total Deaths - how many cases are there in the country/continent and then how many deaths do they have (in %). Shows likelihood of dying if you contract covid in selected country/continent

SELECT location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM coviddeaths
WHERE location = 'Europe';

SELECT location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM coviddeaths
WHERE location = 'United Kingdom';


-- Looking at Total Cases vs Population in United Kingdom 
-- Shows what percentage of population got Covid


SELECT location, date, total_cases,population, (total_cases/population)*100 AS DeathPercentage 
FROM coviddeaths
WHERE location = 'United Kingdom';

-- Global numbers

SELECT SUM(new_cases) AS total_cases,SUM(new_deaths) AS total_deaths,(SUM(new_deaths)/SUM(new_cases))*100 DeathPercentage
FROM coviddeaths;


-- Looking at Countries with Highest Infection Rate

SELECT location, MAX(CAST(total_cases AS UNSIGNED)) AS HighestInfectionCount
FROM coviddeaths
GROUP BY location
ORDER BY 1,2 DESC;


-- Looking at Countries with Highest Infection Rate compared to Population

SELECT location,population, MAX(CAST(total_cases AS UNSIGNED))AS HighestInfectionCount,(MAX(total_cases)/population)*100 AS PercentPopulationInfected
FROM coviddeaths
WHERE continent != ' '
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;


-- Showing Continents with Highest Death Count

SELECT location, MAX(CAST(total_deaths AS UNSIGNED))AS TotalDeathCount
FROM coviddeaths
WHERE continent = ''
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- Showing Countries with Highest Death Count

SELECT location,MAX(CAST(total_deaths AS UNSIGNED))AS TotalDeathCount
FROM coviddeaths
WHERE continent != ''
GROUP BY location
ORDER BY TotalDeathCount DESC;



-- joining vaccination and covid deaths tables

SELECT * FROM covidvaccination vac
JOIN coviddeaths dea
ON vac.location = dea.location AND vac.date = dea.date
LIMIT 100;

-- Looking at Total Population vs Vaccinations using windows function 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccination vac
ON dea.location = vac.location AND dea.date = vac.date
ORDER BY 2, 3;


-- USE CTE
WITH popvsvac (continent, location,  date, population, new_vaccinations,RollingPeopleVaccinated) AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccination vac
ON dea.location = vac.location AND dea.date = vac.date
ORDER BY 2,3 
)
SELECT *, (RollingPeopleVaccinated/population) * 100 AS PercentPopulationVaccinated
FROM popvsvac;

-- OR USE TEMP TABLE

DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),  
date nvarchar(255) , 
population numeric, 
new_vaccinations nvarchar(255),
RollingPeopleVaccinated numeric
);
INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccination vac
ON dea.location = vac.location AND dea.date = vac.date;

SELECT *, (RollingPeopleVaccinated/population) * 100 AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;


-- Creating view to store data for later, looking at Continents with Highest Death Count

CREATE VIEW HighestDeathCountperContinent AS
SELECT location, MAX(CAST(total_deaths AS UNSIGNED))AS TotalDeathCount
FROM coviddeaths
WHERE continent = '' AND location != 'High income' AND location != 'Low income'
GROUP BY location 
ORDER BY TotalDeathCount DESC;

-- Creating view to store data for later, looking at Rolling Numbers of People Vaccinated

CREATE VIEW RollingPeopleVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccination vac
ON dea.location = vac.location AND dea.date = vac.date
ORDER BY 2, 3;

-- You can query directly from view  and use for the visualisation later
SELECT * FROM RollingPeopleVaccinated;