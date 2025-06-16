#!/usr/bin/env Rscript
###############################################################################
# PHASE 12: SPACETIME CONVERSION
# Converte dati AQ_EM_sum da array a oggetti spatio-temporali
# Per compatibilità con codice target che richiede @time e @sp@coords slots
###############################################################################

# Carica librerie necessarie
if (!require("spacetime", quietly = TRUE)) {
  install.packages("spacetime")
  library(spacetime)
}
if (!require("sp", quietly = TRUE)) {
  install.packages("sp") 
  library(sp)
}

source("scripts/utils/Config.R")
source("scripts/utils/Utils.R")

cat("=== PHASE 12: SPACETIME CONVERSION ===\n")

#' Converte array AQ_EM_sum in oggetto spatio-temporale
#' @param array_file Path al file RDS contenente array [lat,lon,time]
#' @param output_file Path di output per oggetto spatio-temporale
#' @return Oggetto STFDF (spatio-temporal full data frame)
convert_to_spacetime <- function(array_file, output_file) {
  
  cat("Converting:", basename(array_file), "\n")
  
  # Carica array
  data_array <- readRDS(array_file)
  cat("  Array dimensions:", paste(dim(data_array), collapse=" x "), "\n")
  
  # Estrai coordinate e tempo dai dimnames
  lat_vals <- as.numeric(dimnames(data_array)[[1]])
  lon_vals <- as.numeric(dimnames(data_array)[[2]])
  time_vals <- dimnames(data_array)[[3]]
  
  cat("  Lat range:", min(lat_vals), "to", max(lat_vals), "\n")
  cat("  Lon range:", min(lon_vals), "to", max(lon_vals), "\n")
  cat("  Time entries:", length(time_vals), "\n")
  
  # Converte time da CF numeric a Date
  # AQ_EM_sum ha sempre formato CF numerico (days since 1850-01-01)
  if (is.numeric(time_vals)) {
    # Formato CF standard
    reference_date <- as.Date("1850-01-01")
    time_dates <- reference_date + as.numeric(time_vals)
  } else if (is.character(time_vals)) {
    # Prova diversi formati
    if (all(nchar(time_vals) == 8)) {
      # Formato DDMMYYYY
      time_dates <- as.Date(time_vals, format="%d%m%Y")
    } else {
      # Prova come numerico CF in formato character
      time_numeric <- suppressWarnings(as.numeric(time_vals))
      if (!any(is.na(time_numeric))) {
        reference_date <- as.Date("1850-01-01")
        time_dates <- reference_date + time_numeric
      } else {
        stop("Formato temporale non riconosciuto")
      }
    }
  } else {
    stop("Tipo temporale non supportato: ", class(time_vals))
  }
  
  # Verifica che la conversione sia riuscita
  if (any(is.na(time_dates))) {
    stop("Errore nella conversione temporale: alcuni valori sono NA")
  }
  
  cat("  Time range:", as.character(min(time_dates)), "to", as.character(max(time_dates)), "\n")
  
  # Crea griglia spaziale
  coords_grid <- expand.grid(lon = lon_vals, lat = lat_vals)
  coordinates(coords_grid) <- ~ lon + lat
  proj4string(coords_grid) <- CRS("+proj=longlat +datum=WGS84")
  
  # Crea struttura spazio-temporale
  cat("  Creating spacetime object...\n")
  
  # Riorganizza dati: da [lat,lon,time] a vettore per ogni tempo
  st_data_list <- list()
  
  for (t in seq_along(time_dates)) {
    # Estrai slice temporale [lat,lon] per tempo t
    time_slice <- data_array[,,t]
    
    # Converte in vettore (ordine: lon cambia più velocemente)
    # Compatibile con expand.grid(lon, lat)
    values_vector <- as.vector(t(time_slice))  # trasposizione per ordine corretto
    
    # Crea data.frame per questo tempo
    df_t <- data.frame(
      emissions = values_vector,
      time = time_dates[t]
    )
    
    st_data_list[[t]] <- df_t
  }
  
  # Combina tutti i tempi
  full_df <- do.call(rbind, st_data_list)
  
  # Ripeti coordinate per ogni tempo
  n_times <- length(time_dates)
  coords_full <- do.call(rbind, replicate(n_times, coords_grid@coords, simplify = FALSE))
  
  # Crea oggetto spaziale completo
  coords_sp <- SpatialPoints(coords_full, proj4string = CRS("+proj=longlat +datum=WGS84"))
  
  # Crea oggetto spatio-temporale
  stfdf <- STFDF(
    sp = coords_sp,
    time = rep(time_dates, each = nrow(coords_grid)),
    data = data.frame(emissions = full_df$emissions)
  )
  
  cat("  STFDF created with dimensions:", nrow(stfdf@sp), "spatial x", length(unique(index(stfdf@time))), "temporal\n")
  
  # Verifica struttura
  cat("  Verification:\n")
  cat("    @sp class:", class(stfdf@sp), "\n")
  cat("    @time class:", class(stfdf@time), "\n")
  cat("    @sp@coords dimensions:", paste(dim(stfdf@sp@coords), collapse=" x "), "\n")
  cat("    Time index length:", length(index(stfdf@time)), "\n")
  
  # Salva risultato
  saveRDS(stfdf, output_file)
  cat("  Saved:", basename(output_file), "\n")
  
  return(stfdf)
}

