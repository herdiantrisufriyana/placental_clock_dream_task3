stratified_plot_element <- function(eval_results, benchmark = "win"){
  eval_results |>
    left_join(submission, by = join_by(model)) |>
    left_join(
      performance |>
        mutate(metric = factor(metric, c("RMSE", "MAE", "r")))
      , by = join_by(sub, metric)
    ) |>
    mutate_at(
      c("sub", "code", "rank", "val")
      ,\(x) ifelse(is.na(x), "", x)
    ) |>
    rename_at(benchmark, \(x) "benchmark") |>
    mutate(avg  = ifelse(avg >= 5, 5, avg)) |>
    ggplot(aes(level, avg, fill = benchmark)) +
    geom_col() +
    facet_grid(
      strata ~ metric
      ,scales = "free"
      ,space = "free_y"
      ,switch = "y"
    ) +
    coord_flip() +
    xlab("") +
    scale_y_continuous(
      ""
      ,breaks = c(0, 0.25, 0.5, 0.75, 1, 2, 3, 5)
      ,labels = c(0, "", "", "", 1, 2, 3, 5)
    ) +
    scale_fill_discrete(benchmark) +
    theme(strip.text.y.left = element_text(angle = 0))
}