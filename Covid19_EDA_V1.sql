
-- Select Data that we are going to start with
SELECT location, date, population, total_cases, new_cases, total_deaths
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in your country

SELECT location, population, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) AS deathPerc
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'Canada'
ORDER BY 1,3;

--Total Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT location, population, date, total_cases, total_deaths, ROUND((total_cases/population)*100,2) AS InfectPerc
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'Canada'
ORDER BY 1,3;

-- Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS highestInfections, MAX((total_cases/population))*100 AS InfectPercent
FROM PortfolioProject.dbo.CovidDeaths
Group by population, location
ORDER BY highestInfections DESC

-- Countries with Highest Death Count per Population
SELECT location, MAX(cast(total_deaths as int)) AS DeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY DeathCount DESC

--Contintents with the highest death count per population
SELECT continent, MAX(cast(total_deaths as int)) AS DeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY DeathCount DESC

--Global Numbers
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
