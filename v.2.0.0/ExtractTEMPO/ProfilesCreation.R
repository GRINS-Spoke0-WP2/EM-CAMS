source("../Utils.R")
source("../Config.R")

# Function to save daily profiles as matrix (3D) per year
save_daily_profiles_as_matrix <- function(list_of_dfs, start_year, output_dir,profile_name) {
  indexFromYear <- 1
  
  for (year in start_year:(start_year + length(list_of_dfs) / 365 - 1)) {
    days_in_year <- if (year %% 4 == 0) 366 else 365
    
    FD_matrix <- NULL
    
    for (day in 1:days_in_year) {
      df <- list_of_dfs[[indexFromYear + day - 1]]
      dcast_matrix <- dcast(df, x ~ y, value.var = "value")
      value_matrix <- as.matrix(dcast_matrix[,-1])
      FD_matrix <- abind(FD_matrix, value_matrix, along = 3)
    }
    
    # Insert the year right after the sector letter
    file_name <- sub("(FD_[A-Z])", paste0("\\1_", year), profile_name)
    
    # Save the file
    saveRDS(FD_matrix, file = file.path(output_dir, paste0(file_name, ".rds")))
    
    
    rm(FD_matrix)
    gc()
    
    indexFromYear <- indexFromYear + days_in_year
  }
}

# Function for saving weekly profiles
save_weekly_profiles <- function(list_of_dfs, output_dir, profile_name) {
  week_matrix <- NULL
  
  for (day in 1:7) {
    df <- list_of_dfs[[day]]
    dcast_matrix <- dcast(df, x ~ y, value.var = "value")
    value_matrix <- as.matrix(dcast_matrix[,-1])
    week_matrix <- abind(week_matrix, value_matrix, along = 3)
  }
  
  saveRDS(week_matrix, file = file.path(output_dir, paste0(profile_name, "_weekly.rds")))
}

# Function for saving monthly profiles
save_monthly_profiles <- function(list_of_dfs, output_dir, profile_name) {
  # Creare una matrice per i 12 mesi
  monthly_matrix <- NULL
  
  for (month in 1:12) {
    df <- list_of_dfs[[month]]
    dcast_matrix <- dcast(df, x ~ y, value.var = "value")
    value_matrix <- as.matrix(dcast_matrix[,-1])
    monthly_matrix <- abind(monthly_matrix, value_matrix, along = 3)
  }
  
  saveRDS(monthly_matrix, file = file.path(output_dir, paste0(profile_name, "_monthly.rds")))
}

