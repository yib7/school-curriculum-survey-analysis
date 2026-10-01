# =============================================================================
# SUPPLEMENTAL VISUALIZATIONS — Race Education Survey Data Report
# Author: Yibarek Tadesse
# Purpose: Two new plots that directly address professor feedback:
#   (1) Interaction plot: How Trump vs. non-Trump voters responded differently
#       to each VAN025 framing condition (the "tripwire" finding)
#   (2) Partisanship breakdown: Anti-CRT support by party identity (pid7)
#       to show that ideology, not demographics, drives opposition
#
# OUTPUT: All plots saved as PNG files to ./saved_output_survey/
# =============================================================================

# --- Create output folder if it doesn't already exist ----------------------
output_dir <- "saved_output_survey"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
  cat(paste0("Created output folder: ", output_dir, "/\n"))
} else {
  cat(paste0("Output folder already exists: ", output_dir, "/\n"))
}

library(haven)
library(dplyr)
library(ggplot2)

# ---- File paths (update these to match your local setup) -------------------
path_cces <- "data/CCES23_VAN_OUTPUT.sav"
path_vand <- "data/VAND0049_OUTPUT_numeric.csv"
# ----------------------------------------------------------------------------


# =============================================================================
# PLOT 1: Framing Condition x Trump Vote Interaction (VAN025)
#
# WHAT THIS SHOWS: The professor asked us to contextualize WHY Option 3
# caused a sharp drop in support. This interaction plot makes that visible:
# Trump-leaning respondents react much more negatively to the "divisive
# concepts" framing than everyone else, even though baseline levels are
# similar at Option 1. The gap opens up dramatically at Option 3.
#
# HOW TO READ IT: Each line traces one group (Trump vs. Non-Trump voters)
# across the four framing conditions. A sharp divergence at Option 3 is
# the key finding the regression flagged (p < 0.001).
# =============================================================================

df_cces <- as_factor(read_sav(path_cces))

# --- Step 1: Create a clean Trump-voter indicator from VAN022 ---------------
# VAN022 captures 2024 presidential vote preference.
# We create a simple two-group variable: Trump voters vs. everyone else.
# This makes the interaction easy to see without cluttering the plot.
df_cces_interact <- df_cces %>%
  filter(!is.na(VAN025_treat) & !is.na(VAN025) & !is.na(VAN022)) %>%
  mutate(
    # Adjust the string match below if your factor labels differ slightly
    trump_voter = case_when(
      grepl("Trump", as.character(VAN022), ignore.case = TRUE) ~ "Intend to vote for Trump",
      TRUE ~ "All Other Respondents"
    ),
    # Convert the 7-point outcome to numeric for averaging
    van025_num = as.numeric(VAN025)
  )

# --- Step 2: Compute group means by framing condition and Trump status ------
interact_summary <- df_cces_interact %>%
  group_by(VAN025_treat, trump_voter) %>%
  summarise(
    mean_support = mean(van025_num, na.rm = TRUE),
    se           = sd(van025_num, na.rm = TRUE) / sqrt(n()),
    n            = n(),   # keep n so we can flag small cells and annotate the plot
    .groups = "drop"
  )

# Print a diagnostic table so you can spot thin cells before plotting.
# Any row with n < 30 should be interpreted with caution.
cat("\n--- Cell sizes (n) by framing condition and voter group ---\n")
print(interact_summary[, c("VAN025_treat", "trump_voter", "n", "mean_support", "se")])
cat("NOTE: cells with n < 30 will have wide error bars and unstable means.\n\n")

