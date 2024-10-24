norm_minmax = function(x, xmin, xmax){
  p <- (x - xmin) / (xmax - xmin)
  ifelse(p < 0, 0, ifelse(p > 1, 1, p))
}