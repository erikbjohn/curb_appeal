spatialCurbAppeal <- function(){
  regData <- data.table::fread('~/Dropbox/pkg.data/curb_appeal/Filtered_Denver_Data_forCurbAnalysis.csv')
  head(regData)
  load('~/Dropbox/pkg.data/parcels/clean/address/parcels.address.rdata')
  head(shps)
}