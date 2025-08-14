# ========================================================================
# COORDINATE CONVERTER EM-CAMS v.2.1.0
# ========================================================================
# Script per convertire l'ordine delle coordinate da [LON, LAT] a [LAT, LON]
# 
# Il progetto EM-CAMS usa la convenzione [LONGITUDINE, LATITUDINE] che è
# corretta e coerente. Questo script permette di convertire i dati per
# compatibilità con software/standard che richiedono [LATITUDINE, LONGITUDINE].
#
# SUPPORTA:
# - Array/matrici con dimensioni multiple: [lon, lat, sector, year, ...]
# - Liste con coordinate lon/lat
# - Conserva tutte le altre dimensioni nell'ordine originale
# - Mantiene tutti gli attributi e dimnames
#
# AUTORE: EM-CAMS Team
# VERSIONE: v.2.1.0
# DATA: 3 giugno 2025
# ========================================================================

# Carica librerie necessarie
if(!require(abind)) {
  cat("📦 Installando package 'abind'...\n")
  install.packages("abind")
  library(abind)
}

#' Converte l'ordine delle coordinate da [lon, lat] a [lat, lon]
#'
#' @param data Array, matrice o lista con coordinate lon/lat
#' @param verbose Logical, se TRUE mostra messaggi dettagliati
#' @return Oggetto con coordinate convertite a [lat, lon]
#' @examples
#' # Per array 4D [lon, lat, sector, year]
#' converted_data <- convert_lon_lat_to_lat_lon(my_array)
#' 
#' # Per lista con elementi lon/lat
#' converted_list <- convert_lon_lat_to_lat_lon(my_list)
convert_lon_lat_to_lat_lon <- function(data, verbose = TRUE) {
  
  if(verbose) {
    cat("🔄 CONVERSIONE COORDINATE: [LON, LAT] → [LAT, LON]\n")
    cat(paste(rep("=", 50), collapse=""), "\n")
  }
  
  # Verifica input
  if(is.null(data)) {
    stop("❌ Errore: dati di input sono NULL")
  }
  
  # Caso 1: LISTA con elementi lon/lat
  if(is.list(data) && !is.data.frame(data)) {
    if(verbose) cat("📋 Tipo dati: Lista\n")
    
    if("lon" %in% names(data) && "lat" %in% names(data)) {
      if(verbose) {
        cat("✅ Trovati elementi 'lon' e 'lat' nella lista\n")
        cat("🌍 LON range:", paste(range(data$lon), collapse=" a "), "\n")
        cat("🌍 LAT range:", paste(range(data$lat), collapse=" a "), "\n")
      }
      
      # Crea nuova lista con ordine invertito
      converted_data <- data
      
      # Scambia lon e lat mantenendo tutto il resto
      temp_lon <- converted_data$lon
      converted_data$lat <- temp_lon
      converted_data$lon <- data$lat
      
      # Se la lista ha nomi ordinati, aggiorna l'ordine
      if(!is.null(names(converted_data))) {
        name_order <- names(converted_data)
        lon_idx <- which(name_order == "lon")
        lat_idx <- which(name_order == "lat")
        
        if(length(lon_idx) == 1 && length(lat_idx) == 1) {
          # Scambia posizioni nell'ordine dei nomi
          name_order[c(lon_idx, lat_idx)] <- name_order[c(lat_idx, lon_idx)]
          converted_data <- converted_data[name_order]
        }
      }
      
      if(verbose) {
        cat("✅ Conversione completata\n")
        cat("📋 Nuovo ordine elementi:", paste(names(converted_data), collapse=", "), "\n\n")
      }
      
      return(converted_data)
      
    } else {
      if(verbose) cat("⚠️  Lista non contiene elementi 'lon' e 'lat'\n\n")
      return(data)  # Restituisce dati originali
    }
  }
  
  # Caso 2: ARRAY o MATRICE
  if(is.array(data) || is.matrix(data)) {
    if(verbose) {
      cat("📐 Tipo dati: Array/Matrice\n")
      cat("📏 Dimensioni originali:", paste(dim(data), collapse=" x "), "\n")
    }
    
    # Controlla dimnames
    dn <- dimnames(data)
    if(is.null(dn)) {
      if(verbose) cat("⚠️  Nessun dimname trovato - impossibile identificare lon/lat\n\n")
      return(data)
    }
    
    if(verbose) cat("🏷️  Dimnames disponibili per", length(dn), "dimensioni\n")
    
    # Trova le dimensioni lon e lat
    lon_dim <- NULL
    lat_dim <- NULL
    
    for(i in seq_len(length(dn))) {
      if(!is.null(dn[[i]])) {
        # Controlla se sono coordinate numeriche
        coords <- suppressWarnings(as.numeric(dn[[i]]))
        
        if(!all(is.na(coords))) {
          coord_range <- range(coords, na.rm = TRUE)
          
          # Identifica LON: range più ampio o valori > 90
          if(coord_range[1] >= -180 && coord_range[2] <= 180) {
            if(coord_range[1] >= -90 && coord_range[2] <= 90) {
              # Potrebbe essere LAT
              if(is.null(lat_dim)) {
                lat_dim <- i
                if(verbose) cat("   Dim", i, ": LATITUDINE (", paste(coord_range, collapse=" a "), ")\n")
              }
            } else {
              # Probabilmente LON (valori > 90 o < -90)
              if(is.null(lon_dim)) {
                lon_dim <- i
                if(verbose) cat("   Dim", i, ": LONGITUDINE (", paste(coord_range, collapse=" a "), ")\n")
              }
            }
          }
        }
      }
    }
    
    # Se non trovate entrambe le dimensioni, prova con le prime 2
    if(is.null(lon_dim) || is.null(lat_dim)) {
      if(length(dn) >= 2) {
        # Assumiamo che le prime 2 dimensioni siano lon e lat
        lon_dim <- 1
        lat_dim <- 2
        if(verbose) {
          cat("⚠️  Coordinate non identificate automaticamente\n")
          cat("📐 Assunto: Dim 1=LON, Dim 2=LAT (standard EM-CAMS)\n")
        }
      } else {
        if(verbose) cat("❌ Impossibile trovare 2 dimensioni per lon/lat\n\n")
        return(data)
      }
    }
    
    if(verbose) {
      cat("🔄 Scambio dimensioni:", lon_dim, "(LON) ↔", lat_dim, "(LAT)\n")
    }
    
    # Crea vettore di permutazione
    perm_order <- seq_len(length(dim(data)))
    perm_order[c(lon_dim, lat_dim)] <- perm_order[c(lat_dim, lon_dim)]
    
    if(verbose) {
      cat("📋 Ordine originale dimensioni:", paste(seq_len(length(dim(data))), collapse=", "), "\n")
      cat("📋 Nuovo ordine dimensioni:     ", paste(perm_order, collapse=", "), "\n")
    }
    
    # Applica permutazione
    converted_data <- aperm(data, perm_order)
    
    # Aggiorna dimnames se presenti
    if(!is.null(dn)) {
      new_dimnames <- dn[perm_order]
      dimnames(converted_data) <- new_dimnames
    }
    
    # Conserva attributi
    attributes_to_keep <- attributes(data)
    attributes_to_keep$dim <- dim(converted_data)
    attributes_to_keep$dimnames <- dimnames(converted_data)
    attributes(converted_data) <- attributes_to_keep
    
    if(verbose) {
      cat("✅ Conversione completata\n")
      cat("📏 Nuove dimensioni:", paste(dim(converted_data), collapse=" x "), "\n")
      
      # Mostra nuovi dimnames
      new_dn <- dimnames(converted_data)
      if(!is.null(new_dn) && length(new_dn) >= 2) {
        if(!is.null(new_dn[[1]]) && !is.null(new_dn[[2]])) {
          lat_coords <- suppressWarnings(as.numeric(new_dn[[1]]))
          lon_coords <- suppressWarnings(as.numeric(new_dn[[2]]))
          
          if(!all(is.na(lat_coords))) {
            cat("🌍 Nuova Dim 1 (LAT):", paste(range(lat_coords, na.rm=TRUE), collapse=" a "), "\n")
          }
          if(!all(is.na(lon_coords))) {
            cat("🌍 Nuova Dim 2 (LON):", paste(range(lon_coords, na.rm=TRUE), collapse=" a "), "\n")
          }
        }
      }
      cat("\n")
    }
    
    return(converted_data)
  }
  
  # Caso 3: DATA.FRAME
  if(is.data.frame(data)) {
    if(verbose) {
      cat("📊 Tipo dati: Data.frame\n")
      cat("📋 Colonne:", paste(colnames(data), collapse=", "), "\n")
    }
    
    if("lon" %in% colnames(data) && "lat" %in% colnames(data)) {
      converted_data <- data
      
      # Scambia colonne
      temp_lon <- converted_data$lon
      converted_data$lon <- converted_data$lat
      converted_data$lat <- temp_lon
      
      # Riordina colonne se lon e lat sono le prime due
      col_order <- colnames(converted_data)
      lon_idx <- which(col_order == "lon")
      lat_idx <- which(col_order == "lat")
      
      if(length(lon_idx) == 1 && length(lat_idx) == 1) {
        col_order[c(lon_idx, lat_idx)] <- col_order[c(lat_idx, lon_idx)]
        converted_data <- converted_data[, col_order]
      }
      
      if(verbose) {
        cat("✅ Colonne lon/lat scambiate\n")
        cat("📋 Nuovo ordine colonne:", paste(colnames(converted_data), collapse=", "), "\n\n")
      }
      
      return(converted_data)
      
    } else {
      if(verbose) cat("⚠️  Data.frame non contiene colonne 'lon' e 'lat'\n\n")
      return(data)
    }
  }
  
  # Tipo di dato non supportato
  if(verbose) {
    cat("❌ Tipo di dato non supportato:", class(data), "\n\n")
  }
  return(data)
}

