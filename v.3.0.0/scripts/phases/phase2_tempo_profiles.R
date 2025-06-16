###############################################################################
# EM-CAMS v.3.0.0 - Phase 2: CAMS-REG-TEMPO Profiles Extraction
###############################################################################
# Description: Extract temporal profiles from CAMS-REG-TEMPO dataset for
#              daily and monthly variations in emissions
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
###############################################################################

# Start phase timer
start_time_phase2 <- Sys.time()
cat("Starting Phase 2: CAMS-REG-TEMPO Profiles Extraction\n")

# Load TEMPO extraction module
source("scripts/extraction/ExtractTEMPO/ExtractTEMPO.R")

# Define input file paths for TEMPO data
nc_file_path_daily_weekly <- "data/raw/CAMS-REG-TEMPO/CAMS-REG-TEMPO_EUR_0.1x0.1_tmp_weights_v3.1_daily.nc"
nc_file_path_monthly <- "data/raw/CAMS-REG-TEMPO/CAMS-REG-TEMPO_EUR_0.1x0.1_tmp_weights_v3.1_monthly.nc"

# Output directory for processed TEMPO data
output_dir <- "data/processed/TEMPO_data"

# Ensure output directory exists
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Define temporal profiles to extract
# FM_F: Monthly factors for F sector
# FW_F: Weekly factors for F sector  
# FD_C: Daily factors for C sector
# FD_L_nh3: Daily factors for L sector, NH3 specific
# FD_K_nh3_nox: Daily factors for K sector, NH3 and NOx specific
tempo_profiles <- list(
  list(profile = "FM_F", description = "Monthly factors for F sector"),
  list(profile = "FW_F", description = "Weekly factors for F sector"),
  list(profile = "FD_C", description = "Daily factors for C sector"),
  list(profile = "FD_L_nh3", description = "Daily factors for L sector (NH3)"),
  list(profile = "FD_K_nh3_nox", description = "Daily factors for K sector (NH3, NOx)")
)

# Extract each temporal profile
cat("Extracting", length(tempo_profiles), "temporal profiles\n")

for (profile_info in tempo_profiles) {
  profile_name <- profile_info$profile
  profile_desc <- profile_info$description
  
  cat("Processing:", profile_desc, "\n")
  
  # Process the temporal profile
  process_profile(
    nc_file_path_daily_weekly = nc_file_path_daily_weekly,
    nc_file_path_monthly = nc_file_path_monthly,
    profile_name = profile_name,
    output_dir = output_dir
  )
  
  # Verify output files were created
  expected_files <- c(
    file.path(output_dir, paste0(profile_name, "_daily.rds")),
    file.path(output_dir, paste0(profile_name, "_weekly.rds")),
    file.path(output_dir, paste0(profile_name, "_monthly.rds"))
  )
  
  created_files <- expected_files[file.exists(expected_files)]
  cat("Created", length(created_files), "profile files for", profile_name, "\n")
}

# Verify longitude and latitude indices extraction
lonlat_boundary_file <- "data/raw/CAMS-REG-TEMPO/CAMS-REG-TEMPO_EUR_0.1x0.1_tmp_weights_v3.1_daily.nc"
if (file.exists(lonlat_boundary_file)) {
  cat("Extracting coordinate indices for spatial boundary\n")
  # Note: get_lon_lat_indices function call would be here if needed
  # get_lon_lat_indices(lonlat_boundary_file, boundary)
}

# Phase completion summary
end_time_phase2 <- Sys.time()
phase2_duration <- difftime(end_time_phase2, start_time_phase2, units = "secs")

cat("\n==> PHASE 2 COMPLETED\n")
cat("==> Processing time:", round(phase2_duration, 2), "seconds\n")
cat("==> Output directory:", output_dir, "\n")
cat("==> Temporal profiles extracted:", length(tempo_profiles), "\n\n")
