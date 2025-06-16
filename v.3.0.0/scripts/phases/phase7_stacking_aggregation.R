###############################################################################
# EM-CAMS v.3.0.0 - Phase 7: Data Stacking and Sector Aggregation
###############################################################################
# Description: Stack daily data along years and aggregate emissions across
#              all sectors to create final emission inventories
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
###############################################################################

# Start phase timer
start_time_phase7 <- Sys.time()
cat("Starting Phase 7: Data Stacking and Sector Aggregation\n")

# Load required computation module
source("scripts/computation/Computation/ComputeFinal.R")

# Define processing parameters
input_folder <- "data/processed/DAILY_data"
start_year <- 2000
end_year <- 2022

# Define sectors and pollutants for stacking
# Only process sectors that have actual daily data files
pollutants_stack <- c("NOx")  # Focus on NOx as specified in original code

# Dynamically detect available sectors based on existing files
available_sectors <- c()
for (pollutant in pollutants_stack) {
  pollutant_dir <- file.path(input_folder, tolower(gsub("x", "x", pollutant)))  # nox
  if (dir.exists(pollutant_dir)) {
    daily_files <- list.files(pollutant_dir, pattern = "^Daily_([A-L])_.*\\.rds$")
    sector_matches <- regmatches(daily_files, regexpr("Daily_([A-L])_", daily_files))
    detected_sectors <- unique(gsub("Daily_([A-L])_", "\\1", sector_matches))
    available_sectors <- unique(c(available_sectors, detected_sectors))
  }
}

# Sort sectors alphabetically
available_sectors <- sort(available_sectors)

cat("Processing sectors:", paste(available_sectors, collapse = ", "), "\n")
cat("Processing pollutants:", paste(pollutants_stack, collapse = ", "), "\n")
cat("Year range:", start_year, "-", end_year, "\n")

###############################################################################
# Sub-Phase 7A: Stack Daily Data by Sector and Pollutant
###############################################################################
cat("\nSub-Phase 7A: Stacking daily data along years\n")

stacking_start_time <- Sys.time()
successful_stacks <- 0
failed_stacks <- 0

# Stack daily data for each combination of sector and pollutant
for (sector in available_sectors) {
  for (pollutant in pollutants_stack) {
    cat("Stacking data for sector", sector, "pollutant", pollutant, "\n")
    
    tryCatch({
      StackDailyData(
        input_folder = input_folder,
        sector = sector,
        pollutant = pollutant,
        start_year = start_year,
        end_year = end_year
      )
      
      successful_stacks <- successful_stacks + 1
      
    }, error = function(e) {
      cat("Error stacking sector", sector, "pollutant", pollutant, ":", e$message, "\n")
      failed_stacks <- failed_stacks + 1
    })
  }
}

stacking_end_time <- Sys.time()
stacking_duration <- difftime(stacking_end_time, stacking_start_time, units = "secs")

cat("Sub-Phase 7A completed in", round(stacking_duration, 2), "seconds\n")
cat("Successfully stacked:", successful_stacks, "sector-pollutant combinations\n")
cat("Failed stacking:", failed_stacks, "sector-pollutant combinations\n")

# Verify stacked data output
stacked_folder <- file.path(input_folder, "DailyAlongYears")
if (dir.exists(stacked_folder)) {
  stacked_files <- length(list.files(stacked_folder, pattern = "\\.rds$", recursive = TRUE))
  cat("Created", stacked_files, "stacked daily files in", stacked_folder, "\n")
} else {
  warning("Stacked data directory not found:", stacked_folder)
}

###############################################################################
# Sub-Phase 7B: Aggregate All Sectors into Final Emission Inventories
###############################################################################
cat("\nSub-Phase 7B: Aggregating all sectors into final inventories\n")

aggregation_start_time <- Sys.time()

# Define output directory for sector-aggregated data
output_folder_em_sum <- file.path(input_folder, "EM_sum")
dir.create(output_folder_em_sum, recursive = TRUE, showWarnings = FALSE)

successful_aggregations <- 0
failed_aggregations <- 0

# Aggregate sectors for each pollutant
for (pollutant in pollutants_stack) {
  cat("Aggregating all sectors for pollutant:", pollutant, "\n")
  
  tryCatch({
    SumAllSectorsIntoOne(
      input_folder = stacked_folder,
      pollutant = pollutant,
      start_year = start_year,
      end_year = end_year,
      output_folder = output_folder_em_sum
    )
    
    successful_aggregations <- successful_aggregations + 1
    cat("✓ Successfully aggregated", pollutant, "across all sectors\n")
    
  }, error = function(e) {
    cat("Error aggregating pollutant", pollutant, ":", e$message, "\n")
    failed_aggregations <- failed_aggregations + 1
  })
}

aggregation_end_time <- Sys.time()
aggregation_duration <- difftime(aggregation_end_time, aggregation_start_time, units = "secs")

cat("Sub-Phase 7B completed in", round(aggregation_duration, 2), "seconds\n")
cat("Successfully aggregated:", successful_aggregations, "pollutants\n")
cat("Failed aggregation:", failed_aggregations, "pollutants\n")

# Verify final aggregated output
if (dir.exists(output_folder_em_sum)) {
  final_files <- list.files(output_folder_em_sum, pattern = "^EM_.*\\.rds$")
  cat("Created", length(final_files), "final emission inventory files\n")
  
  # Display final files
  if (length(final_files) > 0) {
    cat("Final emission inventory files (year-by-year):\n")
    for (file in final_files) {
      file_path <- file.path(output_folder_em_sum, file)
      file_size <- round(file.size(file_path) / 1024 / 1024, 2)  # Size in MB
      cat("  -", file, "(", file_size, "MB )\n")
    }
  }
} else {
  warning("Final aggregated data directory not found:", output_folder_em_sum)
}

###############################################################################
# Phase 7 Summary and Data Location Information
###############################################################################
cat("\nData output summary:\n")
cat("==============================\n")

# Per-sector stacked data
cat("1. Per-sector daily data (stacked along years):\n")
cat("   Directory:", stacked_folder, "\n")
cat("   Format: [pollutant]_[sector]_[year].rds\n")
cat("   Structure: [longitude, latitude, day_of_year]\n")

# Sector-aggregated final data  
cat("\n2. Final emission inventories (all sectors aggregated):\n")
cat("   Directory:", output_folder_em_sum, "\n")
cat("   Format: EM_[pollutant]_[year].rds\n")
cat("   Structure: [longitude, latitude, day_of_year]\n")
cat("   ★ These are the primary final results (year-by-year for efficiency)\n")

# Additional processing information
cat("\nProcessing information:\n")
cat("- Coordinate system: [Longitude, Latitude] (standard for EM-CAMS)\n")
cat("- Temporal resolution: Daily (365/366 days per year)\n")
cat("- Spatial coverage: European domain\n")
cat("- Sectors: GNFR sectors A-L (12 sectors total)\n")

# Phase completion summary
end_time_phase7 <- Sys.time()
phase7_duration <- difftime(end_time_phase7, start_time_phase7, units = "secs")

cat("\n==> PHASE 7 COMPLETED\n")
cat("==> Total processing time:", round(phase7_duration, 2), "seconds\n")
cat("==> Stacking operations:", successful_stacks, "successful,", failed_stacks, "failed\n")
cat("==> Aggregation operations:", successful_aggregations, "successful,", failed_aggregations, "failed\n")
cat("==> Final data location:", output_folder_em_sum, "\n\n")
