# =============================================================================
# SUPPLEMENTAL VISUALIZATIONS 2 — Race Education Survey Data Report
# Author: Yibarek Tadesse
#
# Three new plots, each visualizing a core claim the written report makes
# but that no existing chart yet shows:
#
#  PLOT 3 | "Which family conversations actually predicted BLM support?"
#           Dot-and-whisker coefficient plot of the 7 parental socialization
#           variables (Q37_1 through Q37_7) from the RPS Wave 1 regression.
#           Directly supports the report's parental socialization argument.

library(dplyr)
library(ggplot2)
library(broom)   # tidy() extracts regression coefficients into a clean data frame

# --- Output folder (create if missing) --------------------------------------
output_dir <- "figures"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
  cat(paste0("Created output folder: ", output_dir, "/\n"))
} else {
  cat(paste0("Output folder already exists: ", output_dir, "/\n"))
}

# ---- File paths (update to match your local setup) -------------------------
path_rps <- "data/RPS Wave 1.csv"
# ----------------------------------------------------------------------------

# Stop with a clear message if the survey files are not in data/ (they are not published here).
# Run this script from the repository root so the relative paths below resolve.
missing_files <- c(path_rps)
missing_files <- missing_files[!file.exists(missing_files)]
if (length(missing_files) > 0) {
  stop("Missing data file(s): ", paste(missing_files, collapse = ", "),
       "
Put the survey files in data/ at the repository root and run from there (see README).",
       call. = FALSE)
}


# =============================================================================
# PLOT 3: Parental Socialization Coefficient Plot (RPS Wave 1 / BLM)
#
# The report finds that parents who taught about White privilege (+0.153),
# equality (+0.092) and important historical figures (+0.073) were more
# supportive of BLM, while parents who taught that Black people should be more
# respectful to police (-0.158) were less supportive. This plot shows the OLS
# coefficient for each of the seven Q37 items (frequency of telling, 1-4),
# with 95% confidence intervals.
#
# HOW TO READ IT:
#   - Each dot is the estimated effect of that parental topic on BLM support
#     (Q26, 1-4 scale), holding all other variables constant.
#   - Bars extending RIGHT of zero = more of that parental message -> higher
#     BLM support. Bars extending LEFT = lower BLM support.
#   - Dots whose confidence interval does NOT cross zero are statistically
#     significant at p < 0.05.
#
# Q37 ITEM KEY (Updated from Codebook Screenshot):
#   Q37_1 = People are equal, regardless of their race or ethnic background
#   Q37_2 = White people get ahead because they work harder than other groups
#   Q37_3 = People from other racial or ethnic groups are sometimes still discriminated against
#   Q37_4 = If Black people were more respectful to the police, things would go better
#   Q37_5 = About important people in the history of other racial or ethnic groups
#   Q37_6 = About the possibility that some people might treat him or her badly because of our race
#   Q37_7 = About the rewards or special privileges that might come from being White
# =============================================================================

# --- Load and clean RPS data (mirrors main script logic) --------------------
df_rps_raw <- read.csv(path_rps, stringsAsFactors = FALSE)

df_rps_clean <- df_rps_raw %>%
  mutate(across(c(Q26, Q27, Q28, Q45,
                  Q37_1, Q37_2, Q37_3, Q37_4,
                  Q37_5, Q37_6, Q37_7), as.numeric)) %>%
  filter(
    Q26   %in% 1:4,
    Q27   %in% 1:4,
    Q28   %in% 1:4,
    Q45   >= 1 & Q45 <= 6,
    Q37_1 %in% 1:4,
    Q37_2 %in% 1:4,
    Q37_3 %in% 1:4,
    Q37_4 %in% 1:4,
    Q37_5 %in% 1:4,
    Q37_6 %in% 1:4,
    Q37_7 %in% 1:4
  )

# --- Re-run the BLM regression from the main script ------------------------
model_blm <- lm(Q26 ~
                  Q27 +
                  as.factor(Q28) +
                  Q45 +
                  Q37_1 + Q37_2 + Q37_3 + Q37_4 +
                  Q37_5 + Q37_6 + Q37_7,
                data = df_rps_clean)

