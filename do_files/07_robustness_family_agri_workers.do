/********************************************************************************
Project:       Gender Wage Inequality in Bhutan: Regional and Distributional Decompositions
Manuscript:    Journal of Asian Economics, ASIECO-D-25-00658R1
File:          07_robustness_family_agri_workers.do

Purpose:       Re-estimates the OLS and Heckman wage models using an expanded wage and employment definition that includes family and agricultural workers.

Data:          Bhutan Labour Force Survey, pooled 2011-2022 microdata.
Data access:   The raw/restricted LFS microdata are not distributed with this
               replication package because access is subject to permission from
               the official data provider. Authorised users should place the
               required dataset in the data/raw folder before running the code.

Input:         ${processed}/lfs_2011_2022_harmonised.dta
Output:        ${tables}/table8_robustness_family_agri_marginal_effects.csv

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
log using "${logs}/07_robustness_family_agri_workers.log", replace text

* Load the harmonised analysis-ready dataset created by 01_clean_harmonise_lfs.do.
use "${processed}/lfs_2011_2022_harmonised.dta", clear

/********************************************************************
* ROBUSTNESS CHECK 3:  Table 8
* INCLUDING FAMILY & AGRICULTURAL WORKERS
* (Alternative Employment & Wage Definitions)
********************************************************************/


****************************************************
* STEP 2: Robustness wage variable (lhourly_income3)
****************************************************
capture drop lhourly_income3
gen lhourly_income3 = lhourly_income

label var lhourly_income3 ///
"Log hourly earnings (including family & agri workers)"

****************************************************
* STEP 3: Sample restriction (prime age)
****************************************************
preserve
keep if age >= 25 & age <= 65


****************************************************
* STEP 3A: DEFINE COMMON REGRESSOR GLOBALS
* These definitions make this robustness script self-contained.
****************************************************

global gender    female

global w_exp     formalwork_experience formalwork_experiencesq

global w_humcap  attended_training ///
                 non_formal elementary_level lower_secondary ///
                 higher_secondary college_level ///
                 atleast_masterdegree religious_studies

global w_marital Married Divorced_seperated Living_together Widowed

global w_house   hh_children ///
                 hh_elderly ///
                 hh_adult_female ///
                 hh_adult_male

global w_job     formal_sector ///
                 contract_worker regular_paid ///
                 ownaccountworker_agri

global w_enter   NGOs civil_service armed_forces farmer private_business state_owned

global w_geo     urban western_region central_region southern_region

global w_time    dyear_2012 dyear_2013 dyear_2014 dyear_2015 dyear_2016 ///
                 dyear_2017 dyear_2018 dyear_2019 dyear_2020 dyear_2021 ///
                 dyear_2022

global s_exp     formalwork_experience formalwork_experiencesq

global s_humcap  attended_training ///
                 non_formal elementary_level lower_secondary ///
                 higher_secondary college_level ///
                 atleast_masterdegree religious_studies

global s_marital Married Divorced_seperated Living_together Widowed

global s_house   hh_children ///
                 hh_elderly ///
                 hh_adult_female ///
                 hh_adult_male

global s_geo     urban western_region central_region southern_region

global s_time    dyear_2012 dyear_2013 dyear_2014 dyear_2015 dyear_2016 ///
                 dyear_2017 dyear_2018 dyear_2019 dyear_2020 dyear_2021 ///
                 dyear_2022

global s_excl    hh_female_head

****************************************************
* =========================
* DEFINE REGRESSOR LISTS
* (Same as baseline, different LFP / wage vars)
* =========================
****************************************************

* Wage equation regressors
global wageXlist_LFP2 ///
    $gender ///
    $w_exp ///
    $w_humcap ///
    $w_marital ///
    $w_house ///
    $w_job ///
    $w_enter ///
    $w_geo ///
    $w_time

* Selection equation regressors
global selXlist_LFP2 ///
    $gender ///
    $s_exp ///
    $s_humcap ///
    $s_marital ///
    $s_house ///
    $s_geo ///
    $s_time ///
    $s_excl

****************************************************
* SECTION A: OLS ROBUSTNESS
****************************************************
reg lhourly_income3 ///
    $wageXlist_LFP2 ///
    [pweight=weight], ///
    vce(robust)

estimates store OLS_LFP2

****************************************************
* SECTION B: HECKMAN SELECTION MODEL (MLE)
****************************************************
heckman lhourly_income3 ///
    $wageXlist_LFP2 ///
    , select(LFP2 = $selXlist_LFP2) ///
      mle ///
      vce(robust)

***********************************************************
	
* C1. Marginal effects on employment probability (policy-relevant)
margins, dydx(*) predict(psel)
eststo me_select

* C2. Marginal effects on wages, conditional on employment (appendix only)
margins, dydx(*) predict(ycond)
eststo me_wage

esttab me_select me_wage using "${tables}/table8_robustness_family_agri_marginal_effects.csv", replace ///
    se b(%5.3f) star(* 0.10 ** 0.05 *** 0.01) wide
	

restore

log close
