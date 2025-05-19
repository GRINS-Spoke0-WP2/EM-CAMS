###############################################################################
## MAIN SCRIPT: main.R
## Version: 2.0.0
## This script is organized in multiple PHASES, each timed for benchmark purposes.
## No lines of your original code are removed, only reorganized.
###############################################################################
# 1. CONFIGURATION & SETUP
source("Config.R")
source("Utils.R")
###############################################################################
## PHASE 1: CONFIGURATION, SETUP STRUCTURE, AND CAMS-REG-ANT YEARLY DATA EXTRACTION
###############################################################################
start_time_phase1 <- Sys.time()

# Get lon/lat indices for REG (this is your existing routine)
get_lon_lat_indices("Data/Raw/CAMS-REG-ANT/CAMS-REG-ANT_EUR_0.05x0.1_anthro_nox_v8.0_yearly.nc", boundary)

# 2. SETUP STRUCTURE
source("setup_structure.R")

# 3. NEW CAMS-REG-ANT YEARLY DATA EXTRACTION
source("ExtractANT/ExtractANT.R")

nc_directory <- "Data/Raw/CAMS-REG-ANT/"
pollutant_names <- c("nh3", "ch4", "co", "co2_bf", "co2_ff", "nmvoc", "nox", "pm2_5", "pm10", "so2")
lon_lat_idx <- readRDS("Data/Processed/lon_lat_idx.rds")

for (pollutant_name in pollutant_names) {
  nc_file_paths <- list.files(nc_directory, pattern = paste0(pollutant_name, "_v"), full.names = TRUE)
  nc_file_paths <- nc_file_paths[order(as.numeric(gsub(".*_v([0-9.]+)_.*", "\\1", nc_file_paths)))]
  all_data_list <- list()
  for (nc_file_path in nc_file_paths) {
    all_data_list <- add_new_years_data_updated(nc_file_path, all_data_list)
  }
  all_data_list_final <- lapply(all_data_list, function(x) x$data)
  all_data_matrix <- build_yearly_matrix(all_data_list_final, lon_lat_idx)
  save_path <- paste0("Data/Processed/ANT_data/REG_ANT_yearly_data_", pollutant_name, ".rds")
  saveRDS(all_data_matrix, file = save_path)
  rm(all_data_matrix, all_data_list, all_data_list_final)
  gc()
}

cat("All REG RDS files saved.\n")
end_time_phase1 <- Sys.time()
cat("==> PHASE 1 completed in:", round(difftime(end_time_phase1, start_time_phase1, units="secs"), 2), "seconds.\n\n")

#!/usr/bin/env Rscript
###############################################################################
## PHASE 2: CAMS-GLOB-ANT → GNFR-monthly → GNFR-daily (SUPER DEBUG)
###############################################################################
start_time <- Sys.time()
library(ncdf4); library(abind); library(lubridate)

# Carica sorgenti
source("ExtractANT/ExtractGLOB.R")    # build_5D_GLOB_from_files()
source("MapGLOBtoGNFR.R")             # map_GLOB_to_GNFR()
source("GLOB_MonthlyToDaily.R")       # CreateWeeklyProfile(), MonthlyToDaily()

# Parametri
glob_nc_dir        <- "Data/Raw/CAMS-GLOB-ANT"
ant_out_dir        <- "Data/Processed/ANT_data"
lonlat_idx_rds     <- "Data/Processed/lon_lat_idx_GLOB.rds"
weekly_csv         <- "Data/Raw/CAMS-REG-TEMPO-SIMPLIFIED/CAMS_TEMPO_v4_1_simplified_Weekly_Factors.csv"
tempo_base_dir     <- "Data/Processed/TEMPO_data"
daily_out_base_dir <- "Data/Processed/DAILY_data/DailyFromGLOB"

# Helper anno/file
get_year <- function(f) as.integer(sub(".*_(\\d{4})\\.nc$", "\\1", basename(f)))
get_poll <- function(f) tolower(sub(".*anthro_([^_]+)_.*","\\1",basename(f)))

