resume_download <- function(url, destfile) {
  len <- if (file.exists(destfile)) file.info(destfile)$size else 0
  h <- new_handle()

  # Set headers to request a range starting from the current file size
  handle_setheaders(h, Range = paste("bytes=", len, "-", sep=""))

  # Open in append mode
  f <- file(destfile, "ab")
  on.exit(close(f), add = TRUE)

  curl_download(url, destfile, handle = h, mode = "ab")
  
  # paste0(
  #   "curl -o "
  #   ,str_remove_all(destfile, "inst/extdata/")
  #   ," "
  #   ,url
  # ) |>
  #   cat()
}