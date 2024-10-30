bmiq_norm_progress <- function(x, data, ...){
  suppressMessages(invisible(capture.output({
    results <-
      data |>
      select(all_of(x)) |>
      champ.norm(...)
  })))
  
  results
}

champ.norm <- function (beta,  arraytype = "450K", cores = 3){
  if (arraytype == "EPIC"){
    probeInfoALL.lv <- readRDS("data/probe_info_epic.rds")
  }
  else{
    probeInfoALL.lv <- readRDS("data/probe_info_others.rds")
  }
  design.v <-
    as.numeric(
      lapply(probeInfoALL.lv, function(x) x)$Design[
        match(
          rownames(beta)
          ,probeInfoALL.lv$probeID
        )
      ]
    )
  if (min(beta, na.rm = TRUE) == 0){
    beta[beta == 0] <- 1e-06
  }
  current_cwd <- getwd()
  if (cores > 1) {
    if (cores > detectCores()) cores <- detectCores()
    cl <- makeCluster(cores)
    registerDoParallel(cl)
    beta.p <-
      foreach(
        x = 1:ncol(beta), .combine = cbind, 
                      .export = c("champ.BMIQ", "blc")
      ) %dopar% champ.BMIQ(
        beta[, x]
        ,design.v
        ,sampleID = colnames(beta)[x]
      )$nbeta
    stopCluster(cl)
  }
  else {
    beta.p <-
      sapply(
        1:ncol(beta)
        ,function(x)
          champ.BMIQ(
            beta[, x]
            ,design.v
            ,sampleID = colnames(beta)[x]
          )$nbeta
      )
  }
  setwd(current_cwd)
  rownames(beta.p) <- rownames(beta)
  colnames(beta.p) <- colnames(beta)
  return(beta.p)
}

