/********************************************************************************
Project:       Gender Wage Inequality in Bhutan: Regional and Distributional Decompositions
Manuscript:    Journal of Asian Economics, ASIECO-D-25-00658R1
File:          02_summary_statistics.do

Purpose:       Generates the summary statistics for the prime-age analysis sample (ages 25-65), corresponding to the descriptive appendix table used in the paper.

Data:          Bhutan Labour Force Survey, pooled 2011-2022 microdata.
Data access:   The raw/restricted LFS microdata are not distributed with this
               replication package because access is subject to permission from
               the official data provider. Authorised users should place the
               required dataset in the data/raw folder before running the code.

Input:         ${processed}/lfs_2011_2022_harmonised.dta
Output:        Stata estimates stored in memory; log file records results

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
log using "${logs}/02_summary_statistics.log", replace text

* Load the harmonised analysis-ready dataset created by 01_clean_harmonise_lfs.do.
use "${processed}/lfs_2011_2022_harmonised.dta", clear

/********************************************************************
* TABLE A2: SUMMARY STATISTICS
* Prime-age sample (25–65)
********************************************************************/

****************************************************
* SAMPLE RESTRICTION
****************************************************
preserve
keep if age >= 25 & age <= 65

****************************************************
* KEY VARIABLES ONLY (NO RENAMING)
****************************************************
global desc_vars ///
    lhourly_income1 ///
    LFP2 ///
	female ///
	year ///
    Married ///
    formalwork_experience ///
    attended_training ///
    illeterate ///
    non_formal ///
    elementary_level ///
    lower_secondary ///
    higher_secondary ///
    college_level ///
    atleast_masterdegree ///
    religious_studies ///
    hh_children ///
    hh_elderly ///
    hh_adult_male ///
    hh_adult_female ///
    hh_female_head ///
    informal_sector ///
    formal_sector ///
    contract_worker ///
    regular_paid ///
    ownaccountworker_agri ///
    urban ///
    eastern_region ///
    central_region ///
    southern_region ///
    western_region

****************************************************
* OVERALL MIN / MAX / MEAN
****************************************************
estpost summarize ///
    $desc_vars

estimates store overall

*************************************
* END: TABLE A2 – SIMPLE SUMMARY STATS
********************************************************************/


restore

log close
