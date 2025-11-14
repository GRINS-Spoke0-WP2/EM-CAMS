library(sp)
library(spacetime)
library(abind)
setwd("EM-CAMS")
# sto subsettando il 2024 dai dati di AMIN per metterli dentro lo script di AMELIA
# poi vorrei fare anche quello di tutti i dataset
# forse però conviene fare prima NO2 o fare tutto?

# NO2 ####
# converting ST
Y <- readRDS("v.3.0.0/data.nosync/EM_NOx-2.rds")
Y <- Y*(10^6)*86400
max_thr <- quantile(Y, .99) # da mettere nel preprocessing !
Y[Y > max_thr] <- max_thr
EM_CAMS_v300_matrix <- Y
EM_CAMS_v300_df <- data.frame(
  Longitude = rep(rep(dimnames(Y)[[2]], each = dim(Y)[1]), dim(Y)[3]),
  Latitude = rep(dimnames(Y)[[1]], dim(Y)[2] * dim(Y)[3]),
  time = rep(as.Date(as.numeric(dimnames(Y)[[3]]), origin = as.Date("1850-01-01")), each = dim(Y)[2] * dim(Y)[1])
)

EM_CAMS_v300_df <- cbind(EM_CAMS_v300_df, matrix(c(Y), ncol = 1))

names(EM_CAMS_v300_df)[-c(1:3)] <- "EM_NO2"
centre <-
  data.frame(Longitude = as.numeric(rep(rep(
    dimnames(Y)[[2]], each = dim(Y)[1]
  ))), Latitude = as.numeric(rep(dimnames(Y)[[1]], dim(Y)[2])))
coordinates(centre) <- c("Longitude", "Latitude")
gridded(centre) <- TRUE
colnames(centre@coords) <- c("coords.x1", "coords.x2")
EM_CAMS_v300_ST <- STFDF(sp = centre,
                         time = unique(EM_CAMS_v300_df$time),
                         data = EM_CAMS_v300_df)

stplot(EM_CAMS_v300_ST[,1:2,"EM_NO2"])

#2023 from Nychka
t <- seq.Date(as.Date("2023-01-01"),as.Date("2023-12-31"),"days")
EM_CAMS_v300_ST <- EM_CAMS_v300_ST[,which(index(EM_CAMS_v300_ST@time)%in% t)]

saveRDS(EM_CAMS_v300_ST, file = "v.3.0.0/data.nosync/ST/EM_NO2_CAMS_v300_ST_2023.rds")

rm(list = setdiff(ls(), c(start_ls, "start_ls")))
gc()

as.Date(as.numeric(dimnames(EM_NO2)[[3]]), origin = as.Date("1850-01-01"))

# all pollutants ####
# sto subsettando il 2024 dai dati di AMIN per metterli dentro lo script di AMELIA

# converting ST
# inserisci i tuoi dati in questa cartella
EM_files <- list.files("v.3.0.0/data.nosync",".rds")

for (i in EM_files) {
  Y <- readRDS(file.path("v.3.0.0/data.nosync",i))
  t_data <- as.Date(as.numeric(dimnames(Y)[[3]]), origin = as.Date("1850-01-01"))
  t_2024 <- seq.Date(as.Date("2024-01-01"),as.Date("2024-12-31"),"days")
  t_idx <- which(t_data %in% t_2024)
  Y <- Y[,,t_idx]
  if(i==EM_files[1]){Y_all <- Y}else{Y_all <- abind(Y_all,Y,along=4)}
}
dimnames(Y_all)[[4]] <- gsub("EM_|-2.rds","",EM_files)
Y_all <- Y_all*(10^6)*86400
EM_CAMS_v300_df <- data.frame(
  Longitude = rep(rep(dimnames(Y_all)[[2]], each = dim(Y_all)[1]), dim(Y_all)[3]),
  Latitude = rep(dimnames(Y_all)[[1]], dim(Y_all)[2] * dim(Y_all)[3]),
  time = rep(as.Date(as.numeric(dimnames(Y_all)[[3]]), origin = as.Date("1850-01-01")), each = dim(Y_all)[2] * dim(Y_all)[1])
)
EM_CAMS_v300_df <- cbind(EM_CAMS_v300_df,as.data.frame(matrix(c(Y_all),nrow(EM_CAMS_v300_df))))
names(EM_CAMS_v300_df)[-c(1:3)]<-paste0("EM_",dimnames(Y_all)[[4]])
centre <-
  data.frame(Longitude = as.numeric(rep(rep(
    dimnames(Y_all)[[2]], each = dim(Y_all)[1]
  ))), Latitude = as.numeric(rep(dimnames(Y_all)[[1]], dim(Y_all)[2])))
coordinates(centre) <- c("Longitude", "Latitude")
gridded(centre) <- TRUE
colnames(centre@coords) <- c("coords.x1", "coords.x2")
EM_CAMS_v300_ST <- STFDF(sp = centre,
                         time = unique(EM_CAMS_v300_df$time),
                         data = EM_CAMS_v300_df)
for (nv in names(EM_CAMS_v300_df)[-c(1:3)]) {
# for (nv in "EM_NMVOC") {
  qt <- .99
  if(nv %in% c("EM_PM2_5","PM10")){qt <- .995}
  if(nv %in% c("EM_CO")){qt <- .999}
  max_thr <- quantile(EM_CAMS_v300_ST@data[,nv], qt) # da mettere nel preprocessing !
  nvi <- which(names(EM_CAMS_v300_df)==nv)
  exceed <- EM_CAMS_v300_ST@data[,nvi] > max_thr
  EM_CAMS_v300_ST@data[exceed,nvi] <- max_thr
  print(stplot(EM_CAMS_v300_ST[,1:2,nv]))
}
# .99 for NOx and SO2 e NMVOC e NH3
# .995 per PM2.5 e PM10
# .999 per CO

saveRDS(EM_CAMS_v300_ST,file = "v.3.0.0/data.nosync/ST/EM_CAMS_v300_ST_ALL.rds")
    
# install.packages("devtools")
# devtools::install_github("GRINS-Spoke0-WP2/geotools")
# library(geotools)

# DA FARE 
library(geotools)
LAUs_EM_df <- geomatching(
  list(EM_CAMS_v300_ST@data),
  settings = list(format = "xyt", type = "grid", crs = 4326),
  aggregate = T
)

save(LAUs_EM_df, file = file.path(C2_path_LAUs, "LAUs_EM_df.rda"))

