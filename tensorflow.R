tensorflow <- function(project_location='~/Dropbox/pkg.data/curb_appeal/', tensorflow_location='~/tensorflow/', classify_name='firstTry',
                       training_dir='~/Dropbox/pkg.data/curb_appeal/Raw/TrainingPhotos/', prediction_dir='~/Dropbox/pkg.data/park.paper/raw/corelogic.photos'){
  # Files already classified
  library(data.table)
  library(stringr)
  
  tensor_location <- paste0(project_location, 'tensors/', classify_name)
  dt_classify_location <- paste0(project_location, 'clean/dt_classify_', classify_name, '.rds')
  graph_location  <- paste0(tensor_location, '/output_graph.pb') # /tmp/output_graph.pb
  labels_location <- paste0(tensor_location, '/output_labels.txt') # /tmp/output_labels.txt
  if (!dir.exists(tensor_location)){
    dir.create(tensor_location)
  }
  
  if (!file.exists(graph_location)){ # Needs training
    # system('cd ~/tensorflow & bazel build tensorflow/examples/image_retraining:label_image')
    train <- list()
    bazel_location <- '~/tensorflow/bazel-bin/tensorflow/examples/image_retraining/retrain'
    system(paste(bazel_location, '--image_dir', path.expand(paste0(project_location, training_dir))))
    # Saves graph to /tmp/output_graph.pb and /tmp/output_labels.txt
    file.copy('/tmp/output_graph.pb', to = graph_location, TRUE)
    file.copy('/tmp/output_labels.txt', to = labels_location, TRUE)
  }
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
  
  if (nrow(f.to.do)>0){
    # Tensor head string 
    str.head <- '~/tensorflow/bazel-bin/tensorflow/examples/image_retraining/label_image'
    str.graph <- paste0('--graph=', path.expand(graph_location))
    str.label <- paste0('--labels=', path.expand(labels_location))
    str.tail <- '--output_layer=final_result:0 --image='
    str.block <- paste(str.head, str.graph, str.label, str.tail)
    integer.sample <- sample(1:nrow(f.to.do),nrow(f.to.do),replace=F) 
    
    for (i in integer.sample){
      #for (i in 1:10){
      cat(i, 'of', nrow(f.to.do), '\n')
      f.name <- f.to.do$f.name[i]
      f.path <- f.to.do$f.path[i]
      pin <- str_extract(f.name, regex('(?<=parcel\\_id\\.).+(?=\\-pano)', perl=TRUE))
      pano_id <- str_extract(f.name, regex('(?<=pano\\_id\\.).+(?=.+\\.jpg)'))
      type <- str_extract(f.name, regex('(own|across)'))
      classes <- system(paste0(str.block, f.path), intern=TRUE)
      l.classes <- sapply(classes, function(x) str_split(x, ' \\(score = '), simplify=TRUE)
      l.classes.dt <- lapply(l.classes, function(x) data.table(pin = pin, pano_id = pano_id, type =type, fName = f.name, val = x[1], prob = x[2]))
      dt.classes.new <- rbindlist(l.classes.dt, use.names = TRUE, fill = TRUE)
      dt.classes.new <- dt.classes.new[val=='a', val:='1']
      dt.classes.new <- dt.classes.new[val=='b', val:='2']
      dt.classes.new <- dt.classes.new[val=='c', val:='3']
      dt.classes.new <- dt.classes.new[val=='d', val:='4']
      dt.classes.new <- dt.classes.new[, val:=as.integer(val)]
      dt.classes.new$prob <- as.numeric(str_replace_all(dt.classes.new$prob, '\\)$', ''))
      print(dt.classes.new)
      cat('\n')
      if(file.exists(dt_classify_location)){
        dt_classify <- rbindlist(list(dt_classify, dt.classes.new), use.names = TRUE)
        saveRDS(dt_classify, dt_classify_location)
      } else {
        dt_classify <- dt.classes.new
        saveRDS(dt.classes.new, dt_classify_location)
      }
    }
    dt_classify <- unique(dt_classify[, .(pin, pano_id, type, fName, val=as.integer(val), prob)])
    saveRDS(dt_classify, dt_classify_location)
  }
  dt_score <- dt_classify[, expect_val := val * prob]
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