# Changelog

## v1.0.0: three-survey data report, rerunnable R scripts and a source check (2026-10-01)

First tagged release.

- The report, three R scripts and three figures are in the repository.
- Every number in the report was checked against the survey files and questionnaires that were available. Corrections made:
  - The anti-CRT item asks about laws limiting "divisive concepts", so the report now says that.
  - The RPS Wave 1 survey covers White parents of White children, so the report now says that.
  - The BLM "understanding" item is self-reported, so the report no longer says respondents "accurately described" BLM's goals.
  - The party-identification sentence now gives the coefficients behind it.
  - The 7-point scale is labeled agree/disagree, as fielded.
- `03_figures_blm.R` was missing a `+`, so its theme never applied. Fixed, and Figure 4 is regenerated.
- Scripts write to `figures/`, stop with a clear message when a data file is missing, and no longer use the deprecated `geom_errorbarh`.
- Added the MIT license, run steps and a Limitations section to the README.