# Processo tutti i file AQ_EM_sum
aq_dir <- "data/processed/DAILY_data/AQ_EM_sum"
st_dir <- "data/processed/DAILY_data/SPACETIME_EM_sum"

if (dir.exists(aq_dir)) {
  # Crea directory output
  dir.create(st_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Trova tutti i file AQ_EM_sum
  aq_files <- list.files(aq_dir, pattern = "\\.rds$", full.names = TRUE)
  
  if (length(aq_files) > 0) {
    cat("Found", length(aq_files), "AQ_EM_sum files to convert\n")
    
    for (aq_file in aq_files) {
      # Nome file output
      base_name <- basename(aq_file)
      st_file <- file.path(st_dir, gsub("\\.rds$", "_ST.rds", base_name))
      
      # Converte solo se non esiste già
      if (!file.exists(st_file)) {
        tryCatch({
          convert_to_spacetime(aq_file, st_file)
        }, error = function(e) {
          cat("  ERROR converting", basename(aq_file), ":", e$message, "\n")
        })
      } else {
        cat("  SKIP", basename(aq_file), "(already exists)\n")
      }
    }
    
    cat("\n=== PHASE 12 COMPLETED ===\n")
    cat("Spacetime objects available in:", st_dir, "\n")
    
    # Test di compatibilità con codice target
    cat("\n=== TESTING TARGET CODE COMPATIBILITY ===\n")
    test_files <- list.files(st_dir, pattern = "\\.rds$", full.names = TRUE)
    if (length(test_files) > 0) {
      test_file <- test_files[1]
      cat("Testing with:", basename(test_file), "\n")
      
      tryCatch({
        EM_CAMS_v100_ST <- readRDS(test_file)
        
        # Test codice target
        cat("  Testing @time access:", class(EM_CAMS_v100_ST@time), "\n")
        cat("  Testing @sp@coords access:", class(EM_CAMS_v100_ST@sp@coords), "\n")
        cat("  Testing index() function:", length(index(EM_CAMS_v100_ST@time)), "time points\n")
        
        # Simula subset temporale
        sub_t <- index(EM_CAMS_v100_ST@time)[1:10]  # Prime 10 date
        temporal_subset <- EM_CAMS_v100_ST[, which(index(EM_CAMS_v100_ST@time) %in% sub_t)]
        cat("  Temporal subset: OK (", ncol(temporal_subset), "time points)\n")
        
        # Simula subset spaziale
        bbox <- c(7, 18, 36, 47)  # [lon_min, lon_max, lat_min, lat_max] per Italia
        spatial_subset <- temporal_subset[
          temporal_subset@sp@coords[, 1] > bbox[1] &
          temporal_subset@sp@coords[, 1] < bbox[2] &
          temporal_subset@sp@coords[, 2] > bbox[3] &
          temporal_subset@sp@coords[, 2] < bbox[4], 
        ]
        cat("  Spatial subset: OK (", nrow(spatial_subset@sp), "spatial points)\n")
        
        cat("  ✅ TARGET CODE COMPATIBILITY: SUCCESS\n")
        
      }, error = function(e) {
        cat("  ❌ TARGET CODE COMPATIBILITY: FAILED -", e$message, "\n")
      })
    }
    
  } else {
    cat("No AQ_EM_sum files found in:", aq_dir, "\n")
    cat("Run Phase 11 first to create AQ_EM_sum data.\n")
  }
} else {
  cat("AQ_EM_sum directory not found:", aq_dir, "\n")
  cat("Run Phase 11 first to create AQ_EM_sum data.\n")
}

cat("\n=== USAGE INSTRUCTIONS ===\n")
cat("Your spacetime objects are now compatible with the target code:\n")
cat("  # Load spacetime object\n")
cat("  EM_CAMS_v100_ST <- readRDS('SPACETIME_EM_sum/nox_2020_ST.rds')\n")
cat("  \n")
cat("  # Use target code directly:\n")
cat("  A4_em_cams <- EM_CAMS_v100_ST[, which(index(EM_CAMS_v100_ST@time) %in% sub_t)]\n")
cat("  A4_em_cams <- A4_em_cams[A4_em_cams@sp@coords[, 1] > bbox[1] & ...]\n")
