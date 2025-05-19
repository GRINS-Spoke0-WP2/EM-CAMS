###############################################################################
# RegridGLOB.R
#
# Provides a function regrid_lat_resolution() that performs an area-preserving
# regridding of a 5D array [lon, lat, sector, month, year] from a 
# 0.1° lat resolution grid to a grid with exactly double the number of latitude
# points (e.g. 260, if the original had 130 points).
# For each original cell, the value is divided by 2 and copied to the two new cells.
###############################################################################
library(abind)

regrid_lat_resolution <- function(data_5d) {
  # Retrieve dimnames (assume the second element corresponds to latitude)
  dn <- dimnames(data_5d)
  if (!is.null(names(dn)) && ("lat" %in% names(dn))) {
    lat_orig <- as.numeric(dn$lat)
  } else if (length(dn) >= 2) {
    lat_orig <- as.numeric(dn[[2]])
  } else {
    stop("The input data must have a 'lat' dimension (either named or as the second element).")
  }
  if (any(is.na(lat_orig))) {
    stop("Cannot coerce latitude dimnames to numeric.")
  }
  
  # Create a new latitude vector by duplicating each original latitude
  # and formatting with two decimals.
  new_lat <- rep(sprintf("%.2f", lat_orig), each = 2)
  n_new_lat <- length(new_lat)
  
  # Get dimensions of the input 5D array: [n_lon, n_lat, n_sector, n_month, n_year]
  dims <- dim(data_5d)
  n_lon    <- dims[1]
  n_lat_orig <- dims[2]
  n_sector <- dims[3]
  n_month  <- dims[4]
  n_year   <- dims[5]
  
  # Preallocate a new array with updated latitude dimension
  new_data <- array(NA, dim = c(n_lon, n_new_lat, n_sector, n_month, n_year))
  
  # Area-preserving regrid:
  # For each original latitude row, duplicate its values divided by 2.
  for (j in 1:n_lat_orig) {
    new_data[, (2 * j) - 1, , , ] <- data_5d[, j, , , ] / 2
    new_data[, (2 * j),     , , ] <- data_5d[, j, , , ] / 2
  }
  
  # Update the dimension names to reflect the new latitudes.
  if (!is.null(names(dn)) && ("lat" %in% names(dn))) {
    dn$lat <- new_lat
  } else if (length(dn) >= 2) {
    dn[[2]] <- new_lat
  }
  dimnames(new_data) <- dn
  
  return(new_data)
}