process_profile <- function(nc_file_path_daily_weekly, nc_file_path_monthly, profile_name, output_dir) {
  
  # Info on the profile
  profile_info <- list(
    FW_F = list(var_name = "FW_F", temporal_dim = "weekly"),
    FW_H = list(var_name = "FW_H", temporal_dim = "weekly"),
    FD_C = list(var_name = "FD_C", temporal_dim = "daily"),
    FD_K_nh3_nox = list(var_name = "FD_K_nh3_nox", temporal_dim = "daily"),
    FD_L_nh3 = list(var_name = "FD_L_nh3", temporal_dim = "daily"),
    FW_A_ch4 = list(var_name = "FW_A_ch4", temporal_dim = "weekly"),
    FW_A_co = list(var_name = "FW_A_co", temporal_dim = "weekly"),
    FW_A_co2 = list(var_name = "FW_A_co2", temporal_dim = "weekly"),
    FW_A_nmvoc = list(var_name = "FW_A_nmvoc", temporal_dim = "weekly"),
    FW_A_nox = list(var_name = "FW_A_nox", temporal_dim = "weekly"),
    FW_A_pm25 = list(var_name = "FW_A_pm25", temporal_dim = "weekly"),
    FW_A_pm10 = list(var_name = "FW_A_pm10", temporal_dim = "weekly"),
    FW_A_sox = list(var_name = "FW_A_sox", temporal_dim = "weekly"),
    FM_L_nh3 = list(var_name = "FM_L_nh3", temporal_dim = "monthly"),
    FM_L2 = list(var_name = "FM_L2", temporal_dim = "monthly"),
    FM_C = list(var_name = "FM_C", temporal_dim = "monthly"),
    FM_K_nh3_nox = list(var_name = "FM_K_nh3_nox", temporal_dim = "monthly"),
    FM_F1_nmvoc = list(var_name = "FM_F1_nmvoc", temporal_dim = "monthly"),
    FM_F1_co = list(var_name = "FM_F1_co", temporal_dim = "monthly"),
    FM_B = list(var_name = "FM_B", temporal_dim = "monthly"),
    FM_F = list(var_name = "FM_F", temporal_dim = "monthly"),
    FM_A_ch4 = list(var_name = "FM_A_ch4", temporal_dim = "monthly"),
    FM_G_ch4 = list(var_name = "FM_G_ch4", temporal_dim = "monthly"),
    FM_A_co = list(var_name = "FM_A_co", temporal_dim = "monthly"),
    FM_G_co = list(var_name = "FM_G_co", temporal_dim = "monthly"),
    FM_A_co2 = list(var_name = "FM_A_co2", temporal_dim = "monthly"),
    FM_G_co2 = list(var_name = "FM_G_co2", temporal_dim = "monthly"),
    FM_A_nmvoc = list(var_name = "FM_A_nmvoc", temporal_dim = "monthly"),
    FM_G_nmvoc = list(var_name = "FM_G_nmvoc", temporal_dim = "monthly"),
    FM_A_nox = list(var_name = "FM_A_nox", temporal_dim = "monthly"),
    FM_G_nox = list(var_name = "FM_G_nox", temporal_dim = "monthly"),
    FM_A_pm25 = list(var_name = "FM_A_pm25", temporal_dim = "monthly"),
    FM_G_pm25 = list(var_name = "FM_G_pm25", temporal_dim = "monthly"),
    FM_A_pm10 = list(var_name = "FM_A_pm10", temporal_dim = "monthly"),
    FM_G_pm10 = list(var_name = "FM_G_pm10", temporal_dim = "monthly"),
    FM_A_sox = list(var_name = "FM_A_sox", temporal_dim = "monthly"),
    FM_G_sox = list(var_name = "FM_G_sox", temporal_dim = "monthly")
  )
  
  # profile_name validation
  if (!(profile_name %in% names(profile_info))) {
    stop("Invalid profile name")
  }
  
  #Selecting the correct nc file path based on the temporal dimension
  nc_file_path <- if (profile_info[[profile_name]]$temporal_dim == "monthly") {
    nc_file_path_monthly
  } else {
    nc_file_path_daily_weekly
  }
  
  nc <- nc_open(nc_file_path)
  
  lon <- ncvar_get(nc, "longitude")
  lat <- ncvar_get(nc, "latitude")
  
  # Bounding box index (impostare il confine manualmente)
  
  lon_idx <- which(lon >= boundary[1] & lon <= boundary[2])
  lat_idx <- which(lat >= boundary[3] & lat <= boundary[4])
  
  # Calculate the number of periods based on the temporal dimension
  num_periods <- if (profile_info[[profile_name]]$temporal_dim == "daily") {
    nc$dim$time$len
  } else if (profile_info[[profile_name]]$temporal_dim == "monthly") {
    nc$dim$month$len 
  } else {
    nc$dim$weekday_index$len
  }
  
  list_of_dfs <- vector("list", num_periods)
  
  #Using for cycle instead of 1:num_periods for memory allocation
  for (period_index in 1:num_periods) {
    start_idx <- c(min(lon_idx), min(lat_idx), period_index)
    count_idx <- c(length(lon_idx), length(lat_idx), 1)
    
    profile_data <- ncvar_get(nc, profile_info[[profile_name]]$var_name, start = start_idx, count = count_idx)
    
    df <- expand.grid(x = lon[lon_idx], y = lat[lat_idx])
    df$value <- as.vector(profile_data)
    
    list_of_dfs[[period_index]] <- df
  }
  
  nc_close(nc)
  
  # Manage the temporal dimension
  if (profile_info[[profile_name]]$temporal_dim == "daily") {
    save_daily_profiles_as_matrix(list_of_dfs, 2000, output_dir,profile_name)
  } else if (profile_info[[profile_name]]$temporal_dim == "weekly") {
    save_weekly_profiles(list_of_dfs, output_dir, profile_name)
  } else if (profile_info[[profile_name]]$temporal_dim == "monthly") {
    save_monthly_profiles(list_of_dfs, output_dir, profile_name)
  }
}

