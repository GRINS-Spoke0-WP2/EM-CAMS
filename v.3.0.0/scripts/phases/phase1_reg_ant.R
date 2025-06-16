###############################################################################
# EM-CAMS v.3.0.0 - Phase 1: CAMS-REG-ANT Yearly Data Extraction
###############################################################################
# Description: Extract and process yearly anthropogenic emission data from
#              CAMS-REG-ANT dataset for specified pollutants and regions
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
###############################################################################

# Start phase timer
start_time_phase1 <- Sys.time()
cat("Starting Phase 1: CAMS-REG-ANT Yearly Data Extraction\n")

# Load required extraction modules
source("scripts/extraction/ExtractANT/ExtractANT.R")

# Use configured pollutants and time range from Main.R
# If not defined, use defaults from Config.R
if (!exists("pollutant_names")) {
  pollutant_names <- pollutant_names_default
}
if (!exists("start_year_global")) {
  start_year_global <- start_year_default
  end_year_global <- end_year_default
}

# Filter to only REG-ANT available pollutants
# REG-ANT available pollutants: CO, NOx, NH3, NMVOC, PM10, PM2.5, SOx, CH4, CO2_ff, CO2_bf
reg_ant_available <- c("co", "nox", "nh3", "nmvoc", "pm10", "pm2_5", "so2", "ch4", "co2_ff", "co2_bf")
pollutants_reg_ant <- intersect(pollutant_names, reg_ant_available)

if (length(pollutants_reg_ant) == 0) {
  cat("⚠️  No REG-ANT compatible pollutants selected. Available:", paste(reg_ant_available, collapse=", "), "\n")
  return()
}

cat("📋 Phase 1 Configuration:\n")
cat("   • Selected pollutants:", paste(toupper(pollutants_reg_ant), collapse=", "), "\n")
cat("   • Time range:", start_year_global, "-", end_year_global, "\n\n")

# Input and output paths  
nc_directory <- "data/raw/CAMS-REG-ANT/"
output_base_dir <- "data/processed/ANT_data"

# Ensure output directory exists
dir.create(output_base_dir, recursive = TRUE, showWarnings = FALSE)

# Load coordinate index data
lon_lat_idx <- readRDS("data/processed/lon_lat_idx.rds")

# Extract yearly data for each pollutant
cat("Processing", length(pollutants_reg_ant), "pollutants\n")

for (pollutant_name in pollutants_reg_ant) {
  cat("Processing pollutant:", toupper(pollutant_name), "\n")
  
  # Find all NetCDF files for this pollutant
  nc_file_paths <- list.files(nc_directory, pattern = paste0(pollutant_name, "_v"), full.names = TRUE)
  nc_file_paths <- nc_file_paths[order(as.numeric(gsub(".*_v([0-9.]+)_.*", "\\1", nc_file_paths)))]
  
  # Process all years for this pollutant
  all_data_list <- list()
  for (nc_file_path in nc_file_paths) {
    all_data_list <- add_new_years_data_updated(nc_file_path, all_data_list)
  }
  
  # Build final yearly matrix
  all_data_list_final <- lapply(all_data_list, function(x) x$data)
  all_data_matrix <- build_yearly_matrix(all_data_list_final, lon_lat_idx)
  
  # Save processed data
  save_path <- paste0(output_base_dir, "/REG_ANT_yearly_data_", pollutant_name, ".rds")
  saveRDS(all_data_matrix, file = save_path)
  
  # Clean up memory
  rm(all_data_matrix, all_data_list, all_data_list_final)
  gc()
  
  cat("Successfully created:", basename(save_path), "\n")
}

cat("All REG RDS files saved.\n")

# Phase completion summary
end_time_phase1 <- Sys.time()
phase1_duration <- difftime(end_time_phase1, start_time_phase1, units = "secs")

cat("\n==> PHASE 1 COMPLETED\n")
cat("==> Extraction time:", round(phase1_duration, 2), "seconds\n")
cat("==> Output directory:", output_base_dir, "\n")
cat("==> Files created:", length(pollutants_reg_ant), "yearly data files\n\n")
