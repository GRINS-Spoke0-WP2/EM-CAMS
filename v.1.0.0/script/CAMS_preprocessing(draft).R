library(doParallel)
registerDoParallel()
library(ncdf4)

setwd("EM-CAMS")
vers <- "v.1.0.0"
#v6.2 #### DOWNLOADED MANUALLY
pathSSD <- "/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/EM-CAMS"
vers <- paste0(pathSSD,"/",vers)
source("v.1.0.0/script/functions.R")
EMfiles <-
  list.files(paste0(vers, "/data/monthly/raw"))
boundary <- c(6, 19, 35, 48)
nc <- nc_open(paste0(vers, "/data/monthly/raw/", EMfiles))
EM_data <- data.frame(getvarCAMS(nc=nc, boundary=boundary, variables="sum"))
names(EM_data)<-c("lon","lat","time","EM_no2")
start <- as.Date("2013-01-01", tz="UTC")
end <- as.Date("2023-12-31", tz="UTC")
EM_data <- EM_data[EM_data$time>=start & EM_data$time <=end,]
EM_data$EM_no2 <- EM_data$EM_no2*10^6*86400
#converting to days
meta_EM <- unique(EM_data[,c(1,2)])
days <- seq.Date(from = start,to=end,by="day")
meta_EM_ext <- cbind(meta_EM[rep(1:nrow(meta_EM),length(days)),],rep(days,each=nrow(meta_EM)))
names(meta_EM_ext)[3]<-"days"

EM_dataset <- merge(meta_EM_ext[,c(1,2,3,6)],EM_data[,c(1,2,7,4)],all.x = T)
EM_dataset <- EM_dataset[,-3]
EM_dataset <- EM_dataset[order(EM_dataset$lon,EM_dataset$lat,EM_dataset$days),]
save(EM_dataset,file="data/EM/CAMS_GLOB_ANT/v6_2/EM_dataset.Rdata")
write.csv(EM_dataset,file = "data/EM/CAMS_GLOB_ANT/v6_2/EM_dataset.csv",
          row.names = F)


#v4.2#### NOT USED
#pathSSD <- "/Volumes/Extreme SSD/Lavoro/GRINS/R_GRINS"

#EMfiles <-
#  list.files(paste0(pathSSD, "/data/EM/CAMS_GLOB_ANT/NO2/v4_2"))
#year <-
#  unlist(lapply(EMfiles, function(x)
#    x <- substr(x, nchar(x) - 6, nchar(x) - 3)))
#boundary <- c(6, 19, 35, 48)
#no2 <-
#  foreach (i = EMfiles,
#           .packages = "ncdf4",
#           .combine = rbind) %dopar% {
#             year <- substr(i, nchar(i) - 6, nchar(i) - 3)
#             nc <-
#               nc_open(paste0(pathSSD, "/data/EM/CAMS_GLOB_ANT/NO2/v4_2/", i))
#             no2 <- data.frame(getvarCAMS(nc, year, boundary, "sum"))
#             names(no2) <- c("lon", "lat", "time", "EM_no2")
#             no2
#           }
#save(no2,file="data/EM/CAMS/no2_monthly.Rdata")
