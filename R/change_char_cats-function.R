change_char_cats = function(data, char_cats){
  data |>
    rownames_to_column(var = "Sample_accession") |>
    gather(colname, old_cat, -Sample_accession) |>
    left_join(
      char_cats
      ,by = join_by(colname, old_cat)
    )|>
    select(Sample_accession, colname, cat = new_cat) |>
    mutate_at(
      c("Sample_accession", "colname")
      ,\(x) factor(x, unique(x))
    ) |>
    spread(colname, cat) |>
    column_to_rownames(var = "Sample_accession")
}