#!/usr/bin/env Rscript
###############################################################################
# ESEMPIO PRATICO - Plotting Dati EM_sum
###############################################################################
# Script di esempio per plottare le emissioni giornaliere EM-CAMS
# Modifica i parametri secondo le tue esigenze
###############################################################################

# Imposta la directory di lavoro
setwd("/Users/aminborqal/Documents/Projects/R/EM-CAMS/v.3.0.0")

# Carica lo strumento di plotting
source("plot_emissions.R")

cat("=== ESEMPI DI PLOTTING DATI EM_SUM ===\n")

# ===== ESEMPIO 1: Plot Singolo =====
cat("\n1. Plot singolo - NOx gennaio 2020\n")

plot_emissions_day(
  file_path = "data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds",
  date = "2020-01-16",
  pollutant = "NOx",
  title = "Emissioni NOx - 16 Gennaio 2020",
  save_path = "esempio_nox_jan2020.png",
  width = 12,
  height = 10
)

cat("✅ Plot salvato: esempio_nox_jan2020.png\n")

# ===== ESEMPIO 2: Confronto Stagionale =====
cat("\n2. Confronto stagionale 2020\n")

stagioni <- list(
  inverno = list(date = "2020-01-15", nome = "Inverno"),
  primavera = list(date = "2020-04-15", nome = "Primavera"), 
  estate = list(date = "2020-07-15", nome = "Estate"),
  autunno = list(date = "2020-10-15", nome = "Autunno")
)

for (stagione in names(stagioni)) {
  info <- stagioni[[stagione]]
  filename <- paste0("nox_", stagione, "_2020.png")
  
  plot_emissions_day(
    file_path = "data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds",
    date = info$date,
    pollutant = "NOx",
    title = paste("Emissioni NOx -", info$nome, "2020"),
    save_path = filename,
    width = 10,
    height = 8
  )
  
  cat("✅ Plot", info$nome, "salvato:", filename, "\n")
}

# ===== ESEMPIO 3: Serie Settimanale =====
cat("\n3. Serie settimanale - Prima settimana marzo 2020\n")

date_settimana <- c("2020-03-01", "2020-03-02", "2020-03-03", 
                   "2020-03-04", "2020-03-05", "2020-03-06", "2020-03-07")

giorni_settimana <- c("Lunedì", "Martedì", "Mercoledì", "Giovedì", 
                     "Venerdì", "Sabato", "Domenica")

for (i in seq_along(date_settimana)) {
  data <- date_settimana[i]
  giorno <- giorni_settimana[i]
  filename <- paste0("nox_", tolower(giorno), "_mar2020.png")
  
  plot_emissions_day(
    file_path = "data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds",
    date = data,
    pollutant = "NOx",
    title = paste("Emissioni NOx -", giorno, format(as.Date(data), "%d %B %Y")),
    save_path = filename,
    width = 10,
    height = 8
  )
  
  cat("✅ Plot", giorno, "salvato:", filename, "\n")
}

# ===== ESEMPIO 4: Confronto Pre/Post COVID =====
cat("\n4. Confronto Pre/Post COVID (marzo 2019 vs 2020)\n")

# Marzo 2019 (pre-COVID)
plot_emissions_day(
  file_path = "data/processed/DAILY_data/EM_sum/EM_NOx_2019.rds",
  date = "2019-03-15",
  pollutant = "NOx",
  title = "Emissioni NOx - 15 Marzo 2019 (Pre-COVID)",
  save_path = "nox_pre_covid_mar2019.png",
  width = 12,
  height = 10
)

# Marzo 2020 (inizio COVID)
plot_emissions_day(
  file_path = "data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds", 
  date = "2020-03-15",
  pollutant = "NOx",
  title = "Emissioni NOx - 15 Marzo 2020 (Inizio COVID)",
  save_path = "nox_covid_mar2020.png",
  width = 12,
  height = 10
)

