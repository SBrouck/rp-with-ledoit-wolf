# 99_utils.R
# Utility functions for robust risk parity portfolio
# Author: Sacha Brouck, MSBA (UW Foster)

# Load required libraries
library(quadprog)
library(riskParityPortfolio)
library(PerformanceAnalytics)
library(dplyr)
library(ggplot2)
library(scales)
library(patchwork)

# Portfolio optimization functions

#' Solve minimum variance portfolio (long-only)
#' @param Sigma Covariance matrix
#' @param w_max Maximum weight per asset
#' @return Optimal weights
solve_mv_longonly <- function(Sigma, w_max = 0.30) {
  n <- nrow(Sigma)
  
  # Quadratic programming setup
  Dmat <- 2 * Sigma
  dvec <- rep(0, n)
  
  # Constraints: sum(w) = 1, w >= 0, w <= w_max
  Amat <- cbind(
    rep(1, n),    # sum constraint
    diag(n),      # non-negativity
    -diag(n)      # upper bound
  )
  bvec <- c(1, rep(0, n), rep(-w_max, n))
  
  # Solve
  result <- solve.QP(Dmat, dvec, Amat, bvec, meq = 1)
  
  if (result$value < 0) {
    warning("QP solver failed, using equal weights")
    return(rep(1/n, n))
  }
  
  return(result$solution)
}

#' Solve equal risk contribution (ERC) portfolio
#' @param Sigma Covariance matrix
#' @param w_max Maximum weight per asset
#' @return Optimal weights
solve_erc <- function(Sigma, w_max = 0.30) {
  tryCatch({
    # Use riskParityPortfolio package
    result <- riskParityPortfolio(Sigma, w_max = w_max)
    return(result$w)
  }, error = function(e) {
    warning("ERC solver failed, using equal weights: ", e$message)
    return(rep(1/nrow(Sigma), nrow(Sigma)))
  })
}

#' Compute portfolio risk contributions
#' @param w Portfolio weights
#' @param Sigma Covariance matrix
#' @return Risk contributions
risk_contributions <- function(w, Sigma) {
  portfolio_var <- as.numeric(t(w) %*% Sigma %*% w)
  marginal_contrib <- Sigma %*% w
  contrib <- w * marginal_contrib / portfolio_var
  return(contrib)
}

# Performance metrics functions

#' Annualized Sharpe ratio
#' @param returns Vector of returns
#' @return Annualized Sharpe ratio
annualized_sharpe <- function(returns) {
  if (length(returns) == 0 || all(is.na(returns))) return(NA)
  mean_ret <- mean(returns, na.rm = TRUE)
  vol_ret <- sd(returns, na.rm = TRUE)
  if (vol_ret == 0) return(NA)
  return(mean_ret / vol_ret * sqrt(252))
}

#' Maximum drawdown
#' @param nav Vector of NAV values
#' @return Maximum drawdown
max_drawdown <- function(nav) {
  if (length(nav) == 0) return(NA)
  PerformanceAnalytics::maxDrawdown(nav)
}

#' Value at Risk (VaR)
#' @param returns Vector of returns
#' @param p Confidence level (default 0.05 for 5% VaR)
#' @return VaR
var_calc <- function(returns, p = 0.05) {
  if (length(returns) == 0 || all(is.na(returns))) return(NA)
  quantile(returns, p, na.rm = TRUE)
}

#' Conditional Value at Risk (CVaR)
#' @param returns Vector of returns
#' @param p Confidence level (default 0.05 for 5% CVaR)
#' @return CVaR
cvar_calc <- function(returns, p = 0.05) {
  if (length(returns) == 0 || all(is.na(returns))) return(NA)
  var_val <- var_calc(returns, p)
  mean(returns[returns <= var_val], na.rm = TRUE)
}

#' Portfolio turnover
#' @param weights_new New portfolio weights
#' @param weights_old Previous portfolio weights
#' @return Turnover (sum of absolute weight changes)
turnover <- function(weights_new, weights_old) {
  sum(abs(weights_new - weights_old))
}

# Backtesting function

#' Run out-of-sample backtest
#' @param returns_df Data frame with returns
#' @param rebalance_dates Vector of rebalancing dates
#' @param weights_fn Function that takes (Sigma, mu) and returns weights
#' @param costs Transaction costs in basis points
#' @param strategy_name Name of the strategy
#' @return Data frame with backtest results
backtest_strategy <- function(returns_df, rebalance_dates, weights_fn, costs = 2.5, strategy_name = "Strategy") {
  
  results <- list()
  nav <- 1.0
  prev_weights <- rep(1/length(tickers), length(tickers))
  
  for (i in seq_along(rebalance_dates)) {
    if (i == length(rebalance_dates)) break
    
    # Current rebalancing date
    rebal_date <- rebalance_dates[i]
    next_rebal_date <- rebalance_dates[i + 1]
    
    # Get estimation window (up to current date)
    est_data <- returns_df %>%
      filter(date <= rebal_date) %>%
      tail(504)  # 2-year window
    
    if (nrow(est_data) < 100) next  # Need sufficient data
    
    # Estimate covariance and mean
    R_est <- as.matrix(est_data[, tickers])
    Sigma_est <- cov(R_est, use = "complete.obs")
    mu_est <- colMeans(R_est, na.rm = TRUE)
    
    # Get optimal weights
    tryCatch({
      new_weights <- weights_fn(Sigma_est, mu_est)
    }, error = function(e) {
      warning("Weight optimization failed for ", strategy_name, " at ", rebal_date, ": ", e$message)
      new_weights <- prev_weights
    })
    
    # Calculate turnover and transaction costs
    turnover_val <- turnover(new_weights, prev_weights)
    cost_impact <- turnover_val * costs / 10000  # Convert bps to decimal
    
    # Get out-of-sample period
    oos_data <- returns_df %>%
      filter(date > rebal_date, date <= next_rebal_date)
    
    if (nrow(oos_data) == 0) next
    
    # Calculate portfolio returns
    portfolio_returns <- rowSums(oos_data[, tickers] * matrix(new_weights, nrow = nrow(oos_data), ncol = length(tickers), byrow = TRUE))
    
    # Apply transaction costs to first return
    if (length(portfolio_returns) > 0) {
      portfolio_returns[1] <- portfolio_returns[1] - cost_impact
    }
    
    # Update NAV
    nav <- nav * prod(1 + portfolio_returns)
    
    # Store results
    results[[i]] <- data.frame(
      strategy = strategy_name,
      date = rebal_date,
      ret = mean(portfolio_returns, na.rm = TRUE),
      nav = nav,
      vol_20d = sd(portfolio_returns, na.rm = TRUE) * sqrt(252),
      turnover = turnover_val,
      var_1m = var_calc(portfolio_returns, 0.05),
      cvar_1m = cvar_calc(portfolio_returns, 0.05)
    )
    
    prev_weights <- new_weights
  }
  
  return(bind_rows(results))
}

# Plotting themes

#' Clean ggplot theme for financial plots
theme_finance <- function() {
  theme_minimal() +
    theme(
      text = element_text(size = 12),
      axis.title = element_text(size = 11),
      axis.text = element_text(size = 10),
      legend.title = element_text(size = 11),
      legend.text = element_text(size = 10),
      plot.title = element_text(size = 14, hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5),
      panel.grid.minor = element_blank(),
      strip.text = element_text(size = 10)
    )
}

cat("✓ Utility functions loaded\n")
