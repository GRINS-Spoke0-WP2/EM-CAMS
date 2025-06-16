# ISTRUZIONI PER PLOTTARE DATI EM_SUM - EM-CAMS v.3.0.0

## 📊 STRUMENTI DI PLOTTING DISPONIBILI

Hai 2 strumenti principali per visualizzare i dati EM_sum:

1. **`plot_emissions.R`** - Strumento completo e dettagliato
2. **`plot_emissions_tool.R`** - Versione avanzata con più opzioni

## 🗂️ STRUTTURA DATI EM_SUM

I tuoi dati sono ubicati in:
```
data/processed/DAILY_data/EM_sum/
├── EM_NOx_2000.rds
├── EM_NOx_2001.rds
├── ...
└── EM_NOx_2022.rds
```

**Struttura**: Array 3D [lon, lat, time] con emissioni giornaliere

## 🚀 METODI DI PLOTTING

### METODO 1: Plot Emissions (Raccomandato)

```r
# Carica lo strumento
source("plot_emissions.R")

# Esempio 1: Plot specifico per data
plot_emissions_day(
  file_path = "data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds",
  date = "2020-01-16",  # 16 gennaio 2020
  pollutant = "NOx",
  save_path = "nox_jan16_2020.png"
)

# Esempio 2: Plot per giorno dell'anno (1-365/366)
plot_emissions_day(
  file_path = "data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds",
  date = 16,  # Giorno 16 dell'anno
  pollutant = "NOx"
)

# Esempio 3: Plot personalizzato
plot_emissions_day(
  file_path = "data/processed/DAILY_data/EM_sum/EM_NOx_2019.rds",
  date = "2019-07-15",
  pollutant = "NOx",
  title = "Emissioni NOx - Estate 2019",
  units = "g/m²/day",
  log_scale = TRUE,
  save_path = "nox_summer_2019.png",
  width = 12,
  height = 10
)
```

### METODO 2: Plot Emissions Tool (Avanzato)

```r
# Carica lo strumento avanzato
source("plot_emissions_tool.R")

# Plot con opzioni avanzate
plot_emissions(
  file_path = "data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds",
  date = "2020-03-15",
  pollutant = "NOx",
  unit_conversion = 1e6 * 60 * 60 * 24,  # kg/m²/s → g/m²/day
  save_path = "nox_march_2020_hd.png",
  width = 15,
  height = 12,
  dpi = 600,  # Alta risoluzione
  log_scale = TRUE
)
```

## 📅 FORMATI DATA SUPPORTATI

| Formato | Esempio | Descrizione |
|---------|---------|-------------|
| YYYY-MM-DD | "2020-01-16" | ISO standard |
| DD-MM-YYYY | "16-01-2020" | Formato europeo |
| Numerico | 16 | Giorno dell'anno (1-365/366) |

## 🎨 OPZIONI DI PERSONALIZZAZIONE

### Parametri Principali

```r
# Parametri disponibili in plot_emissions_day()
plot_emissions_day(
  file_path = "path/to/file.rds",  # [RICHIESTO] File RDS
  date = "2020-01-01",             # [RICHIESTO] Data o giorno
  pollutant = "NOx",               # Nome inquinante per titolo
  title = "Titolo personalizzato", # Titolo custom
  save_path = "my_plot.png",       # Salva plot (opzionale)
  units = "g/m²/day",              # Unità di misura
  conversion_factor = 1e6*60*60*24, # Fattore conversione unità
  log_scale = TRUE,                # Scala logaritmica
  width = 10,                      # Larghezza in pollici
  height = 8                       # Altezza in pollici
)
```

### Formati di Output

```r
# PNG (default)
save_path = "plot.png"

# PDF per pubblicazioni
save_path = "plot.pdf"

# JPEG per web
save_path = "plot.jpg"

# SVG per vettoriale
save_path = "plot.svg"
```

## 🔍 ESEMPI PRATICI

