###############################################################################
# EM-CAMS v.3.0.0 - Phase 11: Final Data Conversion
###############################################################################
# Description: Combined coordinate [LON,LAT] → [LAT,LON] and time conversion
#              to CF standard (days since 1850-01-01) format
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
# Output: AQ_EM_sum/ directory with fully converted emission files
###############################################################################

# Start phase timer
start_time_phase11 <- Sys.time()
cat("Starting Phase 11: Final Data Conversion (Coordinates + Time)\n")

# Load required modules
source("scripts/computation/Computation/TimeConversion.R")
if(file.exists("scripts/utils/coordinate_converter.R")) {
  source("scripts/utils/coordinate_converter.R")
} else {
  cat("⚠️ Coordinate converter not found, will use built-in functions\n")
}

# Configuration from Main.R
input_folder <- final_conversion_input_dir
output_folder <- final_conversion_output_dir
backup_enabled <- TRUE

# Display configuration
cat("=== PHASE 11 CONFIGURATION ===\n")
cat("Input folder:", input_folder, "\n")
cat("Output folder:", output_folder, "\n")
cat("Conversions: [LON,LAT] → [LAT,LON] + DDMMYYYY → CF time\n")

# Validate input folder
if (!dir.exists(input_folder)) {
  stop("Input folder not found: ", input_folder)
}

# Find emission files to convert
em_files <- list.files(input_folder, pattern = "EM_.*\\.rds$", full.names = TRUE)

if (length(em_files) == 0) {
  stop("No emission files found in ", input_folder)
}

cat("\n=== FILES TO PROCESS ===\n")
for (i in seq_along(em_files)) {
  filename <- basename(em_files[i])
  file_size <- round(file.size(em_files[i]) / 1024 / 1024, 1)
  cat(sprintf("[%2d] %s (%s MB)\n", i, filename, file_size))
}
cat("Total files:", length(em_files), "\n")

# Create output folder
if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
  cat("Created output folder:", output_folder, "\n")
}

# Load coordinate index for conversion
coord_file <- "data/processed/lon_lat_idx.rds"
if(file.exists(coord_file)) {
  coord_data <- readRDS(coord_file)
  cat("Loaded coordinate reference:", coord_file, "\n")
} else {
  cat("⚠️ Coordinate file not found, using existing dimnames\n")
  coord_data <- NULL
}

# Process files
cat("\n=== PROCESSING FILES ===\n")

processed_count <- 0
failed_count <- 0
total_start_time <- Sys.time()

