imputation <- function(obj, step, ...){
  if(step == "Identify datasets"){
    obj$data <-
      obj$data0 |>
      pull(Dataset_ID) |>
      unique()
    
    obj$data <-
      obj$data |>
      `names<-`(obj$data) |>
      lapply(
        \(x)
        list(
          Sample_accession =
            obj$data0 |>
            filter(Dataset_ID == x) |>
            rownames()
          ,Sample_Name =
            ano |>
            filter(
              Sample_accession
              %in% c(
                obj$data0 |>
                  filter(Dataset_ID == x) |>
                  rownames()
              )
            ) |>
            pull(Sample_Name)
        )
      )
  }
  
  if(step == "Identify DMPs"){
    obj$dmp <-
      champ.DMP(
        beta =
          beta_norm_bmiq[, bind_rows(obj$data)$Sample_Name, drop = FALSE] |>
          as.matrix() |>
          `class<-`("matrix_array")
        ,pheno =
          obj$data0[bind_rows(obj$data)$Sample_accession, ,drop = FALSE] |>
          pull(outcome)
        ,...
      )
  }
  
  if(step == "Imputation train set"){
    obj$imp_train_set <-
      beta_norm_bmiq[
        rownames(obj$dmp[[obj$dmp_comparison]])
        ,bind_rows(obj$data)$Sample_Name
        ,drop = FALSE
      ] |>
      `colnames<-`(bind_rows(obj$data)$Sample_accession) |>
      t() |>
      as.data.frame() |>
      rownames_to_column(var = "Sample_accession") |>
      left_join(
        obj$data0 |>
          rownames_to_column(var = "Sample_accession") |>
          select(-Dataset_ID)
        ,by = join_by(Sample_accession)
      ) |>
      mutate(outcome = as.integer(outcome == obj$dmp_outcome_cat)) |>
      select(outcome, everything()) |>
      column_to_rownames(var = "Sample_accession")
  }
  
  if(step == "Identify imputee data"){
    obj$data_imputee <-
      list(
        Sample_accession =
          obj$data_imputee
        ,Sample_Name =
          ano |>
          filter(
            Sample_accession
            %in% c(
              obj$data_imputee
            )
          ) |>
          pull(Sample_Name)
      )
  }
  
  if(step == "Imputation set"){
    obj$imp_set <-
      beta_norm_bmiq[
        rownames(obj$dmp[[obj$dmp_comparison]])
        ,obj$data_imputee$Sample_Name
        ,drop = FALSE
      ] |>
      `colnames<-`(obj$data_imputee$Sample_accession) |>
      t() |>
      as.data.frame()
  }
  
  obj
}