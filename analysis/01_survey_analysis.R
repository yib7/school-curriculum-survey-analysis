library(haven)
library(dplyr)
library(ggplot2)

# file paths here for the relevant .csv and .sav files (CCES23 then VAND0049 then RPS Wave 1)

path_cces <- "data/CCES23_VAN_OUTPUT.sav"
path_vand <- "data/VAND0049_OUTPUT_numeric.csv"
path_rps  <- "data/RPS Wave 1.csv"


# Section 1: CCES23 data (looking at VAN025 & VAN026)

df_cces <- as_factor(read_sav(path_cces))

# VAN025: schools race wording
cat("\n summary stats for VAN025 \n")

summary_van025 <- df_cces %>%
  filter(!is.na(VAN025_treat) & !is.na(VAN025)) %>%
  group_by(VAN025_treat) %>%
  summarise(
    mean_attitude = mean(as.numeric(VAN025), na.rm = TRUE),
    count = n(),
    .groups = "drop"
  )
print(summary_van025)

cat("\n running the regression for VAN025 \n")

model_van025 <- lm(as.numeric(VAN025) ~ 
                     VAN025_treat * gender4 + 
                     VAN025_treat * child18 +
                     VAN025_treat * educ + 
                     VAN025_treat * race + 
                     VAN025_treat * VAN022 + 
                     VAN025_treat * as.numeric(VAN030), 
                   data = df_cces)
print(summary(model_van025))


# VAN026: ethnic studies wording
cat("\n summary stats for VAN026 \n")

summary_van026 <- df_cces %>%
  filter(!is.na(VAN026_treat) & !is.na(VAN026)) %>%
  group_by(VAN026_treat) %>%
  summarise(
    mean_attitude = mean(as.numeric(VAN026), na.rm = TRUE),
    count = n(),
    .groups = "drop"
  )
print(summary_van026)

cat("\n running the regression for VAN026 \n")

model_van026 <- lm(as.numeric(VAN026) ~ 
                     VAN026_treat * gender4 + 
                     VAN026_treat * child18 +
                     VAN026_treat * educ + 
                     VAN026_treat * race + 
                     VAN026_treat * VAN022 + 
                     VAN026_treat * as.numeric(VAN030), 
                   data = df_cces)
print(summary(model_van026))

# --- NEW SECTION: Checking Gender's Effect on Support Score (VAN026) ---
cat("\n --- Quick Check: Gender vs. Average Support Score (VAN026) --- \n")

# 1. Simple Summary: What was the overall average score by gender?
gender_support_summary <- df_cces %>%
  filter(!is.na(gender4) & !is.na(VAN026)) %>%
  group_by(gender4) %>%
  summarise(
    mean_support = round(mean(as.numeric(VAN026), na.rm = TRUE), 2),
    count = n(),
    .groups = "drop"
  )
cat("\nOverall Average Support by Gender:\n")
print(gender_support_summary)

# 2. Interaction Summary: Did genders react differently to specific framing options?
gender_framing_summary <- df_cces %>%
  filter(!is.na(gender4) & !is.na(VAN026) & !is.na(VAN026_treat)) %>%
  group_by(VAN026_treat, gender4) %>%
  summarise(
    mean_support = round(mean(as.numeric(VAN026), na.rm = TRUE), 2),
    count = n(),
    .groups = "drop"
  ) %>%
  arrange(VAN026_treat, gender4)
cat("\nAverage Support by Gender AND Framing Option:\n")
print(gender_framing_summary, n = Inf) # n=Inf ensures it prints all rows

# 3. Quick Statistical Test (ANOVA) to see if the overall gender differences are significant
cat("\nANOVA Test: Does Gender significantly affect the VAN026 score overall?\n")
gender_anova <- aov(as.numeric(VAN026) ~ gender4, data = df_cces)
print(summary(gender_anova))
# -----------------------------------------------------------------------

# Section 2: VAND0049 data (Anti-CRT laws)

df_vand_raw <- read.csv(path_vand)

# filter the raw data for numbers (like -99) that would mess results. 

df_vand_clean <- df_vand_raw %>%
  filter(
    anti_crt < 5,
    pid7 < 8,
    school_undermine < 8,
    school_uncomfortable < 8,
    import_race < 8
  )

cat("\n summary stats: anti-CRT law support \n")
summary_crt <- df_vand_clean %>%
  group_by(anti_crt) %>%
  summarise(count = n(), .groups = "drop") %>%
  mutate(
    percentage = round((count / sum(count)) * 100, 1),
    # making a nice text label column just for the graph
    label = factor(anti_crt, 
                   levels = c(1, 2, 3, 4),
                   labels = c("Strongly Favor\n(Limit CRT)", 
                              "Somewhat Favor", 
                              "Somewhat Oppose", 
                              "Strongly Oppose\n(Allow CRT)"))
  )
print(summary_crt)

