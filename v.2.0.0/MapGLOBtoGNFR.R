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
  lon_vals <- ll$lon[ ll$lon_idx ]  # extract actual longitudes from indices
  lat_vals <- ll$lat[ ll$lat_idx ]  # extract actual latitudes from indices
  lon_n    <- prettyNum(lon_vals, trim=TRUE, scientific=FALSE)
  lat_n    <- prettyNum(lat_vals, trim=TRUE, scientific=FALSE)
  
  # 2) Extract original dimnames from input array
  dn         <- dimnames(data_5d)
  orig_sect  <- dn[[3]]  # dimension 3 = sector names (GLOB)
  orig_month <- dn[[4]]  # dimension 4 = months
  orig_year  <- dn[[5]]  # dimension 5 = years
  
  # 3) Define GNFR sectors as target sector names
  newS <- c("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "S")
  d    <- dim(data_5d)  # shape of the original array [lon, lat, sector, month, year]
  
  # 4) Create output array with updated dimensions and GNFR-based dimnames
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
    
    # Get indices of GLOB sectors that map to this GNFR sector
    idx <- which(mapped == gnfr)
    if (length(idx) == 0) next  # skip if no matching sector
    
    # Sum all GLOB sector slices that map to the same GNFR sector
    for (k in idx) {
      out[,,i,,] <- out[,,i,,] + data_5d[,,k,,]
    }
  }
  
  return(out)
}

