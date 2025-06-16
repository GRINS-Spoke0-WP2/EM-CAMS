# ------------------------------------------------------------------------------
# File: ComputeFinal.R
# ------------------------------------------------------------------------------
# Contiene le funzioni finali di calcolo e aggregazione:
#   - DailyPRF_fromFMFW
#   - StackDailyData
#   - SumAllSectorsIntoOne  (supporta sub-range di somma)
# ------------------------------------------------------------------------------

DailyPRF_fromFMFW <- function(FM_profile, FW_profile, sector,
                              start_year = 2000, end_year = 2020,
                              output_base = "data/processed/TEMPO_data/DailyProfiles") {
  
  is_leap_year <- function(y) (y %% 4 == 0 & y %% 100 != 0) | (y %% 400 == 0)
  days_in_month <- function(y) {
    if (is_leap_year(y)) c(31,29,31,30,31,30,31,31,30,31,30,31)
    else                c(31,28,31,30,31,30,31,31,30,31,30,31)
  }
  first_weekday <- function(y) {
    w <- as.POSIXlt(paste0(y, "-01-01"))$wday
    if (w == 0) 7 else w
  }
  days_in_year <- function(y) if (is_leap_year(y)) 366 else 365
  
  sector_folder <- file.path(output_base, sector)
  if (!dir.exists(sector_folder)) dir.create(sector_folder, recursive = TRUE)
  
  for (yr in seq(start_year, end_year)) {
    message("Processing year: ", yr)
    
    dimM  <- days_in_month(yr)
    ndays <- days_in_year(yr)
    wk    <- first_weekday(yr)
    
    # costruisci vettori date (numeric time)
    dates <- seq.Date(as.Date(paste0(yr, "-01-01")),
                      by = "day", length.out = ndays)
    cf_t  <- as.numeric(dates - as.Date("1850-01-01"))  # Numeric days since 1850-01-01
    rd_t  <- format(dates, "%Y-%m-%d")
    
    # inizializza array
    x_dim <- dim(FM_profile)[1]
    y_dim <- dim(FM_profile)[2]
    daily_profile <- array(
      0,
      dim = c(x_dim, y_dim, ndays),
      dimnames = list(lon = NULL, lat = NULL, time = cf_t)
    )
    attr(daily_profile, "dates") <- rd_t
    
    # popolamento
    counter <- 1
    for (m in seq_along(dimM)) {
      for (d in seq_len(dimM[m])) {
        daily_profile[,,counter] <- FM_profile[,,m] * FW_profile[,,wk]
        counter <- counter + 1
        wk      <- ifelse(wk == 7, 1, wk + 1)
      }
    }
    
    # salva
    outf <- file.path(sector_folder, paste0("DailyProfile_", yr, "_", sector, ".rds"))
    saveRDS(daily_profile, outf)
    rm(daily_profile); gc()
  }
}


StackDailyData <- function(input_folder, sector, pollutant,
                         start_year, end_year) {
  library(abind)
  
  # Special handling for sector F: limit to 2020 (no simplified profiles available)
  if (sector == "F" && end_year > 2020) {
    cat("  Note: Sector F limited to 2020 (no simplified profiles available for 2021+)\n")
    end_year <- 2020
  }
  
  years <- seq(start_year, end_year)
  tmp   <- lapply(years, function(yr) {
    # First try: pollutant subdirectory (Phase 5 output)
    f1 <- file.path(input_folder, pollutant,
                    paste0("Daily_", sector, "_", yr, "_", pollutant, ".rds"))
    if (!file.exists(f1)) {
      # Second try: root input folder (legacy format)
      f1 <- file.path(input_folder,
                      paste0("Daily_", sector, "_", yr, "_", pollutant, ".rds"))
      if (!file.exists(f1)) {
        # Third try: SimplifiedDailyData (Phase 6 output)
        f2 <- file.path(input_folder, "SimplifiedDailyData", pollutant,
                        paste0("D_", sector, "_", yr, ".rds"))
        if (!file.exists(f2)) stop("File not found for year ", yr)
        f1 <- f2
      }
    }
    readRDS(f1)
  })
  
  stacked <- abind(tmp, along = 3)
  
  # etichette time CF + dates attr
  total_days <- dim(stacked)[3]
  start_date <- as.Date(paste0(start_year, "-01-01"))
  dates      <- seq.Date(start_date, by = "day", length.out = total_days)
  cf_t       <- as.character(as.integer(dates - as.Date("1850-01-01")))
  rd_t       <- format(dates, "%Y-%m-%d")
  
  # lon/lat names (numeric for proper spatial processing)
  lonlat <- readRDS("data/processed/lon_lat_idx.rds")
  lon_names <- as.numeric(lonlat$lon[lonlat$lon_idx])
  lat_names <- as.numeric(lonlat$lat[lonlat$lat_idx])
  
  # time names (numeric days since 1850-01-01)
  time_names <- as.numeric(cf_t)
  
  dimnames(stacked) <- list(lon = lon_names, lat = lat_names, time = time_names)
  attr(stacked, "dates") <- rd_t
  
  # salva multiperiodo
  outdir <- file.path(input_folder, "DailyAlongYears")
  if (!dir.exists(outdir)) dir.create(outdir, recursive = TRUE)
  outf <- file.path(outdir,
                    paste0("Daily_", sector, "_", start_year, "_", end_year, "_", pollutant, ".rds"))
  saveRDS(stacked, outf)
}


