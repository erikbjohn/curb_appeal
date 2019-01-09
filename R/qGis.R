funQgis <- function(dt_classify){
  library(parcels)
  library(tidyr)
  library(sp)
  load('~/Dropbox/pkg.data/parcels/clean/shapes/shapes.parcels.rdata')
  load('~/Dropbox/pkg.data/parks/clean/parks.rdata')
  photo.dir <- '~/Dropbox/pkg.data/park.paper/raw/corelogic.photos/'
  
  # Parcels (across view)
 # dt.classify.across <- dt.classify[type=='across', .(pin, fName, category, score)]
#  dt.classify.across <- dt.classify.across[, head(.SD,1), by=.(pin, category)]
#  dt.spread.across <- tidyr::spread(dt.classify.across, key=category, value=score)
#  dt.spread.across$fLocation <- path.expand(paste0(photo.dir, dt.spread.across$fName))
#  shp.parcel.view.across <- sp::merge(shapes.parcels, dt.spread.across, by.x='parcel.id', by.y='pin')
#  shp.parcel.view.across <- shp.parcel.view.across[!(is.na(shp.parcel.view.across$fName)),]
#  rgdal::writeOGR(obj = shp.parcel.view.across, '.', '/home/ebjohnson5/Dropbox/pkg.data/park.paper/raw/ESRIshapes/parcel.view.across',driver="ESRI Shapefile")
  # Parcels (own view)
  dt_own <- dt_classify[type=='own', .(pin, fName, ex)]
  dt_own$fLocation <- path.expand(paste0(photo.dir, dt_own$fName))
  shp_own <- sp::merge(shapes.parcels, dt_own, by.x='parcel.id', by.y='pin')
  shp_own <- shp_own[!(is.na(shp_own$fName)),]
  rgdal::writeOGR(obj = shp_own, '.', '/home/ebjohnson5/Dropbox/pkg.data/curb_appeal/Raw/ESRIshapes/parcel_own',driver="ESRI Shapefile")
  # Parks   # Parcels
  rgdal::writeOGR(obj = shapes.parcels, '.', '/home/ebjohnson5/Dropbox/pkg.data/curb_appeal/Raw/ESRIshapes/parcels',driver="ESRI Shapefile")
}
