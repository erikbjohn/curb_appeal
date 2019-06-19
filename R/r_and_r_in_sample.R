r_and_r_in_sample <- function(){
  dt_r_and_r_in_sample_location <- '~/Dropbox/pkg.data/curb_appeal/jrefe/r_and_r/in_sample.rds'
  ground_truth_location <- '~/Dropbox/pkg.data/curb_appeal/jrefe/r_and_r/in_sample_groundtruth.rds'
  if(!file.exists(dt_r_and_r_in_sample_location)){
    if(!file.exists(ground_truth_location)){
      # First, create the list of panos in each type
      f_list <- list.files('~/Dropbox/pkg.data/curb_appeal/Raw/TrainingPhotos_Sriram', full.names = TRUE, include.dirs = FALSE, recursive = TRUE)
      scores <- stringr::str_extract(f_list, pattern = '(?<=Sriram\\/).+(?=\\/(own|across))')
      f_names <- stringr::str_extract(f_list,'(own|across).+.(?=\\.jpg)')
      dt_ground_truth <- data.table::data.table(f_name = f_names, ground_truth_score_char = scores)
      dt_ground_truth <- dt_ground_truth[ground_truth_score_char=='a', ground_truth_score:=1]
      dt_ground_truth <- dt_ground_truth[ground_truth_score_char=='b', ground_truth_score:=2]
      dt_ground_truth <- dt_ground_truth[ground_truth_score_char=='c', ground_truth_score:=3]
      dt_ground_truth <- dt_ground_truth[ground_truth_score_char=='d', ground_truth_score:=4]
      saveRDS(dt_ground_truth, ground_truth_location)
    } else {
      dt_ground_truth <- readRDS(ground_truth_location)
    }
    # Now, score the photos using the pretrained machine
    lapply(f_list, function(x) file.copy(x, stringr::str_replace(x, '(?<=Raw\\/).+(?=\\/(own|across))', 'training_to_score'), overwrite = FALSE))
    system('python3 /home/ebjohnson5/Documents/Github/curb_appeal/python/label_image_batch_r_and_r_in_sample.py')
    # Import the csv data
    f_from_python <- list.files('~/Dropbox/pkg.data/curb_appeal/jrefe/r_and_r/in_sample_scores/')
    # Check which were not labeled
    files_labeled <- stringr::str_replace(f_from_python, pattern = '\\.jpg.+', '')
    files_to_label <- dt_ground_truth$f_name
    missing_labels <- files_to_label[!files_to_label %in% files_labeled]
    if(length(missing_labels)>0) cat(missing_labels)
    i <- 0
    for(f.name in f_from_python){
      i <- i+1
      pin <- str_extract(f.name, regex('(?<=parcel\\_id\\.).+(?=\\-pano)', perl=TRUE))
      pano_id <- str_extract(f.name, regex('(?<=pano\\_id\\.).+(?=.+\\.jpg)'))
      type <- str_extract(f.name, regex('(own|across)'))
      classes <- fread(paste0('~/Dropbox/pkg.data/curb_appeal/jrefe/r_and_r/in_sample_scores/', f.name))  
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
    dt_in_sample <- dt_ground_truth[dt_classify]
    dt_in_sample$fName <- NULL
    # Export as csv for Sriram
    fwrite(dt_in_sample, '~/Dropbox/pkg.data/curb_appeal/jrefe/r_and_r/training_photo_list.csv')
    saveRDS(dt_in_sample, dt_r_and_r_in_sample_location)
  } else {
    dt_in_sample <- readRDS(dt_r_and_r_in_sample_location)
  }
  return(dt_in_sample)
}