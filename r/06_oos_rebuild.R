library(readr); library(dplyr); library(lubridate); library(xts); library(PerformanceAnalytics)

# Inputs
prices <- read_csv("data/prices.csv", show_col_types = FALSE)   # adjusted prices
rf     <- read_csv("data/riskfree_dgs1.csv", show_col_types = FALSE)  # daily 1y yield (%)
oos_w  <- read_csv("out/weights_timeline.csv", show_col_types = FALSE) # one row per month per strategy with weights w_i,t

# 1) Monthly asset returns
px_xts <- xts(prices[,-1], order.by = as.Date(prices$date))
ret_d  <- Return.calculate(px_xts, method = "log")
ret_m  <- apply.monthly(ret_d, colSums)      # monthly log-returns
ret_m  <- exp(ret_m) - 1                     # to simple returns
ret_tbl <- tibble(date = as.Date(index(ret_m)), coredata(ret_m))

# 2) Monthly risk-free (convert to simple monthly)
rf_xts <- xts(rf$rf_pct/100, order.by = as.Date(rf$date))  # rate in decimal
rf_m   <- apply.monthly(rf_xts, mean)
rf_m_s <- (1 + rf_m/12) - 1
rf_tbl <- tibble(date = as.Date(index(rf_m_s)), rf = as.numeric(rf_m_s))

# 3) Join weights for each strategy and compute portfolio returns
# expected schema of weights_timeline.csv:
# date,strategy,SPY,TLT,... (same columns as asset names),turnover,cost_bps
w <- read_csv("out/weights_timeline.csv", show_col_types = FALSE)

calc_port <- function(df, strat) {
  ws <- df %>% filter(strategy == strat)
  dfj <- ws %>% left_join(ret_tbl, by = "date") %>% left_join(rf_tbl, by = "date")
  assets <- intersect(colnames(ret_tbl)[-1], colnames(ws))
  stopifnot(length(assets) > 0)
  r_p  <- as.matrix(dfj[, assets]) %*% as.matrix(t(dfj[, assets]))  # placeholder to trigger stop if wrong
}

# safer explicit loop
build_series <- function(ws) {
  assets <- intersect(colnames(ret_tbl)[-1], colnames(ws))
  X <- ws %>% left_join(ret_tbl, by = "date") %>% left_join(rf_tbl, by = "date")
  # portfolio return net of costs (bps on turnover)
  r_raw <- rowSums(as.matrix(X[, assets]) * as.matrix(ws[, assets]))
  cost  <- if ("cost_bps" %in% names(ws)) ws$cost_bps/1e4 else 0
  r_net <- r_raw - cost * (ws$turnover %||% 0)
  tibble(date = X$date, ret = r_net, rf = X$rf)
}

make_nav <- function(series) {
  nav <- cumprod(1 + series$ret - series$rf)  # excess return NAV
  peak <- cummax(nav)
  dd <- (nav - peak)/peak
  tibble(date = series$date, ret = series$ret - series$rf, nav = nav, dd = dd)
}

weights_tl <- read_csv("out/weights_timeline.csv", show_col_types = FALSE)
strategies <- unique(weights_tl$strategy)

oos_full <- bind_rows(lapply(strategies, function(s) {
  ws <- weights_tl %>% filter(strategy == s) %>% arrange(date)
  ser <- build_series(ws)
  nav <- make_nav(ser)
  nav %>% mutate(strategy = s)
}))

# 4) Summary metrics
sumtab <- oos_full %>%
  group_by(strategy) %>%
  summarise(
    ann_sharpe = mean(ret, na.rm=TRUE)/sd(ret, na.rm=TRUE)*sqrt(12),
    ann_vol    = sd(ret, na.rm=TRUE)*sqrt(12),
    max_dd     = min(dd, na.rm=TRUE),
    turnover_m = mean(weights_tl$turnover[weights_tl$strategy==first(strategy)], na.rm=TRUE),
    var_1m     = quantile(ret, 0.05, na.rm=TRUE),
    cvar_1m    = mean(ret[ret <= var_1m], na.rm=TRUE)
  ) %>% arrange(desc(ann_sharpe))

write_csv(oos_full, "out/oos_rebuilt.csv")
write_csv(sumtab,   "out/oos_summary.csv")

# 5) Drawdown plot
library(ggplot2); library(scales)
p_dd <- ggplot(oos_full, aes(date, dd, color = strategy)) +
  geom_line(size=.7) +
  scale_y_continuous(labels = percent) +
  labs(title = "Out-of-sample drawdowns",
       y = "Drawdown", x = NULL,
       caption = "Monthly excess returns; costs and turnover applied") +
  theme_minimal(base_size = 12)
ggsave("out/fig_drawdown.png", p_dd, width = 10, height = 5.5, dpi = 200)
