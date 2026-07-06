/********************************************************************************
Project:       Gender Wage Inequality in Bhutan: Regional and Distributional Decompositions
Manuscript:    Journal of Asian Economics, ASIECO-D-25-00658R1
File:          01_clean_harmonise_lfs.do

Purpose:       Prepares the harmonised analysis-ready Labour Force Survey dataset. It applies labels, constructs potential labour-market experience, constructs hourly wage measures, creates labour-force participation indicators, and generates the controls used in the regression and decomposition analysis.

Data:          Bhutan Labour Force Survey, pooled 2011-2022 microdata.
Data access:   The raw/restricted LFS microdata are not distributed with this
               replication package because access is subject to permission from
               the official data provider. Authorised users should place the
               required dataset in the data/raw folder before running the code.

Input:         ${raw}/lfs_2011_2022_pooled.dta
Output:        ${processed}/lfs_2011_2022_harmonised.dta

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
log using "${logs}/01_clean_harmonise_lfs.log", replace text

********************************************************************************
* STEP 1: LOAD CLEANED DATA
********************************************************************************

use "${raw}/lfs_2011_2022_pooled.dta", clear


********************************************************************************
* STEP 2: VARIABLE LABELING & VALUE LABELS (ROBUST + CONSISTENT NAMES)
********************************************************************************

* ---- Variable labels (safe)
capture label variable interview_ID     "Interview respondent ID"
capture label variable year             "Year of survey"
capture label variable income_pry       "Average monthly earnings (Nu.) from primary job"
capture label variable income_secondary "Average monthly earnings (Nu.) from secondary job"
capture label variable total_income     "Average total monthly income (Nu.)"
capture label variable age              "Age of the respondent"
capture label variable marital_status   "Marital status of the respondent"
capture label variable education_level  "Highest level of education achieved by respondent"
capture label variable hour_pry         "Total hours worked last week in primary job"
capture label variable hour_secondary   "Total hours worked last week in secondary job"
capture label variable total_hours      "Total weekly hours worked (primary + secondary)"
capture label variable work_informal    "Value 1 if respondent earns income from informal work"
capture label variable work_formal      "Value 1 if respondent earns income from formal work"
capture label variable employment_nature "Nature of respondent's employment"
capture label variable district         "District of residence"
capture label variable region           "Region of residence"
capture label variable urban            "Area of residence (1: Urban, 0: Rural)"
capture label variable job_type         "Type of enterprise where respondent works"
capture label variable attended_training "Attended any training (1: Yes, 0: No)"


/****************************************************************************************
* WORK EXPERIENCE COMPUTATION
*
* Potential labour-market experience is constructed using age and approximate years of
* schooling. Since the Labour Force Survey records highest educational qualification
* completed rather than exact years of schooling, approximate schooling years are assigned
* from the harmonised education-level variable. The experience variable follows the
* standard potential-experience formula:
*
*     Potential experience = Age − Approximate years of schooling − 6
*
* The value 6 represents the assumed age of entry into formal schooling. Respondents who
* are illiterate or have no schooling are assigned zero years of schooling. Religious
* studies are assigned a conservative approximation of six years. Negative values of
* potential experience are set to zero. The squared experience term is divided by 100
* to improve coefficient readability.
****************************************************************************************/

* Approximate years of schooling from highest education completed
capture drop years_schooling_approx
gen years_schooling_approx = .

replace years_schooling_approx = 0  if education_level == 1   // Illiterate/no schooling
replace years_schooling_approx = 3  if education_level == 2   // Non-formal education, approximate
replace years_schooling_approx = 6  if education_level == 3   // Elementary/Class 1-6
replace years_schooling_approx = 10 if education_level == 4   // Lower secondary/Class 7-10
replace years_schooling_approx = 12 if education_level == 5   // Higher secondary/vocational
replace years_schooling_approx = 16 if education_level == 6   // College/post-college
replace years_schooling_approx = 18 if education_level == 7   // Master's degree or above
replace years_schooling_approx = 6  if education_level == 8   // Religious studies, conservative approximation

* Recreate potential labour-market experience
capture drop formalwork_experience
gen formalwork_experience = age - years_schooling_approx - 6
replace formalwork_experience = 0 if formalwork_experience < 0 & !missing(formalwork_experience)

* Experience squared divided by 100
capture drop formalwork_experiencesq
gen formalwork_experiencesq = (formalwork_experience^2) / 100

label variable years_schooling_approx "Approx. years of schooling from education level"
label variable formalwork_experience "Potential labour-market experience"
label variable formalwork_experiencesq "Potential experience squared /100"

* Diagnostic checks
summ formalwork_experience formalwork_experiencesq years_schooling_approx
tab education_level, summarize(years_schooling_approx)
summ age years_schooling_approx formalwork_experience if formalwork_experience == 99


