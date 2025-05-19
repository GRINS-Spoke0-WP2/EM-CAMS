# ------------------------------------------------------------------------------
# File: ComputeFinal.R
# ------------------------------------------------------------------------------
# Contiene le funzioni finali di calcolo e aggregazione:
#   - DailyPRF_fromFMFW
#   - StackDailyData
#   - SumAllSectorsIntoOne  (modificata per salvare anno per anno)
# ------------------------------------------------------------------------------

DailyPRF_fromFMFW <- function(FM_profile, FW_profile, sector) {
  
  is_leap_year <- function(year) {
    (year %% 4 == 0 & year %% 100 != 0) | (year %% 400 == 0)
  }
  
  get_days_in_month <- function(year) {
    if (is_leap_year(year)) {
      c(31,29,31,30,31,30,31,31,30,31,30,31)
    } else {
      c(31,28,31,30,31,30,31,31,30,31,30,31)
    }
  }
  
  get_first_day_of_year <- function(year) {
    w <- as.POSIXlt(paste0(year, "-01-01"))$wday
    if (w == 0) 7 else w
  }
  
  get_days_in_year <- function(year) {
    if (is_leap_year(year)) 366 else 365
  }
  
  start_year <- 2000
  end_year   <- 2020
  
  sector_folder <- file.path("Data/Processed/TEMPO_data/DailyProfiles", sector)
  if (!dir.exists(sector_folder)) dir.create(sector_folder, recursive = TRUE)
  
  for (year in start_year:end_year) {
    message("Processing year: ", year)
    
    days_in_month   <- get_days_in_month(year)
    total_days      <- get_days_in_year(year)
    current_weekday <- get_first_day_of_year(year)
    
    x_dim <- dim(FM_profile)[1]
    y_dim <- dim(FM_profile)[2]
    daily_profile <- array(0, dim = c(x_dim, y_dim, total_days))
    
    day_counter <- 1
    for (m in seq_along(days_in_month)) {
      for (d in seq_len(days_in_month[m])) {
        daily_profile[,,day_counter] <-
          FM_profile[,,m] * FW_profile[,,current_weekday]
        day_counter     <- day_counter + 1
        current_weekday <- ifelse(current_weekday == 7, 1, current_weekday + 1)
      }
    }
    
    output_file <- file.path(
      sector_folder,
      paste0("DailyProfile_", year, "_", sector, ".rds")
    )
    saveRDS(daily_profile, output_file)
    rm(daily_profile); gc()
  }
}


StackDailyData <- function(input_folder, sector, pollutant, start_year, end_year) {
  library(abind)
  
  daily_data_list <- vector("list", length = end_year - start_year + 1)
  names(daily_data_list) <- as.character(start_year:end_year)
  
  for (year in start_year:end_year) {
    fname <- file.path(
      input_folder,
      paste0("Daily_", sector, "_", year, "_", pollutant, ".rds")
    )
    if (!file.exists(fname)) {
      alt <- file.path(input_folder, "SimplifiedDailyData", pollutant,
                       paste0("D_", sector, "_", year, ".rds"))
      if (!file.exists(alt)) {
        stop("File not found for year ", year, ": ", alt)
      }
      fname <- alt
    }
    daily_data_list[[as.character(year)]] <- readRDS(fname)
  }
  
  stacked_daily_data <- abind(daily_data_list, along = 3)
  
  # Etichette temporali in ddmmyyyy
  total_days  <- dim(stacked_daily_data)[3]
  start_date  <- as.Date(paste0(start_year, "-01-01"))
  date_seq    <- seq.Date(from = start_date, by = "day", length.out = total_days)
  time_names  <- format(date_seq, "%d%m%Y")
  
  # Carica lon/lat idx e crea nomi “puliti”
  lon_lat_idx <- readRDS("Data/Processed/lon_lat_idx.rds")
  lon_vals    <- lon_lat_idx$lon[lon_lat_idx$lon_idx]
  lat_vals    <- lon_lat_idx$lat[lon_lat_idx$lat_idx]
  lon_names   <- prettyNum(lon_vals, trim = TRUE, scientific = FALSE)
  lat_names   <- prettyNum(lat_vals, trim = TRUE, scientific = FALSE)
  
  dimnames(stacked_daily_data) <- list(
    lon  = lon_names,
    lat  = lat_names,
    time = time_names
  )
  
  outdir <- file.path(input_folder, "DailyAlongYears")
  if (!dir.exists(outdir)) dir.create(outdir, recursive = TRUE)
  saveRDS(
    stacked_daily_data,
    file = file.path(
      outdir,
      paste0("Daily_", sector, "_", start_year, "_", end_year, "_", pollutant, ".rds")
    )
  )
}


SumAllSectorsIntoOne <- function(input_folder, pollutant, start_year, end_year, output_folder) {
  # helper per giorni/anno
  is_leap <- function(y) (y %% 4 == 0 & y %% 100 != 0) | (y %% 400 == 0)
  days_in_year <- function(y) if (is_leap(y)) 366 else 365
  
  # preparazione cartella di output
  if (!dir.exists(output_folder)) dir.create(output_folder, recursive = TRUE)
  
  # anni e indici cumulati
  years    <- seq(start_year, end_year)
  days_vec <- sapply(years, days_in_year)
  cum_days <- cumsum(days_vec)
  start_idx <- c(1, head(cum_days, -1) + 1)
  end_idx   <- cum_days
  
  sectors <- LETTERS[1:12]
  
  for (i in seq_along(years)) {
    yr       <- years[i]
    idx      <- start_idx[i]:end_idx[i]
    total_sum <- NULL
    
    message("Summing for year ", yr, " (days ", min(idx), "–", max(idx), ")")
    
    for (s in sectors) {
      # path al file multi-anno per questo settore
      fn <- file.path(
        input_folder,
        paste0("Daily_", s, "_", start_year, "_", end_year, "_", pollutant, ".rds")
      )
      if (!file.exists(fn)) stop("File mancante: ", fn)
      
      # carica, sottoseleziona, poi libera la grande matrice
      arr   <- readRDS(fn)
      slice <- arr[,, idx, drop = FALSE]
      rm(arr); gc()
      
      # somma
      if (is.null(total_sum)) {
        total_sum <- slice
      } else {
        total_sum <- total_sum + slice
      }
      rm(slice); gc()
    }
    
    # salva il risultato per l'anno
    out_fn <- file.path(
      output_folder,
      paste0("SumAllSectors_", pollutant, "_", yr, ".rds")
    )
    saveRDS(total_sum, out_fn)
    message("  -> saved: ", out_fn)
    
    rm(total_sum); gc()
  }
}
