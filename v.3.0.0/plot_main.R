###############################################################################
# EM-CAMS v.3.0.0 - Plotting Main Interface
###############################################################################
# Description: Interactive main script for plotting emission data
# Author: EM-CAMS Development Team
# Version: 3.0.0
# Date: 2024
###############################################################################

# Load plotting functions
source("plotting_functions.R")

cat("###############################################################################\n")
cat("#                     EM-CAMS v.3.0.0 - PLOTTING TOOL                       #\n")
cat("###############################################################################\n\n")

# List available emission files
em_sum_dir <- "data/processed/DAILY_data/EM_sum"
if (!dir.exists(em_sum_dir)) {
  stop("EM_sum directory not found: ", em_sum_dir)
}

em_files <- list.files(em_sum_dir, pattern = "EM_.*\\.rds$", full.names = TRUE)

if (length(em_files) == 0) {
  stop("No emission files found in ", em_sum_dir)
}

cat("📊 AVAILABLE EMISSION FILES:\n")
cat("============================\n")
for (i in seq_along(em_files)) {
  filename <- basename(em_files[i])
  file_size <- round(file.size(em_files[i]) / 1024 / 1024, 1)
  cat(sprintf("[%2d] %s (%s MB)\n", i, filename, file_size))
}

# Get user choice for file
cat("\n🎯 SELECT EMISSION FILE:\n")
cat("Enter number (1-", length(em_files), "): ")
file_choice <- as.numeric(readline())

if (is.na(file_choice) || file_choice < 1 || file_choice > length(em_files)) {
  stop("Invalid file selection")
}

selected_file <- em_files[file_choice]
cat("Selected:", basename(selected_file), "\n\n")

# Load file to get info
em_data <- readRDS(selected_file)
max_days <- dim(em_data)[3]
dims <- dim(em_data)

# Extract year from filename for context
year_match <- regmatches(basename(selected_file), regexpr("\\b(19|20)\\d{2}\\b", basename(selected_file)))
year <- if (length(year_match) > 0) year_match[1] else "Unknown"

cat("📈 FILE INFORMATION:\n")
cat("====================\n")
cat("Dimensions:", paste(dims, collapse = " x "), "(lon x lat x days)\n")
cat("Year:", year, "\n")
cat("Total days:", max_days, "\n")
cat("Data range: Day 1 to", max_days, "\n")

# Show some date examples
if (year != "Unknown") {
  start_date <- as.Date(paste0(year, "-01-01"))
  cat("Examples:\n")
  cat("  Day 1   = ", format(start_date, "%d %B %Y"), "\n")
  cat("  Day 100 = ", format(start_date + 99, "%d %B %Y"), "\n")
  cat("  Day 200 = ", format(start_date + 199, "%d %B %Y"), "\n")
  if (max_days >= 365) cat("  Day 365 = ", format(start_date + 364, "%d %B %Y"), "\n")
}

# Get day choice
cat("\n📅 SELECT DAY TO PLOT:\n")
cat("======================\n")
cat("Enter:\n")
cat("  - Day number (1-", max_days, ")\n")
cat("  - Date string (YYYY-MM-DD)\n")
cat("  - 'random' for random day\n")
cat("  - 'summer' for day 200 (mid summer)\n")
cat("  - 'winter' for day 15 (mid winter)\n")
cat("\nYour choice: ")
day_input <- readline()

# Process day choice
if (day_input == "random") {
  selected_day <- sample(1:max_days, 1)
  cat("Random day selected:", selected_day, "\n")
} else if (day_input == "summer") {
  selected_day <- min(200, max_days)
  cat("Summer day selected:", selected_day, "\n")
} else if (day_input == "winter") {
  selected_day <- 15
  cat("Winter day selected:", selected_day, "\n")
} else if (grepl("^\\d+$", day_input)) {
  selected_day <- as.numeric(day_input)
  if (selected_day < 1 || selected_day > max_days) {
    stop("Day must be between 1 and ", max_days)
  }
} else if (grepl("^\\d{4}-\\d{2}-\\d{2}$", day_input)) {
  selected_day <- day_input
} else {
  stop("Invalid day format")
}

# Auto-detect pollutant
pollutant <- detect_pollutant(selected_file)

# Plot options
cat("\n🎨 PLOTTING OPTIONS:\n")
cat("====================\n")
cat("[1] Display only\n")
cat("[2] Display and save\n")
cat("[3] Save with custom name\n")
cat("\nEnter choice (1-3): ")
plot_choice <- as.numeric(readline())

save_path <- NULL
if (plot_choice == 2) {
  # Auto-generate filename
  if (is.character(selected_day)) {
    date_part <- gsub("-", "", selected_day)
  } else {
    if (year != "Unknown") {
      date_obj <- as.Date(paste0(year, "-01-01")) + (selected_day - 1)
      date_part <- format(date_obj, "%Y%m%d")
    } else {
      date_part <- sprintf("day%03d", selected_day)
    }
  }
  
  filename <- paste0(tolower(pollutant), "_", date_part, "_", year, ".png")
  filename <- gsub("[^a-zA-Z0-9_.-]", "", filename)  # Remove special characters
  save_path <- file.path("plots", filename)
  
} else if (plot_choice == 3) {
  cat("Enter filename (without extension): ")
  custom_name <- readline()
  save_path <- file.path("plots", paste0(custom_name, ".png"))
}

# Create plots directory if needed
if (!is.null(save_path)) {
  if (!dir.exists("plots")) {
    dir.create("plots", recursive = TRUE)
    cat("Created plots directory\n")
  }
}

# Execute plot
cat("\n🚀 GENERATING PLOT...\n")
cat("========================\n")

tryCatch({
  p <- plot_emissions(
    em_file = selected_file,
    day = selected_day,
    pollutant = pollutant,
    save_path = save_path
  )
  
  cat("\n✅ PLOTTING COMPLETED SUCCESSFULLY!\n")
  
  if (!is.null(save_path)) {
    cat("📁 Plot saved to:", save_path, "\n")
  }
  
}, error = function(e) {
  cat("\n❌ ERROR DURING PLOTTING:\n")
  cat(e$message, "\n")
})

cat("\n" + repeat("=", 80) + "\n")
cat("EM-CAMS Plotting Session Complete\n")
cat(repeat("=", 80) + "\n")
