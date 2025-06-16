###############################################################################
# EM-CAMS v.3.0.0 - Phase 8: CAMS-GLOB-ANT → GNFR-monthly → GNFR-daily
###############################################################################
# Description: Extract GLOB-ANT data, map to GNFR sectors, and convert 
#              monthly data to daily profiles
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
###############################################################################

# Start phase timer
start_time_phase8 <- Sys.time()
cat("Starting Phase 8: CAMS-GLOB-ANT → GNFR-monthly → GNFR-daily\n")

# Load required libraries
library(ncdf4)
library(abind)
library(lubridate)

# Load configuration and utilities
source("scripts/utils/Config.R")                        # boundary definition
source("scripts/utils/Utils.R")                         # sector_names_GLOB definition

# Verify that required variables are loaded
if (!exists("boundary")) {
  stop("ERROR: 'boundary' variable not found. Check Config.R loading.")
}
if (!exists("sector_names_GLOB")) {
  stop("ERROR: 'sector_names_GLOB' variable not found. Check Utils.R loading.")
}

cat("✓ Configuration loaded: boundary =", paste(boundary, collapse=", "), "\n")
cat("✓ GLOB sectors loaded:", length(sector_names_GLOB), "sectors\n")

# Load required modules
source("scripts/extraction/ExtractANT/ExtractGLOB.R")    # build_5D_GLOB_from_files()
source("scripts/computation/MapGLOBtoGNFR.R")           # map_GLOB_to_GNFR()
source("scripts/computation/GLOB_MonthlyToDaily.R")     # CreateWeeklyProfile(), MonthlyToDaily()

# Define processing parameters
glob_nc_dir        <- "data/Raw/CAMS-GLOB-ANT"
ant_out_dir        <- "data/processed/ANT_data"
lonlat_idx_rds     <- "data/processed/lon_lat_idxGLOBBB.rds"
weekly_csv         <- "data/Raw/CAMS-REG-TEMPO-SIMPLIFIED/CAMS_TEMPO_v4_1_simplified_Weekly_Factors.csv"
tempo_base_dir     <- "data/processed/TEMPO_data"
daily_out_base_dir <- "data/processed/DAILY_data/DailyFromGLOB"

# Helper functions for file processing
get_year <- function(f) as.integer(sub(".*_(\\d{4})\\.nc$", "\\1", basename(f)))
get_poll <- function(f) tolower(sub(".*anthro_([^_]+)_.*","\\1",basename(f)))

# Find NetCDF files
nc_files <- list.files(glob_nc_dir, "\\.nc$", full.names=TRUE)
cat("Found NetCDF files:", length(nc_files), "\n")

if(!length(nc_files)) {
  warning("No .nc files found in ", glob_nc_dir)
  return()
}

# Detect unique pollutants
unique_polls <- unique(sapply(nc_files, get_poll))
cat("Detected pollutants:", paste(unique_polls, collapse=", "), "\n")

