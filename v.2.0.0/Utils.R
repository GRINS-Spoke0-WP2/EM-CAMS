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
get_lon_lat_indices <- function(nc_file_path, boundary) {
  # Open the NetCDF file
  nc <- open_nc_file(nc_file_path)
  
  # Get longitude and latitude variables
  lon <- ncvar_get(nc, "lon")
  lat <- ncvar_get(nc, "lat")
  
  # Determine the indices within the specified boundaries
  lon_idx <- which(lon >= boundary[1] & lon <= boundary[2])
  lat_idx <- which(lat >= boundary[3] & lat <= boundary[4])
  
  # Save lon, lat, lon_idx, lat_idx in an RDS file
  saveRDS(list(lon = lon, lat = lat, lon_idx = lon_idx, lat_idx = lat_idx), 
          "Demo/Data/Processed/ANT_data/lon_lat_idx.rds")
  
  # Close the NetCDF file
  nc_close(nc)
  
  # Return the extracted data
  return(list(lon = lon, lat = lat, lon_idx = lon_idx, lat_idx = lat_idx))
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