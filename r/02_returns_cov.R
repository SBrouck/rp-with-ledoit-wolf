# 02_returns_cov.R
# Rolling returns and Ledoit-Wolf shrinkage covariance estimation
# Author: Sacha Brouck, MSBA (UW Foster)

# Load required libraries
library(readr)
library(dplyr)
library(tidyr)
library(zoo)
library(corpcor)
library(PerformanceAnalytics)
library(yaml)

# Set working directory to project root
setwd(dirname(dirname(rstudioapi::getActiveDocumentContext()$path)))

# Read configuration
cfg <- yaml::read_yaml("config/project.yaml")
tickers <- cfg$tickers
est_window_days <- cfg$est_window_days
seed <- cfg$seed

# Set seed for reproducibility
set.seed(seed)

cat("=== Rolling Returns and Covariance Estimation ===\n")

# Read price data
px <- read_csv("data/prices.csv")
rf <- read_csv("data/riskfree_dgs1.csv")

cat("Price data loaded:", nrow(px), "observations\n")
cat("Risk-free data loaded:", nrow(rf), "observations\n")

# Compute log returns
rx <- px %>%
  mutate(across(-date, ~log(.x/lag(.x)))) %>%
  filter(!is.na(.[[2]]))  # Remove first row with NA

cat("Returns computed:", nrow(rx), "observations\n")

# Merge with risk-free rate
rx <- rx %>%
  left_join(rf, by = "date") %>%
  mutate(rf_daily = rf_pct / 100 / 252)  # Convert annual to daily

# Find rebalancing dates (monthly endpoints)
ends <- PerformanceAnalytics::endpoints(rx$date, on = "months")
# Ensure we have enough data for estimation window
ends <- ends[ends > est_window_days]

cat("Rebalancing dates:", length(ends), "monthly endpoints\n")
cat("First rebalance:", as.character(rx$date[ends[1]]), "\n")
cat("Last rebalance:", as.character(rx$date[ends[length(ends)]]), "\n")

# Initialize storage for rolling estimates
cov_records <- list()
mu_records <- list()

cat("\nComputing rolling covariance estimates...\n")

# Loop through rebalancing dates
for (i in seq_along(ends)) {
  end_idx <- ends[i]
  start_idx <- end_idx - est_window_days + 1
  
  if (start_idx < 1) next
  
  # Extract estimation window
  win_data <- rx[start_idx:end_idx, ]
  R_win <- as.matrix(win_data[, tickers])
  
  # Compute Ledoit-Wolf shrinkage covariance
  S_shrink <- corpcor::cov.shrink(R_win, verbose = FALSE)
  
  # Compute sample mean
  mu_win <- colMeans(R_win, na.rm = TRUE)
  
  # Store results
  cov_records[[i]] <- list(
    date = rx$date[end_idx],
    Sigma = as.vector(S_shrink[upper.tri(S_shrink, diag = TRUE)])
  )
  
  mu_records[[i]] <- list(
    date = rx$date[end_idx],
    mu = mu_win
  )
  
  if (i %% 12 == 0) {
    cat("Processed", i, "of", length(ends), "rebalancing dates\n")
  }
}

# Convert to data frames
cov_df <- bind_rows(cov_records)
mu_df <- bind_rows(mu_records)

# Write rolling covariance estimates
write_csv(cov_df, "out/cov_rolling.csv")
cat("✓ Rolling covariance saved to out/cov_rolling.csv\n")

# Write rolling mean estimates
write_csv(mu_df, "out/mu_rolling.csv")
cat("✓ Rolling means saved to out/mu_rolling.csv\n")

# Extract latest estimates for Excel
latest_cov <- cov_records[[length(cov_records)]]$Sigma
latest_mu <- mu_records[[length(mu_records)]]$mu

# Reshape latest covariance to matrix for Excel
n_assets <- length(tickers)
S_matrix <- matrix(0, n_assets, n_assets)
S_matrix[upper.tri(S_matrix, diag = TRUE)] <- latest_cov
S_matrix[lower.tri(S_matrix)] <- t(S_matrix)[lower.tri(S_matrix)]

# Write latest estimates for Excel
write_csv(data.frame(Sigma = as.vector(S_matrix)), "out/latest_sigma.csv")
write_csv(data.frame(mu = latest_mu), "out/latest_mu.csv")

cat("✓ Latest covariance matrix saved to out/latest_sigma.csv\n")
cat("✓ Latest mean vector saved to out/latest_mu.csv\n")

# Create equal weights for first rebalancing (prev_weights.csv)
equal_weights <- rep(1/length(tickers), length(tickers))
write_csv(data.frame(weight = equal_weights), "out/prev_weights.csv")
cat("✓ Initial equal weights saved to out/prev_weights.csv\n")

cat("\n=== Covariance Estimation Complete ===\n")
cat("Final covariance matrix eigenvalues:\n")
print(eigen(S_matrix)$values)
