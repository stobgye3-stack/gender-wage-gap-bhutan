/********************************************************************************
Project:       Gender Wage Inequality in Bhutan: Regional and Distributional Decompositions
Manuscript:    Journal of Asian Economics, ASIECO-D-25-00658R1
File:          04_main_wage_models_decompositions.do

Purpose:       Estimates the baseline OLS wage model, the Heckman sample-selection model, Heckman marginal effects, and the Blinder-Oaxaca decompositions for the pooled, urban, and rural samples.

Data:          Bhutan Labour Force Survey, pooled 2011-2022 microdata.
Data access:   The raw/restricted LFS microdata are not distributed with this
               replication package because access is subject to permission from
               the official data provider. Authorised users should place the
               required dataset in the data/raw folder before running the code.

Input:         ${processed}/lfs_2011_2022_harmonised.dta
Output:        ${tables}/table3_heckman_marginal_effects.csv; ${tables}/table4_oaxaca_pooled.rtf; ${tables}/table5_1_oaxaca_urban.rtf; ${tables}/table5_2_oaxaca_rural.rtf

How to use:    This script is designed to be run from 00_master.do after the
               project folder globals are defined. It can also be run separately
               after updating the project path below if required. The script uses
               relative paths only; no personal computer paths are required.

Important:     The empirical logic follows the working code used for the paper.
               Revisions made for this replication package are limited to
               documentation, relative paths, standardised output locations, and
               consistent section headings.

Article authors:
               Dr Sonam Tobgye
               Professor Simon Feeny
               Professor Preety Pratima Srivastava

Code author:   Dr Sonam Tobgye
Software:      Stata 17 or later
Last updated:  July 2026
********************************************************************************/

clear all
set more off
version 17

* Define relative project paths if the script is run directly.
if "${project}" == "" {
    global project "."
}
if "${raw}" == "" {
    global raw "${project}/data/raw"
}
if "${processed}" == "" {
    global processed "${project}/data/processed"
}
if "${tables}" == "" {
    global tables "${project}/outputs/tables"
}
if "${logs}" == "" {
    global logs "${project}/outputs/logs"
}

capture log close
log using "${logs}/04_main_wage_models_decompositions.log", replace text

* Load the harmonised analysis-ready dataset created by 01_clean_harmonise_lfs.do.
use "${processed}/lfs_2011_2022_harmonised.dta", clear


*------------------------------------------------------------
* SAMPLE RESTRICTION: Prime-age adults
*------------------------------------------------------------
drop if age < 25 | age > 65

********************************************************************************
*** DEPENDENT VARIABLES
********************************************************************************
global wagevar   lhourly_income1     // log hourly wage (paid workers only)
global selvar    LFP1                // 1 = paid employment, 0 otherwise

********************************************************************************
*** CORE VARIABLE OF INTEREST
********************************************************************************
global gender    female              // 1 = female, 0 = male


********************************************************************************
*** =========================
*** WAGE EQUATION
*** =========================
*** Determinants of HOURLY WAGES (Conditional on Employment)
********************************************************************************

*------------------------------------------------------------
* POTENTIAL LABOUR-MARKET EXPERIENCE
*------------------------------------------------------------
* Potential labour-market experience and squared potential experience
global w_exp     formalwork_experience formalwork_experiencesq

*------------------------------------------------------------
* HUMAN CAPITAL
*------------------------------------------------------------
* Reference group: illiterate
global w_humcap  attended_training ///
                 non_formal elementary_level lower_secondary ///
                 higher_secondary college_level ///
                 atleast_masterdegree religious_studies
*------------------------------------------------------------
* MARITAL STATUS
*------------------------------------------------------------
* Reference group: Single / never married
global w_marital Married Divorced_seperated Living_together Widowed

*------------------------------------------------------------
* HOUSEHOLD CONSTRAINTS (GENDER-RELEVANT)
*------------------------------------------------------------
global w_house   hh_children ///
                 hh_elderly ///
                 hh_adult_female ///
                 hh_adult_male
				 
			 
*------------------------------------------------------------
* JOB & EMPLOYMENT CHARACTERISTICS
*------------------------------------------------------------
* Reference groups: informal sector, casual/self work
global w_job     formal_sector ///
                 contract_worker regular_paid ///
                 ownaccountworker_agri 

*------------------------------------------------------------
* ENTERPRISE / SECTOR TYPE: Ref private_company
*------------------------------------------------------------
global w_enter NGOs civil_service armed_forces farmer private_business  state_owned

*------------------------------------------------------------
* GEOGRAPHY Ref: eastern_region
*------------------------------------------------------------
global w_geo  urban western_region central_region southern_region

* GEOGRAPHY Ref: eastern_region (without urban rural for bo decomposition)
*------------------------------------------------------------
global w_geo1  western_region central_region southern_region

*------------------------------------------------------------
* TIME FIXED EFFECTS; Ref 2011
*------------------------------------------------------------
global w_time    dyear_2012 dyear_2013 dyear_2014 dyear_2015 dyear_2016 ///
                 dyear_2017 dyear_2018 dyear_2019 dyear_2020 dyear_2021 ///
                 dyear_2022

*------------------------------------------------------------
* FULL WAGE EQUATION LIST
*------------------------------------------------------------
global wageXlist ///
    $gender ///
    $w_exp ///
    $w_humcap ///
	$w_marital ///
	$w_house ///
    $w_job ///
    $w_enter ///
    $w_geo ///
    $w_time

********************************************************************************
*** =========================
*** SELECTION EQUATION
*** =========================
*** Determinants of PAID EMPLOYMENT
********************************************************************************

*------------------------------------------------------------
* POTENTIAL LABOUR-MARKET EXPERIENCE
*------------------------------------------------------------
* Potential labour-market experience and squared potential experience
global s_exp     formalwork_experience formalwork_experiencesq

