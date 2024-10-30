library(readr)
library(optparse)
library(vroom)
library(tibble)
library(purrr)
library(dplyr)
library(RPMM)
library(pbapply)
library(tidyr)
library(stringr)
source(file.path("utils.R"))

option_list <-
  list(
    make_option(
      "--input"
      ,type = "character"
      ,default = "/input"
      ,help = "Input directory [default=/input]"
      ,metavar="character"
    )
    ,make_option(
      "--output"
      ,type = "character"
      ,default = "/output"
      ,help = "Output directory [default=/output]"
      ,metavar = "character"
    )
    ,make_option(
      "--data"
      ,type = "character"
      ,default = "data"
      ,help = "Data directory [default=data]"
      ,metavar = "character"
    )
    ,make_option(
      "--extdata"
      ,type = "character"
      ,default = "inst/extdata"
      ,help = "Extension data directory [default=inst/extdata]"
      ,metavar = "character"
    )
    ,make_option(
      "--intermediate"
      ,type = "character"
      ,default = "intermediate"
      ,help = "Intermediate data directory [default=intermediate]"
      ,metavar = "character"
    )
  )

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

var_ga <- readRDS(file.path(opt$data, "var_ga.rds"))
Sample_IDs <- readRDS(file.path(opt$intermediate, "Sample_IDs.rds"))

ga_res_conds_est_set <-
  file.path(
    opt$intermediate
    ,paste0("ga_res_conds_", var_ga, "_est_predictions.csv")
  ) |>
  `names<-`(var_ga) |>
  imap(
    ~ .x |>
      read_csv(show_col_types = FALSE)|>
      mutate(rowname = Sample_IDs) |>
      column_to_rownames(var = "rowname")
  )

ga_resfull_est_set <-
  file.path(opt$intermediate, paste0(var_ga, "_pred_prob.csv")) |>
  `names<-`(var_ga) |>
  imap(
    ~ .x |>
      read_csv(show_col_types = FALSE) |>
      mutate(rowname = Sample_IDs) |>
      column_to_rownames(var = "rowname") |>
      rename_at("predicted_probability", \(x) .y)
  ) |>
  reduce(cbind) |>
  select_at(var_ga)

ga_res_conds_pred_est_set <-
  ga_res_conds_est_set |>
  imap(
    ~ .x |>
      rownames_to_column(var = "Sample_ID") |>
      left_join(
        ga_resfull_est_set |>
          rename_at(.y, \(x) "prob") |>
          select(prob) |>
          rownames_to_column(var = "Sample_ID")
        ,by = join_by(Sample_ID)
      ) |>
      column_to_rownames(var = "Sample_ID") |>
      mutate(prob_prediction = prob * prediction) |>
      select(prob_prediction) |>
      rename_at("prob_prediction", \(x) .y)
  ) |>
  reduce(cbind)

ga_res_conds_pred_est_set |>
  write_csv(file.path(opt$intermediate, "ga_res_conds_pred_est_set.csv"))