cat("✅ Confronto COVID salvato: nox_pre_covid_mar2019.png, nox_covid_mar2020.png\n")

# ===== ESEMPIO 5: Plot Alta Risoluzione =====
cat("\n5. Plot alta risoluzione per pubblicazione\n")

# Carica strumento avanzato se disponibile
if (file.exists("plot_emissions_tool.R")) {
  source("plot_emissions_tool.R")
  
  plot_emissions(
    file_path = "data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds",
    date = "2020-06-21",  # Solstizio d'estate
    pollutant = "NOx",
    save_path = "nox_solstizio_estate_HD.pdf",
    width = 16,
    height = 12,
    dpi = 600,
    title_override = "NOx Emissions - Summer Solstice 2020"
  )
  
  cat("✅ Plot HD salvato: nox_solstizio_estate_HD.pdf\n")
} else {
  cat("⚠️ plot_emissions_tool.R non trovato, uso versione standard\n")
  
  plot_emissions_day(
    file_path = "data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds",
    date = "2020-06-21",
    pollutant = "NOx", 
    title = "Emissioni NOx - Solstizio Estate 2020",
    save_path = "nox_solstizio_estate.png",
    width = 16,
    height = 12
  )
  
  cat("✅ Plot salvato: nox_solstizio_estate.png\n")
}

# ===== ESEMPIO 6: Analisi Weekend vs Feriale =====
cat("\n6. Confronto Feriale vs Weekend\n")

# Martedì (feriale)
plot_emissions_day(
  file_path = "data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds",
  date = "2020-06-02",  # Martedì
  pollutant = "NOx",
  title = "Emissioni NOx - Martedì (Giorno Feriale)",
  save_path = "nox_feriale_mar2020.png"
)

# Domenica (weekend)
plot_emissions_day(
  file_path = "data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds",
  date = "2020-06-07",  # Domenica
  pollutant = "NOx", 
  title = "Emissioni NOx - Domenica (Weekend)",
  save_path = "nox_weekend_dom2020.png"
)

cat("✅ Confronto Feriale/Weekend salvato\n")

# ===== RIEPILOGO =====
cat("\n" + "="*50)
cat("\n🎉 ESEMPI COMPLETATI!\n")
cat("\nFile generati:\n")

plot_files <- c(
  "esempio_nox_jan2020.png",
  "nox_inverno_2020.png", "nox_primavera_2020.png", 
  "nox_estate_2020.png", "nox_autunno_2020.png",
  "nox_lunedì_mar2020.png", "nox_martedì_mar2020.png", 
  "nox_mercoledì_mar2020.png", "nox_giovedì_mar2020.png",
  "nox_venerdì_mar2020.png", "nox_sabato_mar2020.png", "nox_domenica_mar2020.png",
  "nox_pre_covid_mar2019.png", "nox_covid_mar2020.png",
  "nox_feriale_mar2020.png", "nox_weekend_dom2020.png"
)

for (file in plot_files) {
  if (file.exists(file)) {
    cat("  ✅", file, "\n")
  } else {
    cat("  ❌", file, "(non trovato)\n")
  }
}

cat("\n📊 Puoi ora visualizzare tutti i plot generati!\n")
cat("💡 Modifica questo script per creare i tuoi plot personalizzati.\n")

# ===== FUNZIONI UTILITY =====
cat("\n📚 FUNZIONI UTILITY DISPONIBILI:\n")
cat("\n# Per plot rapido:\n")
cat("source('plot_emissions.R')\n")
cat("plot_emissions_day('file.rds', 'data', 'pollutant')\n")

cat("\n# Per verificare file disponibili:\n") 
cat("list.files('data/processed/DAILY_data/EM_sum/')\n")

cat("\n# Per verificare struttura dati:\n")
cat("data <- readRDS('file.rds'); dim(data)\n")

cat("\n=== FINE ESEMPI ===\n")
