parcel_centroids <- function(){
  library(data.table)
  dt_parcels <- fread('~/Dropbox/pkg.data/curb_appeal/Filtered_Denver_Data_forCurbAnalysis.csv')
  PINS <- unique(dt_parcels$pin)
  parcels <- readRDS('~/Dropbox/pkg.data/parcels/clean/shapes/shapes.parcels.denver.wgs84.rds')
  coords.parcels <- lapply(parcels@polygons, function(x) x@Polygons[[1]]@labpt)
  coords.parcels <- do.call(rbind, coords.parcels)
  coords.parcels <- as.data.table(coords.parcels)
  setnames(coords.parcels, names(coords.parcels), c('lon', 'lat'))
  coords.parcels <- data.table(PIN=parcels@data$parcel.id, coords.parcels)
  coords.parcels <- coords.parcels[PIN %in% PINS]
  write.csv(coords.parcels, '~/Dropbox/pkg.data/curb_appeal/coords_parcels.csv')
}