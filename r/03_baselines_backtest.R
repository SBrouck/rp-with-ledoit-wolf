# 03_baselines_backtest.R
# Baseline portfolio strategies and out-of-sample backtesting
# Author: Sacha Brouck, MSBA (UW Foster)

# Load required libraries
library(readr)
library(dplyr)
library(tidyr)
library(yaml)

# Set working directory to project root
setwd(dirname(dirname(rstudioapi::getActiveDocumentContext()$path)))

# Source utility functions
source("r/99_utils.R")

# Read configuration
cfg <- yaml::read_yaml("config/project.yaml")
tickers <- cfg$tickers
cost_bps <- cfg$cost_bps
w_max <- cfg$w_max
seed <- cfg$seed

# Set seed for reproducibility
set.seed(seed)

cat("=== Baseline Portfolio Strategies Backtest ===\n")

# Read data
rx <- read_csv("data/prices.csv") %>%
  mutate(across(-date, ~log(.x/lag(.x)))) %>%
  filter(!is.na(.[[2]]))

rf <- read_csv("data/riskfree_dgs1.csv") %>%
  mutate(rf_daily = rf_pct / 100 / 252)

# Merge returns with risk-free rate
rx <- rx %>%
  left_join(rf, by = "date") %>%
  filter(!is.na(rf_daily))

cat("Returns data loaded:", nrow(rx), "observations\n")

# Find rebalancing dates (monthly endpoints)
ends <- PerformanceAnalytics::endpoints(rx$date, on = "months")
ends <- ends[ends > 504]  # Ensure sufficient estimation window

cat("Rebalancing dates:", length(ends), "monthly endpoints\n")

# Define strategy functions
equal_weight_fn <- function(Sigma, mu) {
  rep(1/length(tickers), length(tickers))
}

mv_longonly_fn <- function(Sigma, mu) {
  solve_mv_longonly(Sigma, w_max)
}

erc_fn <- function(Sigma, mu) {
  solve_erc(Sigma, w_max)
}

# Run backtests for each strategy
cat("\nRunning backtests...\n")

# Equal Weight
cat("Backtesting Equal Weight strategy...\n")
ew_results <- backtest_strategy(rx, rx$date[ends], equal_weight_fn, cost_bps, "Equal_Weight")

# Minimum Variance (Long-only)
cat("Backtesting Minimum Variance strategy...\n")
mv_results <- backtest_strategy(rx, rx$date[ends], mv_longonly_fn, cost_bps, "Min_Variance")

# Equal Risk Contribution
cat("Backtesting Equal Risk Contribution strategy...\n")
erc_results <- backtest_strategy(rx, rx$date[ends], erc_fn, cost_bps, "ERC")

# Combine all results
all_results <- bind_rows(ew_results, mv_results, erc_results)

# Calculate summary statistics
summary_stats <- all_results %>%
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

cat("\nSummary Statistics:\n")
print(summary_stats)

# Write detailed results
write_csv(all_results, "out/oos_performance.csv")
cat("✓ Out-of-sample performance saved to out/oos_performance.csv\n")

# Write summary statistics
write_csv(summary_stats, "out/summary_stats.csv")
cat("✓ Summary statistics saved to out/summary_stats.csv\n")

# Validation checks
cat("\nValidation checks:\n")

# Check for monotonic NAV
nav_checks <- all_results %>%
  group_by(strategy) %>%
  summarise(
    monotonic_nav = all(nav >= lag(nav, default = 1), na.rm = TRUE),
    finite_metrics = all(is.finite(c(sharpe_ratio, max_drawdown, avg_turnover)), na.rm = TRUE),
    .groups = "drop"
  )

print(nav_checks)

if (!all(nav_checks$monotonic_nav)) {
  warning("Some strategies have non-monotonic NAV - check for data issues")
}

if (!all(nav_checks$finite_metrics)) {
  warning("Some strategies have non-finite metrics - check calculations")
}

cat("\n=== Baseline Backtest Complete ===\n")
