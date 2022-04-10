Postup
  1. Vytvoření tabulky t_vojta_veverka_project_SQL_primary_final
    
    a)předpřipravím si tabulky t_vojta_veverka_payroll (obsahuje data z tabulek týkajících se mezd), t_vojta_veverka_price (obsahuje data z tabulek týkajících se mezd) a       t_vojta_veverka_economies 
    
    b) následně spojím tyto tabulky podle jejich společného období tj. mezi roky 2006 až 2018 včetně.
  
  2. Na základě takto vytvořeného souboru odpovídám na výzkumné otázky
    a)  OTÁZKA Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
        ODPOVĚĎ na základě SQL dotazu vidíme všechny odvětví, ve kterých mzdy meziročně klesaly. Můžeme konstatovat, že se jedná o jev méně častý a jasným trendem je             růst mezd v jednotlivých odvětvích.
     
     b) OTÁZKA  Kolik je možné si koupit litrŮ mléka a kilogramŮ chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
        ODPOVĚĎ Na základě dat vidíme že v roce 2006 bylo možné koupit v prvním sledovaném období v roce 2006 při průměrné mzdě 20342 Kč 1409 l mléka nebo 1262 kg               chleba. V posledním sledovaném období roku 218 bylo možné koupit při průměrné mzdě 31980 Kč celkem 1614 l mléka nebo 1319 kg chleba.
    
    c) OTÁZKA Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
        ODPOVĚĎ nejnižší percentuální měziroční nárůst byl zaznamenán v roce 2007 u kategorie potravin Rajská jablka červená kulatá a to -30,28%.
    
    d) OTÁZKA Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)
        ODPOVĚĎ Ve sledovaném obdoví nedošlo k více než 10% nárůstu cen oproti nárůstu mezd. K největšímu rozdílu došlo v roce 2013 a to 6,7%.
    
    e) OTÁZKA  Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin i mzdách ve                   stejném nebo násdujícím roce výraznějším růstem?
       ODPOVĚĎ Na základě dat není možné jednoznační určit souvislost mezi růstem HDP a růstem cen a mezd.
  
  3. Vytvoření dodatečného materiálu  pomocí intersect výchozích tabulek countries a economies získám data týkající se jen evropských států - vytvořím VIEW kteý potom        použiji při vytvoření finální tabulky t_vojta_veverka_project_SQL_secondary_final
     
   
  