# --- Step 3: Add descriptive framing labels so the reader knows what each ---
# "Option" actually represents on the x-axis (directly addresses prof feedback)
interact_summary <- interact_summary %>%
  mutate(
    framing_label = recode(as.character(VAN025_treat),
                           # Adjust these level names to match your actual factor levels in VAN025_treat
                           "Option 1" = "Option 1\nRequired learn about historical",
                           "Option 2" = "Option 2\nAllowed learn about historical",
                           "Option 3" = "Option 3\nRequired learn about present-day",
                           "Option 4" = "Option 4\nAllowed learn about present-day"
    ),
    # Lock the x-axis order so it runs Option 1 -> 4 left to right
    framing_label = factor(framing_label, levels = c(
      "Option 1\nRequired learn about historical",
      "Option 2\nAllowed learn about historical",
      "Option 3\nRequired learn about present-day",
      "Option 4\nAllowed learn about present-day"
    ))
  )

# --- Step 4: Build the interaction line plot --------------------------------
plot_interaction_trump <- ggplot(
  interact_summary,
  aes(x = framing_label, y = mean_support,
      color = trump_voter, group = trump_voter)
) +
  # Lines connecting the group means across conditions
  geom_line(linewidth = 1.2) +
  # Points at each condition so the values are easy to read
  geom_point(size = 3.5) +
  # Error bars show +/- 1 standard error around each mean
  geom_errorbar(
    aes(ymin = mean_support - se, ymax = mean_support + se),
    width = 0.15, linewidth = 0.8
  ) +
  # Annotate the mean values directly on the plot for clarity.
  # show.legend = FALSE prevents geom_text from injecting an "a" glyph into the legend.
  geom_text(
    aes(label = round(mean_support, 2)),
    vjust = -1.2, size = 3.5, fontface = "bold",
    show.legend = FALSE
  ) +
  # Show sample size below each point so readers can judge thin cells.
  # Cells with small n produce the wide/clipped error bars seen in the original plot.
  geom_text(
    aes(label = paste0("n=", n), y = mean_support - se - 0.18),
    size = 2.8, color = "gray40", fontface = "italic",
    show.legend = FALSE
  ) +
  # Color palette: red for Trump, blue for others (intuitive political coding)
  scale_color_manual(
    values = c("Intend to vote for Trump" = "#C0392B",
               "All Other Respondents"         = "#2980B9")
  ) +
  # Y-axis: show the full 1–7 scale with plain numeric labels.
  scale_y_continuous(
    breaks = 1:7,
    labels = 1:7
  ) +
  # coord_cartesian zooms the view without dropping data or clipping error bars.
  coord_cartesian(ylim = c(1, 7)) +
  theme_minimal(base_size = 13) +
  labs(
    title    = "How Survey Framing Activates Partisan Identity (VAN025)",
    subtitle = paste0("Prospective Trump voters show a sharp drop in support when\n",
                      'classrooms are forced to teach about present-day racism.'),
    x        = "Framing Condition",
    y        = "Average Support Score (7-point scale)",
    color    = "Voter Group"
  ) +
  theme(
    plot.title    = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "gray30"),
    legend.position = "top",
    legend.title  = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    # Extra right margin prevents the "Option 4 (Moderate)" label from being clipped
    plot.margin = margin(t = 10, r = 30, b = 10, l = 10, unit = "pt")
  )

print(plot_interaction_trump)

# Save Plot 1 to the output folder
ggsave(
  filename = file.path(output_dir, "plot1_trump_framing_interaction.png"),
  plot     = plot_interaction_trump,
  width    = 10,
  height   = 6,
  dpi      = 300
)
cat("Saved: plot1_trump_framing_interaction.png\n")


# =============================================================================
# PLOT 2: Anti-CRT Support by Partisan Identity (VAND0049)
#
# WHAT THIS SHOWS: The professor asked how we tested that opposition to
# anti-CRT laws is "driven almost entirely by partisan identity." This plot
# makes that argument visually: as respondents move from Strong Democrat (1)
# to Strong Republican (7) on the pid7 scale, the proportion favoring
# restrictions climbs steeply while opposition collapses. Demographic
# factors (gender, race) were not significant; partisanship dominated.
#
# HOW TO READ IT: The stacked bars show the distribution of anti-CRT
# stances for each point on the 7-point party ID scale. The right-ward
# shift in the "Strongly Favor" (dark) portion captures the regression
# finding visually.
# =============================================================================

