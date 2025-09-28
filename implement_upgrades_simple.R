# Implement two upgrades to meet standards (SIMPLE VERSION)
library(readr)
library(dplyr)

cat("=== Implementing Standard Upgrades ===\n")

# 1. MEAN-RETURN TREATMENT: Pure Risk-Parity (μ = 0)
cat("1. Implementing Pure Risk-Parity (μ = 0)\n")

# Update latest_mu.csv to zeros
n_assets <- 10
zero_mu <- data.frame(mu = rep(0, n_assets))
write_csv(zero_mu, "out/latest_mu.csv")
cat("✓ Set μ = 0 in out/latest_mu.csv for pure risk-parity\n")

# Update mu_rolling.csv to zeros
mu_rolling <- read_csv("out/mu_rolling.csv")
mu_rolling_zero <- mu_rolling
mu_rolling_zero[, -1] <- 0
write_csv(mu_rolling_zero, "out/mu_rolling.csv")
cat("✓ Updated mu_rolling.csv with μ = 0\n")

# 2. RISK-PARITY DIAGNOSTIC
cat("\n2. Computing Risk-Parity Diagnostic\n")

# Read weights and covariance
evolver_weights <- read_csv("out/evolver_weights.csv")
robust_weights <- evolver_weights$weight

latest_sigma <- read_csv("out/latest_sigma.csv")
Sigma_vector <- latest_sigma$Sigma

# Create 10x10 covariance matrix
Sigma_matrix <- matrix(0, 10, 10)
Sigma_matrix[upper.tri(Sigma_matrix, diag = TRUE)] <- Sigma_vector
Sigma_matrix[lower.tri(Sigma_matrix)] <- t(Sigma_matrix)[lower.tri(Sigma_matrix)]

# Compute risk contributions
portfolio_var <- as.numeric(t(robust_weights) %*% Sigma_matrix %*% robust_weights)
marginal_contrib <- as.vector(Sigma_matrix %*% robust_weights)
risk_contrib_robust <- as.vector(robust_weights * marginal_contrib / portfolio_var)

# ERC comparison
erc_weights <- rep(0.1, 10)
erc_var <- as.numeric(t(erc_weights) %*% Sigma_matrix %*% erc_weights)
erc_marginal_contrib <- as.vector(Sigma_matrix %*% erc_weights)
risk_contrib_erc <- as.vector(erc_weights * erc_marginal_contrib / erc_var)

# Create simple diagnostic table
tickers <- c("SPY","TLT","LQD","HYG","GLD","DBC","VNQ","IWM","EFA","EEM")
risk_parity_diagnostic <- data.frame(
  Asset = tickers,
  Robust_Weight = robust_weights,
  ERC_Weight = erc_weights,
  Robust_RiskContrib_Pct = risk_contrib_robust * 100,
  ERC_RiskContrib_Pct = risk_contrib_erc * 100,
  Robust_Deviation = abs(risk_contrib_robust - 0.1),
  ERC_Deviation = abs(risk_contrib_erc - 0.1)
)

write_csv(risk_parity_diagnostic, "out/risk_parity_diagnostic.csv")
cat("✓ Risk-parity diagnostic saved to out/risk_parity_diagnostic.csv\n")

# Display summary
cat("\nRisk-Parity Diagnostic Summary:\n")
cat("Target risk contribution per asset: 10.0%\n")
cat("Robust-Evolver max deviation from target:", round(max(risk_parity_diagnostic$Robust_Deviation) * 100, 1), "%\n")
cat("ERC max deviation from target:", round(max(risk_parity_diagnostic$ERC_Deviation) * 100, 1), "%\n")

print(risk_parity_diagnostic)

# 3. EXPORT REQUIRED FILES FOR @RISK
cat("\n3. Exporting Files for @RISK Optimization\n")

# Ensure evolver_weights.csv is properly formatted
write_csv(evolver_weights, "out/evolver_weights.csv")
cat("✓ out/evolver_weights.csv ready for @RISK\n")

# Create comprehensive risk_results.csv with all strategies
risk_all <- read_csv("out/risk_results_all_strategies.csv")
risk_all$Sharpe_ann <- risk_all$Sharpe_i * sqrt(12)  # Annualize from monthly

write_csv(risk_all, "out/risk_results.csv")
cat("✓ out/risk_results.csv updated with all strategies and annualized Sharpe\n")

# Display file status
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