# Aggiorna il percorso d'output per i profili semplificati
SimpleProfilesCreation <- function(files_path = Path_simplifiedProfilesCSV, poll, start_year, end_year) {
  list_profiles <- SimpleProfilesExtraction(files_path, poll)
  
  monthly_profile <- list_profiles[[1]]
  weekly_profile <- list_profiles[[2]]
  
  # Create a folder for the pollutant if it doesn't already exist
  pollutant_folder <- file.path("Data/Processed/TEMPO_data/DailySimplifiedProfiles", poll)
  if (!dir.exists(pollutant_folder)) {
    dir.create(pollutant_folder, recursive = TRUE)
  }
  
  for (year in start_year:end_year) {
    print(year)
    
    days_in_month <- get_days_in_month(year)
    current_weekday <- get_first_day_of_year(year)  # Day 1 of the year
    
    # Create the matrix for daily profiles
    sector_profile <- array(0, dim = c(get_days_in_year(year), length(monthly_profile$GNFR)))
    
    sectors <- monthly_profile$GNFR  # Assuming GNFR is a vector of sector names
    
    # Use a numeric index to assign data to the sector_profile array
    for (sector_idx in seq_along(sectors)) {
      sector <- sectors[sector_idx]
      print(sector)
      
      # Get the row for the sector
      monthlyForSector <- monthly_profile[monthly_profile$GNFR == sector, ][, 4:15] #excluding first 3 col(ISO3,POLL,GNFR...)
      weeklyForSector <- weekly_profile[weekly_profile$GNFR == sector, ][, 4:10]
      
      daily_profile <- c()
      
      for (month in 1:12) {
        week_factor <- 7 / days_in_month[month]
        
        for (day in 1:days_in_month[month]) {
          day_weight <- monthlyForSector[[month]] * weeklyForSector[[current_weekday]]
          daily_profile <- c(daily_profile, day_weight)
          
          # Update current_weekday, reset to 1 after Sunday (7)
          current_weekday <- ifelse(current_weekday == 7, 1, current_weekday + 1)
        }
      }
      
      # Assign the daily profile to the corresponding sector
      sector_profile[, sector_idx] <- daily_profile
    }
    
    dimnames(sector_profile)[[2]] <- sectors
    # Save the daily profile in the folder created for the pollutant
    output_file <- file.path(pollutant_folder, paste0("S_D_all_", year, "_", poll, ".rds"))
    saveRDS(sector_profile, output_file)
    rm(sector_profile)
  }
}

## DailyPRF_fromFMFW ####
# Funzione principale aggiornata
DailyPRF_fromFMFW <- function(FM_profile, FW_profile, sector, start_year, end_year) {
  
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
    # Assumendo che FM_profile abbia dimensioni [x, y, 12] e FW_profile abbia dimensioni [x, y, 7]
    x_dim <- dim(FM_profile)[1]
    y_dim <- dim(FM_profile)[2]
    daily_profile <- array(0, dim = c(x_dim, y_dim, total_days))
    
    current_day_of_year <- 1  # Contatore per il giorno dell'anno
    
    for (month in 1:12) {
      print(paste("Processing month:", month))
      
      days_in_current_month <- days_in_month[month]
      
      for (day_in_month in 1:days_in_current_month) {
        # Calcola il profilo giornaliero per il giorno corrente
        daily_profile[,,current_day_of_year] <- FM_profile[,,month] * FW_profile[,,current_weekday]
        
        # Aggiorna i contatori
        current_day_of_year <- current_day_of_year + 1
        current_weekday <- ifelse(current_weekday == 7, 1, current_weekday + 1)
      }
    }
    
    # Salva il profilo giornaliero per l'anno corrente
    output_file <- file.path(sector_folder, paste0("FD_",sector,"_", year, ".rds"))
    saveRDS(daily_profile, output_file)
    rm(daily_profile)
  }
}



## Utils ####

# Function to check if a year is a leap year
is_leap_year <- function(year) {
  return((year %% 4 == 0 & year %% 100 != 0) | (year %% 400 == 0))
}

# Function to get the number of days in each month for a given year
get_days_in_month <- function(year) {
  if (is_leap_year(year)) {
    return(c(31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31))  # Leap year
  } else {
    return(c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31))  # Non-leap year
  }
}

# Function to get the first day of the year
get_first_day_of_year <- function(year) {
  # Get the day of the week, with Sunday as 0
  day_of_week <- as.POSIXlt(paste0(year, "-01-01"))$wday
  
  # Convert 0 (Sunday) to 7 and leave other days unchanged
  return(ifelse(day_of_week == 0, 7, day_of_week))
}

# Function to get the total number of days in a year
get_days_in_year <- function(year) {
  return(ifelse(is_leap_year(year), 366, 365))
}

# Function to extract pollutant profiles from CSV files
SimpleProfilesExtraction <- function(files_path, poll) {
  Monthly_profiles <- ExtractPollutantCSV(files_path[1], poll)
  Weekly_profiles <- ExtractPollutantCSV(files_path[2], poll)
  
  return(list(Monthly_profiles, Weekly_profiles))
}

# Function to read and filter pollutant data from a CSV file
ExtractPollutantCSV <- function(file_path, poll) {
  # Read the CSV file
  data <- read.csv(file_path, header = TRUE, sep = ",")
  
  country <- "ITA"
  # Extract the pollutant data for the specified pollutant and country
  pollutant_data <- data[data$POLL == poll & data$ISO3 == country, ]
  
  return(pollutant_data)
}