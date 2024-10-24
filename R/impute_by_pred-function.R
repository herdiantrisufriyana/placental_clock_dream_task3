impute_by_pred <- function(data, outcome, pred_data, pos = "Yes", neg = "No"){
  data <-
    data |>
    rename_at(outcome, \(x) "target")
  
  data |>
    mutate(
      target =
        data |>
        select(target) |>
        rownames_to_column(var = "Sample_accession") |>
        left_join(
          pred_data |>
            rownames_to_column(var = "Sample_accession")
          ,by = join_by(Sample_accession)
        ) |>
        mutate(
          target =
            ifelse(
              is.na(target)
              ,ifelse(prediction == 1, pos, neg)
              ,target
            )
        ) |>
        pull(target)
    ) |>
    rename_at("target", \(x) outcome)
}