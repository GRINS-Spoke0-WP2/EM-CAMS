###############################################################################
# ExtractGLOB.R
#
# Provides the function build_5D_GLOB_from_files() that reads multiple monthly 
# CAMS-GLOB-ANT NetCDF files (from a given vector of file paths), and returns a 
# 5D array: [lon, lat, sector, month, year]. The output array will have dimnames, 
# including for the "sector" dimension.
###############################################################################
library(ncdf4)
library(abind)

build_5D_GLOB_from_files <- function(
    netcdf_files,
    boundary,
    sector_names_GLOB,
    output_file = NULL
) {
  if (length(netcdf_files) == 0) {
    stop("No NetCDF files provided.")
  }
  
  # Helper: get year from filename
  get_year_from_filename <- function(fname) {
    sub(".*_([0-9]{4})\\.nc", "\\1", fname)
  }
  
  # Internal function: read one file and return a 4D array [lon, lat, sector, month]
  extract_4D_GLOB <- function(nc_file) {
    nc <- nc_open(nc_file)
    on.exit(nc_close(nc), add = TRUE)
    
    lon <- ncvar_get(nc, "lon")
    lat <- ncvar_get(nc, "lat")
    lon_idx <- which(lon >= boundary[1] & lon <= boundary[2])
    lat_idx <- which(lat >= boundary[3] & lat <= boundary[4])
    
    time_vals <- ncvar_get(nc, "time")
    n_month <- length(time_vals)
    
    sector_keys <- names(sector_names_GLOB)
    n_sector <- length(sector_keys)
    
    sector_data_list <- list()
    for (key in sector_keys) {
      # Removed drop argument (not needed)
      arr_3d <- ncvar_get(
        nc,
        varid = sector_names_GLOB[[key]],
        start = c(min(lon_idx), min(lat_idx), 1),
        count = c(length(lon_idx), length(lat_idx), n_month)
      )
      sector_data_list[[key]] <- arr_3d
    }
    
    # Preallocate a 4D array: [lon, lat, sector, month]
    n_lon <- length(lon_idx)
    n_lat <- length(lat_idx)
    data_4d <- array(NA, dim = c(n_lon, n_lat, n_sector, n_month))
    
    for (t in seq_len(n_month)) {
      for (s_i in seq_along(sector_keys)) {
        skey <- sector_keys[s_i]
        data_slice <- sector_data_list[[skey]][, , t]
        data_4d[ , , s_i, t] <- data_slice
      }
    }
    
    # Set dimension names; formattiamo lon/lat con due decimali
    dimnames(data_4d) <- list(
      lon    = sprintf("%.2f", lon[lon_idx]),
      lat    = sprintf("%.2f", lat[lat_idx]),
      sector = sector_keys,
      month  = as.character(seq_len(n_month))
    )
    
    return(data_4d)
  }
  
  # Internal function: promote a 4D array to 5D by adding a year dimension (length = 1)
  promote_to_5D <- function(data_4d, year_label) {
    d4 <- dim(data_4d)
    data_5d <- array(NA, dim = c(d4[1], d4[2], d4[3], d4[4], 1))
    data_5d[ , , , , 1] <- data_4d
    dn4 <- dimnames(data_4d)
    dn5 <- c(dn4, list(year = year_label))
    dimnames(data_5d) <- dn5
    return(data_5d)
  }
  
  # Internal function: merge two 5D arrays along the 5th dimension (year)
  merge_5D_GLOB <- function(x5d, y5d) {
    if (!all(dim(x5d)[1:4] == dim(y5d)[1:4])) {
      stop("Mismatch in the first 4 dimensions - cannot merge.")
    }
    merged <- abind(x5d, y5d, along = 5)
    return(merged)
  }
  
  # Main loop: iterate over all files and merge their data
  all_data_5d <- NULL
  years_accum <- c()
  for (file_path in netcdf_files) {
    cat("\nProcessing file:", file_path, "\n")
    this_year <- get_year_from_filename(file_path)
    cat("Year detected:", this_year, "\n")
    years_accum <- c(years_accum, this_year)
    data_4d <- extract_4D_GLOB(file_path)
    cat("4D shape:", paste(dim(data_4d), collapse=" x "), "\n")
    data_5d <- promote_to_5D(data_4d, this_year)
    cat("Promoted to 5D shape:", paste(dim(data_5d), collapse=" x "), "\n")
    if (is.null(all_data_5d)) {
      all_data_5d <- data_5d
      cat("Initialized final 5D array.\n")
    } else {
      cat("Merging with existing final array...\n")
      all_data_5d <- merge_5D_GLOB(all_data_5d, data_5d)
      cat("New final shape:", paste(dim(all_data_5d), collapse=" x "), "\n")
    }
  }
  
  
  # Optionally save the final 5D array to an RDS file.
  if (!is.null(output_file)) {
    saveRDS(all_data_5d, file = output_file)
    cat("\nFinal 5D array saved to:", output_file, "\n")
  }
  
  return(all_data_5d)
}

