# 01_download.R
# Data acquisition and quality control for robust risk parity portfolio
# Author: Sacha Brouck, MSBA (UW Foster)

# Load required libraries
library(tidyquant)
library(dplyr)
library(tidyr)
library(readr)
library(lubridate)
library(yaml)

# Set working directory to project root
setwd(dirname(dirname(rstudioapi::getActiveDocumentContext()$path)))

# Read configuration
cfg <- yaml::read_yaml("config/project.yaml")
tickers <- cfg$tickers
from <- cfg$from
to <- if (is.null(cfg$to)) Sys.Date() else cfg$to
seed <- cfg$seed

# Set seed for reproducibility
set.seed(seed)

cat("=== Data Download and Quality Control ===\n")
cat("Tickers:", paste(tickers, collapse = ", "), "\n")
cat("Date range:", from, "to", as.character(to), "\n")

# Download ETF prices from Yahoo Finance
cat("\nDownloading ETF prices from Yahoo Finance...\n")
px <- tq_get(tickers, get = "stock.prices", from = from, to = to) %>%
  select(symbol, date, adjusted) %>%
  pivot_wider(names_from = symbol, values_from = adjusted) %>%
  arrange(date)

# Quality control checks
cat("Price data quality checks:\n")
cat("- Total observations:", nrow(px), "\n")
cat("- Date range:", min(px$date), "to", max(px$date), "\n")
cat("- Missing values per ticker:\n")
missing_counts <- px %>%
  summarise(across(-date, ~sum(is.na(.x))))
print(missing_counts)

# Check for common date index
cat("- Unique dates:", length(unique(px$date)), "\n")
cat("- Duplicate rows:", sum(duplicated(px)), "\n")

# Remove rows with any missing values for clean analysis
px_clean <- px %>% filter(complete.cases(.))
cat("- Clean observations (no missing):", nrow(px_clean), "\n")

# Write price data
write_csv(px_clean, "data/prices.csv")
cat("✓ Price data saved to data/prices.csv\n")

# Download risk-free rate from FRED
cat("\nDownloading risk-free rate (DGS1) from FRED...\n")
rf <- tq_get("DGS1", get = "economic.data", from = from, to = to) %>%
  rename(rf_pct = price) %>%
  filter(!is.na(rf_pct))

cat("Risk-free rate data:\n")
cat("- Observations:", nrow(rf), "\n")
cat("- Date range:", min(rf$date), "to", max(rf$date), "\n")
cat("- Missing values:", sum(is.na(rf$rf_pct)), "\n")

# Write risk-free data
write_csv(rf, "data/riskfree_dgs1.csv")
cat("✓ Risk-free data saved to data/riskfree_dgs1.csv\n")

cat("\n=== Data Download Complete ===\n")