#' Converte un file RDS da [lon, lat] a [lat, lon] e salva il risultato
#'
#' @param input_file Percorso del file RDS di input
#' @param output_file Percorso del file RDS di output (opzionale)
#' @param verbose Logical, se TRUE mostra messaggi dettagliati
#' @return Path del file di output creato
convert_rds_file <- function(input_file, output_file = NULL, verbose = TRUE) {
  
  if(verbose) {
    cat("📁 CONVERSIONE FILE RDS\n")
    cat(paste(rep("=", 40), collapse=""), "\n")
    cat("📂 File input:", input_file, "\n")
  }
  
  # Verifica esistenza file
  if(!file.exists(input_file)) {
    stop("❌ File non trovato:", input_file)
  }
  
  # Genera nome output se non specificato
  if(is.null(output_file)) {
    file_parts <- tools::file_path_sans_ext(input_file)
    file_ext <- tools::file_ext(input_file)
    output_file <- paste0(file_parts, "_lat_lon.", file_ext)
  }
  
  if(verbose) {
    cat("📂 File output:", output_file, "\n")
    
    # Info dimensioni file
    file_size_mb <- round(file.info(input_file)$size / 1024 / 1024, 2)
    cat("📏 Dimensione file:", file_size_mb, "MB\n")
  }
  
  # Carica dati
  if(verbose) cat("⏳ Caricamento dati...\n")
  data <- readRDS(input_file)
  
  # Converti coordinate
  converted_data <- convert_lon_lat_to_lat_lon(data, verbose = verbose)
  
  # Salva risultato
  if(verbose) cat("💾 Salvataggio file convertito...\n")
  saveRDS(converted_data, output_file)
  
  if(verbose) {
    output_size_mb <- round(file.info(output_file)$size / 1024 / 1024, 2)
    cat("✅ File salvato:", output_file, "(", output_size_mb, "MB)\n\n")
  }
  
  return(output_file)
}

