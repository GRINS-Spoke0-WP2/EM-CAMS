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
Y <- Y * (10^6) * 86400
max_thr <- quantile(Y, .99) # da mettere nel preprocessing !
Y[Y > max_thr] <- max_thr
EM_CAMS_v300_matrix <- Y
EM_CAMS_v300_df <- data.frame(
  Longitude = rep(rep(dimnames(Y)[[2]], each = dim(Y)[1]), dim(Y)[3]),
  Latitude = rep(dimnames(Y)[[1]], dim(Y)[2] * dim(Y)[3]),
  time = rep(as.Date(
    as.numeric(dimnames(Y)[[3]]), origin = as.Date("1850-01-01")
  ), each = dim(Y)[2] * dim(Y)[1])
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

stplot(EM_CAMS_v300_ST[, 1:2, "EM_NO2"])

#2023 from Nychka
t <- seq.Date(as.Date("2023-01-01"), as.Date("2023-12-31"), "days")
EM_CAMS_v300_ST <- EM_CAMS_v300_ST[, which(index(EM_CAMS_v300_ST@time) %in% t)]

saveRDS(EM_CAMS_v300_ST, file = "v.3.0.0/data.nosync/ST/EM_NO2_CAMS_v300_ST_2023.rds")

rm(list = setdiff(ls(), c(start_ls, "start_ls")))
gc()

as.Date(as.numeric(dimnames(EM_NO2)[[3]]), origin = as.Date("1850-01-01"))

# netcdf 2013-2023  - all pollutants ####
# ho due serie di files, uno che copre 2013-2024 e l'altro dal 2000 al 2012
# ora lavoro solo con il 2013-2024. Dato che si tratta di file
# da quasi 1 GB per inquinante (in matrice quindi già nella forma più snella)
# uso i netcdf
# 03/02/2026: modificare per aggiungere anche il periodo 2000-2012
# e pensare a come estendere al 2025-2026

SSD_path <- "/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/EM-CAMS/v.3.0.0"
EM_files <- list.files(SSD_path, pattern = ".rds")
# for (i in EM_files) {
#   EM_array <- readRDS(file.path(SSD_path,i))
#   print(summary(as.Date(as.numeric(dimnames(EM_array)[[3]]),origin=as.Date("1850-01-01"))))
#   print(dim(EM_array))
#   rm(EM_array)
#   gc()
# } #check they are all the same

i <- EM_files[1]
EM_array <- readRDS(file.path(SSD_path, i))

prova <- EM_array[, , 1]

library(spacetime)
library(sp)

summary(as.Date(as.numeric(dimnames(EM_array)[[3]]), origin = as.Date("1850-01-01")))
dims <- dim(EM_array)
dims <- c(dims, length(EM_files))

library(ncdf4)

lat <- as.numeric(dimnames(EM_array)[[1]])
lat_dim <- ncdim_def("lat", "degrees_north", lat)

lon <- as.numeric(dimnames(EM_array)[[2]])
lon_dim <- ncdim_def("lon", "degrees_east", lon)

time <- as.numeric(dimnames(EM_array)[[3]])
time_dim <- ncdim_def("time", "days", time)

pollutants <- gsub("EM_|-2|.rds", "", EM_files)
pollutants_dim <- ncdim_def("pollutant", "", 1:7)

chunk_dims <- c(260, 130, 30, 7)

values_var <- ncvar_def(
  name = "em_fluxes",
  units = "kg m-2 sec-1",
  dim = list(lat_dim, lon_dim, time_dim, pollutants_dim),
  missval = NA,
  longname = "Emissions from CAMS-REG elaborated by UNIBG",
  prec = "float",
  compression = 6,
  chunksizes = chunk_dims
)

file_name <- file.path(SSD_path, "EM_CAMS_v3_1324_2.nc")

nc <- nc_create(filename = file_name, vars = list(values_var))

for (i in 1:dims[4]) {
  fi <- EM_files[i]
  EM_array <- readRDS(file.path(SSD_path, fi))
  dimnames(EM_array) <- NULL
  ncvar_put(
    nc,
    varid = "em_fluxes",
    vals = EM_array,
    start = c(1, 1, 1, i),
    count = c(dims[1], dims[2], dims[3], 1)
  )
  print(paste("end", pollutants[i]))
}

ncvar_put(nc, "lat", lat)
ncvar_put(nc, "lon", lon)
ncvar_put(nc, "time", time)
ncvar_put(nc, "pollutant", 1:7)
ncatt_put(nc,
          "pollutant",
          "description",
          paste(pollutants, collapse = ";"))

ncatt_put(nc,
          "em_fluxes",
          "description",
          "Emissions from CAMS-REG elaborated by UNIBG")
ncatt_put(nc, 0, "title", "Dataset di emissioni UNIBG")  # attributo globale

nc_close(nc)

#così quando ci sono i dati del 2025 li attacchiamo senza dover aprire tutto il netcdf

# 21.01.2025: penso che sia finita qui la parte in cui facciamo il netcdf
# e che la restante non sia di interesse adesso
# adesso riapro il file per vederlo in faccia


library(ncdf4)
SSD_path <- "/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/EM-CAMS/v.3.0.0"
file_name <- file.path(SSD_path, "EM_CAMS_v3_1324.nc")
nc <- nc_open(file_name)

nc$dim$pollutant$labels

ncvar_get()


# qui (21.01.2025)

# netcdf 2000-2024  - all pollutants ####
# ho due serie di files, uno che copre 2013-2024 e l'altro dal 2000 al 2012
SSD_path <- "/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/EM-CAMS/v.3.0.0"
EM_files <- list.files(SSD_path, pattern = ".rds")
EM_files_2000 <- list.files(file.path(SSD_path, "2000-2012"), pattern = ".rds")

# for (i in EM_files) {
#   EM_array <- readRDS(file.path(SSD_path,i))
#   lat <- as.numeric(dimnames(EM_array)[[1]])
#   lon <- as.numeric(dimnames(EM_array)[[2]])
#   time <- as.numeric(dimnames(EM_array)[[3]])
#   print(summary(lat))
#   print(summary(lon))
#   print(summary(time))
#   print(summary(as.Date(as.numeric(dimnames(EM_array)[[3]]),origin=as.Date("1850-01-01"))))
#   print(dim(EM_array))
#   rm(EM_array)
#   gc()
# } #check they are all the same
#
# for (i in EM_files_2000) {
#   EM_array <- readRDS(file.path(SSD_path,"2000-2012",i))
#   lat <- as.numeric(dimnames(EM_array)[[1]])
#   lon <- as.numeric(dimnames(EM_array)[[2]])
#   time <- as.numeric(dimnames(EM_array)[[3]])
#   print(summary(lat))
#   print(summary(lon))
#   print(summary(time))
#   print(summary(as.Date(as.numeric(dimnames(EM_array)[[3]]),origin=as.Date("1850-01-01"))))
#   print(dim(EM_array))
#   rm(EM_array)
#   gc()
# } #check they are all the same
#
# # CHECK DONE

library(ncdf4)
# 2000-2012
EM_array <- readRDS(file.path(SSD_path, "2000-2012", EM_files_2000[1]))
lat <- as.numeric(dimnames(EM_array)[[1]])
lon <- as.numeric(dimnames(EM_array)[[2]])
time_2000 <- as.numeric(dimnames(EM_array)[[3]])

# extend time 2013-2024
EM_array <- readRDS(file.path(SSD_path, EM_files[1]))
time <- as.numeric(dimnames(EM_array)[[3]])

time <- c(time_2000, time)
time <- as.Date(time, origin = as.Date("1850-01-01"))
time <- as.numeric(time)

# netcdf
lon_dim <- ncdim_def("lon", "degrees_east", lon)
lat_dim <- ncdim_def("lat", "degrees_north", lat)
time_dim <- ncdim_def(
  name = "time",
  units = "days",
  vals = time,
  calendar = "gregorian"
)

chunk_dims <- c(130, 260, 15)

pollutants <- gsub("EM_|-2|.rds", "", EM_files)
long_pol <- c(
  "Carbon Monoxide",
  "Ammonia",
  "Non-Methane Volatile Organic Compounds",
  "Nitrogen Oxides",
  "Particulate matter with diameter less than 10 micrometers",
  "Particulate matter with diameter less than 2.5 micrometers",
  "Sulphure Dioxide"
)

i <- 1
list_var <- list()
for (p in pollutants) {
  list_var[[i]] <- ncvar_def(
    name = p,
    units = "mg m-2 / day",
    dim = list(lon_dim, lat_dim, time_dim),
    missval = NA,
    longname = long_pol[i],
    prec = "float",
    compression = 6,
    chunksizes = chunk_dims
  )
  i <- i + 1
}

file_name <- file.path(SSD_path, "EM_CAMS_v3_0024.nc")

nc <- nc_create(filename = file_name, vars = list_var)

i <- 1
for (p in pollutants) {
  fil <- EM_files_2000[grep(p, EM_files_2000)]
  EM_array_2000 <- readRDS(file.path(SSD_path, "2000-2012", fil))
  EM_array_2000 <- aperm(EM_array_2000,c(2,1,3))
  fil <- EM_files[grep(p, EM_files)]
  EM_array <- readRDS(file.path(SSD_path, fil))
  EM_array <- aperm(EM_array,c(2,1,3))
  EM_array <- abind(EM_array_2000, EM_array, along = 3)
  EM_array <- EM_array * 60 * 60 * 24 * (10^6)
  dimnames(EM_array) <- NULL
  ncvar_put(nc = nc,
            varid = list_var[[i]],
            vals = EM_array)
  i <- i + 1
  print(paste(p,"finished"))
}

ncatt_put(nc, "lon", "description", "East Earth degree from Greenwich") #,verbose=FALSE) #,definemode=FALSE)
ncatt_put(nc, "lat", "description", "North Earth degree from Equator")
ncatt_put(nc, "time", "description", "Number of days from 01-01-2000")

ncatt_put(nc, 0, "title", "Emissions fluxes in Italy for the period 2000-2024")
ncatt_put(nc, 0, "institution", "University of Bergamo")
ncatt_put(nc, 0, "source", "own elaboration for CAMS-REG")
ncatt_put(
  nc,
  0,
  "references",
  "Fusta Moro Alessandro, Borqal Amin, Fassò Alessandro. Emission Daily Dataset over Italy for the period 2000-2024 (2026)"
)

nc_close(nc)

# check
rm(list=ls())
library(ncdf4)
SSD_path <- "/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/EM-CAMS/v.3.0.0"
nc <- nc_open(file.path(SSD_path,"EM_CAMS_v3_0024.nc"))
nc

tt <- seq.Date(as.Date("2000-01-01"),as.Date("2024-12-31"),"days")
nt <- which(tt==as.Date("2023-01-01"))

nox_em <- ncvar_get(nc,"PM2_5",start = c(1,1,nt),count = c(130,260,1))
lon <- ncvar_get(nc,"lon")
lat <- ncvar_get(nc,"lat")
df <- cbind(expand.grid(lon,lat),c(nox_em))
names(df)[3]<-"nox_em"
library(sp)
coordinates(df)<-c("Var1","Var2")

sub <- GRINS_AQCLIM_points_Italy[GRINS_AQCLIM_points_Italy$time == as.Date("2023-01-01"),]
sub <- merge(sub,Station_registry_information)

coordinates(sub)<-c("Longitude","Latitude")
gridded(df)<-TRUE
sub2 <- cbind(sub@data,over(sub, df))
names(sub2)
cor(sub2$AQ_mean_PM2.5,sub2$nox_em,use="pairwise.complete.obs")
nox_em_trh <- quantile(sub2$nox_em,probs = .99)
sub2$nox_em_thr <- sub2$nox_em
sub2$nox_em_thr[sub2$nox_em_thr>nox_em_trh] <- nox_em_trh
cor(sub2$AQ_mean_PM2.5,sub2$nox_em_thr,use="pairwise.complete.obs")
cor(sub2$AQ_mean_PM2.5,log10(sub2$nox_em),use="pairwise.complete.obs")


pm25 <- ncvar_get(nc,"PM2_5",start = c(1,1,1),count = c(130,260,1))
image(pm25)

pm25or <- pm25 / (60 * 60 * 24 * (10^6))
image(log(pm25or))

summary(c(pm25))
hist(c(pm25))
max_thr <- quantile(pm25,.995)
pm25_mod <- pm25
pm25_mod[pm25_mod>max_thr]<-max_thr
image(pm25_mod)

# how to make a dataframe

lon <- ncvar_get(nc,"lon")
lat <- ncvar_get(nc,"lat")
library(ggplot2)
df <- cbind(expand.grid(lon,lat),c(pm25or))
names(df)[3]<-"pm25"
ggplot(df,aes(Var1,Var2,fill=pm25))+
  geom_tile()+
  scale_fill_continuous(transform="log10",
                        type = "viridis")


# create the 2024 for new AQCLIM (and for AMELIA) ####

# ho due serie di files, uno che copre 2013-2024 e l'altro dal 2000 al 2012
SSD_path <- "/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/EM-CAMS/v.3.0.0"
EM_files <- list.files(SSD_path, pattern = ".rds")
EM_files_2000 <- list.files(file.path(SSD_path, "2000-2012"), pattern = ".rds")

# for (i in EM_files) {
#   EM_array <- readRDS(file.path(SSD_path,i))
#   lat <- as.numeric(dimnames(EM_array)[[1]])
#   lon <- as.numeric(dimnames(EM_array)[[2]])
#   time <- as.numeric(dimnames(EM_array)[[3]])
#   print(summary(lat))
#   print(summary(lon))
#   print(summary(time))
#   print(summary(as.Date(as.numeric(dimnames(EM_array)[[3]]),origin=as.Date("1850-01-01"))))
#   print(dim(EM_array))
#   rm(EM_array)
#   gc()
# } #check they are all the same
#
# for (i in EM_files_2000) {
#   EM_array <- readRDS(file.path(SSD_path,"2000-2012",i))
#   lat <- as.numeric(dimnames(EM_array)[[1]])
#   lon <- as.numeric(dimnames(EM_array)[[2]])
#   time <- as.numeric(dimnames(EM_array)[[3]])
#   print(summary(lat))
#   print(summary(lon))
#   print(summary(time))
#   print(summary(as.Date(as.numeric(dimnames(EM_array)[[3]]),origin=as.Date("1850-01-01"))))
#   print(dim(EM_array))
#   rm(EM_array)
#   gc()
# } #check they are all the same
#
# # CHECK DONE

library(ncdf4)
# 2000-2012
EM_array <- readRDS(file.path(SSD_path, "2000-2012", EM_files_2000[1]))
lat <- as.numeric(dimnames(EM_array)[[1]])
lon <- as.numeric(dimnames(EM_array)[[2]])

# extend time 2013-2024
EM_array <- readRDS(file.path(SSD_path, EM_files[1]))
time <- as.numeric(dimnames(EM_array)[[3]])

time <- c(time_2000, time)
time <- as.Date(time, origin = as.Date("1850-01-01"))
time <- time[format(time,"%Y")=="2024"]
time <- as.numeric(time)

# netcdf
lon_dim <- ncdim_def("lon", "degrees_east", lon)
lat_dim <- ncdim_def("lat", "degrees_north", lat)
time_dim <- ncdim_def(
  name = "time",
  units = "days",
  vals = time,
  calendar = "gregorian"
)

chunk_dims <- c(130, 260, 15)

pollutants <- gsub("EM_|-2|.rds", "", EM_files)
long_pol <- c(
  "Carbon Monoxide",
  "Ammonia",
  "Non-Methane Volatile Organic Compounds",
  "Nitrogen Oxides",
  "Particulate matter with diameter less than 10 micrometers",
  "Particulate matter with diameter less than 2.5 micrometers",
  "Sulphure Dioxide"
)

i <- 1
list_var <- list()
for (p in pollutants) {
  list_var[[i]] <- ncvar_def(
    name = p,
    units = "mg m-2 / day",
    dim = list(lon_dim, lat_dim, time_dim),
    missval = NA,
    longname = long_pol[i],
    prec = "float",
    compression = 6,
    chunksizes = chunk_dims
  )
  i <- i + 1
}

file_name <- file.path(SSD_path, "EM_CAMS_v3_24.nc")

nc <- nc_create(filename = file_name, vars = list_var)

i <- 1
for (p in pollutants) {
  # fil <- EM_files_2000[grep(p, EM_files_2000)]
  # EM_array_2000 <- readRDS(file.path(SSD_path, "2000-2012", fil))
  # EM_array_2000 <- aperm(EM_array_2000,c(2,1,3))
  fil <- EM_files[grep(p, EM_files)]
  EM_array <- readRDS(file.path(SSD_path, fil))
  EM_array <- aperm(EM_array,c(2,1,3))
  EM_array <- EM_array * 60 * 60 * 24 * (10^6)
  time <- as.numeric(dimnames(EM_array)[[3]])
  time <- as.Date(time, origin = as.Date("1850-01-01"))
  dimnames(EM_array) <- NULL
  ncvar_put(nc = nc,
            varid = list_var[[i]],
            vals = EM_array[,,format(time,"%Y") == "2024"])
  i <- i + 1
  print(paste(p,"finished"))
}

ncatt_put(nc, "lon", "description", "East Earth degree from Greenwich") #,verbose=FALSE) #,definemode=FALSE)
ncatt_put(nc, "lat", "description", "North Earth degree from Equator")
ncatt_put(nc, "time", "description", "Number of days from 2024-01-01")

ncatt_put(nc, 0, "title", "Emissions fluxes in Italy for the 2024")
ncatt_put(nc, 0, "institution", "University of Bergamo")
ncatt_put(nc, 0, "source", "own elaboration for CAMS-REG")
ncatt_put(
  nc,
  0,
  "references",
  "Fusta Moro Alessandro, Borqal Amin, Fassò Alessandro. Emission Daily Dataset over Italy for the period 2024 (2026)"
)

nc_close(nc)

# check
rm(list=ls())
library(ncdf4)
SSD_path <- "/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/EM-CAMS/v.3.0.0"
nc <- nc_open(file.path(SSD_path,"EM_CAMS_v3_24.nc"))
nc

tt <- seq.Date(as.Date("2024-01-01"),as.Date("2024-12-31"),"days")
nt <- which(tt==as.Date("2024-05-01"))

nox_em <- ncvar_get(nc,"PM2_5",start = c(1,1,nt),count = c(130,260,1))

lon <- ncvar_get(nc,"lon")
lat <- ncvar_get(nc,"lat")
df <- cbind(expand.grid(lon,lat),c(nox_em))
names(df)[3]<-"nox_em"
library(sp)
coordinates(df)<-c("Var1","Var2")

sub <- GRINS_AQCLIM_points_Italy[GRINS_AQCLIM_points_Italy$time == as.Date("2023-01-01"),]
sub <- merge(sub,Station_registry_information)

coordinates(sub)<-c("Longitude","Latitude")
gridded(df)<-TRUE
sub2 <- cbind(sub@data,over(sub, df))
names(sub2)
cor(sub2$AQ_mean_PM2.5,sub2$nox_em,use="pairwise.complete.obs")
nox_em_trh <- quantile(sub2$nox_em,probs = .99)
sub2$nox_em_thr <- sub2$nox_em
sub2$nox_em_thr[sub2$nox_em_thr>nox_em_trh] <- nox_em_trh
cor(sub2$AQ_mean_PM2.5,sub2$nox_em_thr,use="pairwise.complete.obs")
cor(sub2$AQ_mean_PM2.5,log10(sub2$nox_em),use="pairwise.complete.obs")


pm25 <- ncvar_get(nc,"PM2_5",start = c(1,1,1),count = c(130,260,1))
image(pm25)

pm25or <- pm25 / (60 * 60 * 24 * (10^6))
image(log(pm25or))

summary(c(pm25))
hist(c(pm25))
max_thr <- quantile(pm25,.995)
pm25_mod <- pm25
pm25_mod[pm25_mod>max_thr]<-max_thr
image(pm25_mod)

# how to make a dataframe

lon <- ncvar_get(nc,"lon")
lat <- ncvar_get(nc,"lat")
library(ggplot2)
df <- cbind(expand.grid(lon,lat),c(pm25or))
names(df)[3]<-"pm25"
ggplot(df,aes(Var1,Var2,fill=pm25))+
  geom_tile()+
  scale_fill_continuous(transform="log10",
                        type = "viridis")



# h5 (not used) ####

h5createFile(file_name)

h5createDataset(
  file = file_name,
  dataset = "values",
  dims = dims,
  chunk = chunk_dims,
  storage.mode = "double",
  # puoi usare "double" o "float"
  level = 6                 # compressione gzip, da 0 a 9
)

h5writeAttribute(dimnames(EM_array)[[1]], file_name, "values", attr = "lat")
h5writeAttribute(dimnames(EM_array)[[2]], file_name, "values", attr = "lon")
h5writeAttribute(dimnames(EM_array)[[3]], file_name, "values", attr = "time")

h5writeAttribute(pols, file_name, "values", attr = "pollutant")

for (i in 1:dims[4]) {
  fi <- EM_files[i]
  EM_array <- readRDS(file.path(SSD_path, fi))
  dimnames(EM_array) <- NULL
  h5write(
    obj = EM_array,
    file = file_name,
    name = "values",
    index = list(1:dims[1], # tutta la dimensione X
                 1:dims[2], # tutta la dimensione Y
                 1:dims[3], # giorni da scrivere
                 i        # tutti gli inquinanti)))
    ))
}

# converting ST #####
# inserisci i tuoi dati in questa cartella
EM_files <- list.files("v.3.0.0/data.nosync", ".rds")

for (i in EM_files) {
  Y <- readRDS(file.path("v.3.0.0/data.nosync", i))
  t_data <- as.Date(as.numeric(dimnames(Y)[[3]]), origin = as.Date("1850-01-01"))
  # t_2024 <- seq.Date(as.Date("2024-01-01"),as.Date("2024-12-31"),"days")
  # importare anche 2000-2012 e unirli
  # prima controllare che abbia messo
  # le coordinate nello stesso modo e le
  # dimensioni delle matrici
  t_idx <- which(t_data %in% t_2024)
  Y <- Y[, , t_idx]
  if (i == EM_files[1]) {
    Y_all <- Y
  } else{
    Y_all <- abind(Y_all, Y, along = 4)
  }
}
dimnames(Y_all)[[4]] <- gsub("EM_|-2.rds", "", EM_files)
Y_all <- Y_all * (10^6) * 86400
EM_CAMS_v300_df <- data.frame(
  Longitude = rep(rep(dimnames(Y_all)[[2]], each = dim(Y_all)[1]), dim(Y_all)[3]),
  Latitude = rep(dimnames(Y_all)[[1]], dim(Y_all)[2] * dim(Y_all)[3]),
  time = rep(
    as.Date(as.numeric(dimnames(Y_all)[[3]]), origin = as.Date("1850-01-01")),
    each = dim(Y_all)[2] * dim(Y_all)[1]
  )
)
EM_CAMS_v300_df <- cbind(EM_CAMS_v300_df, as.data.frame(matrix(c(Y_all), nrow(EM_CAMS_v300_df))))
names(EM_CAMS_v300_df)[-c(1:3)] <- paste0("EM_", dimnames(Y_all)[[4]])
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
  if (nv %in% c("EM_PM2_5", "PM10")) {
    qt <- .995
  }
  if (nv %in% c("EM_CO")) {
    qt <- .999
  }
  max_thr <- quantile(EM_CAMS_v300_ST@data[, nv], qt) # da mettere nel preprocessing !
  nvi <- which(names(EM_CAMS_v300_df) == nv)
  exceed <- EM_CAMS_v300_ST@data[, nvi] > max_thr
  EM_CAMS_v300_ST@data[exceed, nvi] <- max_thr
  print(stplot(EM_CAMS_v300_ST[, 1:2, nv]))
}
# .99 for NOx and SO2 e NMVOC e NH3
# .995 per PM2.5 e PM10
# .999 per CO

saveRDS(EM_CAMS_v300_ST, file = "v.3.0.0/data.nosync/ST/EM_CAMS_v300_ST_ALL.rds")

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
