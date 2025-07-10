--Projekt SQL
-- ========================================
-- Autor: Veronika Uhrová
-- Název: Analýza vztahu HDP, mezd a cen potravin
-- Databáze: PostgreSQL, DBeaver
-- Období: 2006–2018
-- ========================================
-- VYTVOŘENÍ PRIMÁRNÍ TABULKY
-- ========================================

CREATE TABLE t_veronika_uhrova_project_SQL_primary_final AS
WITH tabulka_1 AS (
	SELECT 
		category_code,
		date_part('year', date_from) AS year_potraviny,
		ROUND (avg (value)::NUMERIC, 2) AS cena_za_rok
	FROM czechia_price cp
	GROUP BY category_code, date_part('year', date_from)
),
tabulka_2 AS (
	SELECT 
	tabulka_1.*,
		cpc.name
	FROM tabulka_1
	JOIN czechia_price_category cpc
	ON tabulka_1.category_code = cpc.code
)
SELECT 
	t2.name AS nazev_potraviny,
	t2.category_code,
	t2.year_potraviny,
	t2.cena_za_rok,
	cpib.name AS nazev_odvetvi,
	cp.industry_branch_code,
	payroll_year,
	avg(value) AS rocni_prumer	
FROM czechia_payroll cp
JOIN tabulka_2 t2
ON cp.payroll_year = t2.year_potraviny
JOIN czechia_payroll_industry_branch cpib
ON cp.industry_branch_code = cpib.code
WHERE 
	value_type_code = 5958    -- průměrná hrubá mzda na zaměstnance
	AND calculation_code = 200 --přepočteno na celé úvazky, dle ČSÚ lepší parameter, eliminuje vyšší počty částečných úvazků v některých odvětvích
GROUP BY 
	industry_branch_code, 
	payroll_year,
	t2.category_code,
	t2.year_potraviny,
	t2.cena_za_rok,
	t2.name,
	cpib.name
ORDER BY industry_branch_code, payroll_year, category_code;

SELECT *
FROM t_veronika_uhrova_project_SQL_primary_final;

-- ========================================
-- VYTVOŘENÍ SEKUNDÁRNÍ TABULKY
-- ========================================

CREATE TABLE t_Veronika_Uhrova_project_SQL_secondary_final AS (
	SELECT 
		country,
		YEAR, 
		gdp,
		population,
		gini
	FROM economies e
	WHERE YEAR BETWEEN 2006 AND 2018
	ORDER BY country, YEAR ASC
);

SELECT *
FROM t_Veronika_Uhrova_project_SQL_secondary_final;


--1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají? (roky 2006-2018)

--Přehled trendu průměrných mezd za roky 2006-2018.
WITH changing_wages AS( 
	SELECT
		industry_branch_code,
		nazev_odvetvi,
		payroll_year,
		rocni_prumer - LAG(rocni_prumer) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year) AS wage_diff,  -- rozdil prum.mzdy mezi roky
		ROUND(100.0 * (rocni_prumer - LAG(rocni_prumer) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year))
			/ NULLIF(LAG(rocni_prumer) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year), 0), 2) AS wage_growth_pct   --prepočet rozdílu mezi roky na procenta
	FROM t_veronika_uhrova_project_SQL_primary_final
	GROUP BY
		industry_branch_code,
		payroll_year,
		nazev_odvetvi,
		rocni_prumer
)
	SELECT 
		cw.*,
		CASE 
			WHEN wage_diff IS NULL THEN NULL
			WHEN wage_diff > 0 THEN 'stoupa'
			WHEN wage_diff = 0 THEN 'stagnuje'
			ELSE 'klesa' 
		END AS trend_mezirocni
	FROM changing_wages cw;
    

--Kolikrát za období roků 2006-2018 došlo k poklesu nebo nárůstu? 

WITH changing_wages AS( 
	SELECT
		industry_branch_code,
		nazev_odvetvi,
		payroll_year,
		rocni_prumer - LAG(rocni_prumer) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year) AS wage_diff,
		ROUND(100.0 * (rocni_prumer - LAG(rocni_prumer) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year))
			/ NULLIF(LAG(rocni_prumer) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year), 0), 2) AS wage_growth_pct   --propočet na procenta
	FROM t_veronika_uhrova_project_SQL_primary_final
	GROUP BY
		industry_branch_code,
		payroll_year,
		nazev_odvetvi,
		rocni_prumer
),
trend AS (
	SELECT 
		*,
		CASE 
			WHEN wage_diff IS NULL THEN NULL
			WHEN wage_diff > 0 THEN 'stoupa'
			WHEN wage_diff = 0 THEN 'stagnuje'
			ELSE 'klesa' 
		END AS trend_mezirocni
	FROM changing_wages
)
SELECT 
    nazev_odvetvi,
    COUNT(*) FILTER (WHERE trend_mezirocni = 'klesa') AS pocet_poklesu,
    COUNT(*) FILTER (WHERE trend_mezirocni = 'stoupa') AS pocet_rustu
