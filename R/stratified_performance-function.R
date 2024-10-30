stratified_performance <- function(eval_data, model_name, subchallenge=2){
  
  leaderboard_results <-
    submission |>
    filter(model == model_name) |>
    left_join(performance, by = join_by(sub, task)) |>
    left_join(leaderboard, by = join_by(metric, task)) |>
    mutate(lb = val, ub = val) |>
    rename(strata = code, level = rank, avg = val) |>
    mutate(strata = "Leaderboard", level = "Yes") |>
    select(-model, -sub)
  
  if(nrow(leaderboard_results) == 0){
    leaderboard_results <-
      data.frame(
        strata = "Leaderboard"
        ,level = "Yes"
        ,metric = c("RMSE", "MAE", "r")
        ,avg = c(0, 0, 0)
        ,lb = c(0, 0, 0)
        ,ub = c(0, 0, 0)
        ,task = subchallenge
      ) |>
      left_join(leaderboard, by = join_by(metric, task))
  }
  
  results <-
    var_ga |>
    unique() |>
    c("trimester", "Dataset_ID", "all") |>
    imap(
      ~ eval_data |>
        mutate(all = "all") |>
        mutate(strata = .x) |>
        rename_at(.x, \(x) "level") |>
        eval_prediction()
    ) |>
    reduce(rbind) |>
    mutate(task = subchallenge) |>
    left_join(leaderboard, by = join_by(metric, task)) |>
    rbind(leaderboard_results) |>
    select(-task)
  
  results |>
    left_join(
      results |>
        filter(strata == "all") |>
        mutate(
          all =
            ifelse(
              metric == "r"
              ,lb - 1.5 * (ub - lb)
              ,ub + 1.5 * (ub - lb)
            )
        ) |>
        select(metric, all)
      ,by = join_by(metric)
    ) |>
    mutate(
      metric = factor(metric, c("RMSE", "MAE", "r"))
      ,strata = factor(strata, unique(strata))
      ,win =
        ifelse(
          metric == "r"
          ,ifelse(lb > current_best, "Yes", "No")
          ,ifelse(ub < current_best, "Yes", "No")
        )
      ,robust =
        ifelse(
          metric == "r"
          ,ifelse(ub >= all, "Yes", "No")
          ,ifelse(lb <= all, "Yes", "No")
        )
    ) |>
    mutate(model = model_name) |>
    select(model, everything())
}