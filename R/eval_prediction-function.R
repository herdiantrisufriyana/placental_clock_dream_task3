eval_prediction <- function(data){
  boot_eval <- list()
  
  for(b in seq(30)){
    set.seed(seed + b)
    
    i <-
      data |>
      nrow() |>
      seq() |>
      sample(size = 10 * nrow(data), replace = TRUE)
    
    boot_eval[[b]] <-
      data[i, , drop = FALSE] |>
      group_by(strata, level) |>
      summarize(
        RMSE = rmse(Y, Yhat, na.rm =TRUE)
        ,MAE = mae(Y, Yhat, na.rm =TRUE)
        ,r = cor.test(Y, Yhat)$estimate
        ,.groups = "drop"
      )
  }
  
  boot_eval <-
    boot_eval |>
    reduce(rbind) |>
    mutate_at(c("RMSE", "MAE", "r"), as.numeric) |>
    gather(metric, value, -strata, -level) |>
    group_by(strata, level, metric) |>
    summarize(
      avg = mean(value)
      ,lb = mean(value) - qnorm(0.975) * sd(value) / sqrt(n())
      ,ub = mean(value) + qnorm(0.975) * sd(value) / sqrt(n())
      ,.groups = "drop"
    ) |>
    mutate_at(c("avg", "lb", "ub"), round, 3)
}