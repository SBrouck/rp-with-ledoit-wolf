# Test script to verify project structure
cat("=== Robust Risk Parity Project Test ===\n")

# Check if all required files exist
required_files <- c(
  "config/project.yaml",
  "data/prices.csv",
  "data/riskfree_dgs1.csv",
  "r/01_download.R",
  "r/02_returns_cov.R",
  "r/03_baselines_backtest.R",
  "r/04_integrate_evolver.R",
  "r/05_figures.R",
  "r/99_utils.R",
  "excel/README_Excel.md",
  "out/cov_rolling.csv",
  "out/mu_rolling.csv",
  "out/latest_sigma.csv",
  "out/latest_mu.csv",
  "out/prev_weights.csv",
  "out/risk_results.csv",
  "out/evolver_weights.csv",
  "out/oos_performance.csv"
)

cat("Checking required files...\n")
all_exist <- TRUE
for (file in required_files) {
  if (file.exists(file)) {
    cat("✓", file, "\n")
  } else {
    cat("✗", file, "MISSING\n")
    all_exist <- FALSE
  }
}

if (all_exist) {
  cat("\n✓ All required files present!\n")
} else {
  cat("\n✗ Some files are missing\n")
}

# Check data files
cat("\nChecking data files...\n")
if (file.exists("data/prices.csv")) {
  prices <- read.csv("data/prices.csv")
  cat("Price data:", nrow(prices), "rows,", ncol(prices), "columns\n")
}

if (file.exists("data/riskfree_dgs1.csv")) {
  rf <- read.csv("data/riskfree_dgs1.csv")
  cat("Risk-free data:", nrow(rf), "rows\n")
}

cat("\n=== Project Test Complete ===\n")
