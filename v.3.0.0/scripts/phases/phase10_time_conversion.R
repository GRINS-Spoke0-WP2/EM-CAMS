###############################################################################
# EM-CAMS v.3.0.0 - Phase 10: Time Dimension Conversion
###############################################################################
# Description: Convert time dimnames from DDMMYYYY format to CF standard 
#              (days since 1850-01-01) for compatibility with spatial libraries
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
###############################################################################

# Start phase timer
start_time_phase10 <- Sys.time()
cat("Starting Phase 10: Time Dimension Conversion\n")

# Load computation module
source("scripts/computation/Computation/TimeConversion.R")

# Use configuration from Main.R
input_folder <- time_input_dir
output_folder <- time_output_dir
backup_enabled <- TRUE
overwrite_original <- time_overwrite_originals

# Display configuration
cat("=== CONFIGURATION ===\n")
cat("Input folder:", input_folder, "\n")
if (overwrite_original) {
  cat("Output: Overwriting original files\n")
  cat("Backup: ", if(backup_enabled) "Enabled" else "Disabled", "\n")
} else {
  cat("Output folder:", output_folder, "\n")
}

# Find emission files to convert
if (!dir.exists(input_folder)) {
  stop("Input folder not found: ", input_folder)
}

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

cat("\nTotal files:", length(em_files), "\n")

# Create output folder if needed
if (!overwrite_original && !dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
  cat("Created output folder:", output_folder, "\n")
}

# Process files
cat("\n=== PROCESSING FILES ===\n")

processed_count <- 0
failed_count <- 0
total_start_time <- Sys.time()

for (i in seq_along(em_files)) {
  input_file <- em_files[i]
  filename <- basename(input_file)
  
  cat(sprintf("\n[%d/%d] Processing: %s\n", i, length(em_files), filename))
  
  tryCatch({
    # Determine output file path
    if (overwrite_original) {
      output_file <- input_file
    } else {
      output_file <- file.path(output_folder, filename)
    }
    
    # Convert time dimnames
    ConvertTimeDimnames(
      input_file = input_file,
      output_file = output_file,
      reference_date = "1850-01-01",
      backup = backup_enabled && overwrite_original,
      verbose = TRUE
    )
    
    processed_count <- processed_count + 1
    cat("  ✅ Success\n")
    
  }, error = function(e) {
    failed_count <- failed_count + 1
    cat("  ❌ Error:", e$message, "\n")
  })
}

# Summary
total_end_time <- Sys.time()
total_duration <- difftime(total_end_time, total_start_time, units = "secs")

cat("\n=== PHASE 10 SUMMARY ===\n")
cat("Files processed successfully:", processed_count, "\n")
cat("Files failed:", failed_count, "\n")
cat("Total processing time:", round(total_duration, 2), "seconds\n")

if (processed_count > 0) {
  avg_time <- round(total_duration / length(em_files), 2)
  cat("Average time per file:", avg_time, "seconds\n")
  
  # Show output location
  if (overwrite_original) {
    cat("Files updated in place:", input_folder, "\n")
    if (backup_enabled) {
      cat("Backup files created with .backup extension\n")
    }
  } else {
    cat("CF-compliant files saved to:", output_folder, "\n")
  }
  
  # Verify a sample file
  sample_file <- if (overwrite_original) em_files[1] else file.path(output_folder, basename(em_files[1]))
  if (file.exists(sample_file)) {
    cat("\n=== VERIFICATION SAMPLE ===\n")
    VerifyTimeConversion(sample_file, verbose = TRUE)
  }
}

# Phase completion
end_time_phase10 <- Sys.time()
phase10_duration <- difftime(end_time_phase10, start_time_phase10, units = "secs")

cat("\n==> PHASE 10 COMPLETED\n")
cat("==> Processing time:", round(phase10_duration, 2), "seconds\n")
cat("==> Files processed:", processed_count, "out of", length(em_files), "\n")

if (processed_count > 0) {
  cat("==> Time dimension format: CF standard (days since 1850-01-01)\n")
  cat("==> Ready for spatial libraries (sf, stars, terra)\n")
}

cat("\n")
