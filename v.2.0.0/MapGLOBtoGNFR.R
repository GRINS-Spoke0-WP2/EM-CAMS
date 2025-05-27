#!/usr/bin/env Rscript
###############################################################################
# MapGLOBtoGNFR.R
# Maps a 5D array [lon, lat, GLOB_sector, month, year] to GNFR sectors,
# and realigns longitude/latitude based on predefined indices.
###############################################################################

# Mapping table: GLOB sector → GNFR sector
sector_map_GLOB_to_GNFR <- list(
  agl = "K", ags = "L", awb = "L", com = "C", res = "C",
  ene = "A", fef = "D", ind = "B", ref = "B", shp = "G",
  sum = "S", swd = "J", tnr = "I", tro = "F"
)

map_GLOB_to_GNFR <- function(data_5d,
                             lonlat_idx_rds = "Data/Processed/lon_lat_idx_GLOB.rds") {
  # 1) Load longitude/latitude index file
  stopifnot(file.exists(lonlat_idx_rds))
  ll       <- readRDS(lonlat_idx_rds)
  lon_vals <- ll$lon[ ll$lon_idx ]
  lat_vals <- ll$lat[ ll$lat_idx ]
  lon_n    <- prettyNum(lon_vals, trim=TRUE, scientific=FALSE)
  lat_n    <- prettyNum(lat_vals, trim=TRUE, scientific=FALSE)
  
  # 2) Extract original dimnames from input array
  dn         <- dimnames(data_5d)
  orig_sect  <- dn[[3]]  # dimension 3 = sector names (GLOB)
  orig_month <- dn[[4]]
  orig_year  <- dn[[5]]
  
  # 2.1) Build mapping vector for each GLOB sector
  mapped <- sapply(orig_sect, function(s) {
    if (!s %in% names(sector_map_GLOB_to_GNFR))
      stop("Sector '", s, "' not found in sector_map_GLOB_to_GNFR")
    sector_map_GLOB_to_GNFR[[s]]
  })
  
  # 3) Define GNFR sectors as target names
  newS <- c("A","B","C","D","E","F","G","H","I","J","K","L","S")
  d    <- dim(data_5d)
  
  # 4) Create output array
  out <- array(
    0,
    dim = c(length(lon_n), length(lat_n), length(newS), d[4], d[5]),
    dimnames = list(
      lon    = lon_n,
      lat    = lat_n,
      sector = newS,
      month  = orig_month,
      year   = orig_year
    )
  )
  
  # 5) Loop through GNFR sectors and fill output array
  for (i in seq_along(newS)) {
    gnfr <- newS[i]
    idx  <- which(mapped == gnfr)
    if (length(idx) == 0) next
    for (k in idx) {
      out[,,i,,] <- out[,,i,,] + data_5d[,,k,,]
    }
  }
  
  return(out)
}
