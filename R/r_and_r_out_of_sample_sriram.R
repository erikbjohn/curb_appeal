r_and_r_out_of_sample_sriram <- function(){
  dt_r_and_r_out_of_sample_sriram_location <- '~/Dropbox/pkg.data/curb_appeal/jrefe/r_and_r/out_of_sample_sriram.rds'
  if(!file.exists(dt_r_and_r_out_of_sample_sriram_location)){
    ground_truth_location <- '~/Dropbox/pkg.data/curb_appeal/jrefe/r_and_r/out_of_sample_groundtruth.rds'
    if(!file.exists(ground_truth_location)){
      # First, create the list of panos in each type
      f_list <- list.files('~/Dropbox/pkg.data/curb_appeal/jrefe/r_and_r/out_of_sample_photos', full.names = TRUE, include.dirs = FALSE, recursive = TRUE)
      scores <- stringr::str_extract(f_list, pattern = '(?<=photos\\/).+(?=\\/own)')
      f_names <- stringr::str_extract(f_list,'own.+.(?=\\.jpg)')
      dt_ground_truth <- data.table::data.table(f_name = f_names, ground_truth_score = scores)
    
      saveRDS(dt_ground_truth, ground_truth_location)
    } else {
      dt_ground_truth <- readRDS(ground_truth_location)
    }
    # Now, score the photos using the pretrained machine
    f_list <- list.files('~/Dropbox/pkg.data/curb_appeal/jrefe/r_and_r/out_of_sample_to_score_sriram/', full.names = TRUE, include.dirs = FALSE, recursive = TRUE)
    lapply(f_list, function(x) file.copy(x, stringr::str_replace(x, '(?<=r\\_and\\_r\\/).+(?=\\/own)', 'out_of_sample_to_score_sriram')))
    l_scores <- list.files('~/Dropbox/pkg.data/curb_appeal/jrefe/r_and_r/out_of_sample_to_score_sriram', full.names=TRUE, recursive = FALSE, include.dirs = FALSE)
    lapply(l_scores, file.remove)
    system('python3 /home/ebjohnson5/Documents/Github/curb_appeal/python/label_image_batch_r_and_r_out_of_sample.py')
    # Import the csv data
    f_from_python <- list.files('~/Dropbox/pkg.data/curb_appeal/jrefe/r_and_r/out_of_sample_scores/')
    # Check which were not labeled
    files_labeled <- stringr::str_replace(f_from_python, pattern = '\\.jpg.+', '')
    files_to_label <- dt_ground_truth$f_name
    missing_labels <- files_to_label[!files_to_label %in% files_labeled]
    if(length(missing_labels)>0) cat(missing_labels)
    i <- 0
    rm(dt_classify)
    rm(dt_out_of_sample)
    for(f.name in f_from_python){
      i <- i+1
      pin <- str_extract(f.name, regex('(?<=parcel\\_id\\.).+(?=\\-pano)', perl=TRUE))
      pano_id <- str_extract(f.name, regex('(?<=pano\\_id\\.).+(?=.+\\.jpg)'))
      type <- str_extract(f.name, regex('(own|across)'))
      classes <- fread(paste0('~/Dropbox/pkg.data/curb_appeal/jrefe/r_and_r/out_of_sample_scores/', f.name))  
      dt.classes.new <- cbind(classes, seq(1:4))
      setnames(dt.classes.new, c('V1', 'V2'), c('prob', 'val'))
      dt.classes.new <- dt.classes.new[, .(pin =pin, pano_id=pano_id, type=type, fName=f.name, val, prob)]
      if(i==1){
        dt_classify <- dt.classes.new
      } else {
        dt_classify <- rbindlist(list(dt_classify, dt.classes.new), use.names = TRUE, fill=TRUE)
      }
    }
    dt_classify <- dt_classify[, expect_val := val*prob]
    dt_classify <- dt_classify[, expect_val := sum(expect_val), by=pin]
    dt_classify <- dt_classify[, max_val_predict := val[which.max(prob)], by=pin]
    dt_classify <- data.table::dcast(dt_classify, pin + pano_id + type + fName + expect_val + max_val_predict ~ val, value.var='prob')
    dt_classify <- dt_classify[, f_name:=stringr::str_replace(fName, '\\.jpg\\.csv', '')]
    setkey(dt_classify, f_name)
    setkey(dt_ground_truth, f_name)
    dt_out_of_sample <- dt_ground_truth[dt_classify]
    caret::confusionMatrix(as.factor(as.character(dt_out_of_sample$max_val_predict)),
                           as.factor(dt_out_of_sample$ground_truth_score))
    
    saveRDS(dt_classify, r_and_r_out_of_sample_sriram_location)
    dt_r_and_r_out_of_sample_sriram <- dt_out_of_sample
    saveRDS(dt_r_and_r_out_of_sample_sriram, dt_r_and_r_out_of_sample_sriram_location)
  } else {
    dt_r_and_r_out_of_sample_sriram <- readRDS(dt_r_and_r_out_of_sample_sriram_location)
  }
  return(dt_r_and_r_out_of_sample_sriram)
}