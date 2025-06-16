###############################################################################
# EM-CAMS v.3.0.0 - Time Conversion Functions
###############################################################################
# Description: Functions to convert time dimnames from DDMMYYYY format to 
#              CF standard (days since reference date)
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
###############################################################################

#' Convert time dimnames from DDMMYYYY format to CF standard
#' 
#' @param input_file Path to input .rds file with emission data
#' @param output_file Path to save converted file (if NULL, overwrites input)
#' @param reference_date Reference date for CF standard (default: "1850-01-01")
#' @param backup Create backup before overwriting (default: TRUE)
#' @param verbose Print progress information (default: FALSE)
#' 
#' @return Path to the converted file
#' 
#' @examples
#' # Convert to new file
#' ConvertTimeDimnames("EM_NOx_2022.rds", "EM_NOx_2022_CF.rds")
#' 
#' # Overwrite original with backup
#' ConvertTimeDimnames("EM_NOx_2022.rds", backup = TRUE)
ConvertTimeDimnames <- function(input_file, 
                               output_file = NULL,
                               reference_date = "1850-01-01",
                               backup = TRUE,
                               verbose = FALSE) {
  
  if (verbose) cat("=== CONVERTING TIME DIMNAMES ===\n")
  
  # Verify input file exists
  if (!file.exists(input_file)) {
    stop("Input file not found: ", input_file)
  }
  
  # Determine output file
  if (is.null(output_file)) {
    output_file <- input_file
  }
  
  # Create backup if requested and overwriting
  if (backup && output_file == input_file) {
    backup_file <- paste0(input_file, ".backup")
    if (!file.exists(backup_file)) {
      file.copy(input_file, backup_file)
      if (verbose) cat("Backup created:", basename(backup_file), "\n")
    }
  }
  
  if (verbose) {
    cat("Input file:", basename(input_file), "\n")
    cat("Output file:", basename(output_file), "\n")
    cat("Reference date:", reference_date, "\n")
  }
  
  # Load emission data
  if (verbose) cat("Loading emission data...\n")
  em_data <- readRDS(input_file)
  
  # Verify data structure
  if (!is.array(em_data) || length(dim(em_data)) != 3) {
    stop("Data must be a 3D array (lon x lat x time)")
  }
  
  dims <- dim(em_data)
  if (verbose) cat("Data dimensions:", paste(dims, collapse = " x "), "\n")
  
  # Check if dimnames exist
  if (is.null(dimnames(em_data)) || is.null(dimnames(em_data)[[3]])) {
    stop("No time dimnames found in the data")
  }
  
  time_names <- dimnames(em_data)[[3]]
  if (verbose) {
    cat("Original time format sample:", head(time_names, 3), "...\n")
    cat("Total time steps:", length(time_names), "\n")
  }
  
  # Convert time dimnames
  if (verbose) cat("Converting time format...\n")
  converted_times <- ConvertDDMMYYYYToCF(time_names, reference_date, verbose = verbose)
  
  # Update dimnames
  dimnames(em_data)[[3]] <- as.character(converted_times)
  
  if (verbose) {
    cat("New time format sample:", head(as.character(converted_times), 3), "...\n")
    cat("Time range:", min(converted_times), "to", max(converted_times), "days since", reference_date, "\n")
  }
  
  # Save converted data
  if (verbose) cat("Saving converted data...\n")
  saveRDS(em_data, output_file)
  
  # Verify file was saved
  if (file.exists(output_file)) {
    file_size <- round(file.size(output_file) / 1024 / 1024, 1)
    if (verbose) cat("File saved successfully (", file_size, "MB )\n")
  } else {
    stop("Failed to save output file")
  }
  
  return(output_file)
}

#' Convert DDMMYYYY date strings to CF standard (days since reference)
#' 
#' @param date_strings Vector of date strings in DDMMYYYY format
#' @param reference_date Reference date as string (YYYY-MM-DD)
#' @param verbose Print conversion details
#' 
#' @return Numeric vector of days since reference date
ConvertDDMMYYYYToCF <- function(date_strings, reference_date = "1850-01-01", verbose = FALSE) {
  
  # Parse reference date
  ref_date <- as.Date(reference_date)
  if (is.na(ref_date)) {
    stop("Invalid reference date format. Use YYYY-MM-DD")
  }
  
  if (verbose) cat("Converting", length(date_strings), "dates to CF format...\n")
  
  # Convert DDMMYYYY strings to Date objects
  parsed_dates <- tryCatch({
    # Extract day, month, year from DDMMYYYY format
    days <- as.numeric(substr(date_strings, 1, 2))
    months <- as.numeric(substr(date_strings, 3, 4))
    years <- as.numeric(substr(date_strings, 5, 8))
    
    # Create Date objects
    as.Date(paste(years, months, days, sep = "-"))
  }, error = function(e) {
    stop("Error parsing DDMMYYYY format: ", e$message)
  })
  
  # Check for invalid dates
  invalid_dates <- is.na(parsed_dates)
  if (any(invalid_dates)) {
    stop("Invalid dates found: ", paste(date_strings[invalid_dates][1:min(5, sum(invalid_dates))], collapse = ", "))
  }
  
  # Calculate days since reference
  cf_days <- as.numeric(parsed_dates - ref_date)
  
  if (verbose) {
    cat("Date range:", min(parsed_dates), "to", max(parsed_dates), "\n")
    cat("CF range:", min(cf_days), "to", max(cf_days), "days since", reference_date, "\n")
  }
  
  return(cf_days)
}

