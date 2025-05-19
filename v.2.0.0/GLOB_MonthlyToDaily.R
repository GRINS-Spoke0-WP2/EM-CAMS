###############################################################################
# GLOB_MonthlyToDaily.R
# Correct handling of 5D arrays (slice5d) to preserve dimnames and allow indexing.
###############################################################################

library(lubridate)

# =============================================================================
# Function: CreateWeeklyProfile
# Description:
#   Reads a CSV file containing weekly temporal profiles for a given pollutant.
#   Extracts the profiles for Italy (ISO3 == "ITA") and returns a matrix
#   with days of the week (rows: 1–7) and GNFR sectors (columns).
#   Optionally merges F1, F2, F3 into a single "F" sector by averaging.
# =============================================================================
CreateWeeklyProfile <- function(weekly_csv, pollutant, out_dir) {
  stopifnot(file.exists(weekly_csv))
  
  df <- read.csv(weekly_csv, stringsAsFactors = FALSE)
  df <- df[toupper(df$POLL) == toupper(pollutant) & df$ISO3 == "ITA", ]
  sectors <- unique(df$GNFR)
  
  # Create an empty weekly matrix: 7 days x number of sectors
  wmat <- matrix(0, 7, length(sectors), dimnames = list(1:7, sectors))
  
  # Fill matrix with values from CSV
  for (i in seq_along(sectors)) {
    vals <- as.numeric(df[toupper(df$GNFR) == toupper(sectors[i]), 4:10])
    wmat[, i] <- vals
  }
  
  # Merge F1, F2, F3 into a single 'F' sector if all are present
  if (all(c("F1", "F2", "F3") %in% colnames(wmat))) {
    Fvals <- rowMeans(wmat[, c("F1", "F2", "F3")], na.rm = TRUE)
    keep  <- setdiff(colnames(wmat), c("F1", "F2", "F3"))
    posE  <- which(keep == "E")  # maintain original column order
    m     <- wmat[, keep, drop = FALSE]
    wmat  <- cbind(m[, 1:posE, drop = FALSE], F = Fvals, m[, (posE + 1):ncol(m), drop = FALSE])
  }
  
  # Save the result to .rds file
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(out_dir, paste0("S_W_simplified_", toupper(pollutant), ".rds"))
  saveRDS(wmat, path)
  
  invisible(wmat)
}


# =============================================================================
# Function: MonthlyToDaily
# Description:
#   Converts monthly emissions into daily values using a weekly temporal profile.
#   The output is a 4D array: [lon, lat, sector, day].
#   This function loops through each year, applies the temporal profile, 
#   and saves both the detailed and the sector-summed daily emissions.
# =============================================================================
MonthlyToDaily <- function(monthly_rds, weekly_rds, lonlat_idx_rds,
                           pollutant, output_dir, years) {
  cat("DEBUG[MonthlyToDaily] Starting for", pollutant, "\n")
  stopifnot(file.exists(monthly_rds),
            file.exists(weekly_rds),
            file.exists(lonlat_idx_rds))
  
  # Load data from RDS files
  md   <- readRDS(monthly_rds)     # Monthly emissions: 5D array
  wmat <- readRDS(weekly_rds)      # Weekly profile matrix: [1:7, sectors]
  ll   <- readRDS(lonlat_idx_rds)  # Coordinate indices and values
  
  # Prepare dimension names for output
  lon_n <- prettyNum(ll$lon[ll$lon_idx], trim = TRUE, scientific = FALSE)
  lat_n <- prettyNum(ll$lat[ll$lat_idx], trim = TRUE, scientific = FALSE)
  
  dn       <- dimnames(md)
  avail    <- as.integer(dn[[5]])  # Years available (5th dimension)
  yrs      <- intersect(years, avail)  # Only process requested years
  secs     <- setdiff(intersect(colnames(wmat), dn[[3]]), "S")  # Valid GNFR sectors
  
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Loop over years
  for (yr in yrs) {
    cat("  • Year", yr, "\n")
    iy <- which(avail == yr)
    
    # Extract the 4D monthly emission slice for the selected year
    slice5d <- md[,,,, iy]  # [lon, lat, sector, month]
    cat("    slice5d dim:", paste(dim(slice5d), collapse = " x "), "\n")
    cat("    slice5d sectors:", head(dimnames(slice5d)[[3]], 5), "...\n")
    
    # Create daily sequence and corresponding metadata
    dates   <- seq.Date(as.Date(paste0(yr, "-01-01")), as.Date(paste0(yr, "-12-31")), by = "day")
    ndays   <- length(dates)
    cf_t    <- as.character(as.numeric(dates - as.Date("1850-01-01")))  # Time in "days since 1850"
    rd_t    <- format(dates, "%Y-%m-%d")  # Readable date strings
    
    # Initialize daily emissions array: [lon, lat, sector, time]
    Dyn <- array(
      0,
      dim      = c(length(lon_n), length(lat_n), length(secs), ndays),
      dimnames = list(lon = lon_n, lat = lat_n, sector = secs, time = cf_t)
    )
    attr(Dyn, "dates") <- rd_t
    T
    # Compute weekdays and months for all days in year
    wd_seq   <- wday(dates, week_start = 1)  # 1 = Monday
    mon_seq  <- month(dates)
    
    # Compute normalization weights for each month (sum of profile values)
    month_wt <- sapply(1:12, function(m) sum(wmat[wd_seq[mon_seq == m], ], na.rm = TRUE))
    cat("    month_wt[1:3]:", head(month_wt, 3), "\n")
    
    # Distribute monthly values into daily using the weekly profile
    for (s in secs) {
      cat("    processing sector", s, "\n")
      for (d in seq_len(ndays)) {
        mo <- mon_seq[d]  # Current month
        wd <- wd_seq[d]   # Current weekday
        # Daily value = (monthly value) * (weekly weight) 
        Dyn[,,s,d] <- (slice5d[,,s,mo] * wmat[wd, s]) 
      }
    }
    
    # Save full 4D daily emissions array
    sec_fn <- file.path(output_dir, sprintf("GLOB_daily_%s_%04d.rds", pollutant, yr))
    saveRDS(Dyn, sec_fn)
    cat("    saved sector daily file:", sec_fn, "| exists?", file.exists(sec_fn), "\n")
    
    # Compute and save total daily emissions across all sectors: [lon, lat, time]
    SumArr <- apply(Dyn, c(1,2,4), sum)
    dimnames(SumArr) <- list(lon = lon_n, lat = lat_n, time = cf_t)
    attr(SumArr, "dates") <- rd_t
    
    sum_fn <- file.path(output_dir, sprintf("GLOB_daily_%s_sum_%04d.rds", pollutant, yr))
    saveRDS(SumArr, sum_fn)
    cat("    saved summed daily file:", sum_fn, "| exists?", file.exists(sum_fn), "\n\n")
  }
  
  cat("DEBUG[MonthlyToDaily] Finished for", pollutant, "\n\n")
}
