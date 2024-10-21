# getvarCAMS ####
getvarCAMS<-function(nc,year=NULL,boundary,variables){
  b <- boundary
  lo <- round(ncvar_get(nc,"lon"),2)
  la <- round(ncvar_get(nc,"lat"),2)
  st <- c(nrow(lo[lo <= b[1]]),
          nrow(la[la <= b[3]]),
          1)
  co <- c(nrow(lo[lo >= b[1] & lo <= b[2]]),
          nrow(la[la >= b[3] & la <= b[4]]),
          nc$dim$time$len)
  x <- ncvar_get(nc,"lon",start=st[1],count=co[1])
  y <- ncvar_get(nc,"lat",start=st[2],count=co[2])
  t <- ncvar_get(nc,"time",start=st[3],count=co[3])
  listnames <- variables
  Nvars <- length(listnames)
  ncvar <- list()
  for (i in 1:Nvars){
    ncvar[[i]] <- ncvar_get(nc,listnames[i],start=st,count=co)
  }
  # i identifies the sector
  dflist<-list()
  t <- as.POSIXct(t*3600, origin="1850-01-01 00:00:00", tz="UTC")
  if(is.null(year)){
    yearmin<-substr(as.character(min(t)),1,4)
    yearmax<-substr(as.character(max(t)),1,4)
  }else{
    yearmin<-year
    yearmax<-year
  }
  start_time <- as.Date(paste0(yearmin,"/01/01"))
  end_time <- as.Date(paste0(yearmax,"/12/31"))
  time<-seq(start_time,end_time,by="months")
  for (ln in listnames) {
    dflist[[ln]]<-data.frame(
      lon=rep(x,(length(y)*length(t))),
      lat=rep(rep(y,each=length(x)),length(t)),
      time=rep(time,each=(length(x)*length(y))),
      CAMSvar=c(ncvar[[which(listnames==ln)]])
    )
  }
  return(dflist)
}
