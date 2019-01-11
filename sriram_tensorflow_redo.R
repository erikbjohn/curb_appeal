# python3 label_image.py --graph=/home/ebjohnson5/Dropbox/pkg.data/curb_appeal/models/output_graph.pb --labels=/home/ebjohnson5/Dropbox/pkg.data/curb_appeal/models/output_labels.txt --input_layer=Placeholder --output_layer=final_result --image=/home/ebjohnson5/Dropbox/pkg.data/park.paper/raw/corelogic.photos/across-parcel_id.160434124-pano_id.r71YbMLftAjxHMd-55DrTg.jpg

library(data.table)
library(stringr)
dt <- readRDS('~/Dropbox/pkg.data/curb_appeal/Data/johnson.rds')
sample_pins <- dt[, .(pin=as.character(pin), sample_pin=pin)]

dt_classify_location <- '~/Dropbox/pkg.data/curb_appeal/Clean/sriram_retrain.rds'

if(file.exists(dt_classify_location)){
  dt_classify <- readRDS(dt_classify_location)
  files.complete <- unique(dt_classify$fName)
} else {
  files.complete <- ''
}

# List of all possible files
f.dir <- '~/Dropbox/pkg.data/park.paper/raw/corelogic.photos'
f.list.path <- list.files(f.dir, full.names = TRUE)
f.list <- list.files(f.dir)
f.to.do <- data.table(f.name = f.list[which(!(f.list %in% files.complete))], f.path =f.list.path[which(!(f.list %in% files.complete))])
f.to.do <- f.to.do[, parcel_id:=stringr::str_extract(f.name, '(?<=id\\.).+(?=\\-pano_id)')]
f.to.do <- f.to.do[parcel_id %in% sample_pins$pin]

if (nrow(f.to.do)>0){
  # Tensor head string 
  str.head <- 'python3 /home/ebjohnson5/Dropbox/pkg.data/curb_appeal/models/label_image.py'
 # --image=/home/ebjohnson5/Dropbox/pkg.data/park.paper/raw/corelogic.photos/across-parcel_id.160434124-pano_id.r71YbMLftAjxHMd-55DrTg.jpg
  str.graph <- '--graph=/home/ebjohnson5/Dropbox/pkg.data/curb_appeal/models/output_graph.pb'
  str.label <- '--labels=/home/ebjohnson5/Dropbox/pkg.data/curb_appeal/models/output_labels.txt --input_layer=Placeholder'
  str.tail <- '--output_layer=final_result --image='
  str.block <- paste(str.head, str.graph, str.label, str.tail)
  integer.sample <- sample(1:nrow(f.to.do),nrow(f.to.do),replace=F) 
  
  iter <- 0
  for (i in integer.sample){
    tic <- Sys.time()
    iter <- iter + 1
    #for (i in 1:10){
    cat(iter, 'of', nrow(f.to.do), '\n')
    f.name <- f.to.do$f.name[i]
    f.path <- f.to.do$f.path[i]
    pin <- str_extract(f.name, regex('(?<=parcel\\_id\\.).+(?=\\-pano)', perl=TRUE))
    pano_id <- str_extract(f.name, regex('(?<=pano\\_id\\.).+(?=.+\\.jpg)'))
    type <- str_extract(f.name, regex('(own|across)'))
    classes <- system(paste0(str.block, f.path), intern=TRUE)
    l.classes <- sapply(classes, function(x) str_split(x, ' '), simplify=TRUE)
    l.classes.dt <- lapply(l.classes, function(x) data.table(pin = pin, pano_id = pano_id, type =type, fName = f.name, val = x[1], prob = x[2]))
    dt.classes.new <- rbindlist(l.classes.dt, use.names = TRUE, fill = TRUE)
    dt.classes.new <- dt.classes.new[val=='a', val:='1']
    dt.classes.new <- dt.classes.new[val=='b', val:='2']
    dt.classes.new <- dt.classes.new[val=='c', val:='3']
    dt.classes.new <- dt.classes.new[val=='d', val:='4']
    dt.classes.new <- dt.classes.new[, val:=as.integer(val)]
    dt.classes.new$prob <- as.numeric(str_replace_all(dt.classes.new$prob, '\\)$', ''))
    print(dt.classes.new)
    cat('\n', Sys.time() - tic, '\n')
    if(file.exists(dt_classify_location)){
      dt_classify <- rbindlist(list(dt_classify, dt.classes.new), use.names = TRUE, fill=TRUE)
      saveRDS(dt_classify, dt_classify_location)
    } else {
      dt_classify <- dt.classes.new
      if((iter %% 100) == 0){
        saveRDS(dt.classes.new, dt_classify_location)
      }
    }
  }
  dt_classify <- unique(dt_classify[, .(pin, pano_id, type, fName, val=as.integer(val), prob)])
  saveRDS(dt_classify, dt_classify_location)
}
dt_score <- dt_classify[, expect_val := val * prob]
write.csv(dt_score, file='~/Downloads/Sriram_training.csv')
return(dt_classify)
}


f <- lapply(1:4, function(x) list.files(path = paste0('~/Dropbox/pkg.data/curb_appeal/Raw/TrainingPhotos/', x)))

for (j in 1:4){
  for(i in 1:4){
    if (i != j){
      cat(i, ',', j, '\n')
      f[[i]][f[[i]] %in% f[[j]]]
    }
  }
}