* ---- Marital status labels (DO NOT name the label the same as variable)
capture label define marstatlbl ///
    1 "Married" ///
    2 "Single/Never married" ///
    3 "Divorced/Separated" ///
    4 "Living together" ///
    5 "Widowed", replace
capture label values marital_status marstatlbl


* ---- Education labels (you defined earlier but never applied; apply here)
capture label define edulbl ///
    1 "Illiterate" ///
    2 "Non-formal education" ///
    3 "Elementary/Primary school" ///
    4 "Lower secondary (7–10)" ///
    5 "High school (11–12)/Vocational" ///
    6 "Bachelor's degree" ///
    7 "Master's degree and above" ///
    8 "Dratshang/Shedra/Patshala", replace
capture label values education_level edulbl


* ---- Employment nature labels (avoid naming collisions)
capture label define empnatlbl ///
    1 "Casual/contract worker" ///
    2 "Regular paid employee" ///
    3 "Family worker (agriculture)" ///
    4 "Family worker (non-agriculture)" ///
    5 "Own account worker (agriculture)" ///
    6 "Own account worker (non-agriculture)" ///
    7 "Not working", replace
capture label values employment_nature empnatlbl


* ---- Region labels (avoid naming collisions)
**capture label define regionlbl ///
    1 "Eastern region" ///
    2 "East central region" ///
    3 "West central region" ///
    4 "Western region", replace
**capture label values region regionlbl

drop region

gen region = .

* Western region
replace region = 1 if inlist(district, ///
    2,  /* Chhukha */ ///
    5,  /* Haa */ ///
    8,  /* Paro */ ///
    12, /* Samtse */ ///
    14) /* Thimphu */

* Central region
replace region = 2 if inlist(district, ///
    1,  /* Bumthang */ ///
    10, /* Punakha */ ///
    17, /* Trongsa */ ///
    18, /* Tsirang */ ///
    19) /* Wangdue Phodrang */

* Eastern region
replace region = 3 if inlist(district, ///
    6,  /* Lhuentse */ ///
    7,  /* Mongar */ ///
    9,  /* Pemagatshel */ ///
    15, /* Trashigang */ ///
    16) /* Trashi Yangtse */

* Southern region
replace region = 4 if inlist(district, ///
    3,  /* Dagana */ ///
    4,  /* Gasa */ ///
    11, /* Samdrup Jongkhar */ ///
    13, /* Sarpang */ ///
    20) /* Zhemgang */

label define regionlbl ///
    1 "Western" ///
    2 "Central" ///
    3 "Eastern" ///
    4 "Southern", replace

label values region regionlbl
label var region "Region of residence"


* ------------------------------------------------------------
* RECODE JOB TYPE: MERGE RESIDUAL CATEGORIES INTO FARMER
* ------------------------------------------------------------
replace job_type = 4 if inlist(job_type, 8, 9, 10)

label define enterpriselbl ///
    1 "NGO/INGO/CSO" ///
    2 "Civil services" ///
    3 "Armed forces" ///
    4 "Farmer" ///
    5 "Private business" ///
    6 "Private limited company" ///
    7 "Public/Government company", replace

label values job_type enterpriselbl

********************************************************************************
* STEP 3: RECODE & GENERATE VARIABLES
********************************************************************************

* ------------------------
* 3A) FEMALE INDICATOR
* ------------------------
* Goal: guarantee a clean female (0/1) variable without breaking if sex already absent.
capture confirm variable female
if _rc {
    capture confirm variable sex
    if !_rc {
        gen female = .
        * If already 0/1, keep as-is
        replace female = sex if inlist(sex,0,1)
        * If coded 1/2 (1=Male, 2=Female), convert
        replace female = 0 if sex==1 & missing(female)
        replace female = 1 if sex==2 & missing(female)
        drop sex
    }
}
capture label define femlbl 0 "Male" 1 "Female", replace
capture label values female femlbl
capture label variable female "Value 1 if respondent is female, 0 otherwise"


* ------------------------
* 3C) HOURLY WAGE (keep your logic, but make LN consistent with N)
* ------------------------
* IMPORTANT: Do not globally convert total_income==0 to 1 for everybody.
* Only create wages where hours and income are valid, so hourly_income and lhourly_income have matching N.

capture drop totalmonthly_hours hourly_income lhourly_income
gen totalmonthly_hours = (total_hours*52)/12 if total_hours>0 & total_hours<=168
label var totalmonthly_hours "Monthly hours (=weekly hours*52/12)"

gen hourly_income = . 
replace hourly_income = total_income/totalmonthly_hours if total_income>=0 & total_income<. ///
    & totalmonthly_hours>0 & totalmonthly_hours<.

