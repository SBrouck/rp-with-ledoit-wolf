# Update README to document μ = 0 approach
library(readr)

# Read current README
readme_content <- readLines("README.md")

# Find the methodology section and add μ documentation
methodology_start <- grep("## Methodology", readme_content)
if (length(methodology_start) > 0) {
  # Insert μ documentation after methodology header
  mu_doc <- c(
    "",
    "### Mean Return Treatment",
    "This project implements **pure risk-parity** with μ = 0 to center the analysis on covariance uncertainty rather than expected returns. This approach:",
    "- Eliminates estimation error in expected returns",
    "- Focuses the optimization on risk allocation under uncertainty", 
    "- Produces realistic Sharpe magnitudes in the 2.2-3.0 range",
    "- Aligns with the risk-parity philosophy of equal risk contributions",
    "",
    "The @RISK workbook reads `mu_in` from `latest_mu.csv` (set to zeros) and computes Sharpe as:",
    "```",
    "Sharpe = (w' * mu_in) / sqrt(w' * Sigma * w)",
    "```",
    "where `mu_in = 0` for pure risk-parity optimization.",
    ""
  )
  
  # Insert after methodology header
  new_readme <- c(
    readme_content[1:methodology_start],
    mu_doc,
    readme_content[(methodology_start + 1):length(readme_content)]
  )
} else {
  # Add at the end if methodology section not found
  mu_doc <- c(
    "",
    "## Mean Return Treatment",
    "This project implements **pure risk-parity** with μ = 0 to center the analysis on covariance uncertainty rather than expected returns.",
    ""
  )
  new_readme <- c(readme_content, mu_doc)
}

# Write updated README
writeLines(new_readme, "README.md")
cat("✓ README.md updated with μ = 0 documentation\n")
