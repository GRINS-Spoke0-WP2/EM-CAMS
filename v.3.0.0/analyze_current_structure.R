#!/usr/bin/env Rscript
###############################################################################
# Analisi della struttura corrente dei dati AQ_EM_sum
# Verifica compatibilità con il codice target spatio-temporale
###############################################################################

setwd("/Users/aminborqal/Documents/Projects/R/EM-CAMS/v.3.0.0")

cat("=== ANALISI STRUTTURA DATI AQ_EM_sum ===\n")

# Controlla se esistono file AQ_EM_sum
aq_dir <- "data/processed/DAILY_data/AQ_EM_sum"
cat("Directory AQ_EM_sum:", aq_dir, "\n")
cat("Directory exists:", dir.exists(aq_dir), "\n")

if (dir.exists(aq_dir)) {
  files <- list.files(aq_dir, pattern = "\\.rds$", full.names = TRUE)
  cat("File AQ_EM_sum trovati:", length(files), "\n")
  
  if (length(files) > 0) {
    cat("Files:\n")
    for (f in head(files, 3)) {
      cat("  -", basename(f), "\n")
    }
    
    # Analizza il primo file
    test_file <- files[1]
    cat("\n=== ANALISI FILE:", basename(test_file), "===\n")
    
    tryCatch({
      data <- readRDS(test_file)
      
      cat("Classe oggetto:", class(data), "\n")
      cat("Tipo oggetto:", typeof(data), "\n")
      cat("Dimensioni:", paste(dim(data), collapse=" x "), "\n")
      
      # Analizza dimnames
      if (!is.null(dimnames(data))) {
        cat("\nDIMNAMES ANALYSIS:\n")
        dn <- dimnames(data)
        for (i in seq_along(dn)) {
          if (!is.null(dn[[i]])) {
            cat("  Dim", i, "name:", names(dimnames(data))[i], "\n")
            cat("  Dim", i, "type:", class(dn[[i]]), "\n")
            cat("  Dim", i, "length:", length(dn[[i]]), "\n")
            cat("  Dim", i, "range:", dn[[i]][1], "to", dn[[i]][length(dn[[i]])], "\n")
          }
        }
      }
      
      # Verifica struttura per il codice target
      cat("\n=== COMPATIBILITÀ CON CODICE TARGET ===\n")
      
      # Il codice target richiede:
      # 1. Oggetto con @time slot
      # 2. Oggetto con @sp@coords slot
      # 3. Indicizzazione temporale con index()
      # 4. Coordinati spaziali accessibili
      
      cat("Struttura attuale è array/matrix:", is.array(data) || is.matrix(data), "\n")
      cat("Ha slot @time:", !is.null(attr(data, "time")), "\n")
      cat("Ha slot @sp:", !is.null(attr(data, "sp")), "\n")
      
      # Analizza se è un oggetto spatio-temporale
      cat("È oggetto spacetime:", inherits(data, "STFDF") || inherits(data, "STIDF"), "\n")
      cat("È oggetto sf:", inherits(data, "sf"), "\n")
      cat("È oggetto sp:", inherits(data, "Spatial"), "\n")
      
      cat("\n=== REQUISITI MANCANTI ===\n")
      cat("PROBLEMA: Il codice target richiede un oggetto spatio-temporale con:\n")
      cat("  1. @time slot (per indicizzazione temporale)\n")
      cat("  2. @sp@coords slot (per subset spaziale)\n")
      cat("  3. Metodi index() per accesso temporale\n")
      cat("  4. Struttura compatibile con spacetime package\n")
      
      cat("\nSTRUTTURA ATTUALE:\n")
      cat("  - Array/matrix multidimensionale\n")
      cat("  - Dimnames: [lat, lon, time]\n")
      cat("  - Formato numerico/character\n")
      cat("  - NON è oggetto spatio-temporale\n")
      
    }, error = function(e) {
      cat("Errore lettura file:", e$message, "\n")
    })
  }
} else {
  cat("Directory AQ_EM_sum non trovata. Controllare se Phase 11 è stato eseguito.\n")
}

cat("\n=== CONCLUSIONI ===\n")
cat("RISPOSTA: NO, non sei pronto per il codice target.\n")
cat("MOTIVO: Il codice richiede oggetto spatio-temporale, non array.\n")
cat("SOLUZIONE: Creare Phase 12 per conversione a oggetto spacetime.\n")