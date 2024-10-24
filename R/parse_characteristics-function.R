parse_characteristics = function(data){
  data <-
    data |>
    select_at(
      colnames(data)[
        str_detect(colnames(data), "characteristics_ch|Characteristics")
      ]
    )
  
  if(all(str_detect(colnames(data), "characteristics_ch"))){
    data <-
      data |>
      rownames_to_column(var = "Sample_accession") |>
      gather(colname, `variable: value`, -Sample_accession) |>
      filter(`variable: value` != "") |>
      separate(`variable: value`, c("variable", "value"), sep = "\\: ") |>
      select(-colname) |>
      mutate_at(c("Sample_accession", "variable"), \(x) factor(x, unique(x))) |>
      unique() |>
      spread(variable, value) |>
      column_to_rownames(var = "Sample_accession")
  }
  
  if(all(str_detect(colnames(data), "Characteristics"))){
    data <-
      data |>
      `colnames<-`(
        colnames(data) |>
          str_remove_all("Characteristics\\[|\\]")
      )
  }
  
  data
}