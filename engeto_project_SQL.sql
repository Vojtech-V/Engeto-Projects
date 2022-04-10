-- Vytvoření tabulek a příprava dat k jejich následnému spojení

CREATE TABLE t_vojta_veverka_payroll AS
SELECT
	payroll_year,
	industry_branch_code,
	cpib.name AS industry_name,
	AVG(value) AS average_salary,
	cpu.name AS currency
FROM czechia_payroll cp
LEFT JOIN czechia_payroll_industry_branch cpib 
	ON cp.industry_branch_code = cpib.code
LEFT JOIN czechia_payroll_unit cpu
	ON cp.unit_code = cpu.code
WHERE calculation_code = 100 
	AND value_type_code = 5958
	AND value IS NOT NULL
	AND industry_branch_code IS NOT NULL
	AND payroll_year >= 2006 
	AND payroll_year <= 2018
GROUP BY payroll_year, industry_branch_code, industry_name
ORDER BY payroll_year, industry_branch_code;

CREATE TABLE t_vojta_veverka_price AS
SELECT
	YEAR(date_from) AS year_of_measurement,
	code AS article_code,
	name AS article,
	ROUND(AVG(value),2) AS average_price,
	price_value,
	price_unit
FROM czechia_price_category cpc
LEFT JOIN czechia_price cp 
	ON cp.category_code = cpc.code
GROUP BY year_of_measurement, article_code, article, price_value, price_unit;

CREATE TABLE t_vojta_veverka_economies AS
SELECT `year`,
	GDP
FROM economies
WHERE country = 'Czech republic'
	AND `year` >= 2006 
	AND `year` <= 2018; 

-- Spojení tabulek podle společného období

CREATE TABLE t_vojta_veverka_project_SQL_primary_final AS
SELECT
	year_of_measurement,
	GDP,
	industry_branch_code,
	industry_name,
	average_salary,
	currency,
	article_code,
	article,
	average_price,
	price_value,
	price_unit
FROM t_vojta_veverka_payroll pa
LEFT JOIN t_vojta_veverka_price pr
	ON pa.payroll_year = pr.year_of_measurement
LEFT JOIN t_vojta_veverka_economies e
	ON pa.payroll_year = e.`year`
ORDER BY year_of_measurement, industry_branch_code;

/*
 *  Výzkumné otázky
 */

-- 1) Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

SELECT *
FROM (SELECT 
	year_of_measurement,
	industry_branch_code,
	industry_name,
	average_salary,
	LAG(average_salary) OVER (PARTITION BY industry_branch_code ORDER BY year_of_measurement) AS previous_year
FROM t_vojta_veverka_project_SQL_primary_final) AS a
WHERE average_salary < previous_year;

-- 2) Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

CREATE VIEW v_vojta_veverka_salary_economy AS
SELECT 
	year_of_measurement,
	ROUND(AVG(average_salary)) AS average_salary_economy
FROM t_vojta_veverka_project_SQL_primary_final
GROUP BY year_of_measurement, currency;

CREATE VIEW v_vojta_veverka_prices_economy AS
SELECT 
	year_of_measurement,
	ROUND(AVG(average_price),2) AS average_prices_economy
FROM t_vojta_veverka_project_SQL_primary_final
GROUP BY year_of_measurement;

CREATE VIEW v_vojta_veverka_2 AS
SELECT
	year_of_measurement,
	article_code,
	article,
	AVG(average_price) AS average_price_per_article,
	price_value,
	price_unit
FROM t_vojta_veverka_project_SQL_primary_final
GROUP BY year_of_measurement, article_code, article, price_value, price_unit;

SELECT
	*,
	ROUND(average_salary_economy/average_price_per_article) AS total_count,
	price_unit 
FROM v_vojta_veverka_salary_economy e
JOIN v_vojta_veverka_2 p
	ON e.year_of_measurement = p.year_of_measurement
WHERE article_code = 111301 OR article_code = 114201;
	

