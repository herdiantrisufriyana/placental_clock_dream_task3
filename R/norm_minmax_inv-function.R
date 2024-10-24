norm_minmax_inv <- function(p, xmin, xmax){
  p * (xmax - xmin) + xmin
}