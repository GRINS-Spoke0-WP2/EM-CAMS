SumAllSectors_NOx_2019 <- readRDS("EM-CAMS/v.2.0.0/data/SumAllSectors_NOx_2019.rds")
dim(SumAllSectors_NOx_2019)
dimnames(SumAllSectors_NOx_2019)
Y <- SumAllSectors_NOx_2019
Y <- aperm(Y,c(2,1,3))
Y[Y>quantile(Y,.99)]<-quantile(Y,.99)

EM_CAMS_NO2_2019 <- data.frame(
  Longitude = rep(rep(dimnames(Y)[[2]], each = dim(Y)[1]), dim(Y)[3]),
  Latitude = rep(dimnames(Y)[[1]], dim(Y)[2] * dim(Y)[3]),
  time = rep(as.Date(as.numeric(dimnames(
    Y
  )[[3]]), origin = as.Date("1850-01-01")), each = dim(Y)[2] * dim(Y)[1])
)
EM_CAMS_NO2_2019 <- cbind(EM_CAMS_NO2_2019,
                               matrix(c(Y)))
names(EM_CAMS_NO2_2019)[4]<-"EM_CAMS_NO2"
centre <-
  data.frame(Longitude = as.numeric(rep(rep(
    dimnames(Y)[[2]], each = dim(Y)[1]
  ))),
  Latitude = as.numeric(rep(dimnames(Y)[[1]], dim(Y)[2])))
coordinates(centre) <- c("Longitude", "Latitude")
gridded(centre) <- TRUE
colnames(centre@coords) <- c("coords.x1", "coords.x2")
EM_CAMS_NO2_2019_ST <- STFDF(
  sp = centre,
  time = unique(EM_CAMS_NO2_2019$time),
  data = EM_CAMS_NO2_2019
)

stplot(EM_CAMS_NO2_2019_ST[, 1:2, "EM_CAMS_NO2"])

saveRDS(EM_CAMS_NO2_2019_ST, file = "EM-CAMS/v.2.0.0/data/EM_CAMS_v2.rds")
