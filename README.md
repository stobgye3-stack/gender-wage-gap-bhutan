# Gender Wage Inequality in Bhutan: Stata Replication Code

This repository contains the Stata replication code for the article:

**Gender Wage Inequality in Bhutan: Regional and Distributional Decompositions**  
Manuscript number: **ASIECO-D-25-00658R1**  
Journal: **Journal of Asian Economics**

The code reproduces the main empirical analysis, including data harmonisation, summary statistics, wage regressions, Heckman sample-selection models, Blinder-Oaxaca decompositions, Juhn-Murphy-Pierce decompositions, and robustness checks.

## Authors

**Article authors**  
Dr Sonam Tobgye  
Professor Simon Feeny  
Professor Preety Pratima Srivastava

**Code author and maintainer**  
Dr Sonam Tobgye

## Repository purpose

The purpose of this repository is to improve transparency and reproducibility by providing the Stata code used in the analysis. The raw Labour Force Survey microdata are **not included** in this repository because access and redistribution are subject to permission from the official data provider.

Researchers who obtain authorised access to the Labour Force Survey data can use this repository to reproduce the analysis by placing the required data file in the appropriate folder and running the master script.

## Data access

This study uses Bhutan Labour Force Survey microdata for the period **2011–2022**. The data are administered by the official data provider and are not redistributed in this repository.

To replicate the analysis, authorised users should request access to the relevant Labour Force Survey files from the official data provider. After access is granted, users should prepare or place the pooled dataset in the following folder:

```text
data/raw/lfs_2011_2022_pooled.dta
```

The code assumes that the pooled input file is named:

```text
lfs_2011_2022_pooled.dta
```

If the file name differs, users should either rename the file or update the input filename in `01_clean_harmonise_lfs.do`.

## Software requirements

The replication code is written for **Stata 17 or later**.

The following user-written Stata packages may be required depending on the script being run:

- `estout` / `esttab`
- `outreg2`
- `oaxaca`
- any additional user-written decomposition commands used in the JMP analysis

The master script checks for selected required packages and installs them from SSC where possible. If a package is unavailable through SSC, users should install it manually following the relevant package documentation.

## Repository structure

```text
stata_replication_code_professional/
│
├── 00_master.do
├── README.md
├── data_access.md
│
├── do_files/
│   ├── 01_clean_harmonise_lfs.do
│   ├── 02_summary_statistics.do
│   ├── 03_table2_wage_gap_by_year.do
│   ├── 04_main_wage_models_decompositions.do
│   ├── 05_jmp_decomposition.do
│   ├── 06_robustness_age_15_65.do
│   ├── 07_robustness_family_agri_workers.do
│   └── 99_optional_lfp_descriptives.do
│
├── data/
│   ├── raw/
│   │   └── README_place_raw_data_here.txt
│   └── processed/
│       └── README_processed_data_created_by_code.txt
│
├── outputs/
│   ├── tables/
│   └── logs/
│
└── docs/
    └── variable_construction_notes.md
```

## Main replication workflow

The main file is:

```text
00_master.do
```

This is the central replication control file. It defines the project folder structure, checks required Stata packages, creates output folders, and runs the analysis scripts in sequence.

To run the replication code:

1. Download or clone this repository.
2. Place the restricted pooled Labour Force Survey dataset in:

```text
data/raw/lfs_2011_2022_pooled.dta
```

3. Open Stata.
4. Set the working directory to the root folder of this repository. For example:

```stata
cd "path/to/stata_replication_code_professional"
```

5. Run the master file:

```stata
do 00_master.do
```

Outputs will be written to:

```text
outputs/tables/
outputs/logs/
```

## Description of Stata scripts

### `00_master.do`

Central replication file. Defines project paths, creates required folders, checks Stata packages, opens a log file, and runs the main scripts in sequence.

### `01_clean_harmonise_lfs.do`

Prepares the harmonised Labour Force Survey dataset. This script constructs the main variables used in the empirical analysis, including the hourly wage variable, labour-force participation indicators, education variables, employment characteristics, region indicators, and potential labour-market experience.

Potential labour-market experience is calculated as:

```text
age − approximate years of schooling − 6
```

Approximate years of schooling are assigned from the respondent’s highest educational qualification. The squared experience term is divided by 100 for coefficient readability.

### `02_summary_statistics.do`

Produces descriptive statistics used in the manuscript and supporting tables.

### `03_table2_wage_gap_by_year.do`

Generates annual gender wage gap summary statistics, including mean and median wage gaps by year, t-tests, and rank-sum tests.

### `04_main_wage_models_decompositions.do`

Runs the main OLS wage regressions, Heckman sample-selection models, marginal effects, and Blinder-Oaxaca decompositions for the pooled, urban, and rural samples.

### `05_jmp_decomposition.do`

Runs the Juhn-Murphy-Pierce decomposition to examine the gender wage gap across the wage distribution.

### `06_robustness_age_15_65.do`

Runs robustness checks using the broader age sample of individuals aged 15–65.

### `07_robustness_family_agri_workers.do`

Runs robustness checks using an expanded labour-force participation definition that includes family and agricultural workers.

### `99_optional_lfp_descriptives.do`

Optional supplementary script for additional labour-force participation descriptives. This file is not part of the main replication sequence unless explicitly called by the user.

## Important notes

- The raw microdata are not included in this repository.
- Do not upload `.dta` files or other restricted data files to GitHub.
- The scripts are designed to be run from `00_master.do`.
- If running scripts individually, ensure that the global paths are already defined or run `00_master.do` first.
- Output files may be overwritten when the scripts are rerun.

## Data confidentiality and redistribution

The authors do not have permission to redistribute the raw Labour Force Survey microdata. This repository therefore provides code and documentation only. Replication is possible for researchers with authorised access to the underlying data.

## Suggested citation

If using this code, please cite the associated article:

Tobgye, S., Feeny, S., & Srivastava, P. P. *Gender Wage Inequality in Bhutan: Regional and Distributional Decompositions*. Journal of Asian Economics, manuscript ASIECO-D-25-00658R1.

A DOI for the replication code may be added after archiving the final repository through Zenodo.

## Contact

For questions about the code, please contact:

Dr Sonam Tobgye  
School of Economics, Finance and Marketing  
RMIT University

stobgye3@gmail.com