#' Verify time conversion was successful
#' 
#' @param file_path Path to converted emission file
#' @param verbose Print verification details
#' 
#' @return TRUE if verification passes, FALSE otherwise
VerifyTimeConversion <- function(file_path, verbose = FALSE) {
  
  if (!file.exists(file_path)) {
    if (verbose) cat("❌ File not found:", file_path, "\n")
    return(FALSE)
  }
  
  if (verbose) cat("Verifying:", basename(file_path), "\n")
  
  tryCatch({
    # Load data
    em_data <- readRDS(file_path)
    
    # Check structure
    if (!is.array(em_data) || length(dim(em_data)) != 3) {
      if (verbose) cat("❌ Invalid data structure\n")
      return(FALSE)
    }
    
    # Check time dimnames
    if (is.null(dimnames(em_data)) || is.null(dimnames(em_data)[[3]])) {
      if (verbose) cat("❌ No time dimnames found\n")
      return(FALSE)
    }
    
    time_names <- dimnames(em_data)[[3]]
    
    # Check if numeric (CF format)
    cf_values <- suppressWarnings(as.numeric(time_names))
    if (any(is.na(cf_values))) {
      if (verbose) cat("❌ Time dimnames are not numeric (CF format)\n")
      return(FALSE)
    }
    
    # Check if values are reasonable (should be positive and large)
    if (any(cf_values < 0) || max(cf_values) < 50000) {
      if (verbose) cat("❌ CF values seem unreasonable\n")
      return(FALSE)
    }
    
    if (verbose) {
      cat("✅ Verification passed\n")
      cat("  Time steps:", length(time_names), "\n")
      cat("  CF range:", min(cf_values), "to", max(cf_values), "\n")
      cat("  Sample values:", paste(head(cf_values, 3), collapse = ", "), "...\n")
    }
    
    return(TRUE)
    
  }, error = function(e) {
    if (verbose) cat("❌ Error during verification:", e$message, "\n")
    return(FALSE)
  })
}

#' Batch convert multiple emission files
#' 
#' @param input_pattern Glob pattern for input files
#' @param output_folder Output folder (if NULL, overwrites originals)
#' @param reference_date Reference date for CF conversion
#' @param backup Create backups when overwriting
#' @param verbose Print progress information
#' 
#' @return Vector of successfully processed files
BatchConvertTimeDimnames <- function(input_pattern,
                                   output_folder = NULL,
                                   reference_date = "1850-01-01",
                                   backup = TRUE,
                                   verbose = TRUE) {
  
  # Find input files
  input_files <- Sys.glob(input_pattern)
  
  if (length(input_files) == 0) {
    stop("No files found matching pattern: ", input_pattern)
  }
  
  if (verbose) {
    cat("=== BATCH TIME CONVERSION ===\n")
    cat("Found", length(input_files), "files to process\n")
    if (!is.null(output_folder)) cat("Output folder:", output_folder, "\n")
  }
  
  # Create output folder if specified
  if (!is.null(output_folder) && !dir.exists(output_folder)) {
    dir.create(output_folder, recursive = TRUE)
    if (verbose) cat("Created output folder\n")
  }
  
  processed_files <- character(0)
  
  for (i in seq_along(input_files)) {
    input_file <- input_files[i]
    filename <- basename(input_file)
    
    if (verbose) cat("\n[", i, "/", length(input_files), "] Processing:", filename, "\n")
    
    tryCatch({
      # Determine output file
      if (is.null(output_folder)) {
        output_file <- input_file
      } else {
        output_file <- file.path(output_folder, filename)
      }
      
      # Convert
      ConvertTimeDimnames(
        input_file = input_file,
        output_file = output_file,
        reference_date = reference_date,
        backup = backup,
        verbose = FALSE
      )
      
      processed_files <- c(processed_files, output_file)
      if (verbose) cat("  ✅ Success\n")
      
    }, error = function(e) {
      if (verbose) cat("  ❌ Error:", e$message, "\n")
    })
  }
  
  if (verbose) {
    cat("\n=== BATCH CONVERSION COMPLETE ===\n")
    cat("Successfully processed:", length(processed_files), "files\n")
    cat("Failed:", length(input_files) - length(processed_files), "files\n")
  }
  
  return(processed_files)
}

cat("Time Conversion Functions loaded!\n")
cat("Main function: ConvertTimeDimnames(input_file, output_file)\n")
cat("Batch function: BatchConvertTimeDimnames(input_pattern, output_folder)\n")
