# Functions

interest_pay <- function(capital, rate){
  capital*rate
}

total_pay <- function(capital, rate, n){
  interest_pay(capital = capital, rate = rate)/(1-(1+rate)^(-n))
}

capital_pay <- function(capital, rate, n){
  total_pay(capital = capital, rate = rate, n = n) - 
    interest_pay(capital = capital, rate = rate)
}

to_uvi <- function(capital, price){
  capital/price
}

to_capital <- function(uvi, price){
  price * uvi
}


compund_rate <- function(rate, n){
  (rate + 1)^n - 1
}

decompund_rate <- function(rate, n){
  (rate + 1)^(1/n) - 1
}

to_monthly_rate <- function(rate){
  decompund_rate(rate, 12)
}

to_yearly_rate <- function(rate){
  compund_rate(rate, 12)
}


calculate_period <- function(uvi, price, rate, n) {
  capital <- to_capital(uvi, price)
  int_pay <- interest_pay(capital, rate)
  tot_pay <- total_pay(capital, rate, n)
  cap_pay <- tot_pay - int_pay
  capital_left <- capital - cap_pay
  uvi <- to_uvi(capital_left, price)
  
  data.frame(uvi, capital_left, cap_pay, int_pay, tot_pay)
}

cum_inflation <- function(x){
  cumprod(x + 1)
}

linear_inflation <- function(initial, final, n) {
  res <- approx(x = c(initial, final), y = c(1, n), n = n)
  res[["x"]]
}

spline_inflation <- function(x, y, n) {
  res <- spline(x = c(initial, final), y = c(1, n), n = n)
  res[["x"]]
}
interpolate_inflation <- function(x, n){
  if(length(unique(x)) == 1) return(rep(x[1], n))
  
  if(length(x) == 2)
    return(linear_inflation(x[1], x[2], n))
  
}

match_all <- function(object, pattern){
  matched <- grep(pattern, names(object))
  lapply(names(object)[matched], function(id) object[[id]])
  
}


lifetime_loan <- function(capital, price, yearly_rate, n, inflation){
  
  uvi <- to_uvi(capital, price)
  rate <- to_monthly_rate(yearly_rate)
  ns <- seq(0, n - 1)
  cumulative_inflation <- cum_inflation(inflation)
  monthly_price <- price * cumulative_inflation
  
  res <- vector(mode = "list", length = n + 1)
  for(i in ns) {
    if(i > 0)  uvi <- res[[i]][, "uvi"]
    price <- monthly_price[i + 1]
    res[[i + 1]] <- calculate_period(uvi, price, rate, n - i)
  }
  res <- do.call(rbind, res)
  res <- transform(res, n = rev(ns), p = ns, 
                   cum_interest_paid = cumsum(int_pay),
                   cum_capital_paid = cumsum(cap_pay),
                   cum_total_paid = cumsum(tot_pay))
  res
}