champ.BMIQ <-
  function(
    beta.v
    ,design.v
    ,nL = 3
    ,doH = TRUE
    ,nfit = 10000
    ,th1.v = c(0.2, 0.75)
    ,th2.v = NULL
    ,niter=5
    ,tol=0.001
    ,sampleID = 1
  ){
    
    type1.idx <- which(design.v==1)
    type2.idx <- which(design.v==2)
    
    beta1.v <- beta.v[type1.idx]
    beta2.v <- beta.v[type2.idx]
    
    ### Check if there are exact 0's or 1's.
    ### If so, regularise using minimum positive and maximum below 1 values.
    if(min(beta1.v)==0){
      beta1.v[beta1.v==0] <- min(setdiff(beta1.v,0))
    }
    if(min(beta2.v)==0){
      beta2.v[beta2.v==0] <- min(setdiff(beta2.v,0))
    }
    if(max(beta1.v)==1){
      beta1.v[beta1.v==1] <- max(setdiff(beta1.v,1))
    }
    if(max(beta2.v)==1){
      beta2.v[beta2.v==1] <- max(setdiff(beta2.v,1))
    }
    
    ### Estimate initial weight matrix from type1 distribution
    w0.m <- matrix(0,nrow=length(beta1.v),ncol=nL)
    w0.m[which(beta1.v <= th1.v[1]),1] <- 1
    w0.m[intersect(which(beta1.v > th1.v[1]),which(beta1.v <= th1.v[2])),2] <- 1
    w0.m[which(beta1.v > th1.v[2]),3] <- 1
    
    ### Fit type1
    ## Fitting EM beta mixture to type1 probes
    set.seed(1234567)
    rand.idx <- sample(1:length(beta1.v),nfit,replace=FALSE)
    em1.o <-
      blc(
        matrix(beta1.v[rand.idx],ncol=1)
        ,w = w0.m[rand.idx,]
        ,maxiter = niter
        ,tol = tol
      )
    subsetclass1.v <- apply(em1.o$w,1,which.max)
    subsetth1.v <-
      c(mean(
        c(max(beta1.v[rand.idx[subsetclass1.v==1]])
          ,min(beta1.v[rand.idx[subsetclass1.v==2]])
        )
      )
      ,mean(
        c(max(beta1.v[rand.idx[subsetclass1.v==2]])
          ,min(beta1.v[rand.idx[subsetclass1.v==3]])
        )
      )
      )
    class1.v <- rep(2,length(beta1.v))
    class1.v[which(beta1.v < subsetth1.v[1])] <- 1
    class1.v[which(beta1.v > subsetth1.v[2])] <- 3
    nth1.v <- subsetth1.v
    
    ### Estimate Modes 
    d1U.o <- density(beta1.v[class1.v==1])
    d1M.o <- density(beta1.v[class1.v==3])
    mod1U <- d1U.o$x[which.max(d1U.o$y)]
    mod1M <- d1M.o$x[which.max(d1M.o$y)]
    d2U.o <- density(beta2.v[which(beta2.v<0.4)])
    d2M.o <- density(beta2.v[which(beta2.v>0.6)])
    mod2U <- d2U.o$x[which.max(d2U.o$y)]
    mod2M <- d2M.o$x[which.max(d2M.o$y)]
    
    
    ### Now deal with type2 fit
    th2.v <- vector()
    th2.v[1] <- nth1.v[1] + (mod2U-mod1U)
    th2.v[2] <- nth1.v[2] + (mod2M-mod1M)
    
    ### Estimate initial weight matrix 
    w0.m <- matrix(0,nrow=length(beta2.v),ncol=nL)
    w0.m[which(beta2.v <= th2.v[1]),1] <- 1
    w0.m[intersect(which(beta2.v > th2.v[1]),which(beta2.v <= th2.v[2])),2] <- 1
    w0.m[which(beta2.v > th2.v[2]),3] <- 1
    
    ## Fitting EM beta mixture to type2 probes
    set.seed(1234567)
    rand.idx <- sample(1:length(beta2.v),nfit,replace=FALSE)
    em2.o <-
      blc(
        matrix(beta2.v[rand.idx],ncol=1)
        ,w = w0.m[rand.idx,]
        ,maxiter = niter
        ,tol = tol
      )
    
    ### For type II probes, 
    ### assign to state (unmethylated, hemi or full methylation)
    subsetclass2.v <- apply(em2.o$w,1,which.max)
    subsetth2.v <-
      c(mean(
        c(max(beta2.v[rand.idx[subsetclass2.v==1]])
          ,min(beta2.v[rand.idx[subsetclass2.v==2]])
        )
      )
      ,mean(
        c(max(beta2.v[rand.idx[subsetclass2.v==2]])
          ,min(beta2.v[rand.idx[subsetclass2.v==3]])
        )
      )
      )
    class2.v <- rep(2,length(beta2.v))
    class2.v[which(beta2.v < subsetth2.v[1])] <- 1
    class2.v[which(beta2.v > subsetth2.v[2])] <- 3
    
    classAV1.v <- vector()
    classAV2.v <- vector()
    for(l in 1:nL){
      classAV1.v[l] <-  em1.o$mu[l,1]
      classAV2.v[l] <-  em2.o$mu[l,1]
    }
    
    ### Start normalising type2 probes
    nbeta2.v <- beta2.v
    
    ### Select U probes
    lt <- 1
    selU.idx <- which(class2.v==lt)
    selUR.idx <- selU.idx[which(beta2.v[selU.idx] > classAV2.v[lt])]
    selUL.idx <- selU.idx[which(beta2.v[selU.idx] < classAV2.v[lt])]
    
    ### Find prob according to typeII distribution
    p.v <-
      pbeta(beta2.v[selUR.idx],em2.o$a[lt,1],em2.o$b[lt,1],lower.tail=FALSE)
    
    ### Find corresponding quantile in type I distribution
    q.v <- qbeta(p.v,em1.o$a[lt,1],em1.o$b[lt,1],lower.tail=FALSE)
    nbeta2.v[selUR.idx] <- q.v
    p.v <-
      pbeta(beta2.v[selUL.idx],em2.o$a[lt,1],em2.o$b[lt,1],lower.tail=TRUE)
    
    ### Find corresponding quantile in type I distribution
    q.v <- qbeta(p.v,em1.o$a[lt,1],em1.o$b[lt,1],lower.tail=TRUE)
    nbeta2.v[selUL.idx] <- q.v
    
    ### Select M probes
    lt <- 3
    selM.idx <- which(class2.v==lt)
    selMR.idx <- selM.idx[which(beta2.v[selM.idx] > classAV2.v[lt])]
    selML.idx <- selM.idx[which(beta2.v[selM.idx] < classAV2.v[lt])]
    
    ### Find prob according to typeII distribution
    p.v <-
      pbeta(beta2.v[selMR.idx],em2.o$a[lt,1],em2.o$b[lt,1],lower.tail=FALSE)
    
    ### Find corresponding quantile in type I distribution
    q.v <- qbeta(p.v,em1.o$a[lt,1],em1.o$b[lt,1],lower.tail=FALSE)
    nbeta2.v[selMR.idx] <- q.v
    
    ### If TRUE, also correct type2 hemimethylated probes
    if(doH){
      ### Select H probes and include ML probes 
      ### (left ML tail is not well described by a beta-distribution).
      lt <- 2
      selH.idx <- c(which(class2.v==lt),selML.idx)
      minH <- min(beta2.v[selH.idx])
      maxH <- max(beta2.v[selH.idx])
      deltaH <- maxH - minH
      
      #### Need to do some patching
      deltaUH <- -max(beta2.v[selU.idx]) + min(beta2.v[selH.idx])
      deltaHM <- -max(beta2.v[selH.idx]) + min(beta2.v[selMR.idx])
      
      ## New maximum of H probes should be
      nmaxH <- min(nbeta2.v[selMR.idx]) - deltaHM
      
      ## New minimum of H probes should be
      nminH <- max(nbeta2.v[selU.idx]) + deltaUH
      ndeltaH <- nmaxH - nminH
      
      ### Perform conformal transformation (shift+dilation)
      
      ## new_beta_H(i) = a + hf*(beta_H(i)-minH)
      hf <- ndeltaH/deltaH 
      
      ### Fix lower point first
      nbeta2.v[selH.idx] <- nminH + hf*(beta2.v[selH.idx]-minH)
      
    }
    
    pnbeta.v <- beta.v
    pnbeta.v[type1.idx] <- beta1.v
    pnbeta.v[type2.idx] <- nbeta2.v
    
    return(
      list(
        nbeta = pnbeta.v
        ,class1 = class1.v
        ,class2 = class2.v
        ,av1 = classAV1.v
        ,av2 = classAV2.v
        ,hf = hf
        ,th1 = nth1.v
        ,th2 = th2.v
      )
    )
    
  }