-- 3) Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
SELECT
	*,
	ROUND(average_price_per_article/previous_year*100-100, 2) AS percentage_change
	FROM(
	SELECT
	year_of_measurement,
	article_code,
	article,
	average_price_per_article,
	LAG(average_price_per_article) OVER (PARTITION BY article_code ORDER BY year_of_measurement) AS previous_year
FROM v_vojta_veverka_2
GROUP BY article_code, year_of_measurement, article, average_price_per_article) AS b
WHERE previous_year IS NOT NULL
ORDER BY percentage_change;

-- 4) Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

CREATE OR REPLACE VIEW v_vojta_veverka_prices_eco AS
SELECT
	*,
	ROUND(average_prices_economy/previous_year*100-100, 1) AS percentage_change
FROM(SELECT	
	*, 
	LAG(average_prices_economy) OVER (ORDER BY year_of_measurement) AS previous_year
	FROM(
		SELECT 
		year_of_measurement,
		ROUND(AVG(average_price),2) AS average_prices_economy
		FROM t_vojta_veverka_project_SQL_primary_final
		GROUP BY year_of_measurement) AS a) AS b;

CREATE OR REPLACE VIEW v_vojta_veverka_salary_eco AS
SELECT
	*,
	ROUND(average_salary_economy/previous_year*100-100, 1) AS percentage_change
FROM(
	SELECT
 	*, 
	LAG(average_salary_economy) OVER (ORDER BY year_of_measurement) AS previous_year
	FROM(
		SELECT 
		year_of_measurement,
		ROUND(AVG(average_salary)) AS average_salary_economy
		FROM t_vojta_veverka_project_SQL_primary_final
		GROUP BY year_of_measurement, currency) AS a) AS b;

SELECT
	*,
	ABS(salary_change - price_change) AS difference 
	FROM(
	SELECT 
		p.year_of_measurement,
		p.percentage_change AS price_change,
		s.percentage_change AS salary_change
	FROM v_vojta_veverka_prices_eco p
	JOIN v_vojta_veverka_salary_eco s
		ON p.year_of_measurement = s.year_of_measurement) AS a
	WHERE price_change IS NOT NULL
	ORDER BY difference DESC;

-- 5) Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin i mzdách ve stejném nebo násdujícím roce výraznějším růstem?

CREATE OR REPLACE VIEW v_vojta_veverka_GDP_percentage AS
SELECT
	*,
	ROUND(GDP/previous_year*100-100, 1) AS percentage_change
FROM(
	SELECT
		*,
		LAG(GDP) OVER (ORDER BY year_of_measurement) AS previous_year
	FROM(
		SELECT
			year_of_measurement,
			GDP 
		FROM t_vojta_veverka_project_SQL_primary_final
		GROUP BY year_of_measurement) AS a) AS b
WHERE previous_year IS NOT NULL;

SELECT
	p.year_of_measurement,
	p.percentage_change AS price_change,
	s.percentage_change AS salary_change,
	g.percentage_change AS change_of_GDP
FROM v_vojta_veverka_prices_eco p
JOIN v_vojta_veverka_salary_eco s
	ON p.year_of_measurement = s.year_of_measurement
JOIN v_vojta_veverka_GDP_percentage g
	ON g.year_of_measurement = p.year_of_measurement;

/* 
 * DODATEČNÁ TABULKA
 */

CREATE OR REPLACE VIEW v_vojta_veverka_countries AS
SELECT
	country
FROM economies
INTERSECT
SELECT
	country
FROM countries
WHERE continent = 'Europe';

CREATE OR REPLACE TABLE t_vojta_veverka_project_SQL_secondary_final AS
SELECT
	e.country,
	e.`year`,
	e.GDP,
	e.GINI,
	e.population
FROM economies e 
JOIN v_vojta_veverka_countries c
	ON e.country = c.country
WHERE `year` >= 2006 
	AND `year` <= 2018
ORDER BY e.country, `year`;


	








	
