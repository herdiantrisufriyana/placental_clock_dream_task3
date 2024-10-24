add_strata_data <- function(data){
  data |>
    left_join(
      ano_ori_ga_conds |>
        rownames_to_column(var = "Sample_accession")
      ,by = join_by(Sample_accession)
    ) |>
    left_join(
      ano_ori_ga_non_conds |>
        select(-Dataset_ID, -GA, -ceiled_GA) |>
        rownames_to_column(var = "Sample_accession")
      ,by = join_by(Sample_accession)
    ) |>
    column_to_rownames(var = "Sample_accession") |>
    mutate(
      trimester =
        case_when(
          ceiled_GA <= 12 ~ "First"
          ,ceiled_GA >= 13 & ceiled_GA <= 26 ~ "Second"
          ,ceiled_GA >= 27 & ceiled_GA <= 36 ~ "Third, preterm"
          ,ceiled_GA >= 37 ~ "Third, term"
          # ,ceiled_GA >= 37 & ceiled_GA <= 42 ~ "Third, term"
          # ,ceiled_GA > 42 ~ "Third, postterm"
        )
    ) |>
    select(
      Y = GA
      ,Yhat = prediction
      ,ceiled_GA
      ,Dataset_ID
      ,trimester
      ,everything()
    )
}