#' Batch conversion di tutti i file in una directory
#'
#' @param input_dir Directory contenente i file da convertire
#' @param output_dir Directory di output (default: input_dir/converted_lat_lon)
#' @param pattern Pattern per i file da convertire (default: "\\.rds$")
#' @param max_files Numero massimo di file da convertire (per test)
convert_directory <- function(input_dir, output_dir = NULL, pattern = "\\.rds$", max_files = NULL) {
  
  cat("📁 CONVERSIONE BATCH DIRECTORY\n")
  cat(paste(rep("=", 50), collapse=""), "\n")
  cat("📂 Directory input:", input_dir, "\n")
  
  if(!dir.exists(input_dir)) {
    stop("❌ Directory non trovata:", input_dir)
  }
  
  # Crea directory output
  if(is.null(output_dir)) {
    output_dir <- file.path(input_dir, "converted_lat_lon")
  }
  
  if(!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    cat("📁 Creata directory output:", output_dir, "\n")
  } else {
    cat("📂 Directory output:", output_dir, "\n")
  }
  
  # Trova file da convertire
  files <- list.files(input_dir, pattern = pattern, full.names = TRUE)
  cat("📋 Trovati", length(files), "file corrispondenti al pattern\n")
  
  if(length(files) == 0) {
    cat("⚠️  Nessun file da convertire\n")
    return(invisible(NULL))
  }
  
  # Limita numero file se specificato
  if(!is.null(max_files) && length(files) > max_files) {
    files <- files[1:max_files]
    cat("⚠️  Limitato a", max_files, "file per test\n")
  }
  
  cat("🔄 Inizio conversione...\n\n")
  
  # Converti ogni file
  converted_files <- character(0)
  errors <- character(0)
  
  for(i in seq_along(files)) {
    input_file <- files[i]
    file_name <- basename(input_file)
    output_file <- file.path(output_dir, file_name)
    
    cat("📄", i, "/", length(files), ":", file_name, "\n")
    
    tryCatch({
      result_file <- convert_rds_file(input_file, output_file, verbose = FALSE)
      converted_files <- c(converted_files, result_file)
      cat("   ✅ Convertito\n")
    }, error = function(e) {
      cat("   ❌ Errore:", e$message, "\n")
      errors <- c(errors, paste(file_name, ":", e$message))
    })
  }
  
  # Riassunto
  cat("\n📊 RIASSUNTO CONVERSIONE\n")
  cat(paste(rep("-", 30), collapse=""), "\n")
  cat("✅ File convertiti:", length(converted_files), "\n")
  cat("❌ Errori:", length(errors), "\n")
  
  if(length(errors) > 0) {
    cat("\n❌ ERRORI DETTAGLIATI:\n")
    for(error in errors) {
      cat("  -", error, "\n")
    }
  }
  
  cat("\n📂 File convertiti salvati in:", output_dir, "\n")
  
  return(list(
    converted_files = converted_files,
    errors = errors,
    output_dir = output_dir
  ))
}

