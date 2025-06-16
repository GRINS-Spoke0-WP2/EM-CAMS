###############################################################################
# EM-CAMS v.3.0.0 - Emissions Plotting Tool
###############################################################################
# Description: Standardized tool for plotting daily emissions from processed data
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
###############################################################################

library(ggplot2)
library(viridis)

#' Plot daily emissions from EM-CAMS processed data
#' 
#' @param file_path Path to the .rds file containing emission data
#' @param date Date in format "YYYY-MM-DD" or day index (1-365/366)
#' @param pollutant Name of pollutant for labeling (e.g., "NOx", "PM2.5")
#' @param unit_conversion Conversion factor for units (default: 1e6 * 60 * 60 * 24 for kg/m²/s to g/m²/day)
#' @param save_path Optional path to save the plot (e.g., "plot.png")
#' @param width Plot width in inches (default: 10)
#' @param height Plot height in inches (default: 8)
#' @param dpi Resolution for saved plots (default: 300)
#' @param log_scale Use log10 scale for emissions (default: TRUE)
#' @param title_override Custom title (if NULL, auto-generated)
#' 
#' @return ggplot object
#' 
#' @examples
#' # Plot using date
plot_emissions("data/processed/DAILY_data/EM_sum/EM_NOx_2019.rds", 
               date = "2019-01-16", pollutant = "NOx")
#' 
#' # Plot using day index
#' plot_emissions("data/processed/DAILY_data/EM_sum/EM_NOx_2019.rds", 
#'                date = 16, pollutant = "NOx")
#' 
#' # Save plot
#' plot_emissions("data/processed/DAILY_data/EM_sum/EM_NOx_2019.rds", 
#'                date = "2019-01-16", pollutant = "NOx", 
#'                save_path = "nox_emissions_jan16.png")
plot_emissions <- function(file_path, 
                          date, 
                          pollutant = "Emissions",
                          unit_conversion = 1e6 * 60 * 60 * 24,
                          save_path = NULL,
                          width = 10,
                          height = 8,
                          dpi = 300,
                          log_scale = TRUE,
                          title_override = NULL) {
  
  # Verify file exists
  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }
  
  cat("Loading emissions data from:", file_path, "\n")
  
  # Load the data
  tryCatch({
    data_matrix <- readRDS(file_path)
  }, error = function(e) {
    stop("Error loading file: ", e$message)
  })
  
  # Verify data structure
  if (!is.array(data_matrix) || length(dim(data_matrix)) != 3) {
    stop("Data must be a 3D array (lon x lat x time)")
  }
  
  cat("Data dimensions:", paste(dim(data_matrix), collapse = " x "), "\n")
  
  # Convert date to day index if needed
  day_index <- convert_date_to_index(date, data_matrix)
  
  # Extract year from filename or date
  year <- extract_year_from_input(file_path, date)
  
  # Extract daily data slice
  daily_data <- data_matrix[, , day_index]
  
  # Apply unit conversion
  daily_data <- daily_data * unit_conversion
  
  # Extract coordinates from dimnames
  if (is.null(dimnames(data_matrix))) {
    # Generate default coordinates if dimnames are missing
    lon_vals <- seq_along(dim(data_matrix)[1])
    lat_vals <- seq_along(dim(data_matrix)[2])
    warning("No coordinate information found. Using indices as coordinates.")
  } else {
    lon_vals <- as.numeric(dimnames(data_matrix)[[1]])
    lat_vals <- as.numeric(dimnames(data_matrix)[[2]])
  }
  
  # Create dataframe for plotting
  df <- expand.grid(
    lon = lon_vals,
    lat = lat_vals
  )
  df$value <- as.vector(daily_data)
  
  # Remove zero/negative values if using log scale
  if (log_scale) {
    df$value[df$value <= 0] <- NA
    valid_data <- !is.na(df$value)
    cat("Valid data points:", sum(valid_data), "out of", nrow(df), "\n")
  }
  
  # Generate date string for title
  date_str <- format_date_for_title(date, day_index, year)
  
  # Create title
  if (is.null(title_override)) {
    title <- paste(pollutant, "Emissions -", date_str)
  } else {
    title <- title_override
  }
  
  # Create the plot
  p <- ggplot(df, aes(x = lon, y = lat, fill = value)) +
    geom_tile() +
    {if (log_scale) scale_fill_viridis_c(name = paste(pollutant, "\n(g/m²/day)"), 
                                        trans = "log10", 
                                        na.value = "grey90") 
     else scale_fill_viridis_c(name = paste(pollutant, "\n(g/m²/day)"), 
                              na.value = "grey90")} +
    coord_fixed(1.3) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
      axis.text = element_text(size = 10),
      axis.title = element_text(size = 12),
      legend.title = element_text(size = 10),
      legend.text = element_text(size = 9)
    ) +
    labs(
      title = title,
      x = "Longitude",
      y = "Latitude"
    )
  
  # Add data statistics to subtitle
  if (log_scale && any(!is.na(df$value))) {
    stats_text <- sprintf("Range: %.2e - %.2e g/m²/day", 
                         min(df$value, na.rm = TRUE), 
                         max(df$value, na.rm = TRUE))
    p <- p + labs(subtitle = stats_text)
  }
  
  # Save or display
  if (!is.null(save_path)) {
    cat("Saving plot to:", save_path, "\n")
    ggsave(save_path, plot = p, dpi = dpi, width = width, height = height)
    cat("Plot saved successfully!\n")
  } else {
    print(p)
  }
  
  return(p)
}