nc_files <- list.files(glob_nc_dir, "\\.nc$", full.names=TRUE)
cat("DEBUG: Found NetCDF files:\n"); print(nc_files); cat("\n")
if(!length(nc_files)) stop("No .nc in ", glob_nc_dir)

unique_polls <- unique(sapply(nc_files, get_poll))
cat("DEBUG: Detected pollutants:", unique_polls, "\n\n")

for(poll in unique_polls){
  POL <- toupper(poll)
  cat("\n============================\n")
  cat("START Pollutant:", POL, "\n")
  
  # 1) Estrarre 5D monthly GLOB
  these_nc   <- nc_files[sapply(nc_files,get_poll)==poll]
  raw5d_file <- file.path(ant_out_dir, sprintf("GLOB_ANT_monthly_data_%s.rds",poll))
  cat("DEBUG: these_nc:\n"); print(these_nc)
  cat("DEBUG: raw5d_file =", raw5d_file, "\n")
  data5d <- build_5D_GLOB_from_files(
    netcdf_files      = these_nc,
    boundary          = boundary,
    sector_names_GLOB = sector_names_GLOB,
    output_file       = raw5d_file
  )
  cat("DEBUG: data5d dim ="); print(dim(data5d))
  cat("DEBUG: data5d dimnames lon,lat,sector,month,year:\n")
  print(lapply(dimnames(data5d), function(x) head(x,3)))
  cat("\n")
  
  # 2) Map GLOB→GNFR
  gnfr5d_file <- file.path(ant_out_dir, sprintf("GLOB_GNFR_ANT_monthly_data_%s.rds",poll))
  cat("DEBUG: gnfr5d_file =", gnfr5d_file, "\n")
  gnfr5d <- map_GLOB_to_GNFR(data5d)
  cat("DEBUG: gnfr5d dim ="); print(dim(gnfr5d))
  cat("DEBUG: gnfr5d dimnames head:\n")
  print(lapply(dimnames(gnfr5d), function(x) head(x,3)))
  saveRDS(gnfr5d, gnfr5d_file)
  cat("DEBUG: after saveRDS(gnfr5d): exists? ", file.exists(gnfr5d_file), "\n\n")
  
  # 3) Monthly→Daily GNFR
  cat("DEBUG: Preparing MonthlyToDaily for", POL, "\n")
  weekly_dir <- file.path(tempo_base_dir,"DailySimplifiedProfiles",POL,"WeeklyProfiles")
  weekly_rds <- file.path(weekly_dir,paste0("S_W_simplified_",POL,".rds"))
  cat("DEBUG: weekly_rds =", weekly_rds, "\n")
  if(!file.exists(weekly_rds)){
    cat("DEBUG: Creating weekly profile...\n")
    CreateWeeklyProfile(weekly_csv,poll,weekly_dir)
  }
  out_daily <- file.path(daily_out_base_dir,poll)
  years_avail <- sort(unique(get_year(these_nc)))
  cat("DEBUG: years_avail =", years_avail, "\n")
  
  MonthlyToDaily(
    monthly_rds    = gnfr5d_file,
    weekly_rds     = weekly_rds,
    lonlat_idx_rds = lonlat_idx_rds,
    pollutant      = POL,
    output_dir     = out_daily,
    years          = years_avail
  )
  
  # verifica cartella
  cat("DEBUG: Listing out_daily:\n")
  print(list.files(out_daily, recursive=TRUE))
  cat("Completed pollutant:", POL, "\n")
}

cat("\n==> All done in", round(difftime(Sys.time(), start_time, units="secs"),2), "sec.\n")

###############################################################################
## PHASE 2: CAMS-REG-TEMPO PROFILES EXTRACTION
###############################################################################
start_time_phase2 <- Sys.time()

