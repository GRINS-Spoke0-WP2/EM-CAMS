###############################################################################
# EM-CAMS v.3.0.0 - Emissions Plotting Tool
###############################################################################
# Description: Standardized plotting tool for visualizing daily emissions data
#              from EM-CAMS pipeline output files
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
###############################################################################

# Load required libraries
library(ggplot2)
library(viridis)
library(scales)

###############################################################################
# Main Plotting Function
###############################################################################

plot_emissions_day <- function(file_path, date, 
                              pollutant = NULL,
                              title = NULL, 
                              save_path = NULL,
                              units = "kg/m²/day",
                              conversion_factor = 1e6 * 60 * 60 * 24,
                              log_scale = TRUE,
                              width = 10, height = 8) {
  
  # Validate inputs
  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }
  
  # Load the emissions data
  cat("Loading emissions data from:", basename(file_path), "\n")
  data_matrix <- readRDS(file_path)
  
  # Extract year from filename if not provided
  if (is.null(pollutant)) {
    filename <- basename(file_path)
    if (grepl("EM_(.+)_(\\d{4})\\.rds", filename)) {
      pollutant <- gsub("EM_(.+)_(\\d{4})\\.rds", "\\1", filename)
    } else {
      pollutant <- "Unknown"
    }
  }
  
  # Convert date to day index
  if (is.character(date)) {
    # Parse date string (e.g., "2020-01-16" or "16-01-2020")
    if (grepl("^\\d{4}-\\d{2}-\\d{2}$", date)) {
      parsed_date <- as.Date(date)
    } else if (grepl("^\\d{2}-\\d{2}-\\d{4}$", date)) {
      parsed_date <- as.Date(date, format = "%d-%m-%Y")
    } else {
      stop("Date format not recognized. Use 'YYYY-MM-DD' or 'DD-MM-YYYY'")
    }
    
    # Extract year from date
    year <- format(parsed_date, "%Y")
    
    # Calculate day of year
    day_index <- as.numeric(format(parsed_date, "%j"))
    
  } else if (is.numeric(date)) {
    # Assume it's already day index
    day_index <- date
    year <- "Unknown"
  } else {
    stop("Date must be either a string ('YYYY-MM-DD') or numeric day index")
  }
  
  # Validate day index
  if (day_index < 1 || day_index > dim(data_matrix)[3]) {
    stop("Day index ", day_index, " out of range (1-", dim(data_matrix)[3], ")")
  }
  
  # Extract daily data
  daily_data <- data_matrix[,, day_index]
  
  # Apply conversion factor
  daily_data <- daily_data * conversion_factor
  
  # Extract coordinates from dimnames
  lon_vals <- as.numeric(dimnames(data_matrix)[[1]])
  lat_vals <- as.numeric(dimnames(data_matrix)[[2]])
  
  # Create dataframe for plotting
  df <- expand.grid(
    lon = lon_vals,
    lat = lat_vals
  )
  df$value <- as.vector(daily_data)
  
  # Remove zero/negative values for log scale
  if (log_scale) {
    df$value[df$value <= 0] <- NA
    valid_data <- df$value[!is.na(df$value)]
    if (length(valid_data) == 0) {
      stop("No positive values found for log scale plotting")
    }
  }
  
  # Create title if not provided
  if (is.null(title)) {
    if (is.character(date)) {
      title <- paste0(toupper(pollutant), " Emissions - ", format(parsed_date, "%d %B %Y"))
    } else {
      title <- paste0(toupper(pollutant), " Emissions - Day ", day_index, " (", year, ")")
    }
  }
  
  # Create the plot
  p <- ggplot(df, aes(x = lon, y = lat, fill = value)) +
    geom_tile() +
    coord_fixed(ratio = 1.3) +
    theme_minimal() +
    theme(
      panel.background = element_rect(fill = "white"),
      plot.title = element_text(size = 14, hjust = 0.5),
      axis.title = element_text(size = 12),
      legend.title = element_text(size = 11),
      legend.text = element_text(size = 10)
    ) +
    labs(
      title = title,
      x = "Longitude (°E)",
      y = "Latitude (°N)",
      fill = paste("Emissions\n(", units, ")")
    )
  
  # Apply color scale
  if (log_scale) {
    p <- p + scale_fill_viridis_c(
      name = paste("Emissions\n(", units, ")"),
      trans = "log10",
      labels = trans_format("log10", math_format(10^.x)),
      na.value = "grey90"
    )
  } else {
    p <- p + scale_fill_viridis_c(
      name = paste("Emissions\n(", units, ")"),
      na.value = "grey90"
    )
  }
  
  # Print summary statistics
  cat("\nEmissions Summary:\n")
  cat("Date:", if(is.character(date)) date else paste("Day", day_index), "\n")
  cat("Pollutant:", toupper(pollutant), "\n")
  cat("Total emissions:", format(sum(df$value, na.rm = TRUE), scientific = TRUE), units, "\n")
  cat("Max emissions:", format(max(df$value, na.rm = TRUE), scientific = TRUE), units, "\n")
  cat("Min emissions:", format(min(df$value, na.rm = TRUE), scientific = TRUE), units, "\n")
  cat("Non-zero cells:", sum(df$value > 0, na.rm = TRUE), "out of", nrow(df), "\n")
  
  # Save or display
  if (!is.null(save_path)) {
    cat("Saving plot to:", save_path, "\n")
    ggsave(save_path, plot = p, dpi = 300, width = width, height = height)
    cat("Plot saved successfully!\n")
  } else {
    print(p)
  }
  
  return(p)
}