# --- Extract only the Q37 (parental socialization) coefficients -------------
# broom::tidy() returns a clean data frame: term, estimate, std.error, p.value
blm_coefs <- tidy(model_blm, conf.int = TRUE, conf.level = 0.95) %>%
  filter(grepl("^Q37_", term)) %>%   # keep only the parental socialization rows
  mutate(
    # Human-readable label for each parental topic mapped from the codebook
    label = recode(term,
                   "Q37_1" = "Taught: People are equal regardless of race",
                   "Q37_2" = "Taught: White people get ahead by working harder",
                   "Q37_3" = "Taught: Other groups still face discrimination",
                   "Q37_4" = "Taught: Black people should be more\nrespectful to police (respectability politics)",
                   "Q37_5" = "Taught: Important people in history of other groups",
                   "Q37_6" = "Taught: Possibility of unfair treatment due to own race",
                   "Q37_7" = "Taught: Rewards or privileges of being White"
    ),
    # Flag significance at p < 0.05 for shape encoding
    significant = ifelse(p.value < 0.05, "p < 0.05", "p >= 0.05"),
    # Flag direction for color encoding
    direction = ifelse(estimate > 0, "Positive (more support)", "Negative (less support)")
  ) %>%
  # Sort by effect size so the plot reads top-to-bottom by magnitude
  arrange(estimate) %>%
  mutate(label = factor(label, levels = label))

cat("\n--- Parental Socialization Coefficients (BLM model) ---\n")
print(blm_coefs[, c("label", "estimate", "conf.low", "conf.high", "p.value")])

# --- Build the coefficient plot ---------------------------------------------
plot_blm_coefs <- ggplot(blm_coefs,
                         aes(x = estimate, y = label,
                             color = direction, shape = significant)) +
  # Vertical zero line — anything crossing this is not significant
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50", linewidth = 0.8) +
  # Horizontal confidence interval bars
  geom_errorbar(
    aes(xmin = conf.low, xmax = conf.high),
    orientation = "y", width = 0.25, linewidth = 0.9
  ) +
  # The coefficient dots
  geom_point(size = 4.5) +
  # Coefficient value labels anchored to the OUTER TIP of the CI bar, not the dot.
  # This guarantees the text always clears the error bar regardless of bar width.
  # For positive estimates: label sits just right of conf.high.
  # For negative estimates: label sits just left of conf.low.
  geom_text(
    aes(x     = ifelse(estimate >= 0, conf.high, conf.low),
        label = sprintf("%+.3f", estimate),
        hjust = ifelse(estimate >= 0, -0.15, 1.15)),
    size = 3.2, fontface = "bold", show.legend = FALSE
  ) +
  scale_color_manual(
    values = c("Positive (more support)" = "#1A5276",
               "Negative (less support)" = "#922B21")
  ) +
  scale_shape_manual(
    values = c("p < 0.05" = 16, "p >= 0.05" = 1)  # filled vs. open circle
  ) +
  # Widen x limits slightly so labels on the far ends aren't clipped
  scale_x_continuous(
    limits = c(-0.65, 0.65),
    breaks = seq(-0.5, 0.5, by = 0.25),
    labels = function(x) sprintf("%+.2f", x)
  ) +
  theme_minimal(base_size = 13) +
  labs(
    title    = "Which Family Conversations Predicted BLM Support?",
    x        = "Estimated Effect on BLM Support Score (1-4 scale)",
    y        = NULL,
    color    = "Direction",
    shape    = "Significance") +
  theme(
    plot.title       = element_text(face = "bold", size = 14),
    plot.subtitle    = element_text(size = 11, color = "gray30"),
    legend.position  = "bottom",
    legend.box       = "vertical",
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_line(color = "gray92"),
    axis.text.y      = element_text(size = 10),
    plot.margin      = margin(t = 10, r = 20, b = 10, l = 10, unit = "pt")
  )

print(plot_blm_coefs)

ggsave(
  filename = file.path(output_dir, "plot3_blm_parental_socialization_coefs.png"),
  plot     = plot_blm_coefs,
  width    = 10,
  height   = 6.5,
  dpi      = 300
)
cat("Saved: plot3_blm_parental_socialization_coefs.png\n")