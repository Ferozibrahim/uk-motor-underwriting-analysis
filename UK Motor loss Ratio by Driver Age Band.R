library(tidyverse)
library(scales)

set.seed(42)
n <- 1000

# 1. Generate portfolio
portfolio <- tibble(
  policy_id    = 1001:(1000 + n),
  driver_age   = sample(18:75, n, replace = TRUE),
  vehicle_type = sample(c("Hatchback", "Saloon", "SUV"), n, replace = TRUE, prob = c(0.5, 0.3, 0.2))
) %>%
  mutate(
    # age bands
    age_band = cut(
      driver_age,
      breaks = c(17, 25, 40, 65, 80),
      labels = c("18-25", "26-40", "41-65", "66+")
    ),
    
    annual_premium = case_when(
      age_band == "18-25" ~ sample(c(950, 1050, 1150), n(), replace = TRUE),
      age_band == "26-40" ~ sample(c(650, 750, 850), n(), replace = TRUE),
      age_band == "41-65" ~ sample(c(500, 600, 700), n(), replace = TRUE),
      age_band == "66+"   ~ sample(c(550, 650, 750), n(), replace = TRUE)
    ),
    
    # Claim frequency probabilities by age cohort
    claim_prob = case_when(
      age_band == "18-25" ~ 0.28,
      age_band == "26-40" ~ 0.11,
      age_band == "41-65" ~ 0.07,
      age_band == "66+"   ~ 0.09
    ),
    had_claim = rbinom(n(), size = 1, prob = claim_prob),
    
    claim_amount = case_when(
      had_claim == 1 & age_band == "18-25" ~ round(pmax(rnorm(n(), mean = 4300, sd = 900), 250)),
      had_claim == 1 & age_band != "18-25" ~ round(pmax(rnorm(n(), mean = 2600, sd = 600), 250)),
      TRUE ~ 0
    )
  )

# 2. Performance summary
summary_by_age <- portfolio %>%
  group_by(age_band) %>%
  summarise(
    total_drivers      = n(),
    total_claims       = sum(had_claim),
    claim_frequency    = round(total_claims / total_drivers, 3),
    total_premiums_gbp = sum(annual_premium),
    total_claims_gbp   = sum(claim_amount),
    loss_ratio_pct     = round((total_claims_gbp / total_premiums_gbp) * 100, 1),
    .groups            = "drop"
  )

cat("\n--- Summary by Age Band ---\n")
print(summary_by_age)

# 3. Visualisation
loss_ratio_chart <- ggplot(summary_by_age, aes(x = age_band, y = loss_ratio_pct)) +
  geom_col(fill = "#2B547E", width = 0.5) +
  geom_hline(yintercept = 100, linetype = "dashed", colour = "red", linewidth = 0.8) +
  annotate("text", x = 3, y = 105, label = "Breakeven (100%)", colour = "red", hjust = 0, fontface = "bold") +
  scale_y_continuous(
    labels = function(x) paste0(x, "%"),
    limits = c(0, max(summary_by_age$loss_ratio_pct, 100) * 1.15)
  ) +
  theme_minimal(base_size = 12) +
  labs(
    title = "UK Motor Loss Ratio by Driver Age Band",
    subtitle = "Values above 100% indicate an underwriting loss",
    x = "Driver Age Band",
    y = "Loss Ratio (%)"
  )

print(loss_ratio_chart)
ggsave("loss_ratio_by_age.png", plot = loss_ratio_chart, width = 7, height = 4.5, dpi = 300)