# Function to sum all sectors into one (year-by-year approach for efficiency)
SumAllSectorsIntoOne <- function(input_folder, pollutant, start_year, end_year, output_folder) {
  if (!dir.exists(output_folder)) dir.create(output_folder, recursive = TRUE)
  
  # List of sectors from "A" to "L"
  sectors <- LETTERS[1:12]
  
  # Process each year separately for computational efficiency
  for (year in start_year:end_year) {
    cat("Processing year", year, "for pollutant", pollutant, "\n")
    
    # Variable to store the total sum for this year
    total_sum <- NULL
    sectors_found <- 0
    
    for (sector in sectors) {
      # First try to find stacked files (from DailyAlongYears)
      stacked_file <- file.path(input_folder, paste0("Daily_", sector, "_", start_year, "_", end_year, "_", pollutant, ".rds"))
      
      # If stacked file doesn't exist, try individual year files
      if (!file.exists(stacked_file)) {
        individual_file <- file.path("data/processed/DAILY_data", paste0("Daily_", sector, "_", year, "_", pollutant, ".rds"))
        
        # If individual file doesn't exist, try SimplifiedDailyData
        if (!file.exists(individual_file)) {
          simplified_file <- file.path("data/processed/DAILY_data/SimplifiedDailyData", tolower(pollutant), paste0("D_", sector, "_", year, ".rds"))
          
          if (file.exists(simplified_file)) {
            sector_data <- readRDS(simplified_file)
            sectors_found <- sectors_found + 1
          } else {
            next  # Skip this sector if no file found
          }
        } else {
          sector_data <- readRDS(individual_file)
          sectors_found <- sectors_found + 1
        }
      } else {
        # Extract data for this specific year from stacked file
        stacked_data <- readRDS(stacked_file)
        
        # Calculate which days correspond to this year
        is_leap <- function(y) (y %% 4 == 0 & y %% 100 != 0) | (y %% 400 == 0)
        days_in_year <- function(y) if (is_leap(y)) 366 else 365
        
        years_range <- start_year:end_year
        year_index <- which(years_range == year)
        
        # Calculate start and end indices for this year
        if (year_index == 1) {
          start_idx <- 1
        } else {
          prev_years <- years_range[1:(year_index-1)]
          start_idx <- sum(sapply(prev_years, days_in_year)) + 1
        }
        end_idx <- start_idx + days_in_year(year) - 1
        
        # Extract data for this year only
        if (end_idx <= dim(stacked_data)[3]) {
          sector_data <- stacked_data[,, start_idx:end_idx, drop = FALSE]
          sectors_found <- sectors_found + 1
        } else {
          next  # Skip if indices are out of bounds
        }
      }
      
      # Add to total sum
      if (is.null(total_sum)) {
        total_sum <- sector_data
      } else {
        total_sum <- total_sum + sector_data
      }
      
      # Free memory
      rm(sector_data)
      gc()
    }
    
    if (sectors_found > 0) {
      # Set proper dimension names (all numeric)
      lonlat <- readRDS("data/processed/lon_lat_idx.rds")
      lon_names <- as.numeric(lonlat$lon[lonlat$lon_idx])
      lat_names <- as.numeric(lonlat$lat[lonlat$lat_idx])
      
      # Create numeric time labels (days since 1850-01-01)
      start_date <- as.Date(paste0(year, "-01-01"))
      is_leap <- function(y) (y %% 4 == 0 & y %% 100 != 0) | (y %% 400 == 0)
      days_count <- if (is_leap(year)) 366 else 365
      date_sequence <- seq.Date(from = start_date, by = "day", length.out = days_count)
      reference_date <- as.Date("1850-01-01")
      time_names <- as.numeric(date_sequence - reference_date)
      
      dimnames(total_sum) <- list(lon_names, lat_names, time_names)
      
      # Save the combined matrix for this year
      output_file <- file.path(output_folder, paste0("EM_", pollutant, "_", year, ".rds"))
      saveRDS(total_sum, output_file)
      
      cat("✓ Year", year, "completed - aggregated", sectors_found, "sectors\n")
    } else {
      cat("✗ Year", year, "skipped - no sector data found\n")
    }
    
    # Free memory
    rm(total_sum)
    gc()
  }
  
  cat("Sum of all sectors completed for", pollutant, "from", start_year, "to", end_year, "\n")
}
