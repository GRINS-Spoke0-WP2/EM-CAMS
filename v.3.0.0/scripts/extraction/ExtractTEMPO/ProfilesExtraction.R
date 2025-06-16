source("scripts/utils/Utils.R")
source("scripts/utils/Config.R")

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