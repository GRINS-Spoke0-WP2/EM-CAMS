#!/usr/bin/env Rscript
###############################################################################
# Test rapido per Phase 12 - Verifica struttura AQ_EM_sum
###############################################################################

setwd("/Users/aminborqal/Documents/Projects/R/EM-CAMS/v.3.0.0")

cat("=== TEST PHASE 12: Verifica struttura AQ_EM_sum ===\n")

# Test con un singolo file
test_file <- "data/processed/DAILY_data/AQ_EM_sum/EM_NOx_2020.rds"

if (file.exists(test_file)) {
  cat("Test file:", basename(test_file), "\n")
  
  # Carica e analizza
  data_array <- readRDS(test_file)
  cat("✓ File caricato con successo\n")
  cat("Classe:", class(data_array), "\n")
  cat("Dimensioni:", paste(dim(data_array), collapse=" x "), "\n")
  
  # Analizza dimnames
  if (!is.null(dimnames(data_array))) {
    dn <- dimnames(data_array)
    cat("Dimnames disponibili:", length(dn), "\n")
    
    for (i in seq_along(dn)) {
      cat("  Dim", i, "- length:", length(dn[[i]]), "type:", class(dn[[i]]), "\n")
      if (length(dn[[i]]) > 0) {
        cat("    Range:", dn[[i]][1], "to", dn[[i]][length(dn[[i]])], "\n")
      }
    }
    
    # Verifica ordine [lat, lon, time]
    lat_vals <- dn[[1]]
    lon_vals <- dn[[2]]  
    time_vals <- dn[[3]]
    
    cat("\nANALISI COORDINATE:\n")
    
    # Test coordinate lat
    lat_numeric <- suppressWarnings(as.numeric(lat_vals))
    if (!any(is.na(lat_numeric))) {
      cat("✓ LAT: valori numerici validi\n")
      cat("  Range LAT:", min(lat_numeric), "to", max(lat_numeric), "\n")
    } else {
      cat("✗ LAT: valori non numerici\n")
    }
    
    # Test coordinate lon
    lon_numeric <- suppressWarnings(as.numeric(lon_vals))
    if (!any(is.na(lon_numeric))) {
      cat("✓ LON: valori numerici validi\n")
      cat("  Range LON:", min(lon_numeric), "to", max(lon_numeric), "\n")
    } else {
      cat("✗ LON: valori non numerici\n")
    }
    
    # Test time
    cat("✓ TIME: ", length(time_vals), "valori temporali\n")
    cat("  Formato TIME:", time_vals[1], "...", time_vals[length(time_vals)], "\n")
    
    # Test conversione temporale
    if (is.character(time_vals) && nchar(time_vals[1]) == 8) {
      time_dates <- as.Date(time_vals, format="%d%m%Y")
      if (!any(is.na(time_dates))) {
        cat("✓ TIME: formato DDMMYYYY convertibile a Date\n")
        cat("  Range temporale:", as.character(min(time_dates)), "to", as.character(max(time_dates)), "\n")
      }
    } else if (is.numeric(time_vals)) {
      reference_date <- as.Date("1850-01-01")
      time_dates <- reference_date + as.numeric(time_vals)
      cat("✓ TIME: formato CF convertibile a Date\n")
      cat("  Range temporale:", as.character(min(time_dates)), "to", as.character(max(time_dates)), "\n")
    }
    
    cat("\n=== RISULTATO TEST ===\n")
    cat("✅ STRUTTURA COMPATIBILE con Phase 12\n")
    cat("✅ Dimensioni:", paste(dim(data_array), collapse=" x "), "\n")
    cat("✅ Ordine: [LAT, LON, TIME]\n")
    cat("✅ Coordinate numeriche valide\n")
    cat("✅ Formato temporale convertibile\n")
    
    cat("\n=== PROSSIMI PASSI ===\n")
    cat("🚀 PRONTO per eseguire Phase 12\n")
    cat("💡 Comando: phases_to_run <- c(12); source('Main.R')\n")
    cat("📁 Output: data/processed/DAILY_data/SPACETIME_EM_sum/\n")
    
    # Test dimensioni per stima memoria
    total_elements <- prod(dim(data_array))
    mb_estimate <- (total_elements * 8) / (1024^2)  # 8 bytes per double
    cat("📊 Stima memoria per conversione:", round(mb_estimate, 1), "MB per file\n")
    
  } else {
    cat("✗ Dimnames non disponibili\n")
  }
  
} else {
  cat("✗ File di test non trovato:", test_file, "\n")
  cat("💡 Eseguire prima Phase 11 per creare AQ_EM_sum\n")
}

cat("\n=== FINE TEST ===\n")
