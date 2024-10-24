pearson_fisher_aov_t <- function(V1, V2){
  if(is.numeric(V1) & is.numeric(V2)){
    func <- function(V1, V2){
      cor.test(V1, V2, method = "pearson")
    }
  }else if(!is.numeric(V1) & !is.numeric(V2)){
    func <- function(V1, V2){
      fisher.test(V1, V2)
    }
  }else if(!is.numeric(V1)){
    if(length((unique(V1))) > 2){
      func <- function(V1, V2){
        data <-
          data.frame(
            V2 = V2
            ,V1 = V1
          )
        
        aov(
          V2 ~ V1
          ,data = data
        )
      }
    }else{
      func <- function(V1, V2){
        V2_group_V1_1 = V2[V1 == unique(V1)[1]]
        V2_group_V1_2 = V2[V1 == unique(V1)[2]]
        t.test(
          V2_group_V1_1
          ,V2_group_V1_2
          ,alternative = "two.sided"
          ,paired = FALSE
          ,var.equal = FALSE
        )
      }
    }
  }else{
    if(length((unique(V2))) > 2){
      func <- function(V1, V2){
        data <-
          data.frame(
            V2 = V2
            ,V1 = V1
          )
        
        aov(
          V1 ~ V2
          ,data = data
        )
      }
    }else{
      func <- function(V1, V2){
        V1_group_V2_1 = V1[V2 == unique(V2)[1]]
        V1_group_V2_2 = V1[V2 == unique(V2)[2]]
        t.test(
          V1_group_V2_1
          ,V1_group_V2_2
          ,alternative = "two.sided"
          ,paired = FALSE
          ,var.equal = FALSE
        )
      }
    }
  }
  
  V1_no_ms <- V1[!is.na(V1) & !is.na(V2)]
  V2_no_ms <- V2[!is.na(V2) & !is.na(V1)]
  
  func(V1_no_ms, V2_no_ms)
}