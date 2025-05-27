# Global Configurations and Package Management

# Italy bounding box
boundary <- c(6, 19, 35, 48)

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


