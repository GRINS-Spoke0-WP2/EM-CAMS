###############################################################################
# EM-CAMS v.3.0.0 - Phase 3: Simplified CAMS-REG-TEMPO Profile Extraction
###############################################################################
# Description: Extract simplified temporal profiles from CSV-based TEMPO data
#              for climatological monthly and weekly factors
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
###############################################################################

# Start phase timer
start_time_phase3 <- Sys.time()
cat("Starting Phase 3: Simplified CAMS-REG-TEMPO Profile Extraction\n")

# Load required extraction utilities
source("scripts/extraction/ExtractTEMPO/ProfilesCreation.R")

# Load extraction utilities (assuming function is available in Utils.R)
# Note: SimpleProfilesCreation function should be available

# Define input CSV file paths for simplified TEMPO data
path_monthly_simplified <- "data/raw/CAMS-REG-TEMPO-SIMPLIFIED/CAMS_TEMPO_v4_1_simplified_Monthly_Factors_climatology.csv"
path_weekly_simplified <- "data/raw/CAMS-REG-TEMPO-SIMPLIFIED/CAMS_TEMPO_v4_1_simplified_Weekly_Factors.csv"

# Combine paths for processing
simplified_profile_csv_paths <- c(path_monthly_simplified, path_weekly_simplified)

# Verify input files exist
missing_files <- simplified_profile_csv_paths[!file.exists(simplified_profile_csv_paths)]
if (length(missing_files) > 0) {
  warning("Missing input files:")
  for (file in missing_files) {
    cat("  -", file, "\n")
  }
  stop("Cannot proceed without required input files")
}

# Define pollutants for simplified profile extraction
# Use configured pollutants and time range from Main.R
if (!exists("pollutant_names")) {
  pollutant_names <- pollutant_names_default
}
if (!exists("start_year_global")) {
  start_year_global <- start_year_default
  end_year_global <- end_year_default
}

# Extract ALL available pollutants from CSV (no filtering based on selection)
# This avoids naming inconsistencies between our config (nox, pm2_5, so2) 
# and CSV format (NOx, PM2.5, SOx)
available_pollutants_csv <- c("CO", "NH3", "NMVOC", "NOx", "PM10", "PM2.5", "SOx")

cat("📋 Phase 3 Configuration:\n")
cat("   • Processing ALL available pollutants:", paste(available_pollutants_csv, collapse=", "), "\n")
cat("   • Time range:", start_year_global, "-", end_year_global, "\n")
cat("   • (This ensures all profiles are available regardless of current pollutant selection)\n\n")

# Process simplified profiles for each pollutant
cat("Processing simplified profiles for", length(available_pollutants_csv), "pollutants\n")
cat("Year range:", start_year_global, "-", end_year_global, "\n")

for (pollutant in available_pollutants_csv) {
  cat("Processing simplified profiles for:", pollutant, "\n")
  
  # Extract simplified profiles for current pollutant
  # This function creates both monthly and weekly simplified profiles
  tryCatch({
    SimpleProfilesCreation(
      files_path = simplified_profile_csv_paths,
      poll = pollutant,
      start_year = start_year_global,
      end_year = end_year_global
    )
    cat("✅ Successfully created profiles for:", pollutant, "\n")
  }, error = function(e) {
    cat("❌ Error creating profiles for", pollutant, ":", e$message, "\n")
  })
  
  # Verify output directory structure
  output_base <- "data/processed/TEMPO_data/DailySimplifiedProfiles"
  pollutant_dir <- file.path(output_base, pollutant)
  
  if (dir.exists(pollutant_dir)) {
    monthly_dir <- file.path(pollutant_dir, "MonthlyProfiles")
    weekly_dir <- file.path(pollutant_dir, "WeeklyProfiles")
    
    monthly_files <- length(list.files(monthly_dir, pattern = "\\.rds$", recursive = TRUE))
    weekly_files <- length(list.files(weekly_dir, pattern = "\\.rds$", recursive = TRUE))
    
    cat("Created profiles for", pollutant, ":", monthly_files, "monthly,", weekly_files, "weekly\n")
  }
}

# Verify all expected output directories were created
cat("\nVerifying output structure:\n")
expected_output_base <- "data/processed/TEMPO_data/DailySimplifiedProfiles"

for (pollutant in available_pollutants_csv) {
  pollutant_dir <- file.path(expected_output_base, pollutant)
  if (dir.exists(pollutant_dir)) {
    cat("✓ Output directory created for", pollutant, "\n")
  } else {
    cat("✗ Missing output directory for", pollutant, "\n")
  }
}

# Phase completion summary
end_time_phase3 <- Sys.time()
phase3_duration <- difftime(end_time_phase3, start_time_phase3, units = "secs")

cat("\n==> PHASE 3 COMPLETED\n")
cat("==> Processing time:", round(phase3_duration, 2), "seconds\n")
cat("==> Simplified profiles created for:", length(available_pollutants_csv), "pollutants\n")
cat("==> Output base directory:", expected_output_base, "\n\n")
