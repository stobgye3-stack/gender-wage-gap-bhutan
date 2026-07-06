********************************************************************************
* Project:       Gender Wage Inequality in Bhutan: Regional and Distributional Decompositions
* Manuscript:    Journal of Asian Economics, ASIECO-D-25-00658R1
* File:          00_master.do
*
* Purpose:       Master replication script. It defines folder paths, checks required
*                Stata packages, and runs the analysis scripts in sequence.
*
* Data access:   Raw Labour Force Survey microdata are not included. Authorised users
*                must place the pooled data file in data/raw using the filename:
*                lfs_2011_2022_pooled.dta
*
* How to use:    1. Open Stata.
*                2. Change directory to the root folder of this repository.
*                3. Run: do 00_master.do
*
* Article authors:
*                Dr Sonam Tobgye
*                Professor Simon Feeny
*                Professor Preety Pratima Srivastava
*
* Code author:   Dr Sonam Tobgye
* Software:      Stata 17 or later
* Last updated:  July 2026
********************************************************************************

clear all
set more off
version 17

********************************************************************************
* 0. DEFINE PROJECT PATHS
********************************************************************************

* If running from the root folder of the cloned repository, keep this as ".".
* Otherwise, replace "." with the full path to the repository folder.
global project "."

global raw       "${project}/data/raw"
global processed "${project}/data/processed"
global dofiles   "${project}/do_files"
global tables    "${project}/outputs/tables"
global logs      "${project}/outputs/logs"

capture mkdir "${project}/outputs"
capture mkdir "${tables}"
capture mkdir "${logs}"
capture mkdir "${project}/data"
capture mkdir "${processed}"

********************************************************************************
* 1. CHECK REQUIRED USER-WRITTEN PACKAGES
********************************************************************************

cap which esttab
if _rc ssc install estout, replace

cap which estpost
if _rc ssc install estout, replace

cap which oaxaca
if _rc ssc install oaxaca, replace

cap which jmpierce
if _rc ssc install jmpierce, replace

********************************************************************************
* 2. RUN CORE REPLICATION SCRIPTS
********************************************************************************

do "${dofiles}/01_clean_harmonise_lfs.do"
do "${dofiles}/02_summary_statistics.do"
do "${dofiles}/03_table2_wage_gap_by_year.do"
do "${dofiles}/04_main_wage_models_decompositions.do"
do "${dofiles}/05_jmp_decomposition.do"
do "${dofiles}/06_robustness_age_15_65.do"
do "${dofiles}/07_robustness_family_agri_workers.do"

********************************************************************************
* Optional exploratory file not required for final manuscript tables:
* do "${dofiles}/99_optional_lfp_descriptives.do"
********************************************************************************

display "Replication scripts completed. Please check outputs/tables and outputs/logs."
