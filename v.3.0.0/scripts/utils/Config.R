# Global Configurations and Package Management

# Italy bounding box
boundary <- c(6, 19, 35, 48)

# Default pollutant names and time range (can be overridden in Main.R)
pollutant_names_default <- c("nh3", "ch4", "co", "co2_bf", "co2_ff", "nmvoc", "nox", "pm2_5", "pm10", "so2")
start_year_default <- 2000
end_year_default <- 2022

# Required libraries
required_packages <- c("ncdf4", "abind", "reshape2")

#sector names



# Elenco delle librerie richieste
required_packages <- c("ncdf4", "abind", "reshape2")

# Funzione per controllare, installare (se necessario) e caricare le librerie,
# stampando la versione di ciascuna
check_and_install_packages <- function(pkgs) {
  for (pkg in pkgs) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      install.packages(pkg)
    }
    library(pkg, character.only = TRUE)
    message(pkg, " version: ", packageVersion(pkg))
  }
}

# Esegui il controllo delle librerie
check_and_install_packages(required_packages)


