vroom_rds <- function(file, tmp_csv_path, ...){
  write_csv(as.data.frame(readRDS(file)), tmp_csv_path)
  output <- vroom(tmp_csv_path, ...)
  file.remove(tmp_csv_path)
  output
}