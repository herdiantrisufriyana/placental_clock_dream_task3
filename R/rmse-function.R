rmse <- function(actual, predicted, na.rm = FALSE) {
  sqrt(mean((predicted - actual) ^ 2, na.rm = na.rm))
}