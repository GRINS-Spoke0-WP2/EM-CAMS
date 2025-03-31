###############################################################################
## MAIN SCRIPT: main.R
## Version: 2.0.0
## This script is organized in multiple PHASES, each timed for benchmark purposes.
## No lines of your original code are removed, only reorganized.
###############################################################################


###############################################################################
## PHASE 1: CONFIGURATION, SETUP STRUCTURE, AND NEW CAMS-REG-ANT YEARLY DATA EXTRACTION
###############################################################################
start_time_phase1 <- Sys.time()

# 1. CONFIGURATION
source("Config.R")
source("Utils.R")

# 2. SETUP STRUCTURE
source("setup_structure.R")

# 3. NEW CAMS-REG-ANT YEARLY DATA EXTRACTION
source("ExtractANT/ExtractANT.R")

# Directory containing NetCDF files
nc_directory <- "Data/Raw/CAMS-REG-ANT/"

# List of pollutants
pollutant_names <- c("nh3", "ch4", "co", "co2_bf", "co2_ff", 
                     "nmvoc", "nox", "pm2_5", "pm10", "so2")

# Load the lon_lat_idx file
lon_lat_idx <- readRDS("Data/Processed/lon_lat_idx.rds")

# Loop over each pollutant (SERIAL for now)
for (pollutant_name in pollutant_names) {
  
  # Search for NetCDF files for this pollutant
  nc_file_paths <- list.files(nc_directory, pattern = paste0(pollutant_name, "_v"), full.names = TRUE)
  
  # Sort the file paths by version (optional)
  nc_file_paths <- nc_file_paths[order(as.numeric(gsub(".*_v([0-9.]+)_.*", "\\1", nc_file_paths)))]
  
  # Initialize a list to store data from all years
  all_data_list <- list()
  
  # For each NetCDF, update the list of years
  for (nc_file_path in nc_file_paths) {
    all_data_list <- add_new_years_data_updated(nc_file_path, all_data_list)
  }
  
  # Extract only the "data" part (not the version info)
  all_data_list_final <- lapply(all_data_list, function(x) x$data)
  
  # Build the 4D matrix
  all_data_matrix <- build_yearly_matrix(all_data_list_final, lon_lat_idx)
  
  # Save path for the RDS
  save_path <- paste0("Data/Processed/ANT_data/REG_ANT_yearly_data_", pollutant_name, ".rds")
  saveRDS(all_data_matrix, file = save_path)
  
  # Clean up
  rm(all_data_matrix, all_data_list, all_data_list_final)
  gc()
}

cat("All RDS files have been saved with the specified pollutant names.\n")

end_time_phase1 <- Sys.time()
cat("==> PHASE 1 completed in:", round(difftime(end_time_phase1, start_time_phase1, units="secs"), 2), "seconds.\n\n")


###############################################################################
## PHASE 2: CAMS-REG-TEMPO PROFILES EXTRACTION
###############################################################################
start_time_phase2 <- Sys.time()

source("ExtractTEMPO/ExtractTEMPO.R")

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

source("Computation/DailyPRF_fromFMFW.R")

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

pollutant_name <- "pm2.5"
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
pollutants_simpl_phase6 <- c("NH3", "PM2.5", "PM10", "NOx", "NMVOC", "SOx", "CO")

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
## PHASE 7: STACK DAILY DATA ALONG YEARS (PARALLEL) AND SUM ALL SECTORS
###############################################################################
start_time_phase7 <- Sys.time()

library(foreach)
library(doParallel)


# Detect total cores but use only half to reduce heat/CPU load
all_cores <- parallel::detectCores()
n_cores   <- max(1, floor(all_cores / 2))
cat("Using", n_cores, "out of", all_cores, "available cores to reduce stress.\n")

cl <- makeCluster(n_cores)
registerDoParallel(cl)

clusterEvalQ(cl, {
  source("Config.R")
  source("Utils.R")
  source("Computation/ComputeFinal.R")  # For StackDailyData / SumAllSectorsIntoOne
})

# We set the folder and years
input_folder <- "Data/Processed/DAILY_data"
start_year   <- 2000
end_year     <- 2022

# Sectors and pollutants
sectors      <- LETTERS[1:12]
polls_stack  <- c("PM10", "PM2.5", "NOx", "NH3", "SOx", "CO", "NMVOC")

# A) Parallel stacking of daily data for all (sector, pollutant)
foreach(sector = sectors) %:%
  foreach(pollutant = polls_stack, .packages = c("base")) %dopar% {
    StackDailyData(input_folder, sector, pollutant, start_year, end_year)
  }

cat("==> PHASE 7A: Stacking of daily data for all sectors/pollutants completed.\n")

# B) Summation of all sectors for each pollutant
input_folder_IEDD <- "Data/Processed/DAILY_data/IEDD_output"
foreach(poll = polls_stack, .packages = c("base")) %dopar% {
  output_file <- file.path(input_folder_IEDD, 
                           paste0("Daily_sum_", start_year, "_", end_year, "_", poll, ".rds"))
  SumAllSectorsIntoOne(input_folder_IEDD, output_file, poll, start_year, end_year)
  cat(paste("✔️ Summed all sectors for:", poll, "\n"))
}

stopCluster(cl)

cat("==> PHASE 7B: Summation of daily data across all sectors completed.\n")

end_time_phase7 <- Sys.time()
cat("==> PHASE 7 completed in:", 
    round(difftime(end_time_phase7, start_time_phase7, units = "secs"), 2), "seconds.\n\n")


###############################################################################
## FINAL STATUS
###############################################################################
cat("All steps completed successfully.\n")
cat("Data are ready in 'Data/Processed/DAILY_data/DailyAlongYears' for the stacked data, 
     and 'Data/Processed/DAILY_data/IEDD_output' for the sector-summed data.\n")

cat("==> End of main.R script.\n")
