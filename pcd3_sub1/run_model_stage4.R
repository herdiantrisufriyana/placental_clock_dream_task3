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

Sample_IDs <- readRDS(file.path(opt$intermediate, "Sample_IDs.rds"))

ga_est_set_predictions <-
  read_csv(
    file.path(opt$intermediate, "ga_est_predictions.csv")
    ,show_col_types = FALSE
  ) |>
  mutate(Sample_ID = Sample_IDs)

ga_res_conds_pred_est_set_predictions <-
  read_csv(
    file.path(opt$intermediate, "ga_res_conds_pred_est_predictions.csv")
    ,show_col_types = FALSE
  ) |>
  mutate(Sample_ID = Sample_IDs) |>
  rename(residual_prediction = prediction) |>
  left_join(ga_est_set_predictions, by = join_by(Sample_ID)) |>
  mutate(prediction = prediction + residual_prediction) |>
  select(-residual_prediction)

ga_res_comb_pr_est_set_predictions <-
  read_csv(
    file.path(opt$intermediate, "ga_res_comb_pr_est_predictions.csv")
    ,show_col_types = FALSE
  ) |>
  mutate(Sample_ID = Sample_IDs) |>
  rename(residual_prediction_pr = prediction)

ga_res_comb_tb_est_set_predictions <-
  read_csv(
    file.path(opt$intermediate, "ga_res_comb_tb_est_predictions.csv")
    ,show_col_types = FALSE
  ) |>
  mutate(Sample_ID = Sample_IDs) |>
  rename(residual_prediction_tb = prediction)

ga_res_comb_est_set_predictions <-
  ga_res_conds_pred_est_set_predictions |>
  left_join(ga_res_comb_pr_est_set_predictions, by = join_by(Sample_ID)) |>
  left_join(ga_res_comb_tb_est_set_predictions, by = join_by(Sample_ID)) |>
  mutate(
    prediction =
      prediction
      + ifelse(
        ceiling(prediction) <= 36
        ,ifelse(is.na(residual_prediction_pr), 0, residual_prediction_pr)
        ,ifelse(
          ceiling(prediction) >= 37 & ceiling(prediction) <= 40
          ,ifelse(is.na(residual_prediction_tb), 0, residual_prediction_tb)
          ,0
        )
      )
  ) |>
  select(
    -residual_prediction_pr
    ,-residual_prediction_tb
  )

ga = ga_res_comb_est_set_predictions$prediction

ga[ga > 44] <- 44
ga[ga < 5] <- 5

output_df <-
  data.frame(
    ID = Sample_IDs,
    GA_prediction = ga
  )

write_csv(output_df,  file.path(opt$output, "predictions.csv"))
