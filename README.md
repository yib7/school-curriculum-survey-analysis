# How Survey Framing and Partisan Identity Shape American Views on Race in Education

A data report written for GOVT 394, Directed Research in William & Mary's Public Opinion Polling Lab (Spring 2026). It analyzes three U.S. surveys on how K-12 schools teach about race and racism, using OLS regression in R.

[Read the full report (PDF, 5 pages)](race_education_data_report.pdf)

## Findings

![Support for teaching race and racism by question wording and vote intention](figures/plot1_trump_framing_interaction.png)

- CCES 2023 wording experiment: average support on a 7-point agreement scale ranged from 5.39 when students were "allowed" to learn the history of race and racism to 4.62 when they were "required" to learn about present-day race and racism. Respondents who said they would vote for Trump drove that 0.77-point gap. Their support fell 1.73 points (4.57 to 2.84), while everyone else stayed between 5.61 and 5.90.
- VAND0049, laws limiting the teaching of "divisive concepts": 59.5% of respondents opposed them. In the report's regression, agreeing that schools should teach race even when it is uncomfortable, and saying that talking with children about race is important, went with opposing the laws. Agreeing that teaching race undermines America's founding ideals went with supporting them. Gender had no significant effect.
- RPS Wave 1, BLM support among White parents: 65.6% supported the movement. Teaching children about the privileges of being White had the largest positive coefficient (+0.153) and teaching that Black people should be more respectful to police had the largest negative one (-0.158).

## The data

| Survey | Respondents | Fielded | Who answered |
| --- | --- | --- | --- |
| CCES 2023 Vanderbilt module | 1,000 | 2023 | U.S. adults, random assignment to four wordings per experiment |
| VAND0049 (YouGov race socialization survey) | 4,502 | Apr 30 to May 20, 2025 | White, Black and Hispanic adults, with parents of 5-17 year olds sampled separately |
| RPS Wave 1 | 1,083 (1,052 analyzed) | Dec 2020 | White parents whose children aged 5-18 are all White |

I removed non-response codes before fitting each model. All estimates are unweighted.

## Run the analysis

The survey files are not in this repository. If you have them, the scripts rerun from the repository root.

1. Install R (written and tested with 4.5.1) and the packages: `install.packages(c("haven", "dplyr", "ggplot2", "broom"))`
2. Create a `data/` folder at the repository root and add `CCES23_VAN_OUTPUT.sav`, `VAND0049_OUTPUT_numeric.csv` and `RPS Wave 1.csv`.
3. Run `Rscript analysis/01_survey_analysis.R` for the summary tables and regressions.
4. Run `Rscript analysis/02_figures_framing_and_crt.R` and `Rscript analysis/03_figures_blm.R` to rebuild the figures in `figures/`.

A script stops with a message naming any missing file.

## Repository contents

| Path | Contents |
| --- | --- |
| `race_education_data_report.pdf` | The full report |
| `analysis/01_survey_analysis.R` | Summary statistics and regressions for all three surveys |
| `analysis/02_figures_framing_and_crt.R` | Figures 2 and 3: the framing interaction and anti-CRT stance by party |
| `analysis/03_figures_blm.R` | Figure 4: parental socialization coefficients for BLM support |
| `figures/` | The figures used in the report |

## Limitations

- The estimates are unweighted. VAND0049 samples White, Black and Hispanic adults and parents separately, so its percentages describe that sample, not the U.S. population.
- RPS Wave 1 covers only White parents of White children, surveyed in December 2020. Its BLM numbers say nothing about the general public.
- The models are observational OLS fits on short ordinal scales. The parent items show who holds which views, not what the conversations cause.
- The CCES vote-intention question asked about the 2024 election before it happened.
- There are no automated tests, and the survey data cannot be published, so nobody can rerun the analysis without access to the files.

## Data credit

The survey data were collected by Allison Anoll, Andrew Engelhardt and Mackenzie Israel-Trummel. The analysis, figures and report are my own work, released under the MIT License.

## Author

Yibarek Tadesse, B.S. Computer Science, William & Mary (2026)
