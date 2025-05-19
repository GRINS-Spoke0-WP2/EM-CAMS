# ------------------------------------------------------------------------------
# File: ComputeNormalDaily.R
# ------------------------------------------------------------------------------
# Contiene la funzione principale per il calcolo giornaliero con i profili FD_...
# (Codice originale estratto da "Compute.R")
# ------------------------------------------------------------------------------

calculate_from_FD <- function(PollutantName, yearly_data_file, temporal_profile_folder, output_folder, sector) {
  # Definisci la cartella dove si trovano i dati annuali
  yearly_data_folder <- "Data/Processed/ANT_data"
  
  # Costruisci il nome del file yearly_data automaticamente in base al pollutant (case-sensitive)
  yearly_data_file <- file.path(yearly_data_folder, paste0("REG_ANT_yearly_data_", tolower(PollutantName), ".rds"))
  
  # Carica i dati annuali
  if (!file.exists(yearly_data_file)) {
    stop(paste("Il file yearly data per il pollutant", PollutantName, "non è stato trovato."))
  }
  
  yearly_data_all <- readRDS(yearly_data_file)
  
  # Costruisci il percorso alla cartella che corrisponde al settore
  sector_folder <- file.path(temporal_profile_folder, "DailyProfiles", sector)
  
  # Costruisci automaticamente il pattern per il profilo in base al settore
  profile_pattern <- paste0("D_", sector, "_")
  
  # Ottieni i file all'interno della cartella del settore corrispondente
  TempoFiles <- list.files(sector_folder, pattern = profile_pattern)
  
  # Ottieni i dati annuali per il settore desiderato
  yearly_data <- yearly_data_all[,,sector,]
  
  # Estrai il numero di anni dalla dimensione della matrice annuale
  num_years <- dim(yearly_data)[3]
  
  # L'anno di partenza è il 2000
  start_year <- 2000
  
  # Cicla sugli anni per calcolare i dati giornalieri
  for (year in start_year:(start_year + num_years - 1)) {
    
    # Cerca i file che iniziano con FD_, settore, anno e ignora tutto ciò che segue l'anno
    matching_file <- Sys.glob(file.path(sector_folder, paste0("D_", sector, "_", year, "*.rds")))
    
    # Controlla se esiste un file corrispondente
    if (length(matching_file) == 0) {
      next
    }
    
    # Carica i dati del profilo
    profile_data <- readRDS(matching_file)
    
    # Estrai il numero di giorni dal profilo
    num_days <- dim(profile_data)[3]
    
    # Crea un array per i dati giornalieri
    daily_data <- array(NA, c(dim(yearly_data)[1], dim(yearly_data)[2], num_days),
                        list(dimnames(yearly_data)[[1]], dimnames(yearly_data)[[2]], 1:num_days))
    
    # Cicla sui giorni per calcolare i dati giornalieri
    for (d in 1:num_days) {
      y <- year - start_year + 1
      day_data <- yearly_data[,,y] * profile_data[,,d]
      daily_data[,,d] <- day_data
    }
    
    # Salva i dati giornalieri in un file .rds
    daily_data_file <- file.path(output_folder, paste0("Daily_", sector, "_", year, "_", PollutantName, ".rds"))
    saveRDS(daily_data, daily_data_file)
    
    # Libera la memoria
    rm(daily_data)
  }
}
