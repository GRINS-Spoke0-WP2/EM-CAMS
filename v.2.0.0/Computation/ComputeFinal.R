# ------------------------------------------------------------------------------
# File: ComputeFinal.R
# ------------------------------------------------------------------------------
# Contiene le funzioni finali di calcolo e aggregazione:
#   - DailyPRF_fromFMFW
#   - StackDailyData
#   - SumAllSectorsIntoOne
# (Codice originale estratto da "DailyPRF_fromFMFW.R" e "StackDailyData.R")
# ------------------------------------------------------------------------------

DailyPRF_fromFMFW <- function(FM_profile, FW_profile, sector) {
  
  is_leap_year <- function(year) {
    return((year %% 4 == 0 & year %% 100 != 0) | (year %% 400 == 0))
  }
  
  get_days_in_month <- function(year) {
    if (is_leap_year(year)) {
      return(c(31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31))  # Anno bisestile
    } else {
      return(c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31))  # Anno non bisestile
    }
  }
  
  get_first_day_of_year <- function(year) {
    day_of_week <- as.POSIXlt(paste0(year, "-01-01"))$wday
    return(ifelse(day_of_week == 0, 7, day_of_week))
  }
  
  get_days_in_year <- function(year) {
    return(ifelse(is_leap_year(year), 366, 365))
  }
  
  start_year <- 2000
  end_year <- 2020
  
  # Crea una cartella per il settore se non esiste già
  sector_folder <- file.path("Data/Processed/TEMPO_data/DailyProfiles", sector)
  if (!dir.exists(sector_folder)) {
    dir.create(sector_folder, recursive = TRUE)
  }
  
  for (year in start_year:end_year) {
    print(paste("Processing year:", year))
    
    days_in_month <- get_days_in_month(year)
    total_days <- get_days_in_year(year)
    
    # Ottieni il giorno della settimana del primo giorno dell'anno
    current_weekday <- get_first_day_of_year(year)  # 1=Lunedì, ..., 7=Domenica
    
    # Inizializza l'array per il profilo giornaliero
    x_dim <- dim(FM_profile)[1]
    y_dim <- dim(FM_profile)[2]
    daily_profile <- array(0, dim = c(x_dim, y_dim, total_days))
    
    current_day_of_year <- 1  # Contatore per il giorno dell'anno
    
    for (month in 1:12) {
      print(paste("Processing month:", month))
      
      days_in_current_month <- days_in_month[month]
      
      for (day_in_month in 1:days_in_current_month) {
        daily_profile[,,current_day_of_year] <- FM_profile[,,month] * FW_profile[,,current_weekday]
        
        current_day_of_year <- current_day_of_year + 1
        current_weekday <- ifelse(current_weekday == 7, 1, current_weekday + 1)
      }
    }
    
    # Salva il profilo giornaliero per l'anno corrente
    output_file <- file.path(sector_folder, paste0("DailyProfile_", year, "_", sector, ".rds"))
    saveRDS(daily_profile, output_file)
    rm(daily_profile)
  }
}


StackDailyData <- function(input_folder, sector, pollutant, start_year, end_year) {
  # Load necessary library
  library(abind)
  
  # List to store daily matrices
  daily_data_list <- list()
  
  # Loop over the years
  for (year in start_year:end_year) {
    # Construct the file name
    daily_data_file <- file.path(input_folder, paste0("Daily_", sector, "_", year, "_", pollutant, ".rds"))
    
    # Check if the file exists; if not, look in SimplifiedDailyData/pollutant
    if (!file.exists(daily_data_file)) {
      simplified_data_file <- file.path(input_folder, "SimplifiedDailyData", pollutant, paste0("D_", sector, "_", year, ".rds"))
      
      # If the file doesn't exist in SimplifiedDailyData, throw an error
      if (!file.exists(simplified_data_file)) {
        stop(paste("File for year", year, "not found in DAILY_data or SimplifiedDailyData:", simplified_data_file))
      } else {
        daily_data_file <- simplified_data_file
      }
    }
    
    # Load the daily data for the year
    daily_data <- readRDS(daily_data_file)
    
    # Add the daily data to the list
    daily_data_list[[as.character(year)]] <- daily_data
  }
  
  # Combine all matrices along the time dimension (days)
  stacked_daily_data <- abind(daily_data_list, along = 3)
  
  # Create time labels in dd/mm/yyyy format
  total_days <- dim(stacked_daily_data)[3]
  start_date <- as.Date(paste0(start_year, "-01-01"))
  date_sequence <- seq.Date(from = start_date, by = "day", length.out = total_days)
  formatted_dates <- format(date_sequence, "%d%m%Y")
  
  # Load longitude and latitude indices
  lon_lat_idx <- readRDS("Data/Processed/lon_lat_idx.rds")
  # Use lon_idx and lat_idx to get coordinates and round to 2 decimals
  lon_rounded <- round(lon_lat_idx$lon[lon_lat_idx$lon_idx], 2)
  lat_rounded <- round(lon_lat_idx$lat[lon_lat_idx$lat_idx], 2)
  
  # Convert values to formatted strings to ensure two decimals
  lon_names <- sprintf("%.2f", lon_rounded)
  lat_names <- sprintf("%.2f", lat_rounded)
  
  # Set dimnames for the time dimension
  dimnames(stacked_daily_data) <- list(lon_names, lat_names, formatted_dates)
  
  # Save the stacked data as an RDS file
  saveRDS(stacked_daily_data, file.path(input_folder, paste0("DailyAlongYears/Daily_", sector, "_", start_year, "_", end_year, "_", pollutant, ".rds")))
}

SumAllSectorsIntoOne <- function(input_folder, output_file, pollutant, start_year, end_year) {
  # List of sectors from "A" to "L"
  sectors <- LETTERS[1:12]
  
  # Variable to store the total sum
  total_sum <- NULL
  
  for (sector in sectors) {
    # Handle the special case where files may be named with "NO2" instead of "NOx"
    if (pollutant == "NOx") {
      file_name <- file.path(input_folder, paste0("Daily_", sector, "_", start_year, "_", end_year, "_NOx.rds"))
      if (!file.exists(file_name)) {
        file_name <- file.path(input_folder, paste0("Daily_", sector, "_", start_year, "_", end_year, "_NO2.rds"))
      }
    } else {
      file_name <- file.path(input_folder, paste0("Daily_", sector, "_", start_year, "_", end_year, "_", pollutant, ".rds"))
    }
    
    if (file.exists(file_name)) {
      cat("Processing data for sector:", sector, "\n")
      
      # Load the data for the current sector
      sector_data <- tryCatch(readRDS(file_name), error = function(e) {
        cat("Error for sector", sector, ":", e$message, "\n")
        return(NULL)
      })
      
      if (!is.null(sector_data)) {
        if (is.null(total_sum)) {
          # Initialize total_sum with the first sector's data
          total_sum <- sector_data
        } else {
          # Add the current sector's data to the total sum
          total_sum <- total_sum + sector_data
        }
        
        # Free memory
        rm(sector_data)
        gc()
      }
    } else {
      cat("File not found for sector:", sector, "-", file_name, "\n")
    }
  }
  
  # Save the combined matrix
  saveRDS(total_sum, output_file)
  
  cat("Sum of sectors completed:", output_file, "\n")
}