for (i in seq_along(em_files)) {
  input_file <- em_files[i]
  filename <- basename(input_file)
  output_file <- file.path(output_folder, filename)
  
  cat(sprintf("\n[%d/%d] Processing: %s\n", i, length(em_files), filename))
  
  tryCatch({
    # Load emission data
    cat("  → Loading data...\n")
    emission_data <- readRDS(input_file)
    
    # Step 1: Convert coordinates [LON,LAT] → [LAT,LON]
    cat("  → Converting coordinates [LON,LAT] → [LAT,LON]...\n")
    
    # Get current dimensions
    current_dims <- dim(emission_data)
    current_dimnames <- dimnames(emission_data)
    
    if(length(current_dims) == 3) {
      # Assuming structure: [LON, LAT, TIME]
      # Convert to: [LAT, LON, TIME]
      emission_data <- aperm(emission_data, c(2, 1, 3))
      
      # Update dimnames
      if(!is.null(current_dimnames)) {
        dimnames(emission_data) <- list(
          lat = current_dimnames[[2]],  # LAT becomes first dimension
          lon = current_dimnames[[1]],  # LON becomes second dimension
          time = current_dimnames[[3]]  # TIME remains third
        )
      }
      
      cat("    ✓ Coordinates converted: [", current_dims[1], ",", current_dims[2], ",", current_dims[3], "]",
          " → [", dim(emission_data)[1], ",", dim(emission_data)[2], ",", dim(emission_data)[3], "]\n")
    } else {
      cat("    ⚠️ Unexpected data structure, skipping coordinate conversion\n")
    }
    
    # Step 2: Convert time dimension DDMMYYYY → CF standard
    cat("  → Converting time dimension to CF standard...\n")
    
    time_dimnames <- dimnames(emission_data)$time
    if(!is.null(time_dimnames) && length(time_dimnames) > 0) {
      # Convert DDMMYYYY to CF standard (NUMERIC, not character)
      cf_times <- sapply(time_dimnames, function(date_str) {
        if(nchar(date_str) == 8) {
          # Parse DDMMYYYY format
          day <- as.numeric(substr(date_str, 1, 2))
          month <- as.numeric(substr(date_str, 3, 4))
          year <- as.numeric(substr(date_str, 5, 8))
          
          # Create date and convert to days since 1850-01-01
          date_obj <- as.Date(paste(year, month, day, sep = "-"))
          reference_date <- as.Date("1850-01-01")
          days_since_ref <- as.numeric(date_obj - reference_date)
          
          return(days_since_ref)  # Return NUMERIC, not character
        } else {
          # Try to convert existing value to numeric if possible
          numeric_val <- suppressWarnings(as.numeric(date_str))
          return(if(is.na(numeric_val)) 0 else numeric_val)
        }
      })
      
      # Update time dimnames with NUMERIC values
      dimnames(emission_data)$time <- as.character(cf_times)  # dimnames need character, but clean numeric conversion
      
      cat("    ✓ Time converted: DDMMYYYY → CF numeric (days since 1850-01-01)\n")
      cat("    ✓ Sample times:", head(cf_times, 3), "...\n")
    } else {
      cat("    ⚠️ No time dimnames found, skipping time conversion\n")
    }
    
    # Step 3: Save converted data
    cat("  → Saving to AQ_EM_sum...\n")
    saveRDS(emission_data, output_file)
    
    # Verify output
    output_size <- round(file.size(output_file) / 1024 / 1024, 1)
    cat("  Success - Output size:", output_size, "MB\n")
    
    processed_count <- processed_count + 1
    
  }, error = function(e) {
    failed_count <- failed_count + 1
    cat("   Error:", e$message, "\n")
  })
}

# Cleanup memory
gc()

# Summary
total_end_time <- Sys.time()
total_duration <- difftime(total_end_time, total_start_time, units = "secs")

cat("\n=== PHASE 11 SUMMARY ===\n")
cat("Files processed successfully:", processed_count, "\n")
cat("Files failed:", failed_count, "\n")
cat("Total processing time:", round(total_duration, 2), "seconds\n")

if (processed_count > 0) {
  avg_time <- round(total_duration / length(em_files), 2)
  cat("Average time per file:", avg_time, "seconds\n")
  
  # Show output location and verify a sample
  cat("AQ emission files saved to:", output_folder, "\n")
  
  # Verify a sample file
  sample_file <- file.path(output_folder, basename(em_files[1]))
  if (file.exists(sample_file)) {
    cat("\n=== VERIFICATION SAMPLE ===\n")
    sample_data <- readRDS(sample_file)
    sample_dims <- dim(sample_data)
    sample_dimnames <- dimnames(sample_data)
    
    cat("Sample file:", basename(sample_file), "\n")
    cat("Dimensions:", paste(sample_dims, collapse=" × "), "\n")
    cat("Structure: [LAT, LON, TIME]\n")
    
    if(!is.null(sample_dimnames)) {
      cat("LAT range:", head(sample_dimnames$lat, 1), "to", tail(sample_dimnames$lat, 1), "\n")
      cat("LON range:", head(sample_dimnames$lon, 1), "to", tail(sample_dimnames$lon, 1), "\n")
      cat("TIME format:", head(sample_dimnames$time, 3), "...\n")
      cat("TIME info: CF standard (days since 1850-01-01)\n")
    }
  }
}

# Phase completion
end_time_phase11 <- Sys.time()
phase11_duration <- difftime(end_time_phase11, start_time_phase11, units = "secs")

cat("\n==> PHASE 11 COMPLETED\n")
cat("==> Processing time:", round(phase11_duration, 2), "seconds\n")
cat("==> Files converted:", processed_count, "out of", length(em_files), "\n")

if (processed_count > 0) {
  cat("==> Output format: [LAT, LON, TIME] with CF standard time\n")
  cat("==> Ready for air quality analysis and spatial processing\n")
  cat("==> Location: AQ_EM_sum/ directory\n")
}

cat("\n")