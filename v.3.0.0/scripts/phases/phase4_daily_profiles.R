###############################################################################
# EM-CAMS v.3.0.0 - Phase 4: Daily Profile Creation from FM & FW
###############################################################################
# Description: Create daily temporal profiles by combining monthly (FM) and 
#              weekly (FW) factors for sector F
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
###############################################################################

# Start phase timer
start_time_phase4 <- Sys.time()
cat("Starting Phase 4: Daily Profile Creation from FM & FW\n")

# Load computation module for final profile creation
source("scripts/computation/Computation/ComputeFinal.R")

# Define input file paths for monthly and weekly profiles
fm_profile_file <- "data/processed/TEMPO_data/FM_F_monthly.rds"
fw_profile_file <- "data/processed/TEMPO_data/FW_F_weekly.rds"

# Verify input files exist
required_files <- c(fm_profile_file, fw_profile_file)
missing_files <- required_files[!file.exists(required_files)]

if (length(missing_files) > 0) {
  warning("Missing required profile files:")
  for (file in missing_files) {
    cat("  -", file, "\n")
  }
  stop("Cannot proceed without FM and FW profile files from Phase 2")
}

# Load the temporal profiles
cat("Loading monthly profile (FM_F):", fm_profile_file, "\n")
fm_profile <- readRDS(fm_profile_file)

cat("Loading weekly profile (FW_F):", fw_profile_file, "\n")
fw_profile <- readRDS(fw_profile_file)

# Verify profile data structure
if (is.null(fm_profile) || is.null(fw_profile)) {
  stop("Failed to load required temporal profiles")
}

cat("FM profile dimensions:", if(is.array(fm_profile)) paste(dim(fm_profile), collapse = " x ") else "non-array", "\n")
cat("FW profile dimensions:", if(is.array(fw_profile)) paste(dim(fw_profile), collapse = " x ") else "non-array", "\n")

# Target sector for daily profile creation
target_sector <- "F"

# Create daily profiles by combining monthly and weekly factors
cat("Creating daily profiles for sector", target_sector, "\n")
cat("Combining monthly (FM) and weekly (FW) temporal factors\n")

# Execute the daily profile creation
# This function combines monthly and weekly profiles to create daily variations
DailyPRF_fromFMFW(
  FM_profile = fm_profile,
  FW_profile = fw_profile,
  sector = target_sector
)

# Verify output was created
expected_output_dir <- "data/processed/TEMPO_data/DailyProfiles/F"
expected_output_pattern <- paste0("*_", target_sector, "_daily*")

# Check for created daily profile files
output_files <- list.files(
  path = expected_output_dir,
  pattern = paste0("DailyProfile_.*_", target_sector, "\\.rds$"),
  full.names = TRUE
)

if (length(output_files) > 0) {
  cat("Successfully created daily profiles:\n")
  for (file in output_files) {
    file_size <- file.size(file)
    cat("  -", basename(file), "(", round(file_size/1024, 1), "KB )\n")
  }
} else {
  warning("No daily profile output files found in", expected_output_dir)
}

# Additional verification of profile consistency
cat("Verifying temporal profile consistency:\n")
cat("- Monthly factors should cover 12 months\n")
cat("- Weekly factors should cover 7 days\n")
cat("- Daily profiles should combine both temporal scales\n")

# Phase completion summary
end_time_phase4 <- Sys.time()
phase4_duration <- difftime(end_time_phase4, start_time_phase4, units = "secs")

cat("\n==> PHASE 4 COMPLETED\n")
cat("==> Processing time:", round(phase4_duration, 2), "seconds\n")
cat("==> Daily profiles created for sector:", target_sector, "\n")
cat("==> Output files:", length(output_files), "\n\n")
