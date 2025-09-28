# ---- Setup
library(readr); library(dplyr); library(ggplot2); library(scales); library(stringr); library(tidyr)

# CONFIG: dis-nous sur quelle période le Sharpe exporté par @RISK a été calculé
assume_period <- "monthly"   # "daily" ou "monthly"
annualize <- function(x) {
  k <- if (assume_period == "daily") sqrt(252) else if (assume_period == "monthly") sqrt(12) else 1
  x * k
}

# ---- 1) Charger les tirages @RISK pour toutes les stratégies
risk <- read_csv("out/risk_results_all_strategies.csv", show_col_types = FALSE)

# Normaliser le nom de la colonne Sharpe si besoin
sharpe_col <- names(risk)[str_detect(names(risk), regex("sharpe", ignore_case = TRUE))][1]
stopifnot(!is.na(sharpe_col))

risk <- risk %>%
  rename(Sharpe_raw = !!sharpe_col) %>%
  mutate(Sharpe_ann = annualize(Sharpe_raw))

# ---- 2) Charger les perfs OOS des baselines
oos <- read_csv("out/oos_performance.csv", show_col_types = FALSE)

# ---- 3) Construire la robustesse pour chaque stratégie sous la même incertitude
robust_stats <- risk %>%
  group_by(strategy) %>%
  summarise(
    sharpe_mean = mean(Sharpe_ann, na.rm = TRUE),
    sharpe_p5   = quantile(Sharpe_ann, 0.05, na.rm = TRUE),
    sharpe_p50  = quantile(Sharpe_ann, 0.50, na.rm = TRUE),
    sharpe_p95  = quantile(Sharpe_ann, 0.95, na.rm = TRUE),
    robustness  = sd(Sharpe_ann, na.rm = TRUE),           # définition A
    width_90    = sharpe_p95 - sharpe_p5                  # définition B (si tu préfères)
  ) %>% ungroup()

# ---- 4) Figure 1: Distribution pour le portefeuille robuste
robust_draws <- risk %>% filter(strategy == "Robust_Evolver")

p1 <- ggplot(robust_draws, aes(x = Sharpe_ann)) +
  geom_histogram(bins = 36, fill = "#3E6FB5", color = "white", alpha = 0.9) +
  geom_vline(xintercept = quantile(robust_draws$Sharpe_ann, 0.05), linetype = 2, color = "#D62728", size = 1) +
  geom_vline(xintercept = median(robust_draws$Sharpe_ann), linetype = 2, color = "#FF7F0E", size = 1) +
  geom_vline(xintercept = quantile(robust_draws$Sharpe_ann, 0.95), linetype = 2, color = "#2CA02C", size = 1) +
  labs(
    title = "Simulated Annualized Sharpe — Robust-Evolver under covariance uncertainty",
    x = "Annualized Sharpe Ratio", y = "Density",
    caption = "Inputs: covariance uncertainty via (alpha, s, rho). Units annualized via chosen period."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5),
    plot.caption = element_text(size = 10, hjust = 0.5),
    axis.title = element_text(size = 11),
    axis.text = element_text(size = 10)
  )

ggsave("out/fig_sharpe_dist.png", p1, width = 10, height = 5.5, dpi = 200)

# ---- 5) Figure 2: Frontière Sharpe vs Robustesse pour toutes les stratégies
# On retiendra 'robustness' (sd des tirages)
p2 <- ggplot(robust_stats,
             aes(x = robustness, y = sharpe_mean, color = strategy, label = strategy)) +
  geom_point(size = 4) +
  geom_text(aes(label = strategy), hjust = -0.1, vjust = 0.5, size = 4, show.legend = FALSE) +
  scale_x_continuous("Robustness score (SD of simulated annualized Sharpe)", labels = number_format(accuracy = 0.01)) +
  scale_y_continuous("Annualized Sharpe Ratio", labels = number_format(accuracy = 0.01)) +
  scale_color_brewer(type = "qual", palette = "Set2") +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 14, hjust = 0.5),
    plot.caption = element_text(size = 10, hjust = 0.5),
    axis.title = element_text(size = 11),
    axis.text = element_text(size = 10)
  ) +
  labs(title = "Sharpe vs Robustness Frontier — covariance uncertainty held constant",
       caption = "Same uncertainty for all strategies; Latin Hypercube; seed fixed.")

ggsave("out/fig_frontier.png", p2, width = 10, height = 5.5, dpi = 200)

# ---- 6) Export tableau récap utile pour le README
readr::write_csv(robust_stats, "out/robust_summary.csv")

cat("=== Figures Generated with Unified Sharpe Units ===\n")
cat("Assumed period:", assume_period, "\n")
cat("Annualization factor:", if (assume_period == "daily") sqrt(252) else if (assume_period == "monthly") sqrt(12) else 1, "\n")
cat("✓ Figure 1: Sharpe distribution saved to out/fig_sharpe_dist.png\n")
cat("✓ Figure 2: Sharpe vs Robustness frontier saved to out/fig_frontier.png\n")
cat("✓ Robust summary saved to out/robust_summary.csv\n")

# Afficher les statistiques
cat("\nRobustness Statistics:\n")
print(robust_stats)