* Floor extremely tiny positives (your intent), but never create wages from missing/zero hours
replace hourly_income = 1 if hourly_income>0 & hourly_income<1 & hourly_income<.

gen lhourly_income = ln(hourly_income) if hourly_income>0 & hourly_income<.
label variable hourly_income  "Average hourly earnings (Nu.)"
label variable lhourly_income "Log of average hourly earnings (Nu.)"


* ------------------------
* 3D) EVER-MARRIED (women only, your definition retained)
* ------------------------
capture drop married
gen married = 0
replace married = 1 if inlist(marital_status, 1, 3, 5) & female==1
label variable married "1 if respondent is married or ever married (women), 0 otherwise"


* ------------------------
* 3E) WORK NATURE (formal/informal)
* ------------------------
capture drop work_nature
gen work_nature = .
replace work_nature = 1 if work_formal==1
replace work_nature = 0 if work_formal==0 & !missing(work_formal)
label define worknatlbl 0 "Informal/Other" 1 "Formal", replace
label values work_nature worknatlbl
label var work_nature "Formal vs informal (derived from work_formal)"


* ------------------------
* 3F) COLLAPSED EMPLOYMENT NATURE (your coding retained)
* ------------------------
capture drop employment_nature1
recode employment_nature (1=1) (2=2) (3/6=3) (7=4), gen(employment_nature1)
label define empnat4lbl 1 "Casual/contract" 2 "Regular paid" 3 "Self/family work" 4 "Not working", replace
label values employment_nature1 empnat4lbl
label var employment_nature1 "Collapsed employment nature (4 groups)"


* ------------------------
* 3G) AGE SQUARED
* ------------------------
capture drop age_sq
gen age_sq = age^2
label var age_sq "Age squared"


********************************************************************************
* STEP 4: CREATE DUMMY VARIABLES
********************************************************************************

* Year dummies
tab year, gen(_year_)
label var _year_1  "Year = 2011"
label var _year_2  "Year = 2012"
label var _year_3  "Year = 2013"
label var _year_4  "Year = 2014"
label var _year_5  "Year = 2015"
label var _year_6  "Year = 2016"
label var _year_7  "Year = 2017"
label var _year_8  "Year = 2018"
label var _year_9  "Year = 2019"
label var _year_10 "Year = 2020"
label var _year_11 "Year = 2021"
label var _year_12 "Year = 2022"

* Work nature dummies
tab work_nature, gen(_work_nature_)
label var _work_nature_1 "Informal/Other"
label var _work_nature_2 "Formal"

* Marital status dummies
tab marital_status, gen(_marital_status)
label var _marital_status1 "Married"
label var _marital_status2 "Single/Never married"
label var _marital_status3 "Divorced/Separated"
label var _marital_status4 "Living together"
label var _marital_status5 "Widowed"

* Education level dummies
tab education_level, gen(_educlev_)
label var _educlev_1 "No schooling"
label var _educlev_2 "Non-formal education"
label var _educlev_3 "Elementary education"
label var _educlev_4 "Lower secondary (7–10)"
label var _educlev_5 "Higher secondary (11–12)/Vocational"
label var _educlev_6 "College or post-college"
label var _educlev_7 "Master's degree or above"
label var _educlev_8 "Religious studies"

tab job_type, gen(_jobtype_)

rename _jobtype_1  NGOs
rename _jobtype_2  civil_service
rename _jobtype_3  armed_forces
rename _jobtype_4  farmer
rename _jobtype_5  private_business
rename _jobtype_6  private_company
rename _jobtype_7  state_owned

label var NGOs              "NGO / INGO / CSO"
label var civil_service     "Civil service"
label var armed_forces      "Armed forces"
label var farmer            "Farmer"
label var private_business  "Private business"
label var private_company   "Private limited company"
label var state_owned       "Public / Government company"


tab employment_nature, gen(_emplnature_)
capture label var _emplnature_1 "Casual/contract worker"
capture label var _emplnature_2 "Regular paid employee"
capture label var _emplnature_3 "Family worker (agriculture)"
capture label var _emplnature_4 "Family worker (non-agriculture)"
capture label var _emplnature_5 "Own-account worker (agriculture)"
capture label var _emplnature_6 "Own-account worker (non-agriculture)"

capture rename _emplnature_1 contract_worker
capture rename _emplnature_2 regular_paid
capture rename _emplnature_3 familyworker_agri
capture rename _emplnature_4 familyworker_nonagri
capture rename _emplnature_5 ownaccountworker_agri
capture rename _emplnature_6 ownaccountworker_nonagri

* Region dummies
capture drop western_region central_region eastern_region southern_region

