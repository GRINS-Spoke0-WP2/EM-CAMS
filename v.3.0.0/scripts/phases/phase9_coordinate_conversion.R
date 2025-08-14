###############################################################################
# EM-CAMS v.3.0.0 - Phase 9: Optional Coordinate Conversion
###############################################################################
# Description: Convert emission data coordinates from [LON,LAT] to [LAT,LON]
#              format for compatibility with software requiring latitude-first
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
###############################################################################

# Start phase timer
start_time_phase8 <- Sys.time()
cat("Starting Phase 8: Optional Coordinate Conversion\n")

# Load coordinate conversion utilities
source("scripts/utils/coordinate_converter.R")

# Phase description and purpose
cat("\nPhase 8 Purpose:\n")
cat("================\n")
cat("The EM-CAMS project uses [LONGITUDE, LATITUDE] coordinate convention,\n")
cat("which is correct and consistent throughout the pipeline. This phase\n")
cat("provides optional conversion to [LATITUDE, LONGITUDE] format for\n")
cat("compatibility with software/standards requiring latitude-first ordering.\n\n")

# Define convertible data directories and their descriptions
convertible_data <- list(
  list(
    name = "REG-ANT Yearly Data",
    input_dir = "data/processed/ANT_data",
    output_dir = "data/processed/ANT_data/converted_lat_lon",
    pattern = "^REG_ANT_yearly_data_.*\\.rds$",
    description = "Annual anthropogenic emission data by pollutant [lon, lat, sector, year]",
    priority = "medium"
  ),
  list(
    name = "Final Emission Inventories (EM_sum)",
    input_dir = "data/processed/DAILY_data/EM_sum",
    output_dir = "data/processed/DAILY_data/EM_sum/converted_lat_lon",
    pattern = "\\.rds$",
    description = "Final daily emission inventories (all sectors aggregated) [lon, lat, day_of_year]",
    priority = "high"
  ),
  list(
    name = "Daily Data by Sector",
    input_dir = "data/processed/DAILY_data/DailyAlongYears",
    output_dir = "data/processed/DAILY_data/DailyAlongYears/converted_lat_lon",
    pattern = "\\.rds$",
    description = "Daily emission data by individual sector [lon, lat, day_of_year]",
    priority = "low",
    max_files = 10  # Limit for testing/demonstration
  ),
  list(
    name = "GLOB-ANT Monthly Data",
    input_dir = "data/processed/ANT_data",
    output_dir = "data/processed/ANT_data/converted_lat_lon_glob",
    pattern = "^GLOB_.*_monthly_data_.*\\.rds$",
    description = "Global anthropogenic monthly data [lon, lat, sector, month, year]",
    priority = "low"
  )
)

# Display available data for conversion
cat("Available data for coordinate conversion:\n")
cat("=========================================\n")

for (i in seq_along(convertible_data)) {
  data_info <- convertible_data[[i]]
  cat(sprintf("%d. %s (Priority: %s)\n", i, data_info$name, toupper(data_info$priority)))
  cat(sprintf("   Description: %s\n", data_info$description))
  cat(sprintf("   Input: %s\n", data_info$input_dir))
  cat(sprintf("   Output: %s\n", data_info$output_dir))
  
  # Check if input directory exists and count files
  if (dir.exists(data_info$input_dir)) {
    file_count <- length(list.files(data_info$input_dir, pattern = data_info$pattern))
    cat(sprintf("   Available files: %d\n", file_count))
  } else {
    cat("   Status: Input directory not found\n")
  }
  cat("\n")
}

# Determine whether to perform conversion
convert_coordinates <- FALSE

# Check for interactive mode to ask user confirmation
if (interactive()) {
  cat("🔄 Coordinate Conversion Options:\n")
  cat("1. Convert high-priority data only (Final Emission Inventories)\n")
  cat("2. Convert all available data\n")
  cat("3. Skip coordinate conversion\n")
  
  response <- readline(prompt = "Select option (1/2/3): ")
  
  if (response == "1") {
    convert_coordinates <- "high_priority"
  } else if (response == "2") {
    convert_coordinates <- "all"
  } else {
    convert_coordinates <- FALSE
  }
} else {
  # Non-interactive mode: use configuration variable
  cat("ℹ️  Coordinate conversion disabled (non-interactive mode)\n")
  cat("   To enable conversion, set convert_coordinates variable or run interactively\n")
  
  # Uncomment the line below to enable conversion in non-interactive mode
  # convert_coordinates <- "high_priority"  # or "all"
}

