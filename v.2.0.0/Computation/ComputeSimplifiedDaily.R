# ------------------------------------------------------------------------------
# File: ComputeSimplifiedDaily.R
# ------------------------------------------------------------------------------
# Contiene la funzione principale per il calcolo giornaliero con i profili
# "semplificati" (Codice originale estratto da "ComputeSimple.R")
# ------------------------------------------------------------------------------

DailyDataFromSimplified <- function(yearlyData, start_year, end_year, pollutant_name) {
  
  dimYearlyData <- dim(yearlyData)
  
  # Get the sector names and year names from yearlyData
  sector_names_yearly <- dimnames(yearlyData)[[3]]  
  year_names_str <- dimnames(yearlyData)[[4]]   
  
  # Extract numeric year values
  year_names <- as.numeric(sub("Year ", "", year_names_str))
  
  # Create a folder for the pollutant if it doesn't already exist
  pollutant_folder <- file.path("Data/Processed/DAILY_data/SimplifiedDailyData", pollutant_name)
  if (!dir.exists(pollutant_folder)) {
    dir.create(pollutant_folder, recursive = TRUE)
  }
  
  # Loop over the years
  for (year in start_year:end_year) {
    
    # Check if the current year exists in yearlyData
    if (year %in% year_names) {
      year_idx <- which(year_names == year)
    } else {
      message(paste("Year", year, "not found in yearlyData."))
      next  # Skip to the next year if not found
    }
    
    # Define the path to the simplified profile for the current pollutant and year
    simplified_profile_path <- file.path("Data/Processed/TEMPO_data/DailySimplifiedProfiles", pollutant_name, paste0("S_D_all_", year, "_", pollutant_name, ".rds"))
    
    # Check if the profile exists
    if (!file.exists(simplified_profile_path)) {
      message(paste("Simplified profile for", pollutant_name, "in year", year, "not found. Skipping..."))
      next  # Skip this year if the profile is not found
    }
    
    # Read the simplified profile for the current year
    simplifiedProfile <- readRDS(simplified_profile_path)
    sector_names_simplified <- colnames(simplifiedProfile)
    
    days <- dim(simplifiedProfile)[1]  # Number of days in the simplified profile
    
    # Iterate over sectors
    for (sector in sector_names_yearly) {
      
      # Initialize matrix DailyData
      DailyData <- array(0, dim = c(dimYearlyData[1], dimYearlyData[2], days))  # Reset DailyData for each sector
      
      if (sector %in% sector_names_simplified) {
        
        # Compute daily data
        for (day in 1:days) {
          DailyData[,,day] <- DailyData[,,day] + yearlyData[,,sector,year_idx] * simplifiedProfile[day, sector]
        }
        
        # Save data in RDS format inside the pollutant folder
        output_file <- file.path(pollutant_folder, paste0("D_", sector, "_", year, ".rds"))
        saveRDS(DailyData, output_file)
        
        # Free memory
        gc()
        
      } else {
        message(paste("Sector", sector, "not found in simplified profiles for year", year))
      }
    }
    
    # Free memory by year
    gc()
  }
}