FROM trend t
GROUP BY nazev_odvetvi
ORDER BY pocet_poklesu DESC;

-- Zde možnost zjistit, které roky byl jenom pokles
WITH changing_wages AS( 
	SELECT
		industry_branch_code,
		nazev_odvetvi,
		payroll_year,
		rocni_prumer - LAG(rocni_prumer) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year) AS wage_diff,  -- rozdil prum.mzdy mezi roky
		ROUND(100.0 * (rocni_prumer - LAG(rocni_prumer) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year))
			/ NULLIF(LAG(rocni_prumer) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year), 0), 2) AS wage_growth_pct   --prepočet rozdílu mezi roky na procenta
	FROM t_veronika_uhrova_project_SQL_primary_final
	GROUP BY
		industry_branch_code,
		payroll_year,
		nazev_odvetvi,
		rocni_prumer
),
case_pokles AS(
	SELECT 
		cw.*,
		CASE 
			WHEN wage_diff IS NULL THEN NULL
			WHEN wage_diff > 0 THEN 'stoupa'
			WHEN wage_diff = 0 THEN 'stagnuje'
			ELSE 'klesa' 
		END AS trend_mezirocni
	FROM changing_wages cw
)
SELECT 
	*
FROM case_pokles
WHERE trend_mezirocni = 'klesa'
ORDER BY industry_branch_code, payroll_year;

--Zajímavý rok 2013?
WITH changing_wages AS( 
	SELECT
		industry_branch_code,
		nazev_odvetvi,
		payroll_year,
		rocni_prumer - LAG(rocni_prumer) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year) AS wage_diff,  -- rozdil prum.mzdy mezi roky
		ROUND(100.0 * (rocni_prumer - LAG(rocni_prumer) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year))
			/ NULLIF(LAG(rocni_prumer) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year), 0), 2) AS wage_growth_pct   --prepočet rozdílu mezi roky na procenta
	FROM t_veronika_uhrova_project_SQL_primary_final
	GROUP BY
		industry_branch_code,
		payroll_year,
		nazev_odvetvi,
		rocni_prumer
),
case_pokles AS(
	SELECT 
		cw.*,
		CASE 
			WHEN wage_diff IS NULL THEN NULL
			WHEN wage_diff > 0 THEN 'stoupa'
			WHEN wage_diff = 0 THEN 'stagnuje'
			ELSE 'klesa' 
		END AS trend_mezirocni
	FROM changing_wages cw
)
SELECT 
	*
FROM case_pokles
WHERE trend_mezirocni = 'klesa' AND payroll_year = '2013'
ORDER BY wage_growth_pct;


--2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

SELECT *
FROM t_veronika_uhrova_project_SQL_primary_final;

--Nejdřív tabulka s vyfilltrovanými daty podle zadání, pak přepočet.
WITH primary_set AS (
	SELECT 
		nazev_potraviny,
		year_potraviny,
		cena_za_rok,
		nazev_odvetvi,
		rocni_prumer
	FROM t_veronika_uhrova_project_SQL_primary_final
	WHERE year_potraviny IN (
		(SELECT MIN(year_potraviny) FROM t_veronika_uhrova_project_sql_primary_final), 
	    (SELECT MAX(year_potraviny) FROM t_veronika_uhrova_project_sql_primary_final))   --dynamika!
		AND category_code IN (111301, 114201)
	ORDER BY nazev_potraviny, nazev_odvetvi, year_potraviny
)
SELECT
	nazev_potraviny,
	year_potraviny,
	nazev_odvetvi,
	ROUND((rocni_prumer/cena_za_rok)::NUMERIC, 2) AS ks_potravin_za_mesic,  --rocni_prumer tzn. prum.mesiční plat v danem roce, cena_za_rok znamená prum.cena potraviny za daný rok
	ROUND((12* rocni_prumer/cena_za_rok)::NUMERIC, 2) AS ks_potravin_za_rok
FROM primary_set ps;

