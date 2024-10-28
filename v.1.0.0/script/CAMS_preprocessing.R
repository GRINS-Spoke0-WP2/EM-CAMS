library(doParallel)
registerDoParallel()
library(ncdf4)

setwd("EM-CAMS")
vers <- "v.1.0.0"
#v6.2 #### DOWNLOADED MANUALLY
pathSSD <- "/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/EM-CAMS"
vers <- paste0(pathSSD, "/", vers)
source("v.1.0.0/script/functions.R")
EMfiles <-
  list.files(paste0(vers, "/data/monthly/raw"))
boundary <- c(6, 19, 35, 48)
nc <- nc_open(paste0(vers, "/data/monthly/raw/", EMfiles))
EM_data <-
  data.frame(getvarCAMS(
    nc = nc,
    boundary = boundary,
    variables = "sum"
  ))
names(EM_data) <- c("lon", "lat", "time", "EM_no2")
start <- as.Date("2013-01-01", tz = "UTC")
end <- as.Date("2023-12-31", tz = "UTC")
EM_data <- EM_data[EM_data$time >= start & EM_data$time <= end, ]
EM_data$EM_no2 <- EM_data$EM_no2 * 10 ^ 6 * 86400
#converting to matrix
EM_data <- EM_data[order(EM_data$lat, decreasing = T), ]
EM_data <- EM_data[order(EM_data$lon), ]
EM_data <- EM_data[order(EM_data$time), ]
y <- array(
  c(EM_data$EM_no2),
  c(length(unique(EM_data$lat)),
    length(unique(EM_data$lon)),
    length(unique(EM_data$time))),
  dimnames = list(
    unique(round(EM_data$lat,2)),
    unique(round(EM_data$lon,2)),
    unique(EM_data$time)
  )
)
#converting monthly matrix to daily matrix
dates <- as.Date(as.numeric(dimnames(y)[[3]]))
daily <- seq.Date(min(dates),as.Date("2023-12-31"),by="days")
y_d <- array(NA,c(dim(y)[1:2],length(daily)))
idx <- 0
for (d in 1:length(daily)) {
  print(paste("day",d))
  if (daily[d] %in% dates){idx <- idx + 1}
  y_d[,,d] <- y[,,idx]
}
dimnames(y_d)<-list(dimnames(y)[[1]],dimnames(y)[[2]],daily)

#exporting daily matrix
EM_CAMS_v100_matrix <- y_d
save(EM_CAMS_v100_matrix,file = "v.1.0.0/data/daily/EM_CAMS_v100_matrix.rda")
