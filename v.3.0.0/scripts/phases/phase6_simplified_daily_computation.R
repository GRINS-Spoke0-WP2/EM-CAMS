###############################################################################
# EM-CAMS v.3.0.0 - Phase 6: Daily Data Computation with Simplified Profiles
###############################################################################
# Description: Compute daily emission data using simplified temporal profiles
#              with parallel processing for efficiency
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
###############################################################################

# Start phase timer
start_time_phase6 <- Sys.time()
cat("Starting Phase 6: Daily Data Computation with Simplified Profiles (Parallel)\n")

# Load configuration
source("scripts/utils/Config.R")

# Load required libraries for parallel processing
library(foreach)
library(doParallel)

# Load computation module for simplified daily calculations
source("scripts/computation/Computation/ComputeSimplifiedDaily.R")

# Setup parallel processing
n_cores <- parallel::detectCores()
cat("Detected", n_cores, "CPU cores for parallel processing\n")

# Use most cores but leave one free for system responsiveness
cores_to_use <- max(1, n_cores - 1)
cat("Using", cores_to_use, "cores for parallel processing\n")

cl <- makeCluster(cores_to_use)
registerDoParallel(cl)

# Export required functions and variables to worker nodes
clusterEvalQ(cl, {
  source("scripts/utils/Config.R")
  source("scripts/utils/Utils.R")
  source("scripts/computation/Computation/ComputeSimplifiedDaily.R")
})

# Use global configuration variables
if (!exists("pollutant_names")) {
  pollutant_names <- pollutant_names_default
}
if (!exists("start_year_global")) {
  start_year_global <- start_year_default
  end_year_global <- end_year_default
}

# Define pollutants for simplified profile processing
# Filter configured pollutants to those available for simplified processing
simplified_available <- c("nh3", "pm10", "pm2_5", "nox", "nmvoc", "so2", "co")
pollutants_simplified_phase6 <- intersect(pollutant_names, simplified_available)

# Map pollutant names to corresponding RDS file suffixes
pollutant_file_mapping <- list(
  "nh3" = "nh3",
  "pm10" = "pm10",
  "pm2_5" = "pm2_5",
  "nox" = "nox",
  "nmvoc" = "nmvoc",
  "so2" = "so2",
  "co" = "co"
)

# Convert to uppercase for display
pollutants_display <- toupper(pollutants_simplified_phase6)

cat("📋 Phase 6 Configuration:\n")
cat("   • Selected pollutants:", paste(pollutants_display, collapse=", "), "\n")
cat("   • Time range:", start_year_global, "-", end_year_global, "\n\n")

cat("Processing simplified daily data for pollutants:", paste(pollutants_display, collapse = ", "), "\n")
cat("Year range:", start_year_global, "-", end_year_global, "\n")

# Verify required yearly data files exist
missing_files <- c()
for (pollutant in pollutants_simplified_phase6) {
  file_suffix <- pollutant_file_mapping[[pollutant]]
  if (is.null(file_suffix)) {
    cat("Warning: No file mapping found for pollutant", pollutant, "\n")
    next
  }
  
  yearly_file <- paste0("data/processed/ANT_data/REG_ANT_yearly_data_", file_suffix, ".rds")
  if (!file.exists(yearly_file)) {
    missing_files <- c(missing_files, yearly_file)
  }
}

if (length(missing_files) > 0) {
  cat("Warning: Missing required yearly data files:\n")
  for (file in missing_files) {
    cat("  -", file, "\n")
  }
}

# Execute parallel processing for simplified daily data computation
cat("Starting parallel computation of simplified daily data\n")

processing_results <- foreach(
  pollutant = pollutants_simplified_phase6, 
  .packages = c("base"),
  .combine = rbind,
  .errorhandling = "pass"
) %dopar% {
  
  # Get file suffix for current pollutant
  file_suffix <- pollutant_file_mapping[[pollutant]]
  
  if (is.null(file_suffix)) {
    return(data.frame(
      pollutant = pollutant,
      status = "error",
      message = "No file mapping found",
      stringsAsFactors = FALSE
    ))
  }
  
  # Define yearly data file path
  yearly_file <- paste0("data/processed/ANT_data/REG_ANT_yearly_data_", file_suffix, ".rds")
  
  if (!file.exists(yearly_file)) {
    return(data.frame(
      pollutant = pollutant,
      status = "error", 
      message = paste("Missing yearly data file:", yearly_file),
      stringsAsFactors = FALSE
    ))
  }
  
  # Load yearly data
  tryCatch({
    yearly_data <- readRDS(yearly_file)
    
    # Compute simplified daily data
    DailyDataFromSimplified(
      yearlyData = yearly_data,
      start_year = start_year_global,
      end_year = end_year_global,
      pollutant_name = pollutant
    )
    
    return(data.frame(
      pollutant = pollutant,
      status = "success",
      message = "Successfully processed",
      stringsAsFactors = FALSE
    ))
    
  }, error = function(e) {
    return(data.frame(
      pollutant = pollutant,
      status = "error",
      message = paste("Processing error:", e$message),
      stringsAsFactors = FALSE
    ))
  })
}

# Stop parallel cluster
stopCluster(cl)

# Process and display results
cat("\nParallel processing completed. Results:\n")

if (is.data.frame(processing_results)) {
  successful_pollutants <- processing_results[processing_results$status == "success", "pollutant"]
  failed_pollutants <- processing_results[processing_results$status == "error", ]
  
  cat("Successfully processed:", length(successful_pollutants), "pollutants\n")
  if (length(successful_pollutants) > 0) {
    for (pollutant in successful_pollutants) {
      cat("  ✓", pollutant, "\n")
    }
  }
  
  if (nrow(failed_pollutants) > 0) {
    cat("Failed processing:", nrow(failed_pollutants), "pollutants\n")
    for (i in 1:nrow(failed_pollutants)) {
      cat("  ✗", failed_pollutants[i, "pollutant"], ":", failed_pollutants[i, "message"], "\n")
    }
  }
} else {
  cat("Processing results format unexpected\n")
}

# Verify output directory structure
output_base_dir <- "data/processed/DAILY_data/SimplifiedDailyData"
cat("\nVerifying simplified daily data output:\n")

total_simplified_files <- 0
for (pollutant in pollutants_simplified_phase6) {
  pollutant_dir <- file.path(output_base_dir, pollutant)
  
  if (dir.exists(pollutant_dir)) {
    file_count <- length(list.files(pollutant_dir, pattern = "\\.rds$", recursive = TRUE))
    cat("✓", pollutant, ":", file_count, "simplified daily files\n")
    total_simplified_files <- total_simplified_files + file_count
  } else {
    cat("✗", pollutant, ": No output directory found\n")
  }
}

# Phase completion summary
end_time_phase6 <- Sys.time()
phase6_duration <- difftime(end_time_phase6, start_time_phase6, units = "secs")

cat("\n==> PHASE 6 COMPLETED\n")
cat("==> Processing time:", round(phase6_duration, 2), "seconds\n")
cat("==> Parallel processing used:", cores_to_use, "cores\n")
cat("==> Total simplified files created:", total_simplified_files, "\n")
cat("==> Output directory:", output_base_dir, "\n\n")
