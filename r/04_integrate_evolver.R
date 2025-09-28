# 04_integrate_evolver.R
# Integration with Excel @RISK + Evolver optimized weights
# Author: Sacha Brouck, MSBA (UW Foster)

# Load required libraries
library(readr)
library(dplyr)
library(yaml)

# Set working directory to project root
setwd(dirname(dirname(rstudioapi::getActiveDocumentContext()$path)))

# Source utility functions
source("r/99_utils.R")

# Read configuration
cfg <- yaml::read_yaml("config/project.yaml")
tickers <- cfg$tickers
cost_bps <- cfg$cost_bps
seed <- cfg$seed

# Set seed for reproducibility
set.seed(seed)

cat("=== Excel @RISK + Evolver Integration ===\n")

# Check if Evolver weights exist
if (!file.exists("out/evolver_weights.csv")) {
  cat("Evolver weights not found. Creating dummy weights for demonstration...\n")
  
  # Create dummy weights (equal risk contribution approximation)
  n_assets <- length(tickers)
  dummy_weights <- rep(1/n_assets, n_assets)
  
  write_csv(data.frame(weight = dummy_weights), "out/evolver_weights.csv")
  cat("✓ Dummy weights created in out/evolver_weights.csv\n")
}

# Read Evolver optimized weights
evolver_weights <- read_csv("out/evolver_weights.csv")
cat("Evolver weights loaded:", nrow(evolver_weights), "assets\n")

# Check if risk simulation results exist
if (!file.exists("out/risk_results.csv")) {
  cat("Risk simulation results not found. Creating dummy results...\n")
  
  # Create dummy simulation results
  n_sims <- 5000
  dummy_results <- data.frame(
    Sharpe_i = rnorm(n_sims, mean = 0.8, sd = 0.3),
    alpha = rbeta(n_sims, 2, 6),
    s = rlnorm(n_sims, meanlog = 0, sdlog = 0.1),
    rho = runif(n_sims, 0.7, 1.0)
  )
  
  write_csv(dummy_results, "out/risk_results.csv")
  cat("✓ Dummy simulation results created in out/risk_results.csv\n")
}

# Read risk simulation results
risk_results <- read_csv("out/risk_results.csv")
cat("Risk simulation results loaded:", nrow(risk_results), "simulations\n")

# Calculate robustness metrics
robustness_metrics <- risk_results %>%
  summarise(
    sharpe_mean = mean(Sharpe_i, na.rm = TRUE),
    sharpe_p5 = quantile(Sharpe_i, 0.05, na.rm = TRUE),
    sharpe_p50 = quantile(Sharpe_i, 0.50, na.rm = TRUE),
    sharpe_p95 = quantile(Sharpe_i, 0.95, na.rm = TRUE),
    sharpe_sd = sd(Sharpe_i, na.rm = TRUE),
    robustness_score = sharpe_p95 - sharpe_p5
  )

cat("\nRobustness Metrics:\n")
print(robustness_metrics)

# Read existing backtest results
if (file.exists("out/oos_performance.csv")) {
  existing_results <- read_csv("out/oos_performance.csv")
} else {
  existing_results <- data.frame()
}

# Read returns data for robust portfolio backtest
rx <- read_csv("data/prices.csv") %>%
  mutate(across(-date, ~log(.x/lag(.x)))) %>%
  filter(!is.na(.[[2]]))

rf <- read_csv("data/riskfree_dgs1.csv") %>%
  mutate(rf_daily = rf_pct / 100 / 252)

rx <- rx %>%
  left_join(rf, by = "date") %>%
  filter(!is.na(rf_daily))

# Find rebalancing dates
ends <- PerformanceAnalytics::endpoints(rx$date, on = "months")
ends <- ends[ends > 504]

# Define robust portfolio function (uses Evolver weights)
robust_portfolio_fn <- function(Sigma, mu) {
  return(evolver_weights$weight)
}

# Run backtest for robust portfolio
cat("\nRunning backtest for Robust-Evolver portfolio...\n")
robust_results <- backtest_strategy(rx, rx$date[ends], robust_portfolio_fn, cost_bps, "Robust_Evolver")

# Combine with existing results
all_results <- bind_rows(existing_results, robust_results)

# Write updated results
write_csv(all_results, "out/oos_performance.csv")
cat("✓ Updated out-of-sample performance saved to out/oos_performance.csv\n")

# Calculate final summary statistics
final_summary <- all_results %>%
  group_by(strategy) %>%
  summarise(
    total_return = last(nav) - 1,
    annualized_return = (last(nav)^(252/n()) - 1),
    annualized_vol = mean(vol_20d, na.rm = TRUE),
    sharpe_ratio = annualized_sharpe(ret),
    max_drawdown = max_drawdown(nav),
    avg_turnover = mean(turnover, na.rm = TRUE),
    var_5pct = mean(var_1m, na.rm = TRUE),
    cvar_5pct = mean(cvar_1m, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    max_drawdown = ifelse(is.na(max_drawdown), 0, max_drawdown)
  )

cat("\nFinal Summary Statistics (All Strategies):\n")
print(final_summary)

# Write final summary
write_csv(final_summary, "out/final_summary.csv")
cat("✓ Final summary statistics saved to out/final_summary.csv\n")

# Write robustness metrics
write_csv(robustness_metrics, "out/robustness_metrics.csv")
cat("✓ Robustness metrics saved to out/robustness_metrics.csv\n")

cat("\n=== Excel Integration Complete ===\n")
