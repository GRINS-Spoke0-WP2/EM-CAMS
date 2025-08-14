# ExtractANT.R
library(ncdf4)
library(reshape2)
library(abind)
library(lubridate)  # Per estrarre l'anno dalle date

source("Utils.R")
source("Config.R")

# Funzione per estrarre i dati da tutti i settori in un file NetCDF
extractAllSectors <- function(nc_file_path) {
  # Carica i dati di latitudine e longitudine
  lon_lat_data <- readRDS("Data/Processed/lon_lat_idx.rds")
  
  # Apri il file NetCDF
  nc <- open_nc_file(nc_file_path)
  
  # Indici di longitudine e latitudine
  lon_idx <- lon_lat_data$lon_idx
  lat_idx <- lon_lat_data$lat_idx
  
  # Inizializza la lista dei dati per ciascun settore
  sector_data <- list()
  for (key in names(sector_names)) {
    data <- ncvar_get(nc, sector_names[[key]],
                      start = c(min(lon_idx), min(lat_idx), 1), 
                      count = c(length(lon_idx), length(lat_idx), nc$dim$time$len))
    sector_data[[key]] <- data
  }
  
  # Chiudi il file NetCDF
  nc_close(nc)
  
  # Ritorna i dati estratti insieme a longitudine e latitudine selezionate
  return(list(sector_data = sector_data, lon = lon_lat_data$lon[lon_idx], lat = lon_lat_data$lat[lat_idx]))
}

# Funzione per estrarre i dati di un settore specifico per un anno (time-step)
year_sector <- function(data, sector, time_index, num_time_steps) {
  if (num_time_steps == 1) {
    # Se c'è solo un time-step, seleziona l'intero set di dati del settore
    sector_data <- data$sector_data[[sector]][, ]
  } else {
    # Altrimenti seleziona i dati relativi al time-step specificato
    sector_data <- data$sector_data[[sector]][, , time_index]
  }
  
  # Converte i dati in un data frame con colonne x, y e value
  df <- expand.grid(x = data$lon, y = data$lat)
  df$value <- as.vector(sector_data)
  return(df)
}

# Funzione aggiornata per aggiungere i dati dei nuovi anni in base alla versione del file
# La funzione legge la dimensione temporale per dedurne automaticamente la copertura (gli anni)
add_new_years_data_updated <- function(nc_file_path, all_years_data) {
  # Estrae la versione dal nome del file (es. "_v6.1_")
  current_version <- as.numeric(gsub(".*_v([0-9.]+)_.*", "\\1", nc_file_path))
  
  # Estrae i dati dai settori
  new_data <- extractAllSectors(nc_file_path)
  
  # Legge i valori di time e l'attributo units dal NetCDF
  nc <- nc_open(nc_file_path)
  time_vals <- ncvar_get(nc, "time")
  time_units <- nc$dim$time$units  # es: "days since 1850-01-01 00:00"
  nc_close(nc)
  
  # Converte i valori di time in date reali
  # Assumiamo che le unità siano "days since ..." (modificare se necessario)
  origin_date <- as.Date(sub("days since ", "", time_units))
  time_dates <- origin_date + time_vals
  
  # Estrae il vettore degli anni per ogni time-step
  # Se il file è annuale, si assume che ogni time-step corrisponda a un anno
  this_years <- year(time_dates)
  
  # Determina il numero di time-step presenti nel file
  if (is.null(dim(new_data$sector_data[[1]]))) {
    num_time_steps <- 1  
  } else {
    num_time_steps <- dim(new_data$sector_data[[1]])[3]
    if (is.na(num_time_steps)) num_time_steps <- 1
  }
  
  if(length(this_years) != num_time_steps){
    warning("Il numero di time-step dedotto dalle date non corrisponde alla terza dimensione del dato.")
  }
  
  # Per ogni time-step (anno) presente nel file, aggiunge o aggiorna i dati nella lista
  for (i in seq_along(this_years)) {
    this_year <- this_years[i]
    year_data <- list()
    
    for (sector_key in names(new_data$sector_data)) {
      sector_df <- year_sector(new_data, sector_key, i, num_time_steps)
      year_data[[sector_key]] <- sector_df
    }
    
    key <- paste("Year", this_year)
    # Se i dati per quell'anno esistono già, li aggiorna solo se la versione corrente è maggiore
    if (!is.null(all_years_data[[key]])) {
      if (current_version > all_years_data[[key]]$version) {
        all_years_data[[key]] <- list(data = year_data, version = current_version)
      }
    } else {
      all_years_data[[key]] <- list(data = year_data, version = current_version)
    }
  }
  
  return(all_years_data)
}

# Funzione per costruire la matrice 4D dei dati annuali a partire dalla lista degli anni
build_yearly_matrix <- function(all_data_list, lon_lat_idx) {
  all_data_matrix <- NULL
  
  for (year in 1:length(all_data_list)) {
    year_matrix <- NULL
    
    for (sector in all_data_list[[year]]) {
      # Riorganizza i dati con la funzione dcast (da formato long a matrice)
      dcast_matrix <- dcast(sector, x ~ y, value.var = "value")
      value_matrix <- as.matrix(dcast_matrix[,-1])
      year_matrix <- abind(year_matrix, value_matrix, along = 3)
    }
    
    # Combina le matrici di tutti gli anni lungo la quarta dimensione
    all_data_matrix <- abind(all_data_matrix, year_matrix, along = 4)
  }
  
  # Arrotonda le coordinate (opzionale)
  lon_rounded <- round(lon_lat_idx$lon[lon_lat_idx$lon_idx], 2)
  lat_rounded <- round(lon_lat_idx$lat[lon_lat_idx$lat_idx], 2)
  
  # Assegna i nomi delle dimensioni alla matrice
  dimnames(all_data_matrix) <- list(
    x = lon_lat_idx$lon[lon_lat_idx$lon_idx],
    y = lon_lat_idx$lat[lon_lat_idx$lat_idx],
    sector = names(sector_names),
    year = names(all_data_list)
  )
  
  return(all_data_matrix)
}

# Funzione per estrarre i dati da tutti i settori presenti in un file CSV
extractAllSectorsCSV <- function(csv_file_path, pollutant, countryISO3) {
  data <- read.csv(csv_file_path, header = TRUE)
  data <- data[data$ISO3 == countryISO3, ]
  data <- data[data$POLL == pollutant, ]
  return(data)
}
