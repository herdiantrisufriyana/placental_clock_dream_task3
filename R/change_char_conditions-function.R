change_char_conditions = function(data, char_conditions){
  data <-
    data |>
    select_at(
      colnames(data)[
        colnames(data) |>
          str_detect("^condition")
      ]
    )
  
  if(ncol(data) == 0){
    data
  }else{
    data |>
      rownames_to_column(var = "Sample_accession") |>
      mutate(seq = seq(n())) |>
      gather(old_colname, old_condition, -seq, -Sample_accession) |>
      left_join(
        char_conditions
        ,by = join_by(old_colname, old_condition)
        ,relationship = "many-to-many"
      ) |>
      select(
        seq
        ,Sample_accession
        ,colname = new_colname
        ,condition = new_condition
      ) |>
      mutate_at(
        c("Sample_accession", "colname")
        ,\(x) factor(x, unique(x))
      ) |>
      unique() |>
      filter(!is.na(colname)) |>
      spread(colname, condition) |>
      arrange(seq) |>
      select(-seq) |>
      column_to_rownames(var = "Sample_accession")
  }
}