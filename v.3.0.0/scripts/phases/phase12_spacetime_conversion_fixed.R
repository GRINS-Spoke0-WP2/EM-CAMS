#!/usr/bin/env Rscript
###############################################################################
# PHASE 12: SPACETIME CONVERSION (FIXED VERSION)
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

cat("=== PHASE 12: SPACETIME CONVERSION (FIXED) ===\n")

#' Converte array AQ_EM_sum in oggetto spazio-temporale
#' @param array_file Path al file RDS contenente array [lat,lon,time]
#' @param output_file Path di output per oggetto spazio-temporale
#' @return Oggetto STFDF (spatio-temporal full data frame)
convert_to_spacetime_fixed <- function(array_file, output_file) {
  
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
  cat("  Time entries:", length(time_vals), "type:", class(time_vals), "\n")
  
  # Debug valori temporali
  cat("  Time samples:", head(time_vals, 3), "...", tail(time_vals, 1), "\n")
  
  # Conversione temporale robusta
  time_dates <- NULL
  
  # Caso 1: Valori numerici (formato CF)
  if (is.numeric(time_vals)) {
    reference_date <- as.Date("1850-01-01")
    time_dates <- reference_date + as.numeric(time_vals)
    cat("  Time conversion: CF numeric format\n")
  }
  # Caso 2: Valori character (potrebbero essere CF o DDMMYYYY)
  else if (is.character(time_vals)) {
    # Prova prima conversione numerica CF
    time_numeric <- suppressWarnings(as.numeric(time_vals))
    if (!any(is.na(time_numeric))) {
      reference_date <- as.Date("1850-01-01")
      time_dates <- reference_date + time_numeric
      cat("  Time conversion: CF character format\n")
    }
    # Se fallisce, prova formato DDMMYYYY
    else if (all(nchar(time_vals) == 8)) {
      time_dates <- as.Date(time_vals, format="%d%m%Y")
      cat("  Time conversion: DDMMYYYY format\n")
    }
    else {
      stop("Unknown time format in character vector")
    }
  }
  else {
    stop("Unsupported time type: ", class(time_vals))
  }
  
  # Verifica conversione temporale
  if (is.null(time_dates) || any(is.na(time_dates))) {
    cat("  ERROR: Time conversion failed\n")
    cat("  Original time type:", class(time_vals), "\n")
    cat("  Original samples:", head(time_vals, 5), "\n")
    if (!is.null(time_dates)) {
      cat("  Converted samples:", head(time_dates, 5), "\n")
      cat("  NA count:", sum(is.na(time_dates)), "out of", length(time_dates), "\n")
    }
    stop("Time conversion contains NA values")
  }
  
  cat("  ✓ Time range:", as.character(min(time_dates)), "to", as.character(max(time_dates)), "\n")
  
  # Crea griglia spaziale
  coords_grid <- expand.grid(lon = lon_vals, lat = lat_vals)
  coordinates(coords_grid) <- ~ lon + lat
  proj4string(coords_grid) <- CRS("+proj=longlat +datum=WGS84")
  
  # Riorganizza dati in formato lungo (versione efficiente)
  cat("  Reorganizing data to long format...\n")
  
  n_spatial <- nrow(coords_grid)
  n_temporal <- length(time_dates)
  total_rows <- n_spatial * n_temporal
  
  # Pre-alloca vettori
  emissions_vec <- numeric(total_rows)
  time_vec <- rep(time_dates, each = n_spatial)
  coords_mat <- do.call(rbind, replicate(n_temporal, coords_grid@coords, simplify = FALSE))
  
  # Riempi vettore emissioni
  row_idx <- 1
  for (t in seq_along(time_dates)) {
    time_slice <- data_array[,,t]
    values_vector <- as.vector(t(time_slice))  # trasposizione per ordine lon-lat corretto
    
    end_idx <- row_idx + n_spatial - 1
    emissions_vec[row_idx:end_idx] <- values_vector
    row_idx <- end_idx + 1
  }
  
  # Crea oggetto spaziale
  coords_sp <- SpatialPoints(coords_mat, proj4string = CRS("+proj=longlat +datum=WGS84"))
  
  # Crea oggetto spatio-temporale
  cat("  Creating STFDF object...\n")
  
  stfdf <- STFDF(
    sp = coords_sp,
    time = time_vec,
    data = data.frame(emissions = emissions_vec)
  )
  
  cat("  ✅ STFDF created successfully!\n")
  cat("     Spatial points:", n_spatial, "\n")
  cat("     Temporal points:", n_temporal, "\n")
  cat("     Total records:", nrow(stfdf), "\n")
  cat("     Data range:", round(range(stfdf@data$emissions, na.rm=TRUE), 4), "\n")
  
  # Salva risultato
  saveRDS(stfdf, output_file)
  cat("  💾 Saved:", basename(output_file), "\n")
  
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
    
    # Processa massimo 3 file per test
    test_files <- head(aq_files, 3)
    cat("Processing first", length(test_files), "files for testing...\n")
    
    success_count <- 0
    
    for (aq_file in test_files) {
      # Nome file output
      base_name <- basename(aq_file)
      st_file <- file.path(st_dir, gsub("\\.rds$", "_ST.rds", base_name))
      
      # Converte
      tryCatch({
        convert_to_spacetime_fixed(aq_file, st_file)
        success_count <- success_count + 1
      }, error = function(e) {
        cat("  ❌ ERROR converting", basename(aq_file), ":", e$message, "\n")
      })
    }
    
    cat("\n=== PHASE 12 TEST RESULTS ===\n")
    cat("Successful conversions:", success_count, "out of", length(test_files), "\n")
    
    if (success_count > 0) {
      # Test di compatibilità con codice target
      cat("\n=== TESTING TARGET CODE COMPATIBILITY ===\n")
      test_files_st <- list.files(st_dir, pattern = "\\.rds$", full.names = TRUE)
      if (length(test_files_st) > 0) {
        test_file <- test_files_st[1]
        cat("Testing with:", basename(test_file), "\n")
        
        tryCatch({
          EM_CAMS_v100_ST <- readRDS(test_file)
          
          # Test accesso slots
          cat("  ✓ @time access:", class(EM_CAMS_v100_ST@time)[1], "\n")
          cat("  ✓ @sp@coords access:", class(EM_CAMS_v100_ST@sp@coords)[1], "\n")
          cat("  ✓ index() function:", length(index(EM_CAMS_v100_ST@time)), "time points\n")
          
          # Test subset temporale
          n_test_times <- min(5, length(index(EM_CAMS_v100_ST@time)))
          sub_t <- index(EM_CAMS_v100_ST@time)[1:n_test_times]
          temporal_subset <- EM_CAMS_v100_ST[, which(index(EM_CAMS_v100_ST@time) %in% sub_t)]
          cat("  ✓ Temporal subset: OK (", length(unique(index(temporal_subset@time))), "time points)\n")
          
          # Test subset spaziale
          bbox <- c(7, 18, 36, 47)  # [lon_min, lon_max, lat_min, lat_max] per Italia
          spatial_subset <- temporal_subset[
            temporal_subset@sp@coords[, 1] > bbox[1] &
            temporal_subset@sp@coords[, 1] < bbox[2] &
            temporal_subset@sp@coords[, 2] > bbox[3] &
            temporal_subset@sp@coords[, 2] < bbox[4], 
          ]
          cat("  ✓ Spatial subset: OK (", nrow(spatial_subset@sp), "spatial points)\n")
          
          cat("\n  🎯 TARGET CODE COMPATIBILITY: SUCCESS! ✅\n")
          
        }, error = function(e) {
          cat("  ❌ TARGET CODE COMPATIBILITY: FAILED -", e$message, "\n")
        })
      }
      
      cat("\n=== NEXT STEPS ===\n")
      cat("✅ Phase 12 is working correctly!\n")
      cat("💡 To convert all files, modify the script to process all aq_files\n")
      cat("📁 Spacetime objects will be available in:", st_dir, "\n")
      
    } else {
      cat("❌ No successful conversions. Check time format issues.\n")
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
cat("After successful conversion, use spacetime objects with target code:\n")
cat("\n# Load spacetime object\n")
cat("EM_CAMS_v100_ST <- readRDS('data/processed/DAILY_data/SPACETIME_EM_sum/EM_NOx_2020_ST.rds')\n")
cat("\n# Use target code directly:\n")
cat("sub_t <- index(EM_CAMS_v100_ST@time)[1:10]\n")
cat("A4_em_cams <- EM_CAMS_v100_ST[, which(index(EM_CAMS_v100_ST@time) %in% sub_t)]\n")
cat("A4_em_cams <- A4_em_cams[A4_em_cams@sp@coords[, 1] > bbox[1] & ...]\n")
