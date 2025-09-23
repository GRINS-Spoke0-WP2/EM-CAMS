load("EM-CAMS/v.1.0.0/data/daily/EM_CAMS_v100_matrix.rda")
Y <- EM_CAMS_v100_matrix
max_thr <- quantile(Y, .995) # da mettere nel preprocessing !
Y[Y > max_thr] <- max_thr
# EM_CAMS_v100_matrix <- Y
EM_CAMS_v100_df <- data.frame(
  Longitude = rep(rep(dimnames(Y)[[2]], each = dim(Y)[1]), dim(Y)[3]),
  Latitude = rep(dimnames(Y)[[1]], dim(Y)[2] * dim(Y)[3]),
  time = rep(as.Date(as.numeric(dimnames(
    Y
  )[[3]])), each = dim(Y)[2] * dim(Y)[1])
)

EM_CAMS_v100_df <- cbind(EM_CAMS_v100_df,
                         matrix(c(Y), ncol = 1))

names(EM_CAMS_v100_df)[-c(1:3)] <- "EM_NO2"
centre <-
  data.frame(Longitude = as.numeric(rep(rep(
    dimnames(Y)[[2]], each = dim(Y)[1]
  ))),
  Latitude = as.numeric(rep(dimnames(Y)[[1]], dim(Y)[2])))
coordinates(centre) <- c("Longitude", "Latitude")
gridded(centre) <- TRUE
colnames(centre@coords) <- c("coords.x1", "coords.x2")
EM_CAMS_v100_ST <- STFDF(sp = centre,
                         time = unique(EM_CAMS_v100_df$time),
                         data = EM_CAMS_v100_df)

stplot(EM_CAMS_v100_ST[,1:2,"EM_NO2"])
save(EM_CAMS_v100_ST,
     file = "EM-CAMS/v.1.0.0/data/daily/EM_CAMS_v101_ST.rda")

