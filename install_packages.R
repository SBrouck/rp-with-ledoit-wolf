# Install required packages for robust risk parity project
# Use user library to avoid permission issues

# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Create user library if it doesn't exist
user_lib <- Sys.getenv("R_LIBS_USER")
if (!dir.exists(user_lib)) {
  dir.create(user_lib, recursive = TRUE)
}

# Set library path
.libPaths(c(user_lib, .libPaths()))

required_packages <- c(
  "tidyquant", "dplyr", "tidyr", "readr", "lubridate", 
  "zoo", "corpcor", "quadprog", "riskParityPortfolio", 
  "PerformanceAnalytics", "ggplot2", "scales", "patchwork", 
  "yaml", "data.table"
)

# Install packages if not already installed
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg, dependencies = TRUE, lib = user_lib)
    library(pkg, character.only = TRUE)
  } else {
    cat(pkg, "already installed\n")
  }
}

cat("All required packages installed successfully!\n")
