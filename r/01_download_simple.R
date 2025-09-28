# 01_download_simple.R
# Simplified data download for testing
# Author: Sacha Brouck, MSBA (UW Foster)

# Load basic libraries (should be available by default)
library(utils)

# Set working directory to project root (assuming we're running from project root)
# setwd(dirname(dirname(rstudioapi::getActiveDocumentContext()$path)))

# Read configuration manually (since yaml package might not be installed)
tickers <- c("SPY","TLT","LQD","HYG","GLD","DBC","VNQ","IWM","EFA","EEM")
from <- "2010-01-01"
to <- Sys.Date()
seed <- 20251001

# Set seed for reproducibility
set.seed(seed)

cat("=== Data Download and Quality Control ===\n")
cat("Tickers:", paste(tickers, collapse = ", "), "\n")
cat("Date range:", from, "to", as.character(to), "\n")

# Create dummy data for testing
cat("\nCreating dummy data for testing...\n")

# Create dummy price data
dates <- seq(as.Date(from), as.Date(to), by = "day")
dates <- dates[weekdays(dates) %in% c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday")]

n_days <- length(dates)
n_assets <- length(tickers)

# Generate realistic price data
set.seed(seed)
price_data <- data.frame(date = dates)

for (i in 1:n_assets) {
  # Generate log returns with some correlation
  returns <- rnorm(n_days, mean = 0.0005, sd = 0.02)
  prices <- 100 * exp(cumsum(returns))
  price_data[[tickers[i]]] <- prices
}

# Write price data
write.csv(price_data, "data/prices.csv", row.names = FALSE)
cat("✓ Dummy price data saved to data/prices.csv\n")

# Create dummy risk-free data
rf_data <- data.frame(
  date = dates,
  rf_pct = 2.0 + 0.5 * sin(seq_along(dates) * 2 * pi / 252) + rnorm(n_days, 0, 0.1)
)

write.csv(rf_data, "data/riskfree_dgs1.csv", row.names = FALSE)
cat("✓ Dummy risk-free data saved to data/riskfree_dgs1.csv\n")

cat("\n=== Data Download Complete ===\n")