###############################################################################
# Convenience Functions
###############################################################################

# Plot multiple days for comparison
plot_emissions_comparison <- function(file_paths, dates, titles = NULL, save_path = NULL) {
  
  if (length(file_paths) != length(dates)) {
    stop("file_paths and dates must have the same length")
  }
  
  plots <- list()
  
  for (i in seq_along(file_paths)) {
    title <- if (!is.null(titles)) titles[i] else NULL
    plots[[i]] <- plot_emissions_day(
      file_path = file_paths[i],
      date = dates[i],
      title = title,
      save_path = NULL  # Don't save individual plots
    )
  }
  
  # Combine plots (requires gridExtra or patchwork)
  if (requireNamespace("gridExtra", quietly = TRUE)) {
    combined_plot <- gridExtra::grid.arrange(grobs = plots, ncol = 2)
    
    if (!is.null(save_path)) {
      ggsave(save_path, combined_plot, width = 16, height = 12, dpi = 300)
    }
  } else {
    warning("gridExtra package not found. Displaying plots individually.")
    lapply(plots, print)
  }
  
  return(plots)
}

# Quick plot function for EM-CAMS output files
plot_em_cams <- function(year, pollutant, date, data_dir = "data/processed/DAILY_data/EM_sum") {
  
  file_path <- file.path(data_dir, paste0("EM_", pollutant, "_", year, ".rds"))
  
  if (!file.exists(file_path)) {
    # Try alternative file naming
    alt_files <- list.files(data_dir, pattern = paste0(".*", pollutant, ".*", year, ".*\\.rds"), 
                           full.names = TRUE, ignore.case = TRUE)
    if (length(alt_files) > 0) {
      file_path <- alt_files[1]
      cat("Using alternative file:", basename(file_path), "\n")
    } else {
      stop("No emissions file found for ", pollutant, " in ", year)
    }
  }
  
  plot_emissions_day(file_path = file_path, date = date, pollutant = pollutant)
}

###############################################################################
# Example Usage
###############################################################################

# Uncomment and modify these lines to test the functions:

# # Plot a specific day from EM-CAMS output
# plot_em_cams(
#   year = 2020,
#   pollutant = "NOx", 
#   date = "2020-01-16"
# )
# 
# # Plot with custom settings
# plot_emissions_day(
#   file_path = "data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds",
#   date = "2020-07-15",
#   title = "Summer NOx Emissions - July 15, 2020",
#   save_path = "nox_summer_2020.png",
#   log_scale = TRUE
# )
# 
# # Compare different years
# plot_emissions_comparison(
#   file_paths = c(
#     "data/processed/DAILY_data/EM_sum/EM_NOx_2000.rds",
#     "data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds"
#   ),
#   dates = c("2000-01-16", "2020-01-16"),
#   titles = c("NOx Emissions - 2000", "NOx Emissions - 2020"),
#   save_path = "nox_comparison_2000_vs_2020.png"
# )

cat("EM-CAMS Plotting Tool loaded successfully!\n")
cat("Main function: plot_emissions_day(file_path, date)\n")
cat("Quick function: plot_em_cams(year, pollutant, date)\n")
cat("Use help(plot_emissions_day) for more details.\n")