source("ExtractTEMPO/ExtractTEMPO.R")
#get lon,lat indices 
#get_lon_lat_indices("Data/Raw/CAMS-REG-TEMPO/CAMS-REG-TEMPO_EUR_0.1x0.1_tmp_weights_v3.1_daily.nc",boundary)

# Define paths
nc_file_path_daily_weekly <- "Data/Raw/CAMS-REG-TEMPO/CAMS-REG-TEMPO_EUR_0.1x0.1_tmp_weights_v3.1_daily.nc"
nc_file_path_monthly      <- "Data/Raw/CAMS-REG-TEMPO/CAMS-REG-TEMPO_EUR_0.1x0.1_tmp_weights_v3.1_monthly.nc"
output_dir                <- "Data/Processed/TEMPO_data"

# Process Profiles
process_profile(nc_file_path_daily_weekly, nc_file_path_monthly, "FM_F",       output_dir)
process_profile(nc_file_path_daily_weekly, nc_file_path_monthly, "FW_F",       output_dir)
#process_profile(nc_file_path_daily_weekly, nc_file_path_monthly, "FW_H",     output_dir)
process_profile(nc_file_path_daily_weekly, nc_file_path_monthly, "FD_C",       output_dir)
process_profile(nc_file_path_daily_weekly, nc_file_path_monthly, "FD_L_nh3",   output_dir)
process_profile(nc_file_path_daily_weekly, nc_file_path_monthly, "FD_K_nh3_nox", output_dir)
#process_profile(nc_file_path_daily_weekly, nc_file_path_monthly, "FM_B", NULL, output_dir)
#process_profile(nc_file_path_daily_weekly, nc_file_path_monthly, "FW_B", NULL, output_dir)

end_time_phase2 <- Sys.time()
cat("==> PHASE 2 (CAMS-REG-TEMPO Profiles Extraction) completed in:", 
    round(difftime(end_time_phase2, start_time_phase2, units="secs"), 2), "seconds.\n\n")


###############################################################################
## PHASE 3: SIMPLIFIED-CAMS-REG-TEMPO PROFILE EXTRACTION (CSV-based)
###############################################################################
start_time_phase3 <- Sys.time()

# Extract data from CSV files
Path_MonthlySimplified <- "Data/Raw/CAMS-REG-TEMPO-SIMPLIFIED/CAMS_TEMPO_v4_1_simplified_Monthly_Factors_climatology.csv"
Path_WeeklySimplified  <- "Data/Raw/CAMS-REG-TEMPO-SIMPLIFIED/CAMS_TEMPO_v4_1_simplified_Weekly_Factors.csv"

Path_simplifiedProfilesCSV <- c(Path_MonthlySimplified, Path_WeeklySimplified)

pollutants_simplified <- c("CO", "NH3", "NMVOC", "NOx", "PM10", "PM2.5", "SOx")

for (poll in pollutants_simplified) {
  SimpleProfilesCreation(Path_simplifiedProfilesCSV, poll, 2000, 2022)
}

end_time_phase3 <- Sys.time()
cat("==> PHASE 3 (Simplified-CAMS-REG-TEMPO CSV extraction) completed in:",
    round(difftime(end_time_phase3, start_time_phase3, units="secs"), 2), "seconds.\n\n")


###############################################################################
## PHASE 4: CAMS-REG-TEMPO DAILY PROFILE CREATION using FM & FW
###############################################################################
start_time_phase4 <- Sys.time()

source("Computation/ComputeFinal.R")

FM_profile <- readRDS("Data/Processed/TEMPO_data/FM_F_monthly.rds")
FW_profile <- readRDS("Data/Processed/TEMPO_data/FW_F_weekly.rds")

DailyPRF_fromFMFW(FM_profile, FW_profile, "F")

end_time_phase4 <- Sys.time()
cat("==> PHASE 4 (Daily profiles from FM & FW) completed in:",
    round(difftime(end_time_phase4, start_time_phase4, units="secs"), 2), "seconds.\n\n")


