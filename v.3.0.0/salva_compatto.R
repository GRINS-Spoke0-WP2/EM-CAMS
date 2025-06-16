# VERSIONE COMPATTA - Copia e incolla nel tuo script

# Salva 2023
if(exists("GLOB_daily_nox_sum_2023")) {
  data_2023 <- aperm(GLOB_daily_nox_sum_2023, c(2,1,3))
  if(!is.null(dimnames(GLOB_daily_nox_sum_2023))) {
    dn <- dimnames(GLOB_daily_nox_sum_2023)
    dimnames(data_2023) <- list(lat=dn$lat, lon=dn$lon, time=dn$time)
  }
  saveRDS(data_2023, "data/processed/DAILY_data/EM_sum/EM_NOx_2023_GLOB.rds")
  cat("✅ 2023 salvato\n")
}

# Salva 2024
if(exists("GLOB_daily_nox_sum_2024")) {
  data_2024 <- aperm(GLOB_daily_nox_sum_2024, c(2,1,3))
  if(!is.null(dimnames(GLOB_daily_nox_sum_2024))) {
    dn <- dimnames(GLOB_daily_nox_sum_2024)
    dimnames(data_2024) <- list(lat=dn$lat, lon=dn$lon, time=dn$time)
  }
  saveRDS(data_2024, "data/processed/DAILY_data/EM_sum/EM_NOx_2024_GLOB.rds")
  cat("✅ 2024 salvato\n")
}

# Salva 2025
if(exists("GLOB_daily_nox_sum_2025")) {
  data_2025 <- aperm(GLOB_daily_nox_sum_2025, c(2,1,3))
  if(!is.null(dimnames(GLOB_daily_nox_sum_2025))) {
    dn <- dimnames(GLOB_daily_nox_sum_2025)
    dimnames(data_2025) <- list(lat=dn$lat, lon=dn$lon, time=dn$time)
  }
  saveRDS(data_2025, "data/processed/DAILY_data/EM_sum/EM_NOx_2025_GLOB.rds")
  cat("✅ 2025 salvato\n")
}

cat("🎉 Tutti i file salvati in data/processed/DAILY_data/EM_sum/ con formato [lat,lon,time]\n")