### 1. Analisi Stagionale NOx

```r
source("plot_emissions.R")

# Inverno
plot_emissions_day("data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds", 
                   "2020-01-15", "NOx", save_path = "nox_winter.png")

# Primavera  
plot_emissions_day("data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds", 
                   "2020-04-15", "NOx", save_path = "nox_spring.png")

# Estate
plot_emissions_day("data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds", 
                   "2020-07-15", "NOx", save_path = "nox_summer.png")

# Autunno
plot_emissions_day("data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds", 
                   "2020-10-15", "NOx", save_path = "nox_autumn.png")
```

### 2. Confronto Anni Diversi

```r
# 2019
plot_emissions_day("data/processed/DAILY_data/EM_sum/EM_NOx_2019.rds", 
                   "2019-06-01", "NOx", 
                   title = "NOx Emissions - June 1, 2019",
                   save_path = "nox_2019_june01.png")

# 2020 (stesso giorno)
plot_emissions_day("data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds", 
                   "2020-06-01", "NOx",
                   title = "NOx Emissions - June 1, 2020", 
                   save_path = "nox_2020_june01.png")
```

### 3. Serie Temporale (Batch Plotting)

```r
source("plot_emissions.R")

# Plot multipli per un mese
dates <- c("2020-01-01", "2020-01-08", "2020-01-15", "2020-01-22", "2020-01-29")

for (date in dates) {
  filename <- paste0("nox_", gsub("-", "", date), ".png")
  plot_emissions_day("data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds",
                     date, "NOx", save_path = filename)
}
```

### 4. Plot Ad Alta Risoluzione per Pubblicazioni

```r
source("plot_emissions_tool.R")

plot_emissions(
  "data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds",
  date = "2020-07-15",
  pollutant = "NOx", 
  save_path = "nox_publication_quality.pdf",
  width = 20,
  height = 16,
  dpi = 1200,
  title_override = "High-Resolution NOx Emissions Map"
)
```

## 🎯 TIPS E TROUBLESHOOTING

### 1. Problemi Comuni

```r
# Se ottieni errore "File not found"
file.exists("data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds")

# Se data non è riconosciuta, usa formato numerico
plot_emissions_day("file.rds", date = 185)  # Giorno 185 dell'anno

# Per dati con valori zero/negativi in scala log
log_scale = FALSE  # Usa scala lineare
```

### 2. Verificare Struttura Dati

```r
# Carica e ispeziona file
data <- readRDS("data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds")
dim(data)          # Dimensioni [lon, lat, time]
range(data, na.rm = TRUE)  # Range valori
```

### 3. Performance per File Grandi

```r
# Per file molto grandi, specifica subset
# Modifica il codice per estrarre solo la regione di interesse
```

## 📋 CHECKLIST RAPIDA

✅ **Prima di plottare:**
1. Verifica che il file EM_sum esista
2. Controlla il formato della data
3. Scegli lo strumento appropriato
4. Specifica il path di salvataggio se necessario

✅ **Per plot di qualità:**
1. Usa `log_scale = TRUE` per emissioni
2. Specifica DPI alto per pubblicazioni (≥300)
3. Scegli dimensioni appropriate (width/height)
4. Usa formato PDF per vettoriale

## 🚀 AVVIO RAPIDO

```r
# Setup rapido - copia e incolla questo codice:
setwd("/Users/aminborqal/Documents/Projects/R/EM-CAMS/v.3.0.0")
source("plot_emissions.R")

# Plot di esempio
plot_emissions_day(
  file_path = "data/processed/DAILY_data/EM_sum/EM_NOx_2020.rds",
  date = "2020-06-15",
  pollutant = "NOx",
  save_path = "test_plot.png"
)

cat("✅ Plot salvato come 'test_plot.png'\n")
```

Questa guida ti copre tutti i casi d'uso principali per visualizzare i dati EM_sum!
