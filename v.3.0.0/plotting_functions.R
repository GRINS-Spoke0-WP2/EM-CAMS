###############################################################################
# EM-CAMS v.3.0.0 - Plotting Functions
###############################################################################
# Description: Core plotting functions for emission data visualization
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
###############################################################################

library(ggplot2)
library(viridis)
library(reshape2)

#' Plot emissions using correct coordinates from lon_lat_idx.rds
#' 
#' @param em_file Path to emission .rds file
#' @param day Day to plot (1-365/366 or date string "YYYY-MM-DD")
#' @param pollutant Pollutant name for title
#' @param coords_file Path to coordinate file
#' @param unit_conversion Unit conversion factor (default: kg/m²/s to g/m²/day)
#' @param log_scale Use log10 scale (default: TRUE)
#' @param save_path Optional path to save plot
#' @param width Plot width in inches
#' @param height Plot height in inches
#' @param dpi Plot resolution
#' 
#' @return ggplot object
plot_emissions <- function(em_file, 
                          day, 
                          pollutant = "Emissions",
                          coords_file = "data/processed/lon_lat_idx.rds",
                          unit_conversion = 1e6 * 60 * 60 * 24,
                          log_scale = TRUE,
                          save_path = NULL,
                          width = 12,
                          height = 8,
                          dpi = 300) {
  
  cat("=== PLOTTING EMISSIONS ===\n")
  
  # Verify emission file exists
  if (!file.exists(em_file)) stop("Emission file not found: ", em_file)
  
  # Load emission data
  cat("Loading emission data:", basename(em_file), "\n")
  em_data <- readRDS(em_file)
  
  # Load coordinate data only if needed (fallback)
  coords <- NULL
  if (file.exists(coords_file)) {
    cat("Coordinate file available:", basename(coords_file), "\n")
    coords <- readRDS(coords_file)
  }
  
  # Verify data structure
  if (!is.array(em_data) || length(dim(em_data)) != 3) {
    stop("Emission data must be 3D array (lon x lat x time)")
  }
  
  dims <- dim(em_data)
  cat("Data dimensions:", paste(dims, collapse = " x "), "\n")
  
  # Convert day to index if needed
  day_index <- convert_day_to_index(day, dims[3], em_file)
  
  # Extract day data
  day_data <- em_data[, , day_index]
  
  # Apply unit conversion
  day_data <- day_data * unit_conversion
  
  # Use coordinates from dimnames if available, otherwise fallback to coordinate file
  if (!is.null(dimnames(em_data)) && !is.null(dimnames(em_data)[[1]]) && !is.null(dimnames(em_data)[[2]])) {
    # Use existing dimnames from emission data
    lon_coords <- as.numeric(dimnames(em_data)[[1]])
    lat_coords <- as.numeric(dimnames(em_data)[[2]])
    cat("Using coordinates from emission file dimnames\n")
  } else {
    # Fallback to coordinate file
    if (is.null(coords)) {
      stop("No coordinates available: emission file has no dimnames and coordinate file not found")
    }
    if (!is.list(coords) || !all(c("lon", "lat", "lon_idx", "lat_idx") %in% names(coords))) {
      stop("Coordinate file must contain lon, lat, lon_idx, lat_idx")
    }
    lon_coords <- coords$lon[coords$lon_idx][1:dims[1]]
    lat_coords <- coords$lat[coords$lat_idx][1:dims[2]]
    cat("Using coordinates from coordinate file\n")
  }
  
  cat("Coordinate ranges:\n")
  cat("  Longitude:", min(lon_coords), "to", max(lon_coords), "\n")
  cat("  Latitude:", min(lat_coords), "to", max(lat_coords), "\n")
  
  # Create plotting dataframe
  df <- expand.grid(
    lon = lon_coords,
    lat = lat_coords
  )
  df$value <- as.vector(day_data)
  
  # Handle log scale
  if (log_scale) {
    df$value[df$value <= 0] <- NA
    valid_points <- sum(!is.na(df$value))
    cat("Valid data points for log scale:", valid_points, "out of", nrow(df), "\n")
  }
  
  # Generate title
  date_str <- format_day_for_title(day, day_index, em_file)
  title <- paste(pollutant, "Emissions -", date_str)
  
  # Statistics
  if (any(!is.na(df$value))) {
    stats_text <- sprintf("Range: %.2e - %.2e g/m²/day | Valid points: %d", 
                         min(df$value, na.rm = TRUE), 
                         max(df$value, na.rm = TRUE),
                         sum(!is.na(df$value)))
  } else {
    stats_text <- "No valid data points"
  }
  
  # Create plot
  p <- ggplot(df, aes(x = lon, y = lat, fill = value)) +
    geom_tile() +
    {if (log_scale) 
      scale_fill_viridis_c(name = paste(pollutant, "\n(g/m²/day)"), 
                          trans = "log10", 
                          na.value = "grey90") 
     else 
      scale_fill_viridis_c(name = paste(pollutant, "\n(g/m²/day)"), 
                          na.value = "grey90")} +
    coord_fixed(1.3) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
      plot.subtitle = element_text(hjust = 0.5, size = 10),
      axis.text = element_text(size = 10),
      axis.title = element_text(size = 12),
      legend.title = element_text(size = 11),
      legend.text = element_text(size = 9),
      panel.grid = element_line(color = "white", size = 0.2)
    ) +
    labs(
      title = title,
      subtitle = stats_text,
      x = "Longitude",
      y = "Latitude"
    )
  
  # Save or display
  if (!is.null(save_path)) {
    cat("Saving plot to:", save_path, "\n")
    
    # Create directory if needed
    save_dir <- dirname(save_path)
    if (!dir.exists(save_dir)) {
      dir.create(save_dir, recursive = TRUE)
    }
    
    ggsave(save_path, plot = p, dpi = dpi, width = width, height = height)
    cat("Plot saved successfully!\n")
  }
  
  print(p)
  return(p)
}

#' Convert day input to array index
convert_day_to_index <- function(day, max_days, em_file) {
  if (is.numeric(day)) {
    if (day < 1 || day > max_days) {
      stop("Day index ", day, " out of range (1-", max_days, ")")
    }
    cat("Using day index:", day, "\n")
    return(day)
  } else if (is.character(day)) {
    # Try to parse as date
    tryCatch({
      parsed_date <- as.Date(day)
      year <- as.numeric(format(parsed_date, "%Y"))
      day_of_year <- as.numeric(format(parsed_date, "%j"))
      
      if (day_of_year > max_days) {
        stop("Day ", day_of_year, " exceeds data range (", max_days, " days)")
      }
      
      cat("Date:", day, "-> Day", day_of_year, "of year", year, "\n")
      return(day_of_year)
    }, error = function(e) {
      stop("Invalid date format. Use 'YYYY-MM-DD' or numeric day index (1-365/366)")
    })
  } else {
    stop("Day must be numeric (day index) or character string (YYYY-MM-DD)")
  }
}

#' Format day for plot title
format_day_for_title <- function(day, day_index, em_file) {
  # Extract year from filename
  year_match <- regmatches(basename(em_file), regexpr("\\b(19|20)\\d{2}\\b", basename(em_file)))
  year <- if (length(year_match) > 0) year_match[1] else "Unknown"
  
  if (is.character(day)) {
    tryCatch({
      parsed_date <- as.Date(day)
      return(format(parsed_date, "%d %B %Y"))
    }, error = function(e) {
      return(paste("Day", day_index, "of", year))
    })
  } else {
    # Convert day index to date if year is known
    if (year != "Unknown") {
      tryCatch({
        start_date <- as.Date(paste0(year, "-01-01"))
        target_date <- start_date + (day_index - 1)
        return(format(target_date, "%d %B %Y"))
      }, error = function(e) {
        return(paste("Day", day_index, "of", year))
      })
    } else {
      return(paste("Day", day_index))
    }
  }
}

#' Auto-detect pollutant from filename
detect_pollutant <- function(filename) {
  filename <- tolower(basename(filename))
  
  if (grepl("nox", filename)) return("NOₓ")
  if (grepl("pm2[._]5|pm25", filename)) return("PM₂.₅")
  if (grepl("pm10", filename)) return("PM₁₀")
  if (grepl("so2|sox", filename)) return("SOₓ")
  if (grepl("nh3", filename)) return("NH₃")
  if (grepl("co2", filename)) return("CO₂")
  if (grepl("co", filename)) return("CO")
  if (grepl("nmvoc", filename)) return("NMVOC")
  if (grepl("ch4", filename)) return("CH₄")
  
  return("Emissions")
}

#' Quick plot with auto-detection
quick_plot <- function(em_file, day, save_name = NULL) {
  pollutant <- detect_pollutant(em_file)
  
  save_path <- NULL
  if (!is.null(save_name)) {
    if (!grepl("\\.(png|jpg|jpeg|pdf)$", save_name, ignore.case = TRUE)) {
      save_name <- paste0(save_name, ".png")
    }
    save_path <- file.path("plots", save_name)
  }
  
  plot_emissions(em_file, day, pollutant, save_path = save_path)
}

cat("EM-CAMS Plotting Functions loaded!\n")
cat("Main function: plot_emissions(em_file, day, pollutant)\n")
cat("Quick function: quick_plot(em_file, day, save_name)\n")
