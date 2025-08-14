###############################################################################
# Numeric Dimnames Conversion Functions
###############################################################################
# Functions to ensure all dimnames are numeric for proper spatial processing

#' Convert coordinate dimnames to numeric
#' @param lonlat_data loaded lon_lat_idx.rds data
#' @return list with numeric lon and lat names
get_numeric_coord_names <- function(lonlat_data) {
  list(
    lon = as.numeric(lonlat_data$lon[lonlat_data$lon_idx]),
    lat = as.numeric(lonlat_data$lat[lonlat_data$lat_idx])
  )
}

#' Convert time dimnames from DDMMYYYY to numeric days since 1850-01-01
#' @param time_names character vector in DDMMYYYY format
#' @return numeric vector of days since 1850-01-01
convert_time_to_numeric <- function(time_names) {
  if(is.numeric(time_names)) return(time_names)  # Already numeric
  
  numeric_times <- sapply(time_names, function(date_str) {
    if(nchar(date_str) == 8) {
      # Parse DDMMYYYY format
      day <- as.numeric(substr(date_str, 1, 2))
      month <- as.numeric(substr(date_str, 3, 4))
      year <- as.numeric(substr(date_str, 5, 8))
      
      # Create date and convert to days since 1850-01-01
      date_obj <- as.Date(paste(year, month, day, sep = "-"))
      reference_date <- as.Date("1850-01-01")
      return(as.numeric(date_obj - reference_date))
    } else {
      # Try to convert directly
      return(as.numeric(date_str))
    }
  })
  
  return(as.numeric(numeric_times))
}

#' Set all dimnames to numeric for an emission array
#' @param emission_data 3D array with dimnames
#' @param lonlat_file path to lon_lat_idx.rds file
#' @return array with all numeric dimnames
set_all_numeric_dimnames <- function(emission_data, lonlat_file = "data/processed/lon_lat_idx.rds") {
  
  # Load coordinate data
  lonlat <- readRDS(lonlat_file)
  coord_names <- get_numeric_coord_names(lonlat)
  
  # Get current dimnames
  current_dimnames <- dimnames(emission_data)
  
  # Convert time to numeric
  if(!is.null(current_dimnames$time)) {
    numeric_time <- convert_time_to_numeric(current_dimnames$time)
  } else if(!is.null(current_dimnames[[3]])) {
    numeric_time <- convert_time_to_numeric(current_dimnames[[3]])
  } else {
    numeric_time <- NULL
  }
  
  # Set new numeric dimnames
  dimnames(emission_data) <- list(
    lon = coord_names$lon,
    lat = coord_names$lat,
    time = numeric_time
  )
  
  return(emission_data)
}