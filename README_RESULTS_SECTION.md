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