df_vand_raw <- read.csv(path_vand)

# --- Step 1: Clean the VAND0049 data (same filters as in main script) -------
df_vand_clean <- df_vand_raw %>%
  filter(
    anti_crt < 5,    # drops non-response codes
    pid7     < 8,    # drops non-response codes on party ID scale
    school_undermine    < 8,
    school_uncomfortable < 8,
    import_race         < 8
  ) %>%
  mutate(
    # Convert the 7-point party ID to labeled groups for the x-axis
    party_label = factor(pid7,
                         levels = 1:7,
                         labels = c(
                           "1\nStrong\nDem",
                           "2\nWeak\nDem",
                           "3\nLean\nDem",
                           "4\nIndep.",
                           "5\nLean\nRep",
                           "6\nWeak\nRep",
                           "7\nStrong\nRep"
                         )
    ),
    # Label the anti-CRT stance outcome for the legend
    crt_stance = factor(anti_crt,
                        levels = c(1, 2, 3, 4),
                        labels = c(
                          "Strongly Favor (Limit CRT)",
                          "Somewhat Favor",
                          "Somewhat Oppose",
                          "Strongly Oppose (Allow CRT)"
                        )
    )
  )

# --- Step 2: Compute percentage breakdown by party ID and stance -----------
party_crt_summary <- df_vand_clean %>%
  group_by(party_label, crt_stance) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(party_label) %>%
  mutate(
    pct = round((count / sum(count)) * 100, 1)
  ) %>%
  ungroup()

# --- Step 3: Build the stacked bar chart ------------------------------------
plot_party_crt <- ggplot(
  party_crt_summary,
  aes(x = party_label, y = pct, fill = crt_stance)
) +
  geom_bar(stat = "identity", position = "stack", color = "white", linewidth = 0.4) +
  # Only label segments that are wide enough to read (> 8%)
  geom_text(
    data = filter(party_crt_summary, pct > 8),
    aes(label = paste0(pct, "%")),
    position = position_stack(vjust = 0.5),
    size = 3.2, color = "white", fontface = "bold"
  ) +
  # Color scale: red tones = favor restrictions; blue tones = oppose them
  scale_fill_manual(
    values = c(
      "Strongly Favor (Limit CRT)"      = "#922B21",
      "Somewhat Favor"                   = "#E59866",
      "Somewhat Oppose"                  = "#7FB3D3",
      "Strongly Oppose (Allow CRT)"      = "#1A5276"
    ),
    # Reverse the legend order so "Strongly Oppose" appears at the top
    guide = guide_legend(reverse = TRUE)
  ) +
  theme_minimal(base_size = 13) +
  labs(
    title    = "Anti-CRT Law Support Rises Sharply with Republican Identity",
    subtitle = paste0("Partisanship (pid7, 7-point scale) is the dominant predictor of stance."),
    x        = "Party Identification (1 = Strong Democrat  →  7 = Strong Republican)",
    y        = "Percentage of Respondents",
    fill     = "Stance on Anti-CRT Laws"
  ) +
  theme(
    plot.title      = element_text(face = "bold", size = 14),
    plot.subtitle   = element_text(size = 11, color = "gray30"),
    legend.position = "right",
    legend.title    = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  )

print(plot_party_crt)

# Save Plot 2 to the output folder
ggsave(
  filename = file.path(output_dir, "plot2_partisanship_anticrt.png"),
  plot     = plot_party_crt,
  width    = 10,
  height   = 6.5,
  dpi      = 300
)
cat("Saved: plot2_partisanship_anticrt.png\n")


# =============================================================================
# END OF SUPPLEMENTAL SCRIPT
# Both plots are ready to drop into the report or presentation.
# Plot 1 addresses: "why did Option 3 cause a sharp drop among Trump voters?"
# Plot 2 addresses: "how was partisan identity tested as the key driver?"
# =============================================================================