# Process each pollutant
for(poll in unique_polls){
  POL <- toupper(poll)
  cat("\n============================\n")
  cat("Processing Pollutant:", POL, "\n")
  
  # 1) Extract 5D monthly GLOB data
  these_nc   <- nc_files[sapply(nc_files,get_poll)==poll]
  raw5d_file <- file.path(ant_out_dir, sprintf("GLOB_ANT_monthly_data_%s.rds",poll))
  
  cat("Extracting 5D GLOB data for", length(these_nc), "files\n")
  
  # Debug information
  cat("Files to process:\n")
  for(f in these_nc) {
    cat("  -", basename(f), "| Year:", get_year(f), "\n")
  }
  
  tryCatch({
    # Verify variables before function call
    if (!exists("boundary") || !exists("sector_names_GLOB")) {
      stop("Required variables 'boundary' or 'sector_names_GLOB' not found")
    }
    
    data5d <- build_5D_GLOB_from_files(
      netcdf_files      = these_nc,
      boundary          = boundary,
      sector_names_GLOB = sector_names_GLOB,
      output_file       = raw5d_file
    )
    
    cat("✓ 5D GLOB data extracted - dimensions:", paste(dim(data5d), collapse="x"), "\n")
    
  }, error = function(e) {
    cat("✗ Error extracting 5D GLOB data:", e$message, "\n")
    cat("✗ Debugging info:\n")
    cat("    - boundary exists:", exists("boundary"), "\n")
    cat("    - sector_names_GLOB exists:", exists("sector_names_GLOB"), "\n")
    cat("    - Number of NC files:", length(these_nc), "\n")
    return(NULL)
  })
  
  # Check if data5d extraction was successful
  if (!exists("data5d") || is.null(data5d)) {
    cat("⏭️ Skipping remaining steps for", POL, "due to extraction failure\n")
    next
  }
  
  # 2) Map GLOB sectors to GNFR sectors
  gnfr5d_file <- file.path(ant_out_dir, sprintf("GLOB_GNFR_ANT_monthly_data_%s.rds",poll))
  
  tryCatch({
    gnfr5d <- map_GLOB_to_GNFR(data5d)
    saveRDS(gnfr5d, gnfr5d_file)
    
    cat("✓ GLOB to GNFR mapping completed - dimensions:", paste(dim(gnfr5d), collapse="x"), "\n")
    
  }, error = function(e) {
    cat("✗ Error in GLOB to GNFR mapping:", e$message, "\n")
    return(NULL)
  })
  
  # Check if GNFR mapping was successful  
  if (!exists("gnfr5d") || is.null(gnfr5d)) {
    cat("⏭️ Skipping daily conversion for", POL, "due to GNFR mapping failure\n")
    next
  }
  
  # 3) Convert monthly to daily profiles
  tryCatch({
    # Save the GNFR 5D data temporarily for MonthlyToDaily function
    temp_monthly_rds <- file.path(ant_out_dir, sprintf("temp_GLOB_GNFR_monthly_%s.rds", poll))
    saveRDS(gnfr5d, temp_monthly_rds)
    
    # Create weekly profile from CSV and save as RDS
    weekly_profile <- CreateWeeklyProfile(weekly_csv, poll, tempo_base_dir)
    temp_weekly_rds <- file.path(tempo_base_dir, sprintf("weekly_profile_%s.rds", poll))
    saveRDS(weekly_profile, temp_weekly_rds)
    
    # Get the years from the data dimensions
    data_years <- as.integer(dimnames(gnfr5d)[[5]])
    
    MonthlyToDaily(
      monthly_rds    = temp_monthly_rds,
      weekly_rds     = temp_weekly_rds,
      lonlat_idx_rds = lonlat_idx_rds,
      pollutant      = poll,
      output_dir     = daily_out_base_dir,
      years          = data_years
    )
    
    # Clean up temporary files
    file.remove(temp_monthly_rds)
    file.remove(temp_weekly_rds)
    
    cat("✓ Monthly to daily conversion completed\n")
    
  }, error = function(e) {
    cat("✗ Error in monthly to daily conversion:", e$message, "\n")
  })
  
  # Clean up memory
  if (exists("data5d")) rm(data5d)
  if (exists("gnfr5d")) rm(gnfr5d)
  gc()
  
  cat("Completed processing for", POL, "\n")
}

# Phase completion summary
end_time_phase8 <- Sys.time()
phase8_duration <- difftime(end_time_phase8, start_time_phase8, units = "secs")

cat("\n==> PHASE 8 COMPLETED\n")
cat("==> Processing time:", round(phase8_duration, 2), "seconds\n")
cat("==> GLOB-ANT data processed for", length(unique_polls), "pollutants\n")
cat("==> Output directories:\n")
cat("    - Monthly GLOB data:", ant_out_dir, "\n")
cat("    - Daily GLOB data:", daily_out_base_dir, "\n\n")
