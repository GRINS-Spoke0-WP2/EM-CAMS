EM_CAMS_v200_ST <- readRDS("~/Library/Mobile Documents/com~apple~CloudDocs/Lavoro/PhD Bergamo/R/GitHub/GRINS-Spoke0-WP2/AQ-FRK/v.3.0.8/A_input/data/input/EM_CAMS_v200_ST.rds")
hist(EM_CAMS_v200_ST@data$EM_CAMS_NO2)

hist(EM_CAMS_v200_ST@data$EM_CAMS_NO2*(10^6)*86400)

load("~/Library/Mobile Documents/com~apple~CloudDocs/Lavoro/PhD Bergamo/R/GitHub/GRINS-Spoke0-WP2/AQ-FRK/v.3.0.0/A_input/data/input/AQ_EEA_v100_ST.rda")



summary(EM_CAMS_v2@data)