*------------------------------------------------------------
* HUMAN CAPITAL & EMPLOYABILITY
*------------------------------------------------------------
* Reference group: illiterate
global s_humcap  attended_training ///
                 non_formal elementary_level lower_secondary ///
                 higher_secondary college_level ///
                 atleast_masterdegree religious_studies

*------------------------------------------------------------
* MARITAL STATUS
*------------------------------------------------------------
* Reference group: Single / never married
global s_marital Married Divorced_seperated Living_together Widowed

*------------------------------------------------------------
* HOUSEHOLD CONSTRAINTS (GENDER-RELEVANT)
*------------------------------------------------------------
global s_house   hh_children ///
                 hh_elderly ///
                 hh_adult_female ///
                 hh_adult_male

*------------------------------------------------------------
* EXCLUSION RESTRICTION (IDENTIFICATION)
*------------------------------------------------------------
* Affects labour supply, not wages conditional on employment
global s_excl    hh_female_head

*------------------------------------------------------------
* GEOGRAPHY & JOB ACCESS
*------------------------------------------------------------
* Reference group: rural, eastern region
global s_geo     urban western_region central_region southern_region

*------------------------------------------------------------
* TIME FIXED EFFECTS
*------------------------------------------------------------
* Reference year: 2011
global s_time    dyear_2012 dyear_2013 dyear_2014 dyear_2015 dyear_2016 ///
                 dyear_2017 dyear_2018 dyear_2019 dyear_2020 dyear_2021 ///
                 dyear_2022

*------------------------------------------------------------
* FULL SELECTION EQUATION LIST
*------------------------------------------------------------
global selXlist ///
    $gender ///
	$s_exp ///
    $s_humcap ///
    $s_marital ///
    $s_house ///
    $s_geo ///
    $s_time ///
	$s_excl 

********************************************************************************
*** ESTIMATION (Table 3)
********************************************************************************

*------------------------------------------------------------
* (1) BASELINE OLS (NO SELECTION CORRECTION)
*------------------------------------------------------------
reg $wagevar $wageXlist ///
    [pweight=weight], ///
    vce(robust)

*------------------------------------------------------------
* (2) HECKMAN SAMPLE SELECTION MODEL (MLE)
*------------------------------------------------------------
heckman $wagevar $wageXlist ///
    , select($selvar = $selXlist) ///
      mle ///
      vce(robust)

***********************************************************
	
* C1. Marginal effects on employment probability (policy-relevant)
margins, dydx(*) predict(psel)
eststo me_select

* C2. Marginal effects on wages, conditional on employment (appendix only)
margins, dydx(*) predict(ycond)
eststo me_wage

esttab me_select me_wage using "${tables}/table3_heckman_marginal_effects.csv", replace ///
    se b(%5.3f) star(* 0.10 ** 0.05 *** 0.01) wide
	
	
*------------------------------------------------------------
* Define BO Wage Variable Lists (Aligned with Heckman)
*------------------------------------------------------------
***BO wage covariates – pooled

global bo_wageX_pooled ///
    $w_exp ///
    $w_humcap ///
	$w_marital ///
	$w_house ///
    $w_job ///
    $w_enter ///
    $w_geo ///
    $w_time

*------------------------------------------------------------
* BO wage covariates – urban/rural
*------------------------------------------------------------
global bo_wageX_nourban ///
    $w_exp ///
    $w_humcap ///
	$w_marital ///
	$w_house ///
    $w_job ///
    $w_enter ///
    $w_geo1 ///
    $w_time

****Define BO Selection Equation List (Same Logic)
	
global bo_selX_pooled ///
    $s_exp ///
    $s_humcap ///
    $s_marital ///
    $s_house ///
    $s_geo ///
    $s_time ///
	$s_excl 
	
global bo_selX_nourban ///
    $s_exp ///
    $s_humcap ///
    $s_marital ///
    $s_house ///
    $s_geo1 ///
    $s_time ///
	$s_excl 
	
	
****************************************TABLE 4*****************************************************
* Blinder–Oaxaca twofold decomposition
* Heckman-adjusted gender wage gap (Pooled sample)
***************************************************************************************************
**** BO Pooled

eststo clear

eststo: oaxaca $wagevar $bo_wageX_pooled, ///
    by(female) model1 ///
    (heckman, select($selvar = $bo_selX_pooled)) ///
    noisily relax

esttab using "${tables}/table4_oaxaca_pooled.rtf", ///
    ar2 b(%5.3f) se(%9.3f) ///
    unstack scalars(N) ///
    noobs nomtitle replace wide


****************************************TABLE 5.1***************************************************
* Blinder–Oaxaca twofold decomposition
* Heckman-adjusted gender wage gap – URBAN
***************************************************************************************************

**** BO Urban
eststo clear

eststo: oaxaca $wagevar $bo_wageX_nourban if urban == 1, ///
    by(female) model1 ///
    (heckman, select($selvar = $bo_selX_nourban)) ///
    noisily relax

esttab using "${tables}/table5_1_oaxaca_urban.rtf", ///
    ar2 b(%5.3f) se(%9.3f) ///
    unstack scalars(N) ///
    noobs nomtitle replace wide


****************************************TABLE 5.2***************************************************
eststo clear

eststo: oaxaca $wagevar $bo_wageX_nourban if urban == 0, ///
    by(female) model1 ///
    (heckman, select($selvar = $bo_selX_nourban)) ///
    noisily relax

esttab using "${tables}/table5_2_oaxaca_rural.rtf", ///
    ar2 b(%5.3f) se(%9.3f) ///
    unstack scalars(N) ///
    noobs nomtitle replace wide

log close
