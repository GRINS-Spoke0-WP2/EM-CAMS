#!/usr/bin/env Rscript
###############################################################################
# SALVA DATI GLOB CON DIMENSIONI INVERTITE
# Da [lon,lat,time] a [lat,lon,time] per compatibilità EM-CAMS
###############################################################################

cat("=== INVERSIONE E SALVATAGGIO DATI GLOB ===\n")

# Funzione per invertire e salvare
invert_and_save <- function(data_array, output_path, year = NULL) {
  
  if (is.null(year)) {
    year <- "unknown"
  }
  
  cat("\n--- Processando anno", year, "---\n")
  cat("Dimensioni originali:", paste(dim(data_array), collapse=" x "), "\n")
  
  # Inverti dimensioni: da [lon,lat,time] a [lat,lon,time]
  inverted_array <- aperm(data_array, c(2, 1, 3))
  
  # Inverti anche i dimnames se esistono
  if (!is.null(dimnames(data_array))) {
    dn <- dimnames(data_array)
    new_dimnames <- list(
      lat = dn$lat,    # lat diventa prima dimensione
      lon = dn$lon,    # lon diventa seconda dimensione  
      time = dn$time   # time rimane terza dimensione
    )
    dimnames(inverted_array) <- new_dimnames
    cat("Dimnames invertiti: lat x lon x time\n")
  }
  
  cat("Nuove dimensioni:", paste(dim(inverted_array), collapse=" x "), "\n")
  
  # Salva il file
  saveRDS(inverted_array, output_path)
  cat("✅ Salvato:", output_path, "\n")
  cat("📏 Dimensioni finali:", paste(dim(inverted_array), collapse=" x "), "\n")
  
  return(inverted_array)
}

# ===== SALVA I TUOI DATI =====

# 2023
if (exists("GLOB_daily_nox_sum_2023")) {
  GLOB_daily_nox_sum_2023_fixed <- invert_and_save(
    GLOB_daily_nox_sum_2023, 
    "data/processed/DAILY_data/EM_sum/EM_NOx_2023_GLOB.rds",
    2023
  )
} else {
  cat("⚠️ GLOB_daily_nox_sum_2023 non trovato\n")
}

# 2024  
if (exists("GLOB_daily_nox_sum_2024")) {
  GLOB_daily_nox_sum_2024_fixed <- invert_and_save(
    GLOB_daily_nox_sum_2024,
    "data/processed/DAILY_data/EM_sum/EM_NOx_2024_GLOB.rds", 
    2024
  )
} else {
  cat("⚠️ GLOB_daily_nox_sum_2024 non trovato\n")
}

# 2025
if (exists("GLOB_daily_nox_sum_2025")) {
  GLOB_daily_nox_sum_2025_fixed <- invert_and_save(
    GLOB_daily_nox_sum_2025,
    "data/processed/DAILY_data/EM_sum/EM_NOx_2025_GLOB.rds",
    2025
  )
} else {
  cat("⚠️ GLOB_daily_nox_sum_2025 non trovato\n")
}

# ===== VERIFICA FINALE =====
cat("\n" + "="*50)
cat("\n📋 RIEPILOGO SALVATAGGIO:\n")

output_files <- c(
  "data/processed/DAILY_data/EM_sum/EM_NOx_2023_GLOB.rds",
  "data/processed/DAILY_data/EM_sum/EM_NOx_2024_GLOB.rds", 
  "data/processed/DAILY_data/EM_sum/EM_NOx_2025_GLOB.rds"
)

for (file in output_files) {
  if (file.exists(file)) {
    # Verifica dimensioni del file salvato
    test_data <- readRDS(file)
    dims <- dim(test_data)
    year <- gsub(".*EM_NOx_(\\d{4})_GLOB\\.rds", "\\1", basename(file))
    
    cat("✅", year, ":", basename(file), "\n")
    cat("   Dimensioni [lat,lon,time]:", paste(dims, collapse=" x "), "\n")
    
    # Verifica dimnames
    if (!is.null(dimnames(test_data))) {
      dn <- dimnames(test_data)
      cat("   Lat range:", dn$lat[1], "to", dn$lat[length(dn$lat)], "\n")
      cat("   Lon range:", dn$lon[1], "to", dn$lon[length(dn$lon)], "\n")
      cat("   Time range:", dn$time[1], "to", dn$time[length(dn$time)], "\n")
    }
    cat("\n")
  } else {
    cat("❌", basename(file), "non trovato\n")
  }
}

cat("🎉 INVERSIONE E SALVATAGGIO COMPLETATI!\n")
cat("I file sono ora compatibili con il formato EM-CAMS [lat,lon,time]\n")

# ===== CLEANUP OPZIONALE =====
cat("\n💾 CLEANUP VARIABILI ORIGINALI?\n")
cat("Per liberare memoria, esegui:\n")
cat("rm(GLOB_daily_nox_sum_2023, GLOB_daily_nox_sum_2024, GLOB_daily_nox_sum_2025)\n")
cat("gc()  # garbage collection\n")
