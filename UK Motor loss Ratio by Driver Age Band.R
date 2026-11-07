library(tidyverse)
library(scales)

# Creating the sample for the UK portfolio

set.seed(42)
n <- 1000

portfolio <- tibble(
                    policy_id = 1001:(1000+n),
                    driver_age = sample(18:75, n, replace = TRUE),
                    vehicle_type = sample(c("Hatchback","Saloon","SUV"),n,replace = TRUE, prob = c(0.5,0.3,0.2)),
                    annual_premium = sample(c(450,600,850,1100), n, replace = TRUE),
                    had_claim = sample(c(0,1),n,replace= TRUE, prob = c(0.90,0.10)))%>%
  mutate(
    Claim_amount = if_else(
      had_claim == 1,
      round(pmax(rnorm(n, mean = 2500, sd=600),250)),
      0
    ),
    age_band = cut(
      driver_age,
      breaks = c(17,25,40,65,80),
      labels = c("18-25","26-40","41-65","66+")
    )
  )
head(portfolio)


# performance summary

summary_by_age <- portfolio%>%
  group_by(age_band)%>%
  summarise(
    total_drivers =n(),
    total_claims =sum(had_claim),
    claim_frquency =round(total_claims/total_drivers,3),
    total_premiums_gbp =sum(annual_premium),
    total_claims_gbp =sum(Claim_amount),
    loss_ratio_pct =round((total_claims_gbp/total_premiums_gbp)*100,1)
  )
cat("\n---Summary by Age Band ---\n")
print(summary_by_age)

# Visualising the loss ratio depending on driver age

loss_ratio_chart <- ggplot(summary_by_age,aes(x=age_band,y=loss_ratio_pct))+
  geom_col(fill = "#2B547E",width =0.5)+
  geom_hline(yintercept = 100,linetype = "dashed",colour = "red",linewidth = 0.8)+
  annotate("text",x=1,y=105,label="Breakeven (100%)", colour= "red",hjust =0)+
  scale_y_continuous(labels=function(x) paste0(x, "%"))+
  theme_minimal(base_size = 12)+
  labs(
    title= "UK Motor loss Ratio by Driver age band",
    subtitle = "Values above 100% indicate an underwriting loss",
    x= "Driver Age Band",
    y="Loss Ratio (%)")
print(loss_ratio_chart)
ggsave("loss_ratio_by_age.png", plot = loss_ratio_chart, width = 7, height = 4.5, dpi = 300)
