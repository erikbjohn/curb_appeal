library(RcppCNPy)
fmat <- read.csv('/home/ebjohnson5/Dropbox/pkg.data/curb_appeal/numpy/test.csv', header = FALSE)


for(i in 1:nrow(f.to.do)){
  orig_file = f.to.do[i]$f.path
  dest_file = paste0('~/Data/tmp_photos/', f.to.do[i]$f.name)
  file.copy(orig_file, dest_file)
}

photo_list <- list.files('/home/ebjohnson5/Data/tmp_photos')
class_list <- list.files('/home/ebjohnson5/Data/tmp')
class_list <- stringr::str_replace(class_list, '\\.csv', '')

photo_list_remain <- photo_list[!(photo_list %in% class_list)]
dir.create('/home/ebjohnson5/Data/tmp_photos2')

for(photo in photo_list_remain){
  file.copy(from = paste0('/home/ebjohnson5/Data/tmp_photos/', photo), to = paste0('/home/ebjohnson5/Data/tmp_photos2/', photo))
}

file_size <- sapply(paste0('/home/ebjohnson5/Data/tmp_photos2', photo_list_remain), file.size)
file.remove('/home/ebjohnson5/Data/tmp_photos2/own-parcel_id.160652580-pano_id.MP-Hv1KAuqWIBFDtbxN48A.jpg')


# Import batch created files.
dt_classify_location <- '~/Dropbox/pkg.data/curb_appeal/Clean/sriram_retrain.rds'

if(file.exists(dt_classify_location)){
  dt_classify <- readRDS(dt_classify_location)
  files.complete <- unique(dt_classify$fName)
} else {
  files.complete <- ''
}

# List of all possible files


f_from_python <- list.files('~/Data/tmp/')

for(f.name in f_from_python){
  pin <- str_extract(f.name, regex('(?<=parcel\\_id\\.).+(?=\\-pano)', perl=TRUE))
  pano_id <- str_extract(f.name, regex('(?<=pano\\_id\\.).+(?=.+\\.jpg)'))
  type <- str_extract(f.name, regex('(own|across)'))
  classes <- fread(paste0('~/Data/tmp/', f.name))  
  dt.classes.new <- cbind(classes, seq(1:4))
  setnames(dt.classes.new, c('V1', 'V2'), c('prob', 'val'))
  dt.classes.new <- dt.classes.new[, .(pin =pin, pano_id=pano_id, type=type, fName=f.name, val, prob)]
  dt_classify <- rbindlist(list(dt_classify, dt.classes.new), use.names = TRUE, fill=TRUE)
}
dt_classify <- dt_classify[, expect_val := val*prob]
dt_classify <- dt_classify[, expect_val := sum(expect_val), by=.(pin, pano_id, type)]
write.csv(dt_classify, '~/Dropbox/pkg.data/curb_appeal/Clean/resubmit_scores.csv')
saveRDS(dt_classify, dt_classify_location)

library(tidyr)
dt_spread <- tidyr::spread(dt_classify, val, prob)