cat("\n regression for anti-CRT opposition \n")
# treating gender and race as factors so R knows they are categories
model_crt <- lm(anti_crt ~ 
                  pid7 + 
                  school_undermine + 
                  school_uncomfortable + 
                  import_race + 
                  as.factor(gender) + 
                  as.factor(race), 
                data = df_vand_clean)
print(summary(model_crt))


# Section 3: RPS wave 1 data (BLM support)

df_rps_raw <- read.csv(path_rps, stringsAsFactors = FALSE)

# convert all the survey questions to numeric and filter out stuff like missing answers
df_rps_clean <- df_rps_raw %>%
  mutate(across(c(Q26, Q27, Q28, Q45, Q37_1, Q37_2, Q37_3, Q37_4, Q37_5, Q37_6, Q37_7), as.numeric)) %>%
  filter(
    Q26 %in% c(1, 2, 3, 4),
    Q27 %in% c(1, 2, 3, 4),
    Q28 %in% c(1, 2, 3, 4),
    Q45 >= 1 & Q45 <= 6,
    Q37_1 %in% c(1, 2, 3, 4),
    Q37_2 %in% c(1, 2, 3, 4),
    Q37_3 %in% c(1, 2, 3, 4),
    Q37_4 %in% c(1, 2, 3, 4),
    Q37_5 %in% c(1, 2, 3, 4),
    Q37_6 %in% c(1, 2, 3, 4),
    Q37_7 %in% c(1, 2, 3, 4)
  )

cat("\n summary stats for BLM movement support \n")
summary_blm <- df_rps_clean %>%
  group_by(Q26) %>%
  summarise(count = n(), .groups = "drop") %>%
  mutate(
    percentage = round((count / sum(count)) * 100, 1),
    label = factor(Q26, 
                   levels = c(1, 2, 3, 4),
                   labels = c("Strongly Oppose", 
                              "Somewhat Oppose", 
                              "Somewhat Support", 
                              "Strongly Support"))
  )
print(summary_blm)

cat("\n regression for BLM support \n")
model_blm <- lm(Q26 ~ 
                  Q27 + 
                  as.factor(Q28) + 
                  Q45 +
                  Q37_1 + Q37_2 + Q37_3 + Q37_4 + Q37_5 + Q37_6 + Q37_7, 
                data = df_rps_clean)
print(summary(model_blm))






# bonus bar plots to get visualize idea of starting points and respondent general perspective and because it looks nice

plot_van025 <- ggplot(summary_van025, aes(x = VAN025_treat, y = mean_attitude, fill = VAN025_treat)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", width = 0.7) +
  geom_text(aes(label = round(mean_attitude, 2)), vjust = -0.5, size = 4) +
  theme_minimal() +
  labs(
    title = "Effect of Framing on General Race Ed Support (VAN025)",
    subtitle = "higher scores = more support",
    x = "Framing Condition",
    y = "Average Support Score"
  ) +
  scale_fill_brewer(palette = "Blues") +
  theme(
    legend.position = "none", # hide the legend since the x-axis already explains it
    plot.title = element_text(face = "bold", size = 14)
  )
print(plot_van025)

plot_van026 <- ggplot(summary_van026, aes(x = VAN026_treat, y = mean_attitude, fill = VAN026_treat)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", width = 0.7) +
  geom_text(aes(label = round(mean_attitude, 2)), vjust = -0.5, size = 4) +
  theme_minimal() +
  labs(
    title = "Effect of Framing on Ethnic Studies Support (VAN026)",
    subtitle = "higher scores = more support",
    x = "Framing Condition",
    y = "Average Support Score"
  ) +
  scale_fill_brewer(palette = "Greens") +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 14)
  )
print(plot_van026)


plot_crt <- ggplot(summary_crt, aes(x = label, y = percentage, fill = label)) +
  geom_bar(stat = "identity", color = "black", width = 0.6) +
  geom_text(aes(label = paste0(percentage, "%")), vjust = -0.5, size = 5) +
  theme_minimal() +
  labs(
    title = "Public Support for Anti-CRT Laws",
    subtitle = "Laws limiting the teaching of 'divisive concepts' about race and gender",
    x = "Stance on Law",
    y = "Percentage of Respondents"
  ) +
  scale_fill_brewer(palette = "Reds") +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 14)
  )
print(plot_crt)


plot_blm <- ggplot(summary_blm, aes(x = label, y = percentage, fill = label)) +
  geom_bar(stat = "identity", color = "black", width = 0.6) +
  geom_text(aes(label = paste0(percentage, "%")), vjust = -0.5, size = 5) +
  theme_minimal() +
  labs(
    title = "Public Support for the Black Lives Matter Movement (Q26)",
    subtitle = "Based on 'From what you've read and heard, how do you feel about the BLM movement?'",
    x = "Stance on Movement",
    y = "Percentage of Respondents"
  ) +
  scale_fill_brewer(palette = "Purples") +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 14)
  )
print(plot_blm)