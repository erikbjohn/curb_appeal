tests_logic <- function(){
  tests_logic_location <- '~/Dropbox/pkg.data/curb_appeal/Clean/test_logic.rds'
  if(!file.exists(tests_logic_location)){
  library(data.table)
  dt <- readRDS('~/Dropbox/pkg.data/curb_appeal/Clean/dt_spread.rds')
  l_rational <- rational_sets()
  dt$rational <- FALSE
  n_dt <- nrow(dt)
  for (iPin in 1:n_dt){
    dt_pin <- dt[iPin,]
    dt_gather <- as.data.table(tidyr::gather(dt_pin[, .(v1,v2,v3,v4)], key=curb_appeal))
    dt_gather$curb_appeal <- as.integer(stringr::str_replace(dt_gather$curb_appeal, 'v', ''))
    dt_gather <- dt_gather[order(-value)]
    ranks <- dt_gather$curb_appeal
    log_rational <- length(which(sapply(l_rational, identical, y = as.numeric(ranks)))) == 1
    dt <- dt[iPin, rational := log_rational]
    dt <- dt[iPin, max_category := dt_gather[1]$curb_appeal]
    dt <- dt[iPin, max_probabiliy := dt_gather[1]$value]
    studyPins <- fread('~/Dropbox/pkg.data/curb_appeal/UniquePins.csv')
    
    
    saveRDS(dt, tests_logic_location)
  }
  } else {
    dt <- readRDS(tests_logic_location)
  }
  return(dt)
}
rational_sets <- function(){
  l <- list()
  # If 1 is picked first
  l[[1]] <- c(1,2,3,4)
  # If 2 is picked first
  l[[2]] <- c(2,1,3,4)
  l[[3]] <- c(2,3,1,4)
  l[[4]] <- c(2,3,4,1)
  # If 3 is picked first
  l[[5]] <- c(3,2,4,1)
  l[[6]] <- c(3,4,1,2)
  l[[7]] <- c(3,2,1,4)
  # If 4 is picked first
  l[[6]] <- c(4,3,2,1)
  return(l)
 }