-- Průměrný počet kusů na rok skrze všechny odvětví. 
WITH primary_set AS (
	SELECT 
		nazev_potraviny,
		year_potraviny,
		cena_za_rok,
		nazev_odvetvi,
		rocni_prumer
	FROM t_veronika_uhrova_project_SQL_primary_final
	WHERE year_potraviny IN (
		(SELECT MIN(year_potraviny) FROM t_veronika_uhrova_project_sql_primary_final), 
	    (SELECT MAX(year_potraviny) FROM t_veronika_uhrova_project_sql_primary_final))   --dynamika!
		AND category_code IN (111301, 114201)
	ORDER BY nazev_potraviny, nazev_odvetvi, year_potraviny
),
ks_jednot_odvetvi AS (
	SELECT
		nazev_potraviny,
		year_potraviny,
		nazev_odvetvi,
		ROUND((rocni_prumer/cena_za_rok)::NUMERIC, 2) AS ks_potravin_za_mesic,  --rocni_prumer tzn. prum.mesiční plat v danem roce, cena_za_rok znamená prum.cena potraviny za daný rok
		ROUND((12* rocni_prumer/cena_za_rok)::NUMERIC, 2) AS ks_potravin_za_rok
	FROM primary_set ps
)
SELECT 
	nazev_potraviny,
	year_potraviny,
	ROUND((avg(ks_potravin_za_mesic)), 2) AS ks_mezi_odvetvi_mesic,
	ROUND((avg(ks_potravin_za_rok)), 2) AS ks_mezi_odvetvi_rok
FROM ks_jednot_odvetvi
GROUP BY nazev_potraviny, year_potraviny;


--Stanovení MIN a MAX počtu ks mezi odvětvími.
WITH primary_set AS (
	SELECT 
		nazev_potraviny,
		year_potraviny,
		cena_za_rok,
		nazev_odvetvi,
		rocni_prumer
	FROM t_veronika_uhrova_project_SQL_primary_final
	WHERE year_potraviny IN (
		(SELECT MIN(year_potraviny) FROM t_veronika_uhrova_project_sql_primary_final), 
	    (SELECT MAX(year_potraviny) FROM t_veronika_uhrova_project_sql_primary_final))   --dynamika!
		AND category_code IN (111301, 114201)
	ORDER BY nazev_potraviny, nazev_odvetvi, year_potraviny
),
ks_jednot_odvetvi AS (
	SELECT
		nazev_potraviny,
		year_potraviny,
		nazev_odvetvi,
		ROUND((rocni_prumer/cena_za_rok)::NUMERIC, 2) AS ks_potravin_za_mesic,  --rocni_prumer tzn. prum.mesiční plat v danem roce, cena_za_rok znamená prum.cena potraviny za daný rok
		ROUND((12* rocni_prumer/cena_za_rok)::NUMERIC, 2) AS ks_potravin_za_rok
	FROM primary_set ps
)
SELECT
	nazev_potraviny,
	YEAR_potraviny,
	min(ks_potravin_za_mesic) AS min_mesic,
	max(ks_potravin_za_mesic) AS max_mesic,
	min(ks_potravin_za_rok) AS min_rok,
	max(ks_potravin_za_rok) AS max_rok,
	ROUND (((max(ks_potravin_za_mesic)/min(ks_potravin_za_mesic))), 2) AS nasobek_min_max
FROM ks_jednot_odvetvi
GROUP BY nazev_potraviny, year_potraviny;

--3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? 

SELECT *
FROM t_veronika_uhrova_project_SQL_primary_final;

WITH agregovane_ceny AS (
	SELECT 
		DISTINCT nazev_potraviny,
		category_code,
		year_potraviny,
		cena_za_rok
	FROM t_veronika_uhrova_project_SQL_primary_final
	ORDER BY category_code, year_potraviny
),
mezirocni_rozdily AS (
	SELECT
		nazev_potraviny,
		category_code,
		year_potraviny,
		cena_za_rok,
		cena_za_rok - LAG (cena_za_rok) OVER (PARTITION BY nazev_potraviny ORDER BY year_potraviny) AS mezirocni_rozdil_cena,
		ROUND(100.0 * (cena_za_rok - LAG(cena_za_rok) OVER (PARTITION BY nazev_potraviny ORDER BY year_potraviny)) 
	     / NULLIF(LAG(cena_za_rok) OVER (PARTITION BY nazev_potraviny ORDER BY year_potraviny), 0), 2) AS mezirocni_rust_pct
	FROM agregovane_ceny
	ORDER BY category_code, year_potraviny
)
SELECT 
	nazev_potraviny,
	category_code,
	ROUND(avg(mezirocni_rust_pct)::NUMERIC, 2) AS prumer_pct_2006_2018  --prumer zmen (procent narustu, či poklesu) v prubehu let
FROM mezirocni_rozdily
WHERE mezirocni_rust_pct IS NOT NULL
GROUP BY nazev_potraviny, category_code
ORDER BY prumer_pct_2006_2018 ASC --mezirocni_rust_pct ASC
LIMIT 1;

--4.Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)? 

SELECT 
	*,
	cena_za_rok - LAG(cena_za_rok) OVER (PARTITION BY nazev_potraviny ORDER BY year_potraviny) AS mezirocni_rozdil
	--ROUND (100.0* (cena_za_rok - LAG(cena_za_rok) OVER (PARTITION BY nazev_potraviny ORDER BY year_potraviny)) / NULLIF(LAG(cena_za_rok) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year), 0), 2) AS nezirocni_trend_potraviny