###############################################################################
## PHASE 5: COMPUTE DAILY DATA WITH FD PROFILES
###############################################################################
start_time_phase5 <- Sys.time()

source("Computation/ComputeNormalDaily.R")
source("Computation/ComputeFinal.R")

# Example usage
temporal_profile_folder <- "Data/Processed/TEMPO_data"
output_folder           <- "Data/Processed/DAILY_data"

pollutant_name <- "nh3"
sector         <- "F"
yearly_data_file <- "Data/Processed/ANT_data/REG_ANT_yearly_data_nh3.rds"
calculate_from_FD(pollutant_name, yearly_data_file, temporal_profile_folder, output_folder, sector)

pollutant_name <- "nox"
sector         <- "F"
yearly_data_file <- "Data/Processed/ANT_data/REG_ANT_yearly_data_nox.rds"
calculate_from_FD(pollutant_name, yearly_data_file, temporal_profile_folder, output_folder, sector)

pollutant_name <- "so2"
sector         <- "F"
yearly_data_file <- "Data/Processed/ANT_data/REG_ANT_yearly_data_so2.rds"
calculate_from_FD(pollutant_name, yearly_data_file, temporal_profile_folder, output_folder, sector)

pollutant_name <- "pm10"
sector         <- "F"
yearly_data_file <- "Data/Processed/ANT_data/REG_ANT_yearly_data_pm10.rds"
calculate_from_FD(pollutant_name, yearly_data_file, temporal_profile_folder, output_folder, sector)

pollutant_name <- "pm2_5"
sector         <- "F"
yearly_data_file <- "Data/Processed/ANT_data/REG_ANT_yearly_data_pm2_5.rds"
calculate_from_FD(pollutant_name, yearly_data_file, temporal_profile_folder, output_folder, sector)

pollutant_name <- "nmvoc"
sector         <- "F"
yearly_data_file <- "Data/Processed/ANT_data/REG_ANT_yearly_data_nmvoc.rds"
calculate_from_FD(pollutant_name, yearly_data_file, temporal_profile_folder, output_folder, sector)

pollutant_name <- "co"
sector         <- "F"
yearly_data_file <- "Data/Processed/ANT_data/REG_ANT_yearly_data_co.rds"
calculate_from_FD(pollutant_name, yearly_data_file, temporal_profile_folder, output_folder, sector)

pollutant_name <- "ch4"
sector         <- "F"
yearly_data_file <- "Data/Processed/ANT_data/REG_ANT_yearly_data_ch4.rds"
calculate_from_FD(pollutant_name, yearly_data_file, temporal_profile_folder, output_folder, sector)

pollutant_name <- "co2_ff"
sector         <- "F"
yearly_data_file <- "Data/Processed/ANT_data/REG_ANT_yearly_data_co2_ff.rds"
calculate_from_FD(pollutant_name, yearly_data_file, temporal_profile_folder, output_folder, sector)

pollutant_name <- "co2_bf"
sector         <- "F"
yearly_data_file <- "Data/Processed/ANT_data/REG_ANT_yearly_data_co2_bf.rds"
calculate_from_FD(pollutant_name, yearly_data_file, temporal_profile_folder, output_folder, sector)

end_time_phase5 <- Sys.time()
cat("==> PHASE 5 (Compute daily data with FD) completed in:",
    round(difftime(end_time_phase5, start_time_phase5, units="secs"), 2), "seconds.\n\n")


###############################################################################
## PHASE 6: COMPUTE DAILY DATA WITH SIMPLIFIED PROFILES (IN PARALLEL)
###############################################################################
start_time_phase6 <- Sys.time()

library(foreach)
library(doParallel)

# Setup parallel
n_cores <- parallel::detectCores()
cl <- makeCluster(n_cores)
registerDoParallel(cl)

clusterEvalQ(cl, {
  source("Config.R")
  source("Utils.R")
  source("Computation/ComputeSimplifiedDaily.R")
})