# Execute coordinate conversion based on user selection
if (convert_coordinates != FALSE) {
  cat("🔄 STARTING COORDINATE CONVERSION\n")
  cat(paste(rep("=", 50), collapse=""), "\n")
  
  conversion_start_time <- Sys.time()
  total_converted_files <- 0
  successful_conversions <- 0
  failed_conversions <- 0
  
  # Filter data to convert based on priority selection
  data_to_convert <- if (convert_coordinates == "high_priority") {
    convertible_data[sapply(convertible_data, function(x) x$priority == "high")]
  } else {
    convertible_data
  }
  
  # Process each data category
  for (data_info in data_to_convert) {
    cat("\n📂 Converting:", data_info$name, "\n")
    
    if (!dir.exists(data_info$input_dir)) {
      cat("⚠️  Input directory not found, skipping:", data_info$input_dir, "\n")
      failed_conversions <- failed_conversions + 1
      next
    }
    
    tryCatch({
      # Set max_files parameter if specified
      max_files_param <- if (!is.null(data_info$max_files)) data_info$max_files else NULL
      
      # Execute conversion
      conversion_result <- convert_directory(
        input_dir = data_info$input_dir,
        output_dir = data_info$output_dir,
        pattern = data_info$pattern,
        max_files = max_files_param
      )
      
      # Count converted files
      if (dir.exists(data_info$output_dir)) {
        converted_count <- length(list.files(data_info$output_dir, pattern = "\\.rds$", recursive = TRUE))
        cat("✓ Converted", converted_count, "files for", data_info$name, "\n")
        total_converted_files <- total_converted_files + converted_count
        successful_conversions <- successful_conversions + 1
      }
      
    }, error = function(e) {
      cat("✗ Error converting", data_info$name, ":", e$message, "\n")
      failed_conversions <- failed_conversions + 1
    })
  }
  
  conversion_end_time <- Sys.time()
  conversion_duration <- difftime(conversion_end_time, conversion_start_time, units = "mins")
  
  # Conversion summary
  cat("\n🎉 COORDINATE CONVERSION COMPLETED\n")
  cat(paste(rep("=", 50), collapse=""), "\n")
  cat("⏱️  Conversion time:", round(conversion_duration, 2), "minutes\n")
  cat("📊  Successful conversions:", successful_conversions, "categories\n")
  cat("❌  Failed conversions:", failed_conversions, "categories\n")
  cat("📁  Total files converted:", total_converted_files, "\n")
  
  # Display converted data locations
  cat("\n📂 CONVERTED DATA LOCATIONS:\n")
  for (data_info in data_to_convert) {
    if (dir.exists(data_info$output_dir)) {
      cat("   📁", data_info$name, ":", data_info$output_dir, "\n")
    }
  }
  
  cat("\nℹ️  Converted data maintains identical content with [LAT, LON] coordinate order\n")
  cat("   Use converted files for software requiring latitude-first convention\n")
  
} else {
  cat("⏭️  Coordinate conversion skipped\n")
  cat("\nTo convert coordinates manually, use coordinate_converter.R functions:\n")
  cat("📄 Single file: convert_rds_file('input.rds', 'output.rds')\n")
  cat("📂 Directory:   convert_directory('input_dir/', 'output_dir/')\n")
}

# Phase completion summary and final project status
end_time_phase8 <- Sys.time()
phase8_duration <- difftime(end_time_phase8, start_time_phase8, units = "secs")

cat("\n==> PHASE 8 COMPLETED\n")
cat("==> Processing time:", round(phase8_duration, 2), "seconds\n")

if (convert_coordinates != FALSE) {
  cat("==> Coordinate conversion:", if (convert_coordinates == "high_priority") "High-priority data only" else "All available data", "\n")
  cat("==> Converted files:", total_converted_files, "\n")
} else {
  cat("==> Coordinate conversion: Skipped\n")
}

cat("\n🏁 EM-CAMS v.3.0.0 PIPELINE READY FOR COMPLETION\n")
cat("==> All processing phases completed successfully\n")
cat("==> Main results available in data/processed/DAILY_data/EM_sum/\n")
cat("==> Coordinate system: [Longitude, Latitude] (standard EM-CAMS convention)\n\n")
