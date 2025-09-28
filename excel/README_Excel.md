# Excel @RISK + Evolver Workbook Setup

## File: robust_rp_model.xlsx

### Required Sheets and Named Ranges

#### 1. Sigma_input Sheet
- **Sigma_in**: n×n covariance matrix (10×10 for 10 ETFs)
- **mu_in**: n×1 mean return vector (or zeros for pure risk parity)
- **w_prev**: n×1 previous weights for turnover constraint

#### 2. Params Sheet
- **alpha**: RiskBeta(2,6) - shrinkage intensity toward diagonal
- **s**: RiskLognorm(0, 0.10) - scale volatility ±10%
- **rho**: RiskUniform(0.7, 1.0) - correlation dampening

#### 3. Sigma_build Sheet
- Decompose Σ̂ as D R D (diagonal and correlation)
- Raise R element-wise to power rho
- Rebuild Sigma_star = D R^rho D
- Mix with alpha and scale by s^2
- Ensure positive semi-definite by construction

#### 4. Weights Sheet
- **w_rng**: n×1 decision range for portfolio weights
- Constraints: 0 ≤ w_i ≤ w_max, sum(w) = 1, turnover ≤ τ

#### 5. RiskCalc Sheet
- Portfolio volatility: σ = sqrt(w' Σ_star w)
- Sharpe ratio: (w' μ) / σ
- Risk contributions: RC_i = w_i * (Σ_star w)_i / σ^2
- Optional penalty toward equal risk contributions

#### 6. @RISK Settings
- Latin Hypercube sampling
- 5000 iterations
- Common seed = 20251001
- Record: RiskMean(Sharpe), RiskP5(Sharpe), RiskP95(Sharpe)

#### 7. Evolver Optimization
- Objective: Maximize RiskP5(Sharpe) (worst-case Sharpe)
- Alternative: Maximize RiskMean(Sharpe)
- Subject to: bounds and turnover constraints
- Export optimal weights to /out/evolver_weights.csv
- Export simulation results to /out/risk_results.csv

### Key Formulas

#### Covariance Transformation
```
Sigma_star = s^2 * (alpha * diag(Sigma) + (1-alpha) * D * R^rho * D)
```

#### Portfolio Metrics
```
Portfolio_Vol = SQRT(MMULT(MMULT(TRANSPOSE(w_rng), Sigma_star), w_rng))
Sharpe_Ratio = MMULT(TRANSPOSE(w_rng), mu_in) / Portfolio_Vol
```

#### Risk Contributions
```
Marginal_Contrib = MMULT(Sigma_star, w_rng)
Risk_Contrib = w_rng * Marginal_Contrib / Portfolio_Vol^2
```

### Output Files
- `/out/evolver_weights.csv`: Optimal portfolio weights
- `/out/risk_results.csv`: Simulation results (Sharpe_i, alpha, s, rho)

### Usage Instructions
1. Import latest_sigma.csv and latest_mu.csv to Sigma_input sheet
2. Set up @RISK distributions in Params sheet
3. Run @RISK simulation (5000 iterations)
4. Use Evolver to optimize weights
5. Export results to /out/ directory
6. Run R script 04_integrate_evolver.R to process results
