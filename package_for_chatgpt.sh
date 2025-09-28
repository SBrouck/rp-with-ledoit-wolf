#!/bin/bash
# Package all essential files for ChatGPT continuation

echo "=== Packaging Files for ChatGPT ==="

# Create a summary of what to send
cat > CHATGPT_CONTEXT.md << 'EOL'
# Files to Send to ChatGPT for Project Continuation

## Send these files in this order:

### 1. Project Overview
- README.md
- PROJECT_SUMMARY.md  
- config/project.yaml

### 2. Core R Scripts
- r/01_download.R
- r/02_returns_cov.R
- r/03_baselines_backtest.R
- r/04_integrate_evolver.R
- r/05_figures.R
- r/99_utils.R

### 3. Excel Integration
- excel/README_Excel.md
- excel/robust_rp_model_template.csv

### 4. Sample Data (first 10 rows)
- data/prices.csv (head -10)
- data/riskfree_dgs1.csv (head -10)
- out/oos_performance.csv
- out/risk_results.csv
- out/evolver_weights.csv

### 5. Generated Figures
- out/fig_frontier.png
- out/fig_sharpe_dist.png

## Context Summary:
This is a robust risk parity portfolio optimization project that combines R, @RISK, and Evolver. The project is 90% complete with working R scripts, dummy data, and generated figures. The next steps are to install R packages and set up the Excel @RISK + Evolver workbook for full functionality.

## Current Status:
- ✅ Project structure complete
- ✅ R scripts written and tested
- ✅ Dummy data generated
- ✅ Figures created
- ⏳ Need to install R packages
- ⏳ Need to set up Excel workbook
- ⏳ Need to run with real data
EOL

echo "✓ Created CHATGPT_CONTEXT.md with instructions"

# Create a zip file with all essential files
zip -r robust_riskparity_for_chatgpt.zip \
  README.md \
  PROJECT_SUMMARY.md \
  CHATGPT_CONTEXT.md \
  config/ \
  r/ \
  excel/ \
  out/fig_frontier.png \
  out/fig_sharpe_dist.png \
  out/oos_performance.csv \
  out/risk_results.csv \
  out/evolver_weights.csv

echo "✓ Created robust_riskparity_for_chatgpt.zip"

# Show file sizes
echo ""
echo "Files to send to ChatGPT:"
ls -la README.md PROJECT_SUMMARY.md CHATGPT_CONTEXT.md
ls -la robust_riskparity_for_chatgpt.zip

echo ""
echo "=== Ready for ChatGPT ==="
echo "Send the zip file and mention: 'This is a robust risk parity portfolio project. Please continue from where it left off.'"
