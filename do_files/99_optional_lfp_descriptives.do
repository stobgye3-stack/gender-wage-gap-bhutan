/********************************************************************************
Project:       Gender Wage Inequality in Bhutan: Regional and Distributional Decompositions
Manuscript:    Journal of Asian Economics, ASIECO-D-25-00658R1
File:          99_optional_lfp_descriptives.do

Purpose:       Optional exploratory labour-force participation descriptives and graphs. This script is retained for transparency but is not required to reproduce the final manuscript tables.

Data:          Bhutan Labour Force Survey, pooled 2011-2022 microdata.
Data access:   The raw/restricted LFS microdata are not distributed with this
               replication package because access is subject to permission from
               the official data provider. Authorised users should place the
               required dataset in the data/raw folder before running the code.

Input:         ${processed}/lfs_2011_2022_harmonised.dta
Output:        Optional Stata output and graphs; not part of the core replication sequence

How to use:    This script is designed to be run from 00_master.do after the
               project folder globals are defined. It can also be run separately
               after updating the project path below if required. The script uses
               relative paths only; no personal computer paths are required.

Important:     The empirical logic follows the working code used for the paper.
               Revisions made for this replication package are limited to
               documentation, relative paths, standardised output locations, and
               consistent section headings.
Core status:    Optional; not called by 00_master.do.

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
log using "${logs}/99_optional_lfp_descriptives.log", replace text

* Load the harmonised analysis-ready dataset created by 01_clean_harmonise_lfs.do.
use "${processed}/lfs_2011_2022_harmonised.dta", clear


//*****Summary statistics and graph for Labour Force Participation from year 2014 till 2019 by all sectors

egen femaleLFP = total(LFP) if female==1, by(year) 
egen maleLFP = total(LFP) if female==0, by(year)


bys year : asdoc tabstat femaleLFP, stat(N mean) columns(statistics) replace	

bys year : asdoc  tabstat maleLFP, stat(N mean) columns(statistics) append

twoway connected femaleLFP maleLFP year, sort lwidth(thin thin) msymbol(Oh S)


//*****Summary statistics and graph for Labour Force Participation from year 2014 till 2019 for the sectors affected by MWP

egen femaleLFP1 = total(LFP) if female ==1 & farmer==1 | private_business==1 | private_company ==1, by(year) 
egen maleLFP1 = total(LFP) if female ==0 & farmer==1 | private_business==1 | private_company ==1, by(year) 

bys year : asdoc tabstat femaleLFP1, stat(N mean) columns(statistics) replace	

bys year : asdoc  tabstat maleLFP1, stat(N mean) columns(statistics) append

twoway (line femaleLFP1 year) (line maleLFP1 year)


//*****Summary statistics and graph for Labour Force Participation from year 2014 till 2019 for the sectors affected by MWP and by region

****Urban

egen femaleLFP2 = total(LFP) if female ==1 & urban == 1 & farmer==1 | private_business==1 | private_company ==1, by(year) 
egen maleLFP2 = total(LFP) if female ==0 & urban == 1 & farmer==1 | private_business==1 | private_company ==1, by(year) 

bys year : asdoc tabstat femaleLFP2, stat(N mean) columns(statistics) replace	

bys year : asdoc  tabstat maleLFP2, stat(N mean) columns(statistics) append

line femaleLFP2 maleLFP2  year, legend(size(small))


****Rural

egen femaleLFP3 = total(LFP) if female ==1 & urban == 0 & farmer==1 | private_business==1 | private_company ==1, by(year) 
egen maleLFP3 = total(LFP) if female ==0 & urban == 0 & farmer==1 | private_business==1 | private_company ==1, by(year) 

bys year : asdoc tabstat femaleLFP3, stat(N mean) columns(statistics) replace	

bys year : asdoc  tabstat maleLFP3, stat(N mean) columns(statistics) append

line femaleLFP3 maleLFP3  year, legend(size(small))


* Examine relationship between wage (outcome variable) and explanatory variables:

* What pattern do you notice in the mean wage, as years of education and years of experience rise?
mean (lhourly_income1), over (education_level)
mean (lhourly_income1), over (work_experience)

bysort educ: egen m_lwage= mean (lhourly_income1)
twoway scatter m_lwage education_level

bysort work_experience: egen m_lwage1= mean (lhourly_income1)
twoway scatter m_lwage1 work_experience


* Is there a significant difference in the wage rate of female and male individuals?
mean (lhourly_income1), over (female)


* Is there a significant difference in the wage rate of people who live in the urban areas and those who do not?
mean (lhourly_income1), over (urban)

* Is there a significant difference in the wage rate across the 4 regions
mean (lhourly_income1), over (region*)

//work experience squared 
quietly reg $y1list $x1list $x2list $x3list $x4list $x5list $x6list $x7list [aw=weight]
margins, at ( work_experience=(0(2)54) (mean) $x1list $x2list $x3list $x4list $x5list $x6list $x7list) 
marginsplot, noci


//age squared 
quietly reg $y1list $x1list $x2list $x3list $x4list $x5list $x6list $x7list [aw=weight]
margins, at (age=(15(1)65) (mean) $x1list $x2list $x3list $x4list $x5list $x6list $x7list) 
marginsplot, noci



****TABLE:Summary Statistics

///Overall mean summary Statistics (Year 2012 to 2019, between age 15 to 64)

****select variables for working-age population only (15-65)
		
	drop if age<15|age>65

bys year : asdoc sum , stat(N mean ) replace	

///summary statistics by year and area of residence

bysort year: asdoc sum if urban == 1, replace

bysort year: asdoc sum if urban == 0, replace


****TABLE: Mean of total monthly income by gender (Table 3)

asdoc table year female , contents (mean total_income freq ) col replace
   
       
****TABLE: Mean of total monthly income by gender and by formal sector

asdoc table year female if work_formal ==1 , contents(mean total_income freq ) col replace
asdoc table year female if work_informal ==1 , contents(mean total_income freq ) col append

****TABLE: Percentage of labor force by gender and individuals characteristics

asdoc sum by female , contents (mean total_income freq ) col replace


****Kernal density
// kernel density estimates across years 2012 and 2013
kdensity lhourly_income1 if year == 2012, addplot(kdensity lhourly_income1 if year == 2013)legend(ring(0) pos(2) label(1 "2012") label(2 "2013"))

//by sex
kdensity lhourly_income1 if female == 1, addplot(kdensity lhourly_income1 if female == 0)legend(ring(0) pos(2) label(1 "female") label(2 "male"))



***Table  HECKMAN MLE WITH YEAR DUMMY BUT WITHOUT POLIY AND INTERACTION VARIABLES by sector

  heckman $y1list $x1list $x2list $x4list $x5list $x6list $x7list if formal_sector==1, ///
      select (LFP1 = $x1list $x2list $x4list $x5list $x7list  ///
	       married HH_head) vce(robust)
  outreg2 using Heckman1.doc, replace ctitle(MLE1)
  
****Summary Statistics
   
 *****Smmary statistics from OLS
 
  quietly: reg $y1list $x1list $x2alist $x3list $x5list $x6list $x7list 
  asdoc estat summarize, replace

log close
