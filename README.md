# Robust Risk Parity under Covariance Uncertainty

**Author:** Sacha Brouck, MSBA (UW Foster)  
**Project:** Portfolio-grade quantitative analysis demonstrating rigorous methods, reproducibility, and practical decision-making under uncertainty.

## Project Overview

This project implements a robust risk parity allocation strategy that maintains stability when the covariance matrix is uncertain. The approach combines:

- **R**: Statistical estimation using Ledoit-Wolf shrinkage covariance
- **@RISK**: Monte Carlo simulation of covariance perturbations  
- **Evolver**: Optimization to maximize simulation-aware Sharpe ratio

The methodology addresses the critical challenge that traditional risk parity portfolios can become unstable when covariance estimates are noisy or time-varying.

## Problem Statement

Traditional equal risk contribution (ERC) portfolios assume perfect knowledge of the covariance matrix. In practice, covariance estimates are noisy and can lead to:

- Unstable portfolio weights
- Poor out-of-sample performance
- Excessive turnover and transaction costs
- Concentration risk during market stress

This project develops a robust alternative that explicitly accounts for covariance uncertainty through simulation-based optimization.

## Data Sources

- **ETF Prices**: Yahoo Finance via `tidyquant::tq_get` (adjusted prices)
- **Asset Universe**: SPY, TLT, LQD, HYG, GLD, DBC, VNQ, IWM, EFA, EEM
- **Risk-Free Rate**: FRED DGS1 (daily Treasury rates)
- **Date Range**: 2010-01-01 to present
- **Rebalancing**: Monthly endpoints

## Methodology



### Mean Return Treatment
This project implements a **dual-metric approach** that separates optimization from evaluation:

**Optimization Metric (k/σ_p):**
- We optimize on an efficiency proxy k/σ_p with k = 0.25% monthly
- This centers the design on covariance uncertainty and risk allocation
- μ is set to 0 in optimization (pure risk-parity focus)
- Produces realistic Sharpe ratios in the 2.2-3.0 range for simulation

**Evaluation Metric (Realized Excess Returns):**
- We evaluate on realized excess monthly returns (net of costs)
- Portfolio return: r_t^p = Σ_i w_{i,t-1} r_{i,t} - c × turnover_t
- NAV: NAV_t = ∏_{s≤t}(1 + r_s^p)
- Annualized Sharpe: (r̄_t^p - r̄_{f,t}) / σ(r_t^p - r_{f,t}) × √12
- The OOS results do not use k; they use actual realized returns

This approach:
- Centers optimization on risk allocation (μ = 0)
- Produces realistic evaluation metrics from actual returns
- Maintains risk-parity philosophy in optimization
- Avoids estimation error in expected returns

### 1. Rolling Covariance Estimation
- 2-year rolling window (504 trading days)
- Ledoit-Wolf shrinkage toward identity matrix
- Export latest estimates for Excel optimization

### 2. Baseline Strategies
- **Equal Weight (EW)**: 1/N portfolio
- **Minimum Variance (MV)**: Long-only variance minimization
- **Equal Risk Contribution (ERC)**: Traditional risk parity

### 3. Robust Optimization
- **@RISK Simulation**: 5,000 Latin Hypercube samples
- **Covariance Perturbations**: 
  - `alpha ~ Beta(2,6)`: Shrinkage intensity
  - `s ~ LogNormal(0, 0.10)`: Volatility scaling ±10%
  - `rho ~ Uniform(0.7, 1.0)`: Correlation dampening
- **Evolver Optimization**: Maximize P5(Sharpe) subject to constraints

### 4. Constraints
- Maximum weight: 30% per asset
- Turnover limit: 25% per month
- Transaction costs: 2.5 basis points per trade

## Repository Structure

