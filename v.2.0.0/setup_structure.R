# Script per creare le cartelle necessarie in V.2.0.0

dirs <- c(
  "Data/Raw/CAMS-REG-ANT",
  "Data/Raw/CAMS-REG-TEMPO",
  "Data/Raw/CAMS-REG-TEMPO-SIMPLIFIED",
  "Data/Processed/ANT_data",
  "Data/Processed/TEMPO_data",
  "Data/Processed/DAILY_data",
  "Data/Processed/DAILY_data/DailyAlongYears",
  "ExtractANT",
  "ExtractTEMPO",
  "Computation",
  "Documentation"
)

for (d in dirs) {
  if (!dir.exists(d)) {
    dir.create(d, recursive = TRUE)
  }
}
cat("Struttura V.2.0.0 creata con successo.\n")
