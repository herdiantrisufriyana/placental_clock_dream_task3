mae <- function(actual, predicted, na.rm = FALSE) {
  mean(abs(predicted - actual), na.rm = na.rm)
}