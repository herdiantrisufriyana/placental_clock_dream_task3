change_char_names = function(data, char_names){
  data |>
    rownames_to_column(var = "Sample_accession") |>
    gather(old_colname, value, -Sample_accession) |>
    left_join(
      char_names
      ,by = join_by(old_colname)
    )|>
    select(Sample_accession, colname = new_colname, value) |>
    mutate_at(
      c("Sample_accession", "colname")
      ,\(x) factor(x, unique(x))
    ) |>
    spread(colname, value) |>
    column_to_rownames(var = "Sample_accession")
}