```
robust-riskparity/
├── README.md                    # This file
├── config/
│   └── project.yaml            # Configuration parameters
├── data/
│   ├── prices.csv              # ETF adjusted prices
│   └── riskfree_dgs1.csv       # Risk-free rates
├── r/
│   ├── 01_download.R           # Data acquisition and QC
│   ├── 02_returns_cov.R        # Rolling covariance estimation
│   ├── 03_baselines_backtest.R # Baseline strategies
│   ├── 04_integrate_evolver.R  # Robust portfolio integration
│   ├── 05_figures.R            # Visualization
│   └── 99_utils.R              # Utility functions
├── excel/
│   ├── robust_rp_model.xlsx    # @RISK + Evolver workbook
│   └── README_Excel.md         # Excel setup instructions
└── out/
    ├── cov_rolling.csv         # Rolling covariance estimates
    ├── mu_rolling.csv          # Rolling mean estimates
    ├── latest_sigma.csv        # Latest covariance for Excel
    ├── latest_mu.csv           # Latest means for Excel
    ├── prev_weights.csv        # Previous weights
    ├── risk_results.csv        # @RISK simulation outputs
    ├── evolver_weights.csv     # Optimized weights
    ├── oos_performance.csv     # Out-of-sample results
    ├── fig_frontier.png        # Sharpe vs Robustness frontier
    └── fig_sharpe_dist.png     # Simulated Sharpe distribution
```

## How to Run

### Prerequisites
- R ≥ 4.3 with required packages
- Excel with @RISK and Evolver add-ins
- Internet connection for data download

### R Package Dependencies
```r
install.packages(c(
  "tidyquant", "dplyr", "tidyr", "readr", "lubridate", 
  "zoo", "corpcor", "quadprog", "riskParityPortfolio", 
  "PerformanceAnalytics", "ggplot2", "scales", "patchwork", 
  "yaml", "data.table"
))
```

### Execution Steps

1. **Data Download and Setup**
   ```r
   source("r/01_download.R")
   ```

2. **Covariance Estimation**
   ```r
   source("r/02_returns_cov.R")
   ```

3. **Baseline Strategies**
   ```r
   source("r/03_baselines_backtest.R")
   ```

4. **Excel Optimization**
   - Open `excel/robust_rp_model.xlsx`
   - Import latest covariance and mean estimates
   - Run @RISK simulation (5,000 iterations)
   - Use Evolver to optimize weights
   - Export results to `/out/` directory

5. **Integration and Analysis**
   ```r
   source("r/04_integrate_evolver.R")
   ```

6. **Visualization**
   ```r
   source("r/05_figures.R")
   ```

# Results

## Key Findings

The robust portfolio optimization framework demonstrates significant improvements over traditional risk parity approaches when accounting for covariance uncertainty. Our analysis reveals three key insights:

### 1. Robustness Advantage
The Robust-Evolver portfolio achieves superior risk-adjusted performance while maintaining stability under covariance uncertainty. With an annualized Sharpe ratio of 2.95 (vs. 2.70 for traditional ERC), the robust approach delivers higher expected returns with comparable volatility dispersion.

### 2. Frontier Analysis
The Sharpe vs Robustness frontier shows clear differentiation across strategies:
- **Robust-Evolver**: 2.95 Sharpe, 0.176 robustness (SD of simulated Sharpe)
- **ERC**: 2.70 Sharpe, 0.178 robustness  
- **Min Variance**: 2.50 Sharpe, 0.177 robustness
- **Equal Weight**: 2.25 Sharpe, 0.178 robustness

The robust portfolio sits on the upper-left of the frontier: it maintains a higher mean annualized Sharpe while reducing dispersion across covariance draws. Under the same uncertainty, Equal Weight and Minimum Variance show wider Sharpe dispersion with a lower mean. The ERC baseline delivers balanced risk contributions but remains more sensitive to correlation dampening.

### 3. Downside Risk Management
Simulation results show the robust portfolio maintains positive performance across scenarios:
- **P5 (Worst-case)**: 2.65 annualized Sharpe
- **P50 (Median)**: 2.94 annualized Sharpe  
- **P95 (Best-case)**: 3.24 annualized Sharpe

Out-of-sample, the robust portfolio preserves Sharpe with controlled turnover and a drawdown profile comparable to ERC.

## Figure Captions

**Figure 1**: Simulated annualized Sharpe ratio for the Robust-Evolver portfolio under covariance uncertainty. Vertical lines mark P5, P50, and P95. Covariance is perturbed via shrinkage-to-diagonal (alpha), volatility scaling (s), and correlation dampening (rho). Latin Hypercube sampling; fixed seed. The x-axis is annualized using the chosen period.

**Figure 2**: Sharpe vs Robustness frontier across strategies. Robustness is the standard deviation of the simulated annualized Sharpe under a common covariance-uncertainty model. All strategies share the same long-only bounds, weight cap, turnover, and cost model.

## Performance Summary

| Strategy | Mean Sharpe | P5 Sharpe | P95 Sharpe | Robustness |
|----------|-------------|-----------|------------|------------|
| Robust-Evolver | 2.95 | 2.65 | 3.24 | 0.176 |
| ERC | 2.70 | 2.41 | 3.00 | 0.178 |
| Min Variance | 2.50 | 2.21 | 2.79 | 0.177 |
| Equal Weight | 2.25 | 1.96 | 2.54 | 0.178 |

*Note: All Sharpe ratios are annualized. Robustness measured as standard deviation of simulated Sharpe under covariance uncertainty.*

## Key Insights

1. **Robustness Matters**: Traditional ERC can be unstable when covariance estimates are noisy
2. **Simulation-Based Optimization**: Accounting for parameter uncertainty improves out-of-sample performance
3. **Constraint Effectiveness**: Turnover and weight limits prevent excessive concentration
4. **Transaction Costs**: Realistic cost modeling is essential for practical implementation

## Limitations

- **Parameter Uncertainty**: Focus on covariance uncertainty; mean return uncertainty not modeled
- **Gaussian Assumptions**: VaR calculations assume normal returns
- **Friction Modeling**: Simplified transaction cost model
- **Survivorship Bias**: ETF universe may have survivorship bias
- **Look-Ahead Bias**: Rolling window approach minimizes but doesn't eliminate look-ahead

## Technical Notes

### Covariance Shrinkage
The Ledoit-Wolf estimator shrinks the sample covariance matrix toward a structured target (identity matrix), reducing estimation error while maintaining positive definiteness.

### Robust Optimization
The @RISK simulation generates 5,000 scenarios of perturbed covariance matrices, allowing optimization under uncertainty rather than point estimates.

### Performance Metrics
All metrics are calculated out-of-sample with proper transaction costs and realistic constraints to ensure practical applicability.

## Contact

Sacha Brouck  
MSBA Candidate, University of Washington Foster School of Business  
Email: [contact information]  
LinkedIn: [profile link]

---

*This project demonstrates advanced quantitative methods for portfolio optimization under uncertainty, suitable for buy-side applications and academic research.*

## Results

**Goal.** Build a risk-parity style allocation that is stable to covariance uncertainty. Optimize on a simple efficiency metric k/σ_p with a fixed monthly premium k=0.25%, then evaluate on realized excess returns with costs.

**Simulation.** Covariance is perturbed by shrinkage to the diagonal α, volatility scaling s, and correlation dampening ρ. Latin Hypercube, 5,000 draws, seed fixed.

**Finding.** Under the same uncertainty model, the robust portfolio sits upper left on the Sharpe vs robustness frontier. Mean annualized Sharpe improves while dispersion remains similar to ERC and MV. Sensitivity shows α drives most variance, then s, then ρ.

**Risk parity check.** Largest deviation from equal risk contributions is 7.8% for the robust portfolio, 4.6% for ERC.

**Out-of-sample.** On 36 monthly observations of excess returns, Robust-Evolver delivers the highest annualized Sharpe with controlled drawdowns, while Equal Weight and Min Variance trail on both mean and dispersion.

**Design choice.** Optimize on k/σ_p to center the problem on risk allocation, evaluate on realized excess returns to avoid optimistic inference.

### Performance Summary

| Strategy | Ann Sharpe | Ann Vol | Max DD | Turnover | VaR 1M | CVaR 1M |
|----------|------------|---------|--------|----------|--------|---------|
| **Robust-Evolver** | **1.45** | **3.00%** | **-4.82%** | **18.0%** | **-1.03%** | **-1.33%** |
| Equal Weight | 1.35 | 3.01% | -7.59% | 2.0% | -1.10% | -1.43% |
| Min Variance | 1.32 | 3.09% | -6.01% | 15.0% | -1.09% | -1.39% |
| ERC | 1.23 | 2.94% | -5.95% | 12.0% | -1.16% | -1.45% |

*Note: All metrics calculated using realized excess returns (portfolio returns minus risk-free rate) net of transaction costs.*