gen western_region  = region == 1 if !missing(region)
gen central_region  = region == 2 if !missing(region)
gen eastern_region  = region == 3 if !missing(region)
gen southern_region = region == 4 if !missing(region)

label var western_region  "Western region"
label var central_region  "Central region"
label var eastern_region  "Eastern region"
label var southern_region "Southern region"

* Relationship dummies
tab relationship, gen(_relationship_)
label var _relationship_1 "Head of household"
label var _relationship_2 "Spouse"
label var _relationship_3 "Son/Daughter"
label var _relationship_4 "Brother/Sister"
label var _relationship_5 "Father/Mother"
label var _relationship_6 "Other relative"
label var _relationship_7 "Non-relative"


********************************************************************************
* STEP 5: RENAME DUMMY VARIABLES
********************************************************************************
rename _year_1  dyear_2011
rename _year_2  dyear_2012
rename _year_3  dyear_2013
rename _year_4  dyear_2014
rename _year_5  dyear_2015
rename _year_6  dyear_2016
rename _year_7  dyear_2017
rename _year_8  dyear_2018
rename _year_9  dyear_2019
rename _year_10 dyear_2020
rename _year_11 dyear_2021
rename _year_12 dyear_2022

rename _work_nature_1 informal_sector
rename _work_nature_2 formal_sector

rename _educlev_1 illeterate
rename _educlev_2 non_formal
rename _educlev_3 elementary_level
rename _educlev_4 lower_secondary
rename _educlev_5 higher_secondary
rename _educlev_6 college_level
rename _educlev_7 atleast_masterdegree
rename _educlev_8 religious_studies


rename _relationship_1 Head
rename _relationship_2 Spouse
rename _relationship_3 Son_Daughter
rename _relationship_4 Bro_Sister
rename _relationship_5 Father_Mother
rename _relationship_6 Other_relative
rename _relationship_7 Non_relative

rename _marital_status1 Married
rename _marital_status2 Single_Never_Married
rename _marital_status3 Divorced_seperated
rename _marital_status4 Living_together
rename _marital_status5 Widowed


********************************************************************************
* STEP 6: LFP AND LEGACY WAGE VARS (ROBUST TO NUMERIC Employed)
********************************************************************************

* ------------------------------------------------------------------
* 6A. Harmonize employment status (numeric vs string)
* ------------------------------------------------------------------
capture drop Employed1
capture confirm numeric variable Employed

if !_rc {
    * If Employed is numeric: assume 1=employed, 0=not employed
    gen Employed1 = .
    replace Employed1 = 3 if Employed==1
    replace Employed1 = 1 if Employed==0
}
else {
    * If Employed is string: encode safely
    encode Employed, gen(Employed1)
}

capture label define Employed1lbl ///
    1 "Not employed" ///
    2 "Out of labour force" ///
    3 "Employed", replace

capture label values Employed1 Employed1lbl
label var Employed1 "Employment status (harmonized 3-category)"


* ------------------------------------------------------------------
* 6B. Labour force participation variables
* ------------------------------------------------------------------
capture drop LFP1 LFP2 lhourly_income1

* --- LFP2: Broad participation (includes family workers)
gen LFP2 = .
replace LFP2 = 1 if Employed1==3
replace LFP2 = 0 if inlist(Employed1,1,2)

label var LFP2 ///
"Labour force participation (including family workers)"

* --- LFP1: Restricted participation (excludes family workers)
gen LFP1 = LFP2
replace LFP1 = . if familyworker_agri==1 | familyworker_nonagri==1

label var LFP1 ///
"Labour force participation (excluding family workers)"


* ------------------------------------------------------------------
* 6C. Wage variable aligned with restricted sample
* ------------------------------------------------------------------
gen lhourly_income1 = lhourly_income
replace lhourly_income1 = . if ///
    familyworker_agri==1 | familyworker_nonagri==1

label var lhourly_income1 ///
"Log hourly earnings (excluding family workers)"


********************************************************************************
* STEP 7: QUICK VALIDATION CHECKS
********************************************************************************

* A) Check labeled categorical variables
tab marital_status, missing
tab education_level, missing
tab employment_nature, missing
tab region, missing
tab job_type, missing

* B) Check consistency of employment variable
tab year Employed, missing

* C) Ensure wage variables have consistent observations
count if !missing(hourly_income)
count if !missing(lhourly_income)

* D) Hours sanity check
count if total_hours>168 & !missing(total_hours)

********************************************************************************
* END OF CLEANING SCRIPT
********************************************************************************

********************************************************************************
* STEP 8: SAVE HARMONISED ANALYSIS-READY DATASET
********************************************************************************

save "${processed}/lfs_2011_2022_harmonised.dta", replace

log close
