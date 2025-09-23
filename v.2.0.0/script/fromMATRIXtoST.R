EM_CAMS <- readRDS("EM-CAMS/v.2.0.0/data/EM_NOx.rds")
# summary(as.Date(as.numeric(dimnames(EM_CAMS)[3][[1]]),origin = as.Date("1850-01-01")))
t <- as.Date(as.numeric(dimnames(EM_CAMS)[3][[1]]),origin = as.Date("1850-01-01"))
t201323 <- t <= as.Date("2023-12-31") & t >= as.Date("2013-01-01")
EM_CAMS <- EM_CAMS[,,t201323]
dimnames(EM_CAMS)[[3]] <- as.character(as.numeric(seq.Date(as.Date("2013-01-01"),
                                                           as.Date("2023-12-31"),
                                                           by="days")))
# Y <- EM_CAMS_v100_matrix
Y <- EM_CAMS
max_thr <- quantile(Y, .99) # da mettere nel preprocessing !
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

hist(EM_CAMS_v100_ST@data$EM_NO2)
hist(log(EM_CAMS_v100_ST@data$EM_NO2))

EM_CAMS_v200_ST <- EM_CAMS_v100_ST
save(EM_CAMS_v200_ST,file = "EM_CAMS_v200_ST.rda")
