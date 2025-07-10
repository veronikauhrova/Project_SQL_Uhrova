# SQL projekt: Vztah mezi HDP, mzdami a cenami potravin

Tento projekt analyzuje vývoj mezd, cen potravin a HDP v České republice mezi lety 2006–2018, pomocí dat ČSÚ a datasetu `economies`. Výstupem je množství dotazů nad primární a sekundární tabulkou, které odpovídají na konkrétní ekonomické otázky.

---

## 🗃 Použité datové zdroje

- `czechia_price` – průměrné ceny potravin
- `czechia_payroll` – průměrné mzdy podle odvětví
- `czechia_price_category` – názvy potravin
- `czechia_payroll_industry_branch` – názvy odvětví
- `economies` – mezinárodní makroekonomická data (HDP, GINI, populace)

---

## 🛠 Výpočetní skript

Celý SQL skript se skládá z:

1. Vytvoření primární tabulky `t_veronika_uhrova_project_SQL_primary_final`, kde jsou propojeny ceny potravin a mzdy podle roku a sekundární tabulky `t_veronika_uhrova_project_SQL_secondary_final`, kde jsou mezinárodní makroekonomická data za stejné časové období jako primární tabulka (2006-2018).
2. Otázky a dotazy:**
   - Rostou mzdy ve všech odvětvích?
   - Kolik potravin (mléko a chléb) si mohu koupit za plat?
   - Která potravina zdražuje nejpomaleji?
   - Vyskytl se rok, kdy ceny rostly rychleji než mzdy o více než 10 %?
   - Má HDP vliv na mzdy a ceny potravin?

---

## 📈 Výsledky

### 🔹 1. Mzdy:
- Mzdy v některých odvětvích občas klesly, ale dlouhodobě mají rostoucí trend.
- Nejvíce poklesů bylo v odvětví Těžba a dobývání (B).
- Rok 2013 představuje zlomový bod, kdy došlo k poklesu mezd ve více odborných a kvalifikovaných sektorech (max. až téměř 9% pokles) a zároveň k celkovému zpomalení růstu mezd napříč většinou odvětví. Tento jev lze vysvětlit kombinací faktorů: ekonomickou stagnací (HDP <0), rozpočtovou opatrností firem, regulací a nižší investiční aktivitou (reakce na evropskou dluhovou krizi). Mzdy v odborných a kvalifikovaných oborech jsou více variabilní a citlivé na externí podmínky, a tak se pokles projevil rychle a napříč různými profesemi.

### 🔹 2. Kupní síla:
- V roce 2006 si zaměstnanec mohl v průměru koupit více než 1300 kg chleba nebo přes 1400 litrů mléka za měsíční mzdu a v roce 2018 to bylo přibližně stejné množství chleba, ale došlo k navýšení množství mléka na víc jak 1600 litrů (průmerná mzda mezi všemi odvetvími). 
- Mezi odvětvími se ale množství potravin vzhledem k platu výrazně lišil (3-násobný rozdíl): chléb v rozmezí 724 kg - 2483 kg, mléko v rozmezí 808 l - 2772 l za rok 2006 a chléb v rozmezí 795 kg - 2340 kg, mléko v rozmezí 972 l - 2862 l za rok 2018. Rozdíly v mzdách tak mají přímý a zásadní vliv na dostupnost základních potravin.

### 🔹 3. Potraviny s nejpomalejším růstem:
- Nejnižší meziroční růst ceny měla potravina Cukr krystalový.

### 🔹 4. Překonaly někdy ceny potravin růst mezd o více než 10 %?
- Na základě dat z let 2006–2018 nebyl zaznamenán rok, ve kterém by ceny potravin rostly výrazně rychleji než mzdy — tj. o více než 10 % ročně.

### 🔹 5. HDP vs. mzdy a ceny:
- Na základě dat, lze usoudit, že růst HDP, může mít vliv na růst mezd i cen v tomtéž, nebo dalším roce (skoky v roce 2007, 2017). Korelace zde není jednoznačná, zdá se, že na změny HDP reagují spíše mzdy a ceny potravin jsou ovlivněny i jinými faktory (sklizeň, ceny dovozu, globální trh, silnější koruna) než pouze růstem HDP (např. rok 2018). Růst HDP v roce 2015 byl sice velmi výrazný, ale byl tažen spíše jednorázovými vlivy (zejména dočerpáním evropských fondů), nikoliv spotřebitelskou poptávkou. Firmy tak neviděly potřebu zvyšovat mzdy a cenové tlaky zůstaly nízké i kvůli globálnímu vývoji komodit a silné koruně. Mzdy i ceny reagovaly až o 1–2 roky později, když se ekonomický růst ukázal jako udržitelný a domácí poptávka skutečně zesílila.

---

## 🧾 Poznámky

- Chybějící hodnoty: v prvním roce (2006) nejsou dostupné meziroční rozdíly (`NULL` u `LAG()`) vzhledem k nezařazení dat z roku 2005 do našeho datasetu.
- Hodnoty byly zaokrouhleny na dvě desetinná místa.
- Kód byl psán a testován v prostředí PostgreSQL (DBeaver).