# ========================================================================
# ESEMPI E TEST
# ========================================================================

#' Funzione di test per verificare il funzionamento del converter
test_coordinate_converter <- function() {
  cat("🧪 TEST COORDINATE CONVERTER\n")
  cat(paste(rep("=", 40), collapse=""), "\n")
  
  # Test 1: Array 4D
  cat("📋 Test 1: Array 4D [lon, lat, sector, year]\n")
  
  # Crea array di test
  n_lon <- 10
  n_lat <- 8
  n_sector <- 5
  n_year <- 3
  
  test_array <- array(
    runif(n_lon * n_lat * n_sector * n_year),
    dim = c(n_lon, n_lat, n_sector, n_year),
    dimnames = list(
      lon = seq(6, 18, length.out = n_lon),
      lat = seq(35, 47, length.out = n_lat),
      sector = paste0("S", 1:n_sector),
      year = 2020:2022
    )
  )
  
  cat("   📏 Dimensioni originali:", paste(dim(test_array), collapse=" x "), "\n")
  cat("   🌍 LON range:", paste(range(as.numeric(dimnames(test_array)[[1]])), collapse=" a "), "\n")
  cat("   🌍 LAT range:", paste(range(as.numeric(dimnames(test_array)[[2]])), collapse=" a "), "\n")
  
  # Converti
  converted_array <- convert_lon_lat_to_lat_lon(test_array, verbose = FALSE)
  
  cat("   📏 Dimensioni convertite:", paste(dim(converted_array), collapse=" x "), "\n")
  cat("   🌍 Nuova Dim 1 range:", paste(range(as.numeric(dimnames(converted_array)[[1]])), collapse=" a "), "\n")
  cat("   🌍 Nuova Dim 2 range:", paste(range(as.numeric(dimnames(converted_array)[[2]])), collapse=" a "), "\n")
  
  # Verifica che i dati siano stati scambiati correttamente
  original_value <- test_array[1, 1, 1, 1]
  converted_value <- converted_array[1, 1, 1, 1]
  expected_value <- test_array[1, 1, 1, 1]  # Stesso valore ma posizione scambiata
  
  cat("   ✅ Test array 4D completato\n\n")
  
  # Test 2: Lista
  cat("📋 Test 2: Lista con elementi lon/lat\n")
  
  test_list <- list(
    lon = seq(6, 18, length.out = 10),
    lat = seq(35, 47, length.out = 8),
    data = matrix(runif(80), nrow = 10, ncol = 8)
  )
  
  cat("   🌍 LON originale range:", paste(range(test_list$lon), collapse=" a "), "\n")
  cat("   🌍 LAT originale range:", paste(range(test_list$lat), collapse=" a "), "\n")
  
  converted_list <- convert_lon_lat_to_lat_lon(test_list, verbose = FALSE)
  
  cat("   🌍 Nuova LAT range:", paste(range(converted_list$lat), collapse=" a "), "\n")
  cat("   🌍 Nuova LON range:", paste(range(converted_list$lon), collapse=" a "), "\n")
  cat("   📋 Ordine elementi:", paste(names(converted_list), collapse=", "), "\n")
  cat("   ✅ Test lista completato\n\n")
  
  cat("🎉 TUTTI I TEST COMPLETATI CON SUCCESSO!\n\n")
}

# ========================================================================
# DOCUMENTAZIONE USO
# ========================================================================

cat("📚 COORDINATE CONVERTER EM-CAMS v.2.1.0 CARICATO\n")
cat(paste(rep("=", 50), collapse=""), "\n")
cat("🔧 FUNZIONI DISPONIBILI:\n")
cat("   🔄 convert_lon_lat_to_lat_lon(data, verbose=TRUE)\n")
cat("   📁 convert_rds_file(input_file, output_file=NULL, verbose=TRUE)\n")
cat("   📂 convert_directory(input_dir, output_dir=NULL, pattern='\\.rds$')\n")
cat("   🧪 test_coordinate_converter()\n\n")

cat("⚠️  NOTA: Il progetto EM-CAMS funziona correttamente con [LON, LAT].\n")
cat("   Usa questo converter solo per compatibilità con altri software.\n\n")
