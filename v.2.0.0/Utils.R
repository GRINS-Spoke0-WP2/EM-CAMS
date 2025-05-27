library(ncdf4)

#Open NetCDF file
open_nc_file <- function(file_path) {
    nc <- nc_open(file_path)
    return(nc)
}

#Convert units from kg/m^2 * s to mg/m^2 * day
convert <- function(data_matrix) {
    data_matrix <- data_matrix * 10^6
    data_matrix <- data_matrix * 60 * 60 * 24
    return(data_matrix)
}

# Function to save the matrix to an RDS file and clean up the environment
save_data <- function(data, file_path) {
  # Save the dataset to an RDS file
  saveRDS(data, file = file_path)
}

# Function to get longitude, latitude, and their indices within specified boundaries
# Function to extract longitude, latitude, and their indices within specified boundaries
get_lon_lat_indices <- function(nc_file_path, boundary, output_name) {
  # Open the NetCDF file
  nc <- nc_open(nc_file_path)
  
  # Get longitude and latitude variables
  lon <- ncvar_get(nc, "lon")
  lat <- ncvar_get(nc, "lat")
  
  # Determine the indices within the specified boundaries
  lon_idx <- which(lon >= boundary[1] & lon <= boundary[2])
  lat_idx <- which(lat >= boundary[3] & lat <= boundary[4])
  
  # Prepare the output list
  result <- list(
    lon      = lon,
    lat      = lat,
    lon_idx  = lon_idx,
    lat_idx  = lat_idx
  )
  
  # Save to RDS file
  output_path <- file.path("Data", "Processed", paste0(output_name, ".rds"))
  saveRDS(result, output_path)
  message("Saved to: ", output_path)
  
  # Close the NetCDF file
  nc_close(nc)
}

sector_names <- list(
  A = "A_PublicPower",
  B = "B_Industry",
  C = "C_OtherStationaryComb",
  D = "D_Fugitives",
  E = "E_Solvents",
  F = "F_RoadTransport",
  G = "G_Shipping",
  H = "H_Aviation",
  I = "I_OffRoad",
  J = "J_Waste",
  K = "K_AgriLivestock",
  L = "L_AgriOther",
  S = "SumAllSectors"
)

# Define the mapping for CAMS-GLOB-ANT sectors.
sector_names_GLOB <- list(
  agl = "agl",
  ags = "ags",
  awb = "awb",
  com = "com",
  ene = "ene",
  fef = "fef",
  ind = "ind",
  ref = "ref",
  res = "res",
  shp = "shp",
  sum = "sum",
  swd = "swd",
  tnr = "tnr",
  tro = "tro"
)