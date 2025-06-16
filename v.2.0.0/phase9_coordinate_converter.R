###############################################################################
# EM-CAMS v.2.0.0 - Phase 9: Interactive Coordinate Converter
###############################################################################
# Description: Interactive menu to convert coordinate order from [LON, LAT] to [LAT, LON]
#              for selected datasets and pollutants
# Author: EM-CAMS Development Team
# Version: 2.0.0
# Date: 2024
###############################################################################

# Start phase timer
start_time_phase9 <- Sys.time()
cat("Starting Phase 9: Interactive Coordinate Converter [LON, LAT] → [LAT, LON]\n")

# Load required libraries
library(abind)

# Load coordinate converter
source("coordinate_converter.R")

# Define data directories
ant_data_dir <- "Data/Processed/ANT_data"
daily_data_dir <- "Data/Processed/DAILY_data"
tempo_data_dir <- "Data/Processed/TEMPO_data"

#' Function to discover available data files
discover_data_files <- function() {
  cat("\n🔍 Scanning for available data files...\n")
  
  data_files <- list()
  
  # 1. ANT data files (yearly and monthly)
  if(dir.exists(ant_data_dir)) {
    ant_files <- list.files(ant_data_dir, pattern = "\\.rds$", full.names = TRUE)
    for(f in ant_files) {
      name <- basename(f)
      poll <- NA
      
      # Extract pollutant from filename
      if(grepl("_([a-z0-9_]+)\\.rds$", name)) {
        poll <- gsub(".*_([a-z0-9_]+)\\.rds$", "\\1", name)
      }
      
      data_files[[length(data_files) + 1]] <- list(
        file = f,
        name = name,
        type = "ANT",
        pollutant = poll,
        category = ifelse(grepl("yearly", name), "ANT_yearly", 
                         ifelse(grepl("monthly", name), "ANT_monthly", "ANT_other"))
      )
    }
  }
  
  # 2. Daily data files (EM_sum is most commonly converted)
  em_sum_dir <- file.path(daily_data_dir, "EM_sum")
  if(dir.exists(em_sum_dir)) {
    sum_files <- list.files(em_sum_dir, pattern = "\\.rds$", full.names = TRUE, recursive = TRUE)
    for(f in sum_files) {
      name <- basename(f)
      poll <- NA
      
      # Extract pollutant from filename
      if(grepl("_([a-z0-9_]+)_", name) || grepl("_([a-z0-9_]+)\\.rds$", name)) {
        poll <- gsub(".*_([a-z0-9_]+)(?:_.*|\\.rds)$", "\\1", name)
      }
      
      data_files[[length(data_files) + 1]] <- list(
        file = f,
        name = name,
        type = "DAILY",
        pollutant = poll,
        category = "EM_sum"
      )
    }
  }
  
  # 3. Other daily data categories
  other_daily_dirs <- c("DailyAlongYears", "DailyFromGLOB", "SimplifiedDailyData")
  for(dir_name in other_daily_dirs) {
    dir_path <- file.path(daily_data_dir, dir_name)
    if(dir.exists(dir_path)) {
      files <- list.files(dir_path, pattern = "\\.rds$", full.names = TRUE, recursive = TRUE)
      for(f in files) {
        name <- basename(f)
        poll <- NA
        
        if(grepl("_([a-z0-9_]+)_", name) || grepl("_([a-z0-9_]+)\\.rds$", name)) {
          poll <- gsub(".*_([a-z0-9_]+)(?:_.*|\\.rds)$", "\\1", name)
        }
        
        data_files[[length(data_files) + 1]] <- list(
          file = f,
          name = name,
          type = "DAILY",
          pollutant = poll,
          category = dir_name
        )
      }
    }
  }
  
  return(data_files)
}

#' Function to show interactive menu for data category selection
show_category_menu <- function(data_files) {
  cat("\n📂 STEP 1: Select Data Category\n")
  cat(paste(rep("=", 40), collapse=""), "\n")
  
  # Group by category
  categories <- unique(sapply(data_files, function(x) x$category))
  categories <- categories[!is.na(categories)]
  categories <- sort(categories)
  
  for(i in seq_along(categories)) {
    count <- sum(sapply(data_files, function(x) x$category == categories[i]))
    cat(sprintf("%d. %s (%d files)\n", i, categories[i], count))
  }
  cat(sprintf("%d. All categories\n", length(categories) + 1))
  cat("0. Exit\n")
  
  choice <- as.integer(readline("Select category (number): "))
  
  if(is.na(choice) || choice < 0 || choice > length(categories) + 1) {
    cat("❌ Invalid selection\n")
    return(NULL)
  }
  
  if(choice == 0) return("exit")
  if(choice == length(categories) + 1) return("all")
  
  return(categories[choice])
}

#' Function to show pollutant selection menu
show_pollutant_menu <- function(data_files, selected_category = NULL) {
  cat("\n🧪 STEP 2: Select Pollutant\n")
  cat(paste(rep("=", 40), collapse=""), "\n")
  
  # Filter by category if specified
  if(!is.null(selected_category) && selected_category != "all") {
    data_files <- data_files[sapply(data_files, function(x) x$category == selected_category)]
  }
  
  # Get unique pollutants
  pollutants <- unique(sapply(data_files, function(x) x$pollutant))
  pollutants <- pollutants[!is.na(pollutants)]
  pollutants <- sort(pollutants)
  
  if(length(pollutants) == 0) {
    cat("❌ No pollutants found for selected category\n")
    return(NULL)
  }
  
  for(i in seq_along(pollutants)) {
    count <- sum(sapply(data_files, function(x) x$pollutant == pollutants[i] && !is.na(x$pollutant)))
    cat(sprintf("%d. %s (%d files)\n", i, toupper(pollutants[i]), count))
  }
  cat(sprintf("%d. All pollutants\n", length(pollutants) + 1))
  cat("0. Back to category selection\n")
  
  choice <- as.integer(readline("Select pollutant (number): "))
  
  if(is.na(choice) || choice < 0 || choice > length(pollutants) + 1) {
    cat("❌ Invalid selection\n")
    return(NULL)
  }
  
  if(choice == 0) return("back")
  if(choice == length(pollutants) + 1) return("all")
  
  return(pollutants[choice])
}

#' Function to show file selection menu
show_file_menu <- function(data_files, selected_category = NULL, selected_pollutant = NULL) {
  cat("\n📄 STEP 3: Select Files to Convert\n")
  cat(paste(rep("=", 40), collapse=""), "\n")
  
  # Filter by category and pollutant
  filtered_files <- data_files
  
  if(!is.null(selected_category) && selected_category != "all") {
    filtered_files <- filtered_files[sapply(filtered_files, function(x) x$category == selected_category)]
  }
  
  if(!is.null(selected_pollutant) && selected_pollutant != "all") {
    filtered_files <- filtered_files[sapply(filtered_files, function(x) x$pollutant == selected_pollutant)]
  }
  
  if(length(filtered_files) == 0) {
    cat("❌ No files found matching criteria\n")
    return(NULL)
  }
  
  # Show files
  for(i in seq_along(filtered_files)) {
    f <- filtered_files[[i]]
    size_mb <- round(file.size(f$file) / (1024^2), 2)
    cat(sprintf("%d. %s [%s] (%.2f MB)\n", i, f$name, f$category, size_mb))
  }
  cat(sprintf("%d. All listed files\n", length(filtered_files) + 1))
  cat("0. Back to pollutant selection\n")
  
  choice <- readline("Select files (numbers separated by commas, or single number): ")
  
  if(choice == "0") return("back")
  if(choice == as.character(length(filtered_files) + 1)) return(filtered_files)
  
  # Parse multiple selections
  choices <- tryCatch({
    as.integer(strsplit(choice, ",")[[1]])
  }, error = function(e) {
    cat("❌ Invalid selection format\n")
    return(NULL)
  })
  
  if(is.null(choices) || any(is.na(choices)) || any(choices < 1) || any(choices > length(filtered_files))) {
    cat("❌ Invalid file selection\n")
    return(NULL)
  }
  
  return(filtered_files[choices])
}

#' Main function to convert selected files
convert_selected_files <- function(selected_files) {
  cat("\n🔄 STEP 4: Converting Coordinates\n")
  cat(paste(rep("=", 50), collapse=""), "\n")
  
  if(length(selected_files) == 0) {
    cat("❌ No files selected for conversion\n")
    return(FALSE)
  }
  
  # Create output directory
  output_dir <- "Data/Processed/CONVERTED_LAT_LON"
  if(!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    cat("📁 Created output directory:", output_dir, "\n")
  }
  
  conversion_summary <- list()
  
  for(i in seq_along(selected_files)) {
    file_info <- selected_files[[i]]
    cat(sprintf("\n[%d/%d] Converting: %s\n", i, length(selected_files), file_info$name))
    
    tryCatch({
      # Load data
      cat("   📥 Loading data...\n")
      data <- readRDS(file_info$file)
      
      # Show original dimensions
      if(is.array(data) || is.matrix(data)) {
        cat("   📐 Original dimensions:", paste(dim(data), collapse=" × "), "\n")
        if(!is.null(dimnames(data))) {
          cat("   🏷️  Dimension names:", paste(names(dimnames(data)), collapse=", "), "\n")
        }
      }
      
      # Convert coordinates
      cat("   🔄 Converting [LON, LAT] → [LAT, LON]...\n")
      converted_data <- convert_lon_lat_to_lat_lon(data, verbose = FALSE)
      
      # Show converted dimensions  
      if(is.array(converted_data) || is.matrix(converted_data)) {
        cat("   📐 Converted dimensions:", paste(dim(converted_data), collapse=" × "), "\n")
      }
      
      # Save converted data
      output_file <- file.path(output_dir, paste0("LATLON_", file_info$name))
      saveRDS(converted_data, output_file)
      
      cat("   💾 Saved to:", basename(output_file), "\n")
      cat("   ✅ Conversion completed successfully\n")
      
      conversion_summary[[length(conversion_summary) + 1]] <- list(
        original = file_info$file,
        converted = output_file,
        status = "success"
      )
      
    }, error = function(e) {
      cat("   ❌ Error during conversion:", e$message, "\n")
      conversion_summary[[length(conversion_summary) + 1]] <- list(
        original = file_info$file,
        converted = NA,
        status = "error",
        error = e$message
      )
    })
  }
  
  return(conversion_summary)
}

# Main interactive workflow
cat("\n🎯 EM-CAMS Interactive Coordinate Converter\n")
cat("   Convert data from [LON, LAT] to [LAT, LON] order\n")
cat(paste(rep("=", 60), collapse=""), "\n")

# Step 1: Discover available data
data_files <- discover_data_files()

if(length(data_files) == 0) {
  cat("❌ No data files found in processed directories\n")
  cat("   Check that you have run the previous phases\n")
  return()
}

cat(sprintf("✅ Found %d data files across all categories\n", length(data_files)))

# Interactive menu loop
repeat {
  # Step 2: Category selection
  selected_category <- show_category_menu(data_files)
  if(is.null(selected_category)) next
  if(selected_category == "exit") break
  
  repeat {
    # Step 3: Pollutant selection  
    selected_pollutant <- show_pollutant_menu(data_files, selected_category)
    if(is.null(selected_pollutant)) next
    if(selected_pollutant == "back") break
    
    repeat {
      # Step 4: File selection
      selected_files <- show_file_menu(data_files, selected_category, selected_pollutant)
      if(is.null(selected_files)) next
      if(identical(selected_files, "back")) break
      
      # Step 5: Confirmation
      cat("\n📋 CONVERSION SUMMARY\n")
      cat(paste(rep("=", 30), collapse=""), "\n")
      cat("Category:", ifelse(is.null(selected_category) || selected_category == "all", "All", selected_category), "\n")
      cat("Pollutant:", ifelse(is.null(selected_pollutant) || selected_pollutant == "all", "All", toupper(selected_pollutant)), "\n")
      cat("Files to convert:", length(selected_files), "\n")
      
      confirm <- readline("\nProceed with conversion? (y/n): ")
      if(tolower(confirm) %in% c("y", "yes", "si", "s")) {
        
        # Perform conversion
        results <- convert_selected_files(selected_files)
        
        # Show final summary
        successes <- sum(sapply(results, function(x) x$status == "success"))
        errors <- sum(sapply(results, function(x) x$status == "error"))
        
        cat("\n📊 FINAL SUMMARY\n")
        cat(paste(rep("=", 30), collapse=""), "\n")
        cat("✅ Successful conversions:", successes, "\n")
        cat("❌ Failed conversions:", errors, "\n")
        
        if(successes > 0) {
          cat("📁 Output directory: Data/Processed/CONVERTED_LAT_LON/\n")
        }
      } else {
        cat("❌ Conversion cancelled\n")
      }
      
      # Ask if user wants to convert more files
      more <- readline("\nConvert more files? (y/n): ")
      if(!tolower(more) %in% c("y", "yes", "si", "s")) {
        break
      }
    }
    
    if(!tolower(more) %in% c("y", "yes", "si", "s")) break
  }
  
  if(!tolower(more) %in% c("y", "yes", "si", "s")) break
}

# Phase completion summary
end_time_phase9 <- Sys.time()
phase9_duration <- difftime(end_time_phase9, start_time_phase9, units = "secs")

cat("\n==> PHASE 9 COMPLETED\n")
cat("==> Processing time:", round(phase9_duration, 2), "seconds\n")
cat("==> Coordinate conversion session finished\n\n")
