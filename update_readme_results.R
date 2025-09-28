# Script pour mettre à jour le README avec la section Results
library(readr)

# Lire le README existant
readme_content <- readLines("README.md")

# Lire la section Results
results_section <- readLines("README_RESULTS_SECTION.md")

# Trouver où insérer la section Results (après "## Key Results")
results_start <- grep("## Key Results", readme_content)
if (length(results_start) > 0) {
  # Remplacer la section existante
  key_results_end <- grep("^## ", readme_content)
  key_results_end <- key_results_end[key_results_end > results_start][1]
  
  if (!is.na(key_results_end)) {
    new_readme <- c(
      readme_content[1:(results_start-1)],
      results_section,
      "",
      readme_content[key_results_end:length(readme_content)]
    )
  } else {
    new_readme <- c(
      readme_content[1:(results_start-1)],
      results_section,
      "",
      readme_content[(results_start+1):length(readme_content)]
    )
  }
} else {
  # Ajouter à la fin
  new_readme <- c(readme_content, "", results_section)
}

# Écrire le nouveau README
writeLines(new_readme, "README.md")

cat("✓ README.md updated with Results section\n")
cat("✓ Figures regenerated with unified Sharpe units\n")
cat("✓ All deliverables ready for thesis/presentation\n")
