test_idx_to_accession <- function(path, accession){
  read_csv(path, show_col_types = FALSE) |>
    mutate(
      Sample_accession =
        sapply(idx, \(x) accession[x])
    ) |>
    pull(Sample_accession)
}