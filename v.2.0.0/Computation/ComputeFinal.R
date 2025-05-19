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
                              output_base = "Data/Processed/TEMPO_data/DailyProfiles") {
  
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
    
    # costruisci vettori date
    dates <- seq.Date(as.Date(paste0(yr, "-01-01")),
                      by = "day", length.out = ndays)
    cf_t  <- as.character(as.integer(dates - as.Date("1850-01-01")))
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
  
  years <- seq(start_year, end_year)
  tmp   <- lapply(years, function(yr) {
    f1 <- file.path(input_folder,
                    paste0("Daily_", sector, "_", yr, "_", pollutant, ".rds"))
    if (!file.exists(f1)) {
      f2 <- file.path(input_folder, "SimplifiedDailyData", pollutant,
                      paste0("D_", sector, "_", yr, ".rds"))
      if (!file.exists(f2)) stop("File not found for year ", yr)
      f1 <- f2
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
  
  # lon/lat names
  lonlat <- readRDS("Data/Processed/lon_lat_idx.rds")
  lon_n   <- prettyNum(lonlat$lon[lonlat$lon_idx], trim = TRUE, scientific = FALSE)
  lat_n   <- prettyNum(lonlat$lat[lonlat$lat_idx], trim = TRUE, scientific = FALSE)
  
  dimnames(stacked) <- list(lon = lon_n, lat = lat_n, time = cf_t)
  attr(stacked, "dates") <- rd_t
  
  # salva multiperiodo
  outdir <- file.path(input_folder, "DailyAlongYears")
  if (!dir.exists(outdir)) dir.create(outdir, recursive = TRUE)
  outf <- file.path(outdir,
                    paste0("Daily_", sector, "_", start_year, "_", end_year, "_", pollutant, ".rds"))
  saveRDS(stacked, outf)
}


SumAllSectorsIntoOne <- function(input_folder, pollutant,
                                 stack_start, stack_end,
                                 sum_start, sum_end,
                                 output_folder) {
  is_leap <- function(y) (y %% 4 == 0 & y %% 100 != 0) | (y %% 400 == 0)
  days_in_year <- function(y) if (is_leap(y)) 366 else 365
  
  if (!dir.exists(output_folder)) dir.create(output_folder, recursive = TRUE)
  
  years_stack <- seq(stack_start, stack_end)
  days_stack  <- sapply(years_stack, days_in_year)
  cum_days    <- cumsum(days_stack)
  start_idx   <- c(1, head(cum_days, -1) + 1)
  end_idx     <- cum_days
  
  # intervallo globale all'interno del file stacked
  idx_range <- seq(start_idx[which(years_stack == sum_start)],
                   end_idx  [which(years_stack == sum_end)])
  
  sectors <- LETTERS[1:12]
  total_sum <- NULL
  
  for (s in sectors) {
    fn <- file.path(input_folder,
                    paste0("Daily_", s, "_", stack_start, "_", stack_end, "_", pollutant, ".rds"))
    if (!file.exists(fn)) stop("Missing file: ", fn)
    arr   <- readRDS(fn)
    slice <- arr[,, idx_range, drop = FALSE]
    total_sum <- if (is.null(total_sum)) slice else total_sum + slice
    rm(arr, slice); gc()
  }
  
  # etichette time + dates per il sotto-intervallo
  dates_sum <- seq.Date(as.Date(paste0(sum_start, "-01-01")),
                        as.Date(paste0(sum_end,   "-12-31")), by = "day")
  cf_t_sum  <- as.character(as.integer(dates_sum - as.Date("1850-01-01")))
  rd_t_sum  <- format(dates_sum, "%Y-%m-%d")
  
  dimnames(total_sum) <- list(
    lon  = dimnames(total_sum)[[1]],
    lat  = dimnames(total_sum)[[2]],
    time = cf_t_sum
  )
  attr(total_sum, "dates") <- rd_t_sum
  
  # salva risultato unico per l'intervallo scelto
  out_fn <- file.path(output_folder,
                      paste0("SumAllSectors_", pollutant, "_", sum_start, "_", sum_end, ".rds"))
  saveRDS(total_sum, out_fn)
}
