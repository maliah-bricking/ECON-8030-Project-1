# ECON-8030-Project-1
# Bricking Project 1

This project analyzes GDP per capita growth and its relationship to selected
economic and governance indicators. The analysis is implemented in R.

## Project structure

All files are currently in one folder; the script reads inputs and writes
outputs relative to the R working directory.

| File | Purpose |
| --- | --- |
| `ECON8030 Bricking Project 1.r` | Analysis and figure-generation script |
| `gdp_per_capita_growth_rates.csv` | Country-by-year GDP per capita growth rates |
| `gdp_per_capita_growth_trajectories.png` | Recent country growth trajectories |
| `project1_part3_gdp_growth_summary.png` | Part 3 summary figure included with the project |
| `project1_part4_*.png` | Part 4 country-level and annual-average comparison plots and correlation-matrix figures |

Running the script also writes
`project1_part4_average_country_correlation_matrix.csv` and
`project1_part4_average_country_growth_correlation_matrix.csv` to the working
directory. These CSVs may not be present until the script has been run.

The Part 3 summary image is included as a project deliverable, but the current R
script only calculates and displays the Part 3 summary table; it does not
generate that PNG.

## Data sources and preprocessing

The first workbook is an extract from the World Bank's World Development
Indicators (WDI). The analyses use the following series:

- GDP per capita (constant 2015 US$)
- Unemployment, total (% of total labor force) (modeled ILO estimate)
- Control of Corruption - Governance score (0-100)
- Foreign direct investment, net outflows (% of GDP)
- Population growth (annual %)

The Part 3 and Part 4 Excel workbooks provide the inputs for those respective
analyses. The original extraction queries, download dates, and any upstream
transformations for these workbooks are not recorded in the project files.
Consequently, the work is reproducible from the included workbook snapshots,
but rebuilding those snapshots from the original online source requires that
additional provenance.

The R script:

1. Converts year columns from wide to long form and converts year labels to
   integers.
2. Parses indicator values as numbers, treating blank cells and WDI's `..`
   missing-value marker as missing where applicable.
3. Calculates annual GDP per capita growth as
   `100 * (current-year value / prior-year value - 1)`.
4. For the recent-growth output, uses the last 15 year columns in the WDI
   extract. The prior year is retained for the lag calculation, so the first
   displayed growth year depends on the preceding year's GDP value.
5. For Part 3, groups calculated growth observations into pre-1990,
   1990-2007, and 2008-onward periods, then calculates the mean growth rate
   and observation count for each period.
6. For Part 4, pairs each country's GDP per capita with each comparison
   indicator, omitting rows where either value is missing. It also calculates
   annual averages across the countries with paired observations and creates
   correlation matrices using pairwise complete observations.

Part 4 calculates GDP per capita growth only when consecutive years are
available for that country. Its growth-correlation matrix correlates the
annual average growth rate with the four comparison indicators' annual
country averages.

## Replicating the analysis

### Requirements

- R 4.1 or later (the script uses the native pipe and shorthand function
  syntax).
- The R packages `readxl`, `dplyr`, `tidyr`, `readr`, `ggplot2`, and
  `stringr`.

The script contains `install.packages()` calls for these packages. Package
installation requires an internet connection if a package is not already
installed. It calls `stringr::str_wrap()` but does not install `stringr`, so
install that package separately if needed:

```r
install.packages("stringr")
```

### Steps

1. Place all three `.xlsx` input files and the `.r` script in the same folder.
2. In R or RStudio, set the working directory to that folder. For example:

   ```r
   setwd("C:/path/to/your/Bricking Project 1")
   ```

3. Run the complete script:

   ```r
   source("ECON8030 Bricking Project 1.r")
   ```

4. Find the generated CSV and PNG outputs in the working directory. The script
   also prints plots and opens intermediate tables in an interactive R
   session.

The input workbook names and expected column labels are referenced directly by
the script, so keep the names unchanged unless you also update the script.
Rerunning it overwrites files with matching output names.
