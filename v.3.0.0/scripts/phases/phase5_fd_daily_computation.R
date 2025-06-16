###############################################################################
# EM-CAMS v.3.0.0 - Phase 5: Daily Data Computation with FD Profiles
###############################################################################
# Description: Compute daily emission data using FD (daily) temporal profiles
#              for multiple pollutants and sector F
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
###############################################################################

# Start phase timer
start_time_phase5 <- Sys.time()
cat("Starting Phase 5: Daily Data Computation with FD Profiles\n")

# Load required computation modules
source("scripts/computation/Computation/ComputeNormalDaily.R")
source("scripts/computation/Computation/ComputeFinal.R")

# Define processing parameters
temporal_profile_folder <- "data/processed/TEMPO_data"
output_folder <- "data/processed/DAILY_data"

# Define sectors to process with their available profiles
sectors_to_process <- list(
  list(sector = "F", description = "Sector F (uses Phase 4 profiles)", 
       pollutants = c("nh3", "nox", "so2", "pm10", "pm2_5", "nmvoc", "co", "ch4", "co2_ff", "co2_bf")),
  list(sector = "C", description = "Sector C (native FD profiles)", 
       pollutants = c("nh3", "nox", "so2", "pm10", "pm2_5", "nmvoc", "co", "ch4", "co2_ff", "co2_bf")),
  list(sector = "K", description = "Sector K (native FD profiles)", 
       pollutants = c("nh3", "nox")),
  list(sector = "L", description = "Sector L (native FD profiles)", 
       pollutants = c("nh3"))
)

# Ensure output directory exists
dir.create(output_folder, recursive = TRUE, showWarnings = FALSE)

# Process all sectors with their respective profiles
total_successful <- 0
total_failed <- 0
total_files_created <- 0

cat("Processing", length(sectors_to_process), "sectors with their respective temporal profiles\n\n")

for (sector_info in sectors_to_process) {
  sector <- sector_info$sector
  sector_description <- sector_info$description
  available_pollutants <- sector_info$pollutants
  
  cat("=== PROCESSING", toupper(sector_description), "===\n")
  cat("Available pollutants:", paste(toupper(available_pollutants), collapse = ", "), "\n")
  
  sector_successful <- 0
  sector_failed <- 0
  
  for (pollutant_name in available_pollutants) {
    # Build pollutant info for compatibility
    description <- switch(pollutant_name,
      "nh3" = "Ammonia",
      "nox" = "Nitrogen Oxides", 
      "so2" = "Sulfur Dioxide",
      "pm10" = "Particulate Matter 10μm",
      "pm2_5" = "Particulate Matter 2.5μm", 
      "nmvoc" = "Non-Methane Volatile Organic Compounds",
      "co" = "Carbon Monoxide",
      "ch4" = "Methane",
      "co2_ff" = "Carbon Dioxide (Fossil Fuel)",
      "co2_bf" = "Carbon Dioxide (Biofuel)",
      toupper(pollutant_name)
    )
    
    cat("  Processing:", description, "(", toupper(pollutant_name), ") for sector", sector, "\n")
    
    # Define input yearly data file
    yearly_data_file <- file.path("data/processed/ANT_data", paste0("REG_ANT_yearly_data_", pollutant_name, ".rds"))
    
    # Verify yearly data file exists
    if (!file.exists(yearly_data_file)) {
      cat("    Warning: Missing yearly data file for", pollutant_name, ":", yearly_data_file, "\n")
      sector_failed <- sector_failed + 1
      next
    }
    
    # Execute daily data calculation using appropriate profiles
    tryCatch({
      calculate_from_FD(
        PollutantName = pollutant_name,
        yearly_data_file = yearly_data_file,
        temporal_profile_folder = temporal_profile_folder,
        output_folder = output_folder,
        sector = sector
      )
      
      # Verify output was created
      output_pollutant_dir <- file.path(output_folder, pollutant_name)
      if (dir.exists(output_pollutant_dir)) {
        # Count files for this sector
        sector_files <- list.files(output_pollutant_dir, 
                                 pattern = paste0("Daily_", sector, "_.*\\.rds$"), 
                                 recursive = TRUE)
        created_files <- length(sector_files)
        cat("    Successfully processed", pollutant_name, "- created", created_files, "daily files for sector", sector, "\n")
        sector_successful <- sector_successful + 1
        total_files_created <- total_files_created + created_files
      } else {
        cat("    Warning: No output directory created for", pollutant_name, "\n")
        sector_failed <- sector_failed + 1
      }
      
    }, error = function(e) {
      cat("    Error processing", pollutant_name, "for sector", sector, ":", e$message, "\n")
      sector_failed <- sector_failed + 1
    })
  }
  
  cat("  Sector", sector, "Summary: ✓", sector_successful, "successful, ✗", sector_failed, "failed\n\n")
  total_successful <- total_successful + sector_successful
  total_failed <- total_failed + sector_failed
}

# Verify overall output structure
cat("\nVerifying output structure:\n")
total_output_files <- 0

# Get all unique pollutants across all sectors
all_pollutants <- unique(unlist(lapply(sectors_to_process, function(x) x$pollutants)))

for (pollutant_name in all_pollutants) {
  output_pollutant_dir <- file.path(output_folder, pollutant_name)
  
  if (dir.exists(output_pollutant_dir)) {
    file_count <- length(list.files(output_pollutant_dir, pattern = "\\.rds$", recursive = TRUE))
    cat("✓", toupper(pollutant_name), ":", file_count, "daily files\n")
    total_output_files <- total_output_files + file_count
  } else {
    cat("✗", toupper(pollutant_name), ": No output directory\n")
  }
}

# Phase completion summary
end_time_phase5 <- Sys.time()
phase5_duration <- difftime(end_time_phase5, start_time_phase5, units = "secs")

cat("\n==> PHASE 5 COMPLETED\n")
cat("==> Processing time:", round(phase5_duration, 2), "seconds\n")
cat("==> Successfully processed:", total_successful, "sector-pollutant combinations\n")
cat("==> Failed processing:", total_failed, "sector-pollutant combinations\n")
cat("==> Total daily files created:", total_files_created, "\n")
cat("==> Output directory:", output_folder, "\n\n")