FROM t_veronika_uhrova_project_SQL_primary_final
ORDER BY category_code, year_potraviny;


WITH ceny_za_rok AS (
  SELECT 
    year_potraviny AS rok,
    ROUND(AVG(cena_za_rok), 2) AS prumerna_cena
  FROM t_veronika_uhrova_project_sql_primary_final
  GROUP BY year_potraviny
),
mzdy_za_rok AS (
  SELECT 
    payroll_year AS rok,
    ROUND(AVG(rocni_prumer), 2) AS prumerna_mzda
  FROM t_veronika_uhrova_project_sql_primary_final
  GROUP BY payroll_year
),
rust AS (
  SELECT 
    c.rok,
    c.prumerna_cena,
    m.prumerna_mzda,
    c.prumerna_cena - LAG(c.prumerna_cena) OVER (ORDER BY c.rok) AS diff_cena,   -- růst cen meziročně
    ROUND(
      100.0 * (c.prumerna_cena - LAG(c.prumerna_cena) OVER (ORDER BY c.rok)) 
      / NULLIF(LAG(c.prumerna_cena) OVER (ORDER BY c.rok), 0), 2
    ) AS rust_cen_pct, 
    m.prumerna_mzda - LAG(m.prumerna_mzda) OVER (ORDER BY m.rok) AS diff_mzda,   -- růst mezd meziročně
    ROUND(
      100.0 * (m.prumerna_mzda - LAG(m.prumerna_mzda) OVER (ORDER BY m.rok)) 
      / NULLIF(LAG(m.prumerna_mzda) OVER (ORDER BY m.rok), 0), 2
    ) AS rust_mezd_pct
  FROM ceny_za_rok c
  JOIN mzdy_za_rok m ON c.rok = m.rok
)
SELECT 
  rok,
  rust_cen_pct,
  rust_mezd_pct,
  ROUND(rust_cen_pct - rust_mezd_pct, 2) AS rozdil
FROM rust
WHERE 
  rust_cen_pct IS NOT NULL AND rust_mezd_pct IS NOT NULL
  AND rust_cen_pct - rust_mezd_pct > 10
ORDER BY rozdil DESC;

--Na základě dat z let 2006–2018 nebyl zaznamenán rok, ve kterém by ceny potravin rostly výrazně rychleji než mzdy — tj. o více než 10 % ročně.

--5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

SELECT *
	FROM t_Veronika_Uhrova_project_SQL_secondary_final
	WHERE country = 'Czech Republic';

WITH hdp_cr AS(
	SELECT 
		YEAR,
		gdp,
		LAG(gdp) OVER (ORDER BY year) AS predchozi_gdp,
		ROUND((100.0 * (gdp - LAG(gdp) OVER (ORDER BY year))/NULLIF(LAG(gdp) OVER (ORDER BY year), 0))::NUMERIC, 2) AS growth_gdp_pct
	FROM t_Veronika_Uhrova_project_SQL_secondary_final
	WHERE country = 'Czech Republic'
),
ceny_za_rok AS (
	SELECT 
	    year_potraviny AS rok,
	    ROUND(AVG(cena_za_rok), 2) AS prumerna_cena,
	    LAG(ROUND(AVG(cena_za_rok), 2)) OVER (ORDER BY year_potraviny) AS predchozi_cena
	FROM t_veronika_uhrova_project_sql_primary_final
	GROUP BY year_potraviny
),
ceny_growth AS (
	SELECT 
		rok,
		prumerna_cena,
		ROUND(100.0 * (prumerna_cena - predchozi_cena) / NULLIF(predchozi_cena, 0), 2) AS growth_cena_pct
	FROM ceny_za_rok
),
mzdy_za_rok AS (
  SELECT 
    payroll_year AS rok,
    ROUND(AVG(rocni_prumer), 2) AS prumerna_mzda,
    LAG(ROUND(AVG(rocni_prumer), 2)) OVER (ORDER BY payroll_year) AS predchozi_mzda
  FROM t_veronika_uhrova_project_sql_primary_final
  GROUP BY payroll_year
),
mzdy_growth AS (
	SELECT 
		rok,
		prumerna_mzda,
		ROUND(100.0 * (prumerna_mzda - predchozi_mzda) / NULLIF(predchozi_mzda, 0), 2) AS growth_mzda_pct
	FROM mzdy_za_rok
)
  SELECT 
    h.year,
	h.gdp,
	h.growth_gdp_pct,
	m.growth_mzda_pct,
	c.growth_cena_pct	
  FROM hdp_cr h
  LEFT JOIN mzdy_growth m ON h.year = m.rok
  LEFT JOIN ceny_growth c ON h.YEAR = c.rok
  ORDER BY h.YEAR;
	