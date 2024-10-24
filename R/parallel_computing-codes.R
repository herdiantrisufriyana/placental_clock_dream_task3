if(start){
  # Create multiple CPU clusters for parallel computing.
  cl=makePSOCKcluster(cl)
  registerDoParallel(cl)
  
  # Bring these packages to the CPU clusters.
  clusterEvalQ(cl,{
    library(tidyverse)
    library(knitr)
    library(kableExtra)
    library(ggpubr)
    mutate <- dplyr::mutate
    library(reticulate)
    library(pbapply)
    library(ChAMP)
    reduce <- purrr::reduce
    library(vroom)
    library(parallel)
    library(doParallel)
    library(torch)
    library(digest)
    library(curl)
    library(minfi)
    library(GEOquery)
  })
}else{
  # Close the CPU clusters and clean up memory.
  stopCluster(cl)
  registerDoSEQ()
  rm(cl)
  gc()
}