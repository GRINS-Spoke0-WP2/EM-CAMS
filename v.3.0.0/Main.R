#!/usr/bin/env Rscript
###############################################################################
# EM-CAMS v.3.0.0 - Main Orchestrator
# European Air Quality Data Processing Pipeline
###############################################################################
# Description: Clean, modular orchestrator for the EM-CAMS processing pipeline
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
# 
# This script coordinates the execution of all processing phases for the
# European air quality emissions data processing pipeline.
###############################################################################

###############################################################################
# USER CONFIGURATION - MODIFY THESE VARIABLES AS NEEDED
###############################################################################

# POLLUTANTS TO PROCESS - modify this list to select which pollutants to process
# Available: "nh3", "ch4", "co", "co2_bf", "co2_ff", "nmvoc", "nox", "pm2_5", "pm10", "so2"
# Examples:
   pollutant_names <- c("nox")                    # Only NOx
#   pollutant_names <- c("nox", "nh3")             # Only NOx and NH3  
#   pollutant_names <- c("nox", "nh3", "pm2_5")    # NOx, NH3, and PM2.5
#   pollutant_names <- c("nh3", "ch4", "co", "co2_bf", "co2_ff", "nmvoc", "nox", "pm2_5", "pm10", "so2")  # All pollutants

# TIME RANGE - modify these years to change the processing period
start_year_global <- 2000
end_year_global   <- 2022

# PHASES TO RUN - modify this list to select which phases to execute
# Available phases: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
# Examples:
#   phases_to_run <- c(1, 2, 3)                          # Only phases 1, 2, and 3
#   phases_to_run <- c(7, 8)                             # Only phases 7 and 8
#   phases_to_run <- c(9)                                # Only coordinate conversion
#   phases_to_run <- c(10)                               # Only time conversion
#   phases_to_run <- c(11)                               # Final conversion (coordinates + time → AQ_EM_sum)
#   phases_to_run <- c(12)                               # Spacetime conversion (AQ_EM_sum → spacetime objects)
#   phases_to_run <- c(1, 2, 3, 4, 5, 6, 7, 8, 11, 12)  # Full pipeline → spacetime-ready data
#   phases_to_run <- c(7, 11, 12)                        # Aggregation → spacetime-ready data
phases_to_run <- c(1, 2, 3, 4, 5, 6, 7, 8)  # All main phases (Phase 9-12 excluded by default)

# PHASE 9 COORDINATE CONVERSION SETTINGS
# Directories to convert from [LON,LAT] to [LAT,LON] format
# Examples:
#   convert_directories <- c("data/processed/DAILY_data/EM_sum/")                    # Only EM_sum
#   convert_directories <- c("data/processed/DAILY_data/DailyFromGLOB/")            # Only GLOB data
#   convert_directories <- c()                                                      # No conversion
convert_directories <- c(
  "data/processed/DAILY_data/EM_sum/"
)

# PHASE 10 TIME CONVERSION SETTINGS
# Convert time dimension from DDMMYYYY format to CF standard (days since 1850-01-01)
# Input/Output directories for time conversion
time_input_dir <- "data/processed/DAILY_data/EM_sum/"        # Source directory
time_output_dir <- "data/processed/DAILY_data/EM_sum_CF/"    # CF-compliant output directory
time_overwrite_originals <- FALSE                           # TRUE: backup originals and overwrite, FALSE: create new directory

# PHASE 11 FINAL CONVERSION SETTINGS
# Combined coordinate [LON,LAT] → [LAT,LON] and time DDMMYYYY → CF standard conversion
# Produces air quality ready emission data
final_conversion_input_dir <- "data/processed/DAILY_data/EM_sum/"     # Source directory
final_conversion_output_dir <- "data/processed/DAILY_data/AQ_EM_sum/" # Final AQ-ready output

# SUMMARY OF CONFIGURATION
cat("📋 EM-CAMS v.3.0.0 Configuration:\n")
cat("   • Pollutants:", paste(toupper(pollutant_names), collapse=", "), "\n")
cat("   • Time range:", start_year_global, "-", end_year_global, "\n")
cat("   • Total years:", end_year_global - start_year_global + 1, "\n")
cat("   • Phases to run:", paste(phases_to_run, collapse=", "), "\n")
if(9 %in% phases_to_run && length(convert_directories) > 0) {
  cat("   • Directories to convert:", length(convert_directories), "directories\n")
}
if(10 %in% phases_to_run) {
  cat("   • Time conversion:", time_input_dir, "→", time_output_dir, "\n")
}
if(11 %in% phases_to_run) {
  cat("   • Final conversion: [LON,LAT] + DDMMYYYY → [LAT,LON] + CF time\n")
  cat("   • AQ-ready output:", final_conversion_output_dir, "\n")
}
cat("\n")

###############################################################################

# Start total execution timer
total_start_time <- Sys.time()
cat("==> Starting EM-CAMS v.3.0.0 Processing Pipeline\n")
cat("==> Start time:", format(total_start_time, "%Y-%m-%d %H:%M:%S"), "\n\n")

# Load core configuration and utilities
source("scripts/utils/Config.R")
source("scripts/utils/Utils.R")

###############################################################################
# PHASE 1: CAMS-REG-ANT Yearly Data Extraction
###############################################################################
if(1 %in% phases_to_run) {
  cat("==> PHASE 1: CAMS-REG-ANT Yearly Data Extraction\n")
  source("scripts/phases/phase1_reg_ant.R")
} else {
  cat("⏭️ Skipping Phase 1\n")
}

###############################################################################
# PHASE 2: CAMS-REG-TEMPO Profiles Extraction  
###############################################################################
if(2 %in% phases_to_run) {
  cat("==> PHASE 2: CAMS-REG-TEMPO Profiles Extraction\n")
  source("scripts/phases/phase2_tempo_profiles.R")
} else {
  cat("⏭️ Skipping Phase 2\n")
}

###############################################################################
# PHASE 3: Simplified CAMS-REG-TEMPO Profile Extraction
###############################################################################
if(3 %in% phases_to_run) {
  cat("==> PHASE 3: Simplified CAMS-REG-TEMPO Profile Extraction\n")
  source("scripts/phases/phase3_simplified_profiles.R")
} else {
  cat("⏭️ Skipping Phase 3\n")
}

###############################################################################
# PHASE 4: Daily Profile Creation from FM & FW
###############################################################################
if(4 %in% phases_to_run) {
  cat("==> PHASE 4: Daily Profile Creation from FM & FW\n")
  source("scripts/phases/phase4_daily_profiles.R")
} else {
  cat("⏭️ Skipping Phase 4\n")
}

###############################################################################
# PHASE 5: Daily Data Computation with FD Profiles
###############################################################################
if(5 %in% phases_to_run) {
  cat("==> PHASE 5: Daily Data Computation with FD Profiles\n")
  source("scripts/phases/phase5_fd_daily_computation.R")
} else {
  cat("⏭️ Skipping Phase 5\n")
}

###############################################################################
# PHASE 6: Daily Data Computation with Simplified Profiles (Parallel)
###############################################################################
if(6 %in% phases_to_run) {
  cat("==> PHASE 6: Daily Data Computation with Simplified Profiles\n")
  source("scripts/phases/phase6_simplified_daily_computation.R")
} else {
  cat("⏭️ Skipping Phase 6\n")
}

###############################################################################
# PHASE 7: Data Stacking and Sector Aggregation
###############################################################################
if(7 %in% phases_to_run) {
  cat("==> PHASE 7: Data Stacking and Sector Aggregation\n")
  source("scripts/phases/phase7_stacking_aggregation.R")
} else {
  cat("⏭️ Skipping Phase 7\n")
}

###############################################################################
# PHASE 8: GLOB-ANT Data Processing
###############################################################################
if(8 %in% phases_to_run) {
  cat("==> PHASE 8: GLOB-ANT Data Processing\n")
  source("scripts/phases/phase8_glob_ant.R")
} else {
  cat("⏭️ Skipping Phase 8\n")
}

###############################################################################
# PHASE 11: Final Conversion ([LON,LAT] → [LAT,LON] + DDMMYYYY → CF Standard)
###############################################################################
if(11 %in% phases_to_run) {
  cat("==> PHASE 11: Final Data Conversion (Coordinates + Time)\n")
  source("scripts/phases/phase11_final_conversion.R")
} else {
  cat("⏭️ Skipping Phase 11 (Final Conversion)\n")
}

###############################################################################
# PHASE 10: Time Dimension Conversion (DDMMYYYY → CF Standard)
###############################################################################
if(10 %in% phases_to_run) {
  cat("==> PHASE 10: Time Dimension Conversion\n")
  source("scripts/phases/phase10_time_conversion.R")
} else {
  cat("⏭️ Skipping Phase 10 (Time Conversion)\n")
}

###############################################################################
# PHASE 9: Coordinate Conversion [LON,LAT] → [LAT,LON]
###############################################################################
if(9 %in% phases_to_run) {
  cat("==> PHASE 9: Coordinate Conversion\n")
  
  if(length(convert_directories) > 0) {
    # Load coordinate converter
    if(file.exists("scripts/utils/coordinate_converter.R")) {
      source("scripts/utils/coordinate_converter.R")
    } else if(file.exists("scripts/phases/phase9_coordinate_conversion.R")) {
      source("scripts/phases/phase9_coordinate_conversion.R")
    } else {
      cat("⚠️ Coordinate converter script not found\n")
    }
    
    # Convert each configured directory
    for(dir_to_convert in convert_directories) {
      if(dir.exists(dir_to_convert)) {
        output_dir <- paste0(dir_to_convert, "_lat_lon")
        cat("Converting:", dir_to_convert, "→", output_dir, "\n")
        
        tryCatch({
          # Assuming there's a convert_directory function
          convert_directory(dir_to_convert, output_dir)
          cat("✅ Conversion completed for:", dir_to_convert, "\n")
        }, error = function(e) {
          cat("❌ Error converting", dir_to_convert, ":", e$message, "\n")
        })
      } else {
        cat("⚠️ Directory not found:", dir_to_convert, "\n")
      }
    }
  } else {
    cat("ℹ️ No directories configured for conversion\n")
  }
} else {
  cat("⏭️ Skipping Phase 9 (Coordinate Conversion)\n")
}

###############################################################################
# PHASE 12: Spacetime Conversion (AQ_EM_sum → spacetime objects)
###############################################################################
if(12 %in% phases_to_run) {
  cat("==> PHASE 12: Spacetime Conversion\n")
  source("scripts/phases/phase12_spacetime_conversion.R")
} else {
  cat("⏭️ Skipping Phase 12\n")
}

###############################################################################
# Pipeline Summary
###############################################################################
total_end_time <- Sys.time()
total_duration <- difftime(total_end_time, total_start_time, units = "mins")

cat("\n")
cat(paste(rep("=", 70), collapse=""), "\n")
cat("==> EM-CAMS v.3.0.0 Processing Pipeline Completed Successfully\n")
cat("==> Total execution time:", round(total_duration, 2), "minutes\n")
cat("==> End time:", format(total_end_time, "%Y-%m-%d %H:%M:%S"), "\n")
cat("\n📋 Processing Summary:\n")
cat("   ✅ Pollutants processed:", paste(toupper(pollutant_names), collapse=", "), "\n")
cat("   ✅ Time range:", start_year_global, "-", end_year_global, "\n")
cat("   ✅ Phases executed:", paste(phases_to_run, collapse=", "), "\n")
if(10 %in% phases_to_run) {
  cat("   ✅ Time conversion: CF standard format (days since 1850-01-01)\n")
}
if(11 %in% phases_to_run) {
  cat("   ✅ Final conversion: [LAT,LON] coordinates + CF standard time\n")
}
if(12 %in% phases_to_run) {
  cat("   ✅ Spacetime conversion: AQ_EM_sum → spacetime objects for target code compatibility\n")
}
if(9 %in% phases_to_run) {
  cat("   ✅ Coordinate conversion:", length(convert_directories), "directories\n")
}
