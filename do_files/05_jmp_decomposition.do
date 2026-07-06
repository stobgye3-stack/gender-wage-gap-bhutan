/********************************************************************************
Project:       Gender Wage Inequality in Bhutan: Regional and Distributional Decompositions
Manuscript:    Journal of Asian Economics, ASIECO-D-25-00658R1
File:          05_jmp_decomposition.do

Purpose:       Performs the Juhn-Murphy-Pierce distributional decomposition of the gender wage gap for the pooled, urban, and rural wage distributions.

Data:          Bhutan Labour Force Survey, pooled 2011-2022 microdata.
Data access:   The raw/restricted LFS microdata are not distributed with this
               replication package because access is subject to permission from
               the official data provider. Authorised users should place the
               required dataset in the data/raw folder before running the code.

Input:         ${processed}/lfs_2011_2022_harmonised.dta
Output:        JMP decomposition results in Stata log file

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
log using "${logs}/05_jmp_decomposition.log", replace text

* Load the harmonised analysis-ready dataset created by 01_clean_harmonise_lfs.do.
use "${processed}/lfs_2011_2022_harmonised.dta", clear


********************************************************************************
*** SECTION 5.4: DISTRIBUTIONAL DECOMPOSITION (JMP)
*** Juhn–Murphy–Pierce decomposition of the gender wage gap
***
*** Objective:
***   Examine how the gender wage gap varies across the earnings distribution
***   and decompose it into:
***     (i) Differences in characteristics (quantity effects)
***    (ii) Differences in returns (price effects)
***   (iii) Residual wage structure
***
*** Important:
***   JMP is conditional on paid employment and focuses on wage-setting.
***   Household composition variables are excluded by design.
********************************************************************************


********************************************************************************
*** SAMPLE RESTRICTION FOR JMP DECOMPOSITION
***
*** The JMP decomposition is conducted conditional on observed wages and focuses
*** on wage-setting mechanisms rather than labour supply or participation.
*** Accordingly, the estimation sample is restricted as follows:
***
*** (i) Prime-age adults (25–65):
***     Restricting the sample to prime-age individuals limits bias from schooling-
***     to-work transitions among younger workers and from retirement-related
***     selection at older ages. This ensures comparability with the main wage
***     regressions and avoids distortions in lower-tail wage percentiles.
***
*** (ii) Paid employment only:
***      JMP decomposes observed wage distributions and therefore requires
***      individuals to be in paid employment. Unlike the Heckman framework,
***      JMP does not model selection into work, so the analysis is conducted
***      conditional on employment.
***
*** (iii) Non-missing hourly wages:
***       Individuals with missing or invalid wage information are excluded to
***       ensure a common support across male and female wage distributions and
***       to guarantee stable estimation of distributional components.
********************************************************************************

keep if age >= 25 & age <= 65
keep if Employed == 1
drop if missing(lhourly_income1)

*------------------------------------------------------------
* 2. DEFINE JMP-SPECIFIC COVARIATE GLOBALS
*    (ALIGNED WITH HECKMAN WAGE EQUATION)
*------------------------------------------------------------


*------------------------------------------------------------
* 2(a) POTENTIAL LABOUR-MARKET EXPERIENCE
*------------------------------------------------------------
* Potential labour-market experience and its squared term capture labour market exposure relevant for wage-setting
*------------------------------------------------------------
global jmp_exp ///
    formalwork_experience formalwork_experiencesq


*------------------------------------------------------------
* 2(b) HUMAN CAPITAL
*------------------------------------------------------------
* Education and training determine productive skills
* Reference group: illiterate / no schooling
*------------------------------------------------------------
global jmp_humcap ///
    attended_training ///
    non_formal elementary_level lower_secondary ///
    higher_secondary college_level ///
    atleast_masterdegree religious_studies


*------------------------------------------------------------
* 2(c) JOB & EMPLOYMENT CHARACTERISTICS
*------------------------------------------------------------
* Capture institutional and contractual wage-setting regimes
* Reference groups: informal sector, casual/self work
*------------------------------------------------------------
global jmp_job ///
    formal_sector ///
    contract_worker regular_paid ///
    ownaccountworker_agri 


*------------------------------------------------------------
* 2(d) ENTERPRISE / EMPLOYER TYPE
*------------------------------------------------------------
* Employer characteristics influence wage scales
* Reference group: private limited company
*------------------------------------------------------------
global jmp_enter ///
    NGOs civil_service armed_forces ///
    farmer private_business state_owned


*------------------------------------------------------------
* 2(e) GEOGRAPHY
*------------------------------------------------------------
* Pooled: urban varies
* Subsamples: urban is constant and excluded
* Reference region: eastern region
*------------------------------------------------------------
global jmp_geo_pooled ///
    urban western_region central_region southern_region

global jmp_geo_nourban ///
    western_region central_region southern_region


*------------------------------------------------------------
* 2(f) TIME FIXED EFFECTS
*------------------------------------------------------------
* Control for macroeconomic and survey-round effects
* Reference year: 2011
*------------------------------------------------------------
global jmp_time ///
    dyear_2012 dyear_2013 dyear_2014 dyear_2015 dyear_2016 ///
    dyear_2017 dyear_2018 dyear_2019 dyear_2020 dyear_2021 ///
    dyear_2022


*------------------------------------------------------------
* 2(g) FULL JMP COVARIATE LISTS
*------------------------------------------------------------
global jmp_cov_pooled ///
    $jmp_exp ///
    $jmp_humcap ///
    $jmp_job ///
    $jmp_enter ///
    $jmp_geo_pooled ///
    $jmp_time

global jmp_cov_nourban ///
    $jmp_exp ///
    $jmp_humcap ///
    $jmp_job ///
    $jmp_enter ///
    $jmp_geo_nourban ///
    $jmp_time

********************************************************************************
*** 3. JMP DECOMPOSITION – POOLED SAMPLE
********************************************************************************

* Male wage equation (reference structure)
reg lhourly_income1 $jmp_cov_pooled if female == 0, vce(robust)
estimates store male_wage

* Female wage equation
reg lhourly_income1 $jmp_cov_pooled if female == 1, vce(robust)
estimates store female_wage

* JMP decomposition (males as reference)
jmpierce male_wage female_wage, ///
    reference(1) ///
    statistics(mean p10 p25 p50 p75 p90)



********************************************************************************
*** 4. JMP DECOMPOSITION – URBAN LABOUR MARKETS
********************************************************************************

* Male wage equation (urban)
reg lhourly_income1 $jmp_cov_nourban if female == 0 & urban == 1, vce(robust)
estimates store male_urban

* Female wage equation (urban)
reg lhourly_income1 $jmp_cov_nourban if female == 1 & urban == 1, vce(robust)
estimates store female_urban

* JMP decomposition (urban)
jmpierce male_urban female_urban, ///
    reference(1) ///
    statistics(mean p10 p25 p50 p75 p90)



********************************************************************************
*** 5. JMP DECOMPOSITION – RURAL LABOUR MARKETS
********************************************************************************

* Male wage equation (rural)
reg lhourly_income1 $jmp_cov_nourban if female == 0 & urban == 0, vce(robust)
estimates store male_rural

* Female wage equation (rural)
reg lhourly_income1 $jmp_cov_nourban if female == 1 & urban == 0, vce(robust)
estimates store female_rural

* JMP decomposition (rural)
jmpierce male_rural female_rural, ///
    reference(1) ///
    statistics(mean p10 p25 p50 p75 p90)

********************************************************************************
*** END: JMP DECOMPOSITION
********************************************************************************

log close
