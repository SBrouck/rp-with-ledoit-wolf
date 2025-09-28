# Implement two upgrades to meet standards (FIXED VERSION)
# 1. Mean-return treatment (Pure risk-parity: μ = 0)
# 2. Risk-parity diagnostic

library(readr)
library(dplyr)

cat("=== Implementing Standard Upgrades ===\n")

# 1. MEAN-RETURN TREATMENT: Pure Risk-Parity (μ = 0)
cat("1. Implementing Pure Risk-Parity (μ = 0)\n")

# Update latest_mu.csv to zeros
n_assets <- 10  # SPY, TLT, LQD, HYG, GLD, DBC, VNQ, IWM, EFA, EEM
zero_mu <- data.frame(mu = rep(0, n_assets))
write_csv(zero_mu, "out/latest_mu.csv")
cat("✓ Set μ = 0 in out/latest_mu.csv for pure risk-parity\n")

# Update mu_rolling.csv to zeros for consistency
mu_rolling <- read_csv("out/mu_rolling.csv")
mu_rolling_zero <- mu_rolling
mu_rolling_zero[, -1] <- 0  # Keep date column, zero all others
write_csv(mu_rolling_zero, "out/mu_rolling.csv")
cat("✓ Updated mu_rolling.csv with μ = 0\n")

# 2. RISK-PARITY DIAGNOSTIC
cat("\n2. Computing Risk-Parity Diagnostic\n")

# Read the robust portfolio weights
evolver_weights <- read_csv("out/evolver_weights.csv")
robust_weights <- evolver_weights$weight

# Read the latest covariance matrix (55 elements for 10x10 upper triangular)
latest_sigma <- read_csv("out/latest_sigma.csv")
n_assets <- 10  # Fixed: we know it's 10 assets

# Reshape covariance to matrix (upper triangular to full matrix)
Sigma_vector <- latest_sigma$Sigma
Sigma_matrix <- matrix(0, n_assets, n_assets)
Sigma_matrix[upper.tri(Sigma_matrix, diag = TRUE)] <- Sigma_vector
Sigma_matrix[lower.tri(Sigma_matrix)] <- t(Sigma_matrix)[lower.tri(Sigma_matrix)]

# Compute risk contributions for Robust-Evolver
portfolio_var <- as.numeric(t(robust_weights) %*% Sigma_matrix %*% robust_weights)
marginal_contrib <- Sigma_matrix %*% robust_weights
risk_contrib_robust <- robust_weights * marginal_contrib / portfolio_var

# Compute risk contributions for ERC (equal weights as proxy)
erc_weights <- rep(1/n_assets, n_assets)
erc_var <- as.numeric(t(erc_weights) %*% Sigma_matrix %*% erc_weights)
erc_marginal_contrib <- Sigma_matrix %*% erc_weights
risk_contrib_erc <- erc_weights * erc_marginal_contrib / erc_var

# Create diagnostic table
tickers <- c("SPY","TLT","LQD","HYG","GLD","DBC","VNQ","IWM","EFA","EEM")
risk_parity_diagnostic <- data.frame(
  Asset = tickers,
  Robust_Weight = robust_weights,
  ERC_Weight = erc_weights,
  Robust_RiskContrib = risk_contrib_robust,
  ERC_RiskContrib = risk_contrib_erc,
  Robust_RiskContrib_Pct = risk_contrib_robust * 100,
  ERC_RiskContrib_Pct = risk_contrib_erc * 100
)

# Calculate max deviation from 1/n
target_contrib <- 1/n_assets
robust_max_dev <- max(abs(risk_contrib_robust - target_contrib))
erc_max_dev <- max(abs(risk_contrib_erc - target_contrib))

risk_parity_diagnostic$Robust_Deviation <- abs(risk_contrib_robust - target_contrib)
risk_parity_diagnostic$ERC_Deviation <- abs(risk_contrib_erc - target_contrib)

# Save diagnostic
write_csv(risk_parity_diagnostic, "out/risk_parity_diagnostic.csv")
cat("✓ Risk-parity diagnostic saved to out/risk_parity_diagnostic.csv\n")

# Display summary
cat("\nRisk-Parity Diagnostic Summary:\n")
cat("Target risk contribution per asset:", round(target_contrib * 100, 1), "%\n")
cat("Robust-Evolver max deviation from target:", round(robust_max_dev * 100, 1), "%\n")
cat("ERC max deviation from target:", round(erc_max_dev * 100, 1), "%\n")

print(risk_parity_diagnostic[, c("Asset", "Robust_RiskContrib_Pct", "ERC_RiskContrib_Pct", "Robust_Deviation", "ERC_Deviation")])

# 3. EXPORT REQUIRED FILES FOR @RISK
cat("\n3. Exporting Files for @RISK Optimization\n")

# Ensure evolver_weights.csv is properly formatted
write_csv(evolver_weights, "out/evolver_weights.csv")
cat("✓ out/evolver_weights.csv ready for @RISK\n")

# Create comprehensive risk_results.csv with all strategies
risk_all <- read_csv("out/risk_results_all_strategies.csv")
risk_all$Sharpe_ann <- risk_all$Sharpe_i * sqrt(12)  # Annualize from monthly

# Save the comprehensive results
write_csv(risk_all, "out/risk_results.csv")
cat("✓ out/risk_results.csv updated with all strategies and annualized Sharpe\n")

# Display file sizes
cat("\nFile Status:\n")
files_to_check <- c("out/evolver_weights.csv", "out/risk_results.csv", "out/latest_sigma.csv", "out/latest_mu.csv")
for (file in files_to_check) {
  if (file.exists(file)) {
    size <- file.info(file)$size
    cat("✓", file, "(", size, "bytes )\n")
  } else {
    cat("✗", file, "MISSING\n")
  }
}

cat("\n=== Upgrades Complete ===\n")
cat("Ready for @RISK optimization runs!\n")