# Define the range of years and the pollutants you want to process
start_year_simpl <- 2000
end_year_simpl   <- 2022

# Pollutants for simplified profiles
pollutants_simpl_phase6 <- c("NOx")

# Map each pollutant name to the corresponding RDS file suffix
pollutant_file_map <- list(
  "NH3"   = "nh3",
  "PM10"  = "pm10",
  "PM2.5" = "pm2_5",
  "NOx"   = "nox",
  "NMVOC" = "nmvoc",
  "SOx"   = "so2",
  "CO"    = "co"
)

# Parallel loop to process each pollutant's data
foreach(poll = pollutants_simpl_phase6, .packages = c("base")) %dopar% {
  file_name <- paste0("Data/Processed/ANT_data/REG_ANT_yearly_data_", 
                      pollutant_file_map[[poll]], ".rds")
  yearly_data <- readRDS(file_name)
  DailyDataFromSimplified(yearly_data, start_year_simpl, end_year_simpl, poll)
  cat(paste("✔️ Done simplified daily data for:", poll, "\n"))
}

stopCluster(cl)
cat("==> Phase 6: Daily data computed for all pollutants (simplified profiles).\n")

end_time_phase6 <- Sys.time()
cat("==> PHASE 6 (Compute daily data with Simplified) completed in:",
    round(difftime(end_time_phase6, start_time_phase6, units="secs"), 2), "seconds.\n\n")

###############################################################################
## PHASE 7: STACK DAILY DATA ALONG YEARS (SEQUENTIALLY) AND SUM ALL SECTORS
###############################################################################
start_time_phase7 <- Sys.time()

# Source your configuration and utility scripts
source("Config.R")
source("Utils.R")
source("Computation/ComputeFinal.R")  # Contiene StackDailyData e SumAllSectorsIntoOne

# Impostazioni generali
input_folder   <- "Data/Processed/DAILY_data"
start_year     <- 2000
end_year       <- 2022

# Settori e inquinanti da processare
sectors     <- LETTERS[1:12]
polls_stack <- c("NOx")

###############################################################################
# A) Stack daily data per ogni (sector, pollutant)
###############################################################################
for (sector in sectors) {
  for (pollutant in polls_stack) {
    StackDailyData(
      input_folder = input_folder,
      sector       = sector,
      pollutant    = pollutant,
      start_year   = start_year,
      end_year     = end_year
    )
  }
}
cat("==> PHASE 7A: Stacking of daily data for all sectors/pollutants completed.\n\n")

###############################################################################
# B) Somma di tutti i settori anno per anno in EM_sum
###############################################################################
stacked_folder  <- file.path(input_folder, "DailyAlongYears")
out_folder_EM   <- file.path(input_folder, "EM_sum")
dir.create(out_folder_EM, recursive = TRUE, showWarnings = FALSE)

for (poll in polls_stack) {
  message("Summing all sectors for pollutant: ", poll)
  SumAllSectorsIntoOne(
    input_folder  = stacked_folder,   # leggi i file impilati
    pollutant     = poll,
    start_year    = start_year,
    end_year      = end_year,
    output_folder = out_folder_EM     # qui i file per anno
  )
  message("✔️  Saved summed data for ", poll, " in ", out_folder_EM, "\n")
}

cat("==> PHASE 7B: Summation of daily data across all sectors completed.\n")
cat("I file aggregati per anno sono in: ", out_folder_EM, "\n\n")

###############################################################################
# Final status
###############################################################################
end_time_phase7 <- Sys.time()
cat("==> PHASE 7 completed in:",
    round(difftime(end_time_phase7, start_time_phase7, units = "secs"), 2),
    "seconds.\n\n")
cat("All steps completed successfully.\n",
    "Data are in:\n",
    " - 'Data/Processed/DAILY_data/DailyAlongYears' (per-sector)\n",
    " - 'Data/Processed/DAILY_data/EM_sum' (sector-summed per anno)\n\n")
cat("==> End of main.R script.\n")