#' Convert date input to day index
convert_date_to_index <- function(date, data_matrix) {
  if (is.numeric(date)) {
    # Already a day index
    if (date < 1 || date > dim(data_matrix)[3]) {
      stop("Day index ", date, " out of range (1-", dim(data_matrix)[3], ")")
    }
    return(date)
  } else if (is.character(date)) {
    # Parse date string
    tryCatch({
      parsed_date <- as.Date(date)
      year <- as.numeric(format(parsed_date, "%Y"))
      day_of_year <- as.numeric(format(parsed_date, "%j"))
      
      # Verify day is within data range
      if (day_of_year > dim(data_matrix)[3]) {
        stop("Day ", day_of_year, " exceeds data range (", dim(data_matrix)[3], " days)")
      }
      
      cat("Date:", date, "-> Day", day_of_year, "of year", year, "\n")
      return(day_of_year)
    }, error = function(e) {
      stop("Invalid date format. Use 'YYYY-MM-DD' or numeric day index (1-365/366)")
    })
  } else {
    stop("Date must be numeric (day index) or character string (YYYY-MM-DD)")
  }
}

#' Extract year from filename or date
extract_year_from_input <- function(file_path, date) {
  # Try to extract year from filename first
  filename <- basename(file_path)
  year_match <- regmatches(filename, regexpr("\\b(19|20)\\d{2}\\b", filename))
  
  if (length(year_match) > 0) {
    return(year_match[1])
  }
  
  # Try to extract from date if it's a string
  if (is.character(date)) {
    tryCatch({
      parsed_date <- as.Date(date)
      return(format(parsed_date, "%Y"))
    }, error = function(e) {
      return("Unknown")
    })
  }
  
  return("Unknown")
}

#' Format date for plot title
format_date_for_title <- function(date, day_index, year) {
  if (is.character(date)) {
    tryCatch({
      parsed_date <- as.Date(date)
      return(format(parsed_date, "%d %b %Y"))
    }, error = function(e) {
      return(paste("Day", day_index, "of", year))
    })
  } else {
    # Convert day index to approximate date
    if (year != "Unknown") {
      tryCatch({
        start_date <- as.Date(paste0(year, "-01-01"))
        target_date <- start_date + (day_index - 1)
        return(format(target_date, "%d %b %Y"))
      }, error = function(e) {
        return(paste("Day", day_index, "of", year))
      })
    } else {
      return(paste("Day", day_index))
    }
  }
}

#' Quick plot function for common use cases
#' 
#' @param file_path Path to emission data file
#' @param date Date or day index
#' @param save_name Optional filename for saving (auto-generates path)
#' 
#' @examples
#' quick_plot("data/processed/DAILY_data/EM_sum/EM_NOx_2019.rds", "2019-01-16")
#' quick_plot("data/processed/DAILY_data/EM_sum/EM_NOx_2019.rds", 16, "nox_jan16")
quick_plot <- function(file_path, date, save_name = NULL) {
  # Extract pollutant from filename
  filename <- basename(file_path)
  pollutant <- "Emissions"
  
  if (grepl("NOx|nox", filename, ignore.case = TRUE)) {
    pollutant <- "NOₓ"
  } else if (grepl("PM2\\.5|pm2_5", filename, ignore.case = TRUE)) {
    pollutant <- "PM₂.₅"
  } else if (grepl("PM10|pm10", filename, ignore.case = TRUE)) {
    pollutant <- "PM₁₀"
  } else if (grepl("SO2|sox|so2", filename, ignore.case = TRUE)) {
    pollutant <- "SOₓ"
  } else if (grepl("NH3|nh3", filename, ignore.case = TRUE)) {
    pollutant <- "NH₃"
  } else if (grepl("CO2|co2", filename, ignore.case = TRUE)) {
    pollutant <- "CO₂"
  } else if (grepl("CO|co", filename, ignore.case = TRUE)) {
    pollutant <- "CO"
  } else if (grepl("NMVOC|nmvoc", filename, ignore.case = TRUE)) {
    pollutant <- "NMVOC"
  } else if (grepl("CH4|ch4", filename, ignore.case = TRUE)) {
    pollutant <- "CH₄"
  }
  
  # Generate save path if requested
  save_path <- NULL
  if (!is.null(save_name)) {
    if (!grepl("\\.(png|jpg|jpeg|pdf)$", save_name, ignore.case = TRUE)) {
      save_name <- paste0(save_name, ".png")
    }
    save_path <- file.path("plots", save_name)
    
    # Create plots directory if it doesn't exist
    if (!dir.exists("plots")) {
      dir.create("plots", recursive = TRUE)
    }
  }
  
  # Call main plotting function
  plot_emissions(file_path, date, pollutant, save_path = save_path)
}

#' Fix dimnames of emission data using correct coordinates from lon_lat_idx.rds
#' 
#' @param data_array 3D array with emission data [lon, lat, time]
#' @param coords_file Path to the coordinate file (default: "data/processed/lon_lat_idx.rds")
#' @param verbose Print diagnostic information (default: TRUE)
#' 
#' @return 3D array with corrected dimnames
#' 
#' @examples
#' # Load emission data
#' em_data <- readRDS("data/processed/DAILY_data/EM_sum/EM_NOx_2019.rds")
#' 
#' # Fix dimnames
#' em_data_fixed <- fix_dimnames_from_coords(em_data)
#' 
#' # Check the difference
#' head(dimnames(em_data)[[1]])  # wrong coordinates
#' head(dimnames(em_data_fixed)[[1]])  # correct coordinates
fix_dimnames_from_coords <- function(data_array, 
                                   coords_file = "data/processed/lon_lat_idx.rds",
                                   verbose = TRUE) {
  
  # Verify input is a 3D array
  if (!is.array(data_array) || length(dim(data_array)) != 3) {
    stop("Input must be a 3D array (lon x lat x time)")
  }
  
  # Get array dimensions
  dims <- dim(data_array)
  n_lon <- dims[1]
  n_lat <- dims[2]
  n_time <- dims[3]
  
  if (verbose) {
    cat("=== FIXING DIMNAMES ===\n")
    cat("Array dimensions:", paste(dims, collapse = " x "), "\n")
  }
  
  # Verify coordinate file exists
  if (!file.exists(coords_file)) {
    stop("Coordinate file not found: ", coords_file)
  }
  
  # Load coordinate data
  if (verbose) cat("Loading coordinates from:", coords_file, "\n")
  coords <- readRDS(coords_file)
  
  # Verify coordinate structure
  if (!is.list(coords) || !all(c("lon", "lat") %in% names(coords))) {
    stop("Coordinate file must contain 'lon' and 'lat' elements")
  }
  
  lon_coords <- coords$lon
  lat_coords <- coords$lat
  
  if (verbose) {
    cat("Available coordinates:\n")
    cat("  Lon range:", min(lon_coords), "to", max(lon_coords), "(", length(lon_coords), "points )\n")
    cat("  Lat range:", min(lat_coords), "to", max(lat_coords), "(", length(lat_coords), "points )\n")
  }
  
  # Check dimension compatibility
  if (length(lon_coords) < n_lon) {
    stop("Not enough longitude coordinates (", length(lon_coords), ") for array dimension (", n_lon, ")")
  }
  if (length(lat_coords) < n_lat) {
    stop("Not enough latitude coordinates (", length(lat_coords), ") for array dimension (", n_lat, ")")
  }
  
  # Extract the subset of coordinates that match array dimensions
  # Use the first n_lon and n_lat coordinates to respect boundaries
  lon_subset <- lon_coords[1:n_lon]
  lat_subset <- lat_coords[1:n_lat]
  
  if (verbose) {
    cat("Using coordinate subsets:\n")
    cat("  Lon subset:", min(lon_subset), "to", max(lon_subset), "(", length(lon_subset), "points )\n")
    cat("  Lat subset:", min(lat_subset), "to", max(lat_subset), "(", length(lat_subset), "points )\n")
  }
  
  # Create time dimension names (keep existing if available, otherwise generate)
  if (!is.null(dimnames(data_array)) && !is.null(dimnames(data_array)[[3]])) {
    time_names <- dimnames(data_array)[[3]]
    if (verbose) cat("Preserving existing time dimension names\n")
  } else {
    time_names <- paste0("day_", 1:n_time)
    if (verbose) cat("Generated time dimension names: day_1 to day_", n_time, "\n")
  }
  
  # Assign corrected dimnames
  dimnames(data_array) <- list(
    lon = as.character(lon_subset),
    lat = as.character(lat_subset),
    time = time_names
  )
  
  if (verbose) {
    cat("=== DIMNAMES FIXED ===\n")
    cat("New lon range:", dimnames(data_array)[[1]][1], "to", 
        dimnames(data_array)[[1]][n_lon], "\n")
    cat("New lat range:", dimnames(data_array)[[2]][1], "to", 
        dimnames(data_array)[[2]][n_lat], "\n")
    
    # Check for regular spacing
    lon_diff <- diff(as.numeric(dimnames(data_array)[[1]])[1:min(10, n_lon)])
    lat_diff <- diff(as.numeric(dimnames(data_array)[[2]])[1:min(10, n_lat)])
    cat("Lon spacing (first 10):", paste(round(lon_diff, 4), collapse = ", "), "\n")
    cat("Lat spacing (first 10):", paste(round(lat_diff, 4), collapse = ", "), "\n")
  }
  
  return(data_array)
}

#' Fix dimnames of emission file and save corrected version
#' 
#' @param input_file Path to input .rds file
#' @param output_file Path to save corrected file (if NULL, overwrites input)
#' @param coords_file Path to coordinate file
#' @param verbose Print diagnostic information
#' 
#' @return Path to the corrected file
#' 
#' @examples
#' # Fix a single file
#' fix_emission_file_dimnames("data/processed/DAILY_data/EM_sum/EM_NOx_2019.rds")
#' 
#' # Fix and save to new location
#' fix_emission_file_dimnames("data/processed/DAILY_data/EM_sum/EM_NOx_2019.rds",
#'                           "data/processed/DAILY_data/EM_sum/EM_NOx_2019_fixed.rds")
fix_emission_file_dimnames <- function(input_file, 
                                     output_file = NULL,
                                     coords_file = "data/processed/lon_lat_idx.rds",
                                     verbose = TRUE) {
  
  # Verify input file exists
  if (!file.exists(input_file)) {
    stop("Input file not found: ", input_file)
  }
  
  if (verbose) cat("Loading emission data from:", input_file, "\n")
  
  # Load emission data
  em_data <- readRDS(input_file)
  
  # Fix dimnames
  em_data_fixed <- fix_dimnames_from_coords(em_data, coords_file, verbose)
  
  # Determine output file
  if (is.null(output_file)) {
    output_file <- input_file
    if (verbose) cat("Overwriting original file\n")
  } else {
    if (verbose) cat("Saving to new file:", output_file, "\n")
  }
  
  # Save corrected data
  saveRDS(em_data_fixed, output_file)
  
  if (verbose) {
    file_size <- file.size(output_file)
    cat("File saved successfully (", round(file_size/1024/1024, 1), "MB )\n")
  }
  
  return(output_file)
}

#' Batch fix dimnames for multiple emission files
#' 
#' @param input_pattern Glob pattern for input files (e.g., "data/processed/DAILY_data/EM_sum/EM_NOx_*.rds")
#' @param coords_file Path to coordinate file
#' @param backup Create backup files (default: TRUE)
#' @param verbose Print progress information
#' 
#' @return Vector of processed file paths
#' 
#' @examples
#' # Fix all NOx files
#' batch_fix_emission_dimnames("data/processed/DAILY_data/EM_sum/EM_NOx_*.rds")
#' 
#' # Fix all emission files
#' batch_fix_emission_dimnames("data/processed/DAILY_data/EM_sum/EM_*.rds")
batch_fix_emission_dimnames <- function(input_pattern,
                                      coords_file = "data/processed/lon_lat_idx.rds",
                                      backup = TRUE,
                                      verbose = TRUE) {
  
  # Find matching files
  files <- Sys.glob(input_pattern)
  
  if (length(files) == 0) {
    stop("No files found matching pattern: ", input_pattern)
  }
  
  if (verbose) {
    cat("=== BATCH FIXING DIMNAMES ===\n")
    cat("Found", length(files), "files to process\n")
  }
  
  processed_files <- character(0)
  
  for (i in seq_along(files)) {
    file <- files[i]
    
    if (verbose) {
      cat("\n[", i, "/", length(files), "] Processing:", basename(file), "\n")
    }
    
    tryCatch({
      # Create backup if requested
      if (backup) {
        backup_file <- paste0(file, ".backup")
        if (!file.exists(backup_file)) {
          file.copy(file, backup_file)
          if (verbose) cat("  Backup created:", basename(backup_file), "\n")
        }
      }
      
      # Fix dimnames
      output_file <- fix_emission_file_dimnames(file, NULL, coords_file, verbose = FALSE)
      processed_files <- c(processed_files, output_file)
      
      if (verbose) cat("  ✅ Successfully processed\n")
      
    }, error = function(e) {
      if (verbose) cat("  ❌ Error:", e$message, "\n")
    })
  }
  
  if (verbose) {
    cat("\n=== BATCH PROCESSING COMPLETE ===\n")
    cat("Successfully processed:", length(processed_files), "files\n")
    cat("Failed:", length(files) - length(processed_files), "files\n")
  }
  
  return(processed_files)
}

###############################################################################
# USAGE EXAMPLES
###############################################################################

cat("EM-CAMS Emissions Plotting Tool loaded!\n")
cat("\nUsage examples:\n")
cat("1. Basic plot:\n")
cat('   plot_emissions("data/processed/DAILY_data/EM_sum/EM_NOx_2019.rds", "2019-01-16", "NOₓ")\n')
cat("\n2. Using day index:\n")
cat('   plot_emissions("data/processed/DAILY_data/EM_sum/EM_NOx_2019.rds", 16, "NOₓ")\n')
cat("\n3. Save plot:\n")
cat('   plot_emissions("data/processed/DAILY_data/EM_sum/EM_NOx_2019.rds", "2019-01-16", "NOₓ", save_path="nox_plot.png")\n')
cat("\n4. Quick plot:\n")
cat('   quick_plot("data/processed/DAILY_data/EM_sum/EM_NOx_2019.rds", "2019-01-16")\n')
cat('   quick_plot("data/processed/DAILY_data/EM_sum/EM_NOx_2019.rds", 16, "nox_jan16")\n')
