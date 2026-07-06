/********************************************************************************
Project:       Gender Wage Inequality in Bhutan: Regional and Distributional Decompositions
Manuscript:    Journal of Asian Economics, ASIECO-D-25-00658R1
File:          03_table2_wage_gap_by_year.do

Purpose:       Computes yearly male and female mean and median log hourly wages, mean and median wage gaps, and associated significance tests for Table 2.

Data:          Bhutan Labour Force Survey, pooled 2011-2022 microdata.
Data access:   The raw/restricted LFS microdata are not distributed with this
               replication package because access is subject to permission from
               the official data provider. Authorised users should place the
               required dataset in the data/raw folder before running the code.

Input:         ${processed}/lfs_2011_2022_harmonised.dta
Output:        ${tables}/table2_wagegap_2011_2022.csv

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
log using "${logs}/03_table2_wage_gap_by_year.log", replace text

* Load the harmonised analysis-ready dataset created by 01_clean_harmonise_lfs.do.
use "${processed}/lfs_2011_2022_harmonised.dta", clear

*******************************************************
*** Table 2. Gender Wage Differences (2011–2022)
*** Mean/median log hourly wages by gender + significance tests
*** - Means and mean-gap p-values are SURVEY-WEIGHTED
*** - Medians are (by default) UNWEIGHTED
*** - Rank-sum p-values are UNWEIGHTED (standard Wilcoxon)
*******************************************************

*-----------------------------
* 0) USER SETTINGS (edit once)
*-----------------------------
local yvar   "lhourly_income1"     // your wage variable (excludes family workers by construction)
local wvar   "weight"              // survey weight variable name

* Recommended analytic sample (prime age + observed wage):
* local sample "inrange(age,25,65) & !missing(`yvar')"
* Minimal sample (matches your current output):
local sample "!missing(`yvar')"

* Basic checks
assert inlist(female,0,1) if `sample'
assert !missing(year)     if `sample'

*-----------------------------
* 1) Create results frame
*-----------------------------
capture frame drop wagegap
frame create wagegap
frame wagegap {
    clear
    set obs 0

    gen year = .
    gen N_male   = .
    gen N_female = .

    gen mean_male   = .
    gen mean_female = .
    gen mean_gap    = .   // male - female (log points)

    gen median_male   = .
    gen median_female = .
    gen median_gap    = . // male - female (log points)

    gen p_mean    = .     // p-value for mean difference (weighted regression)
    gen p_ranksum = .     // p-value for distribution difference (Wilcoxon)

    gen str8 p_mean_str    = ""
    gen str8 p_ranksum_str = ""
}

*-----------------------------
* 2) Loop through years
*-----------------------------
levelsof year if `sample', local(yrs)

foreach y of local yrs {

    di as txt "Processing year `y'..."

    * Sample sizes within wage sample (unweighted counts; standard to report N)
    quietly count if year==`y' & female==0 & `sample'
    local nmale = r(N)
    quietly count if year==`y' & female==1 & `sample'
    local nfemale = r(N)

    * Skip years without both groups
    if (`nmale'==0 | `nfemale'==0) continue

    *-----------------------------------------
    * WEIGHTED means by gender (recommended)
    *-----------------------------------------
    quietly mean `yvar' [aw=`wvar'] if year==`y' & female==0 & `sample'
    matrix M = r(table)
    local mean_m = M[1,1]

    quietly mean `yvar' [aw=`wvar'] if year==`y' & female==1 & `sample'
    matrix F = r(table)
    local mean_f = F[1,1]

    local gap_mean = `mean_m' - `mean_f'

    *-----------------------------------------
    * Mean-gap significance (WEIGHTED)
    * Use regression with robust SE; test female coefficient
    *-----------------------------------------
    quietly regress `yvar' female [aw=`wvar'] if year==`y' & `sample', vce(robust)
    quietly test female
    local pmean = r(p)

    *-----------------------------------------
    * Medians by gender (UNWEIGHTED default)
    *-----------------------------------------
    quietly summarize `yvar' if year==`y' & female==0 & `sample', detail
    local med_m = r(p50)

    quietly summarize `yvar' if year==`y' & female==1 & `sample', detail
    local med_f = r(p50)

    local gap_med = `med_m' - `med_f'

    *-----------------------------------------
    * Median/distribution difference significance (UNWEIGHTED)
    *-----------------------------------------
    quietly ranksum `yvar' if year==`y' & `sample', by(female)
    local prank = r(p)

    *-----------------------------------------
    * Format p-values for table display
    *-----------------------------------------
    local pmean_s = cond(missing(`pmean'), "", cond(`pmean'<0.001, "<0.001", string(`pmean',"%6.3f")))
    local prank_s = cond(missing(`prank'), "", cond(`prank'<0.001, "<0.001", string(`prank',"%6.3f")))

    *-----------------------------------------
    * Write to frame
    *-----------------------------------------
    frame wagegap {
        set obs `=_N+1'
        replace year       = `y'        in L
        replace N_male     = `nmale'    in L
        replace N_female   = `nfemale'  in L

        replace mean_male   = `mean_m'   in L
        replace mean_female = `mean_f'   in L
        replace mean_gap    = `gap_mean' in L

        replace median_male   = `med_m'   in L
        replace median_female = `med_f'   in L
        replace median_gap    = `gap_med' in L

        replace p_mean    = `pmean'   in L
        replace p_ranksum = `prank'   in L

        replace p_mean_str    = "`pmean_s'" in L
        replace p_ranksum_str = "`prank_s'" in L
    }
}

*-----------------------------
* 3) Format and display
*-----------------------------
frame wagegap {
    sort year
    format mean_male mean_female mean_gap median_male median_female median_gap %9.3f
}

set linesize 200
frame wagegap: list year N_male N_female ///
    mean_male mean_female mean_gap p_mean_str ///
    median_male median_female median_gap p_ranksum_str, noobs

* Optional export
frame wagegap: export delimited using "${tables}/table2_wagegap_2011_2022.csv", replace
*******************************************************

log close
