own_photos <- function(){
  #pics.list <- list.files('~/Dropbox/pkg.data/park.paper/raw/corelogic.photos', full.names = TRUE)
  #pics.names <- list.files('~/Dropbox/pkg.data/park.paper/raw/corelogic.photos/')
  #dt_pics <- data.table(fName=pics.names, fLoc_start = pics.list)
  #dt_pics <- dt_pics[stringr::str_detect(fName, '^own'), own_photo:=1]
  #dt_pics <- dt_pics[own_photo==1]
  #dir.create('~/Dropbox/own_photos')
  #dt_pics <- dt_pics[, fLoc_end := stringr::str_replace_all(fLoc_start, 'pkg.data\\/park.paper\\/raw\\/corelogic.photos', 'own_photos')]
  #copy_own <- lapply(1:nrow(dt_pics), function(x) file.copy(dt_pics$fLoc_start[x], dt_pics$fLoc_end[x]))
}