
library(ggplot2)

plot_day_emissions <- function(data_matrix, day_index, title = NULL, save_path = NULL) {
  
  # Estrai la matrice del giorno
  daily_data <- data_matrix[,,day_index]
  
  # Estrai le coordinate da dimnames
  lon_vals <- as.numeric(dimnames(data_matrix)[[1]])
  lat_vals <- as.numeric(dimnames(data_matrix)[[2]])
  
  # Crea il dataframe
  df <- expand.grid(
    lon = lon_vals,
    lat = lat_vals
  )
  df$value <- as.vector(daily_data)
  
  # Plot base
  p <- ggplot(df, aes(x = lon, y = lat, fill = value)) +
    geom_tile() +
    scale_fill_viridis_c(name = "Emissions", trans = "log10") +
    coord_fixed(1.3) +
    theme_minimal() +
    labs(
      title = title %||% paste("Emissions - Day", day_index),
      x = "Longitude",
      y = "Latitude"
    )
  
  # Salva o mostra
  if (!is.null(save_path)) {
    ggsave(save_path, plot = p, dpi = 300, width = 8, height = 6)
  } else {
    print(p)
  }
}

plot_day_emissions(
  data_matrix = SumAllSectors_NOx_2020 * 1e6 * 60 * 60 * 24,
  day_index = 16,
  title = "NO₂ Emissions - 16 Jan 2020"
)

plot_day_emissions(
  data_matrix = GLOB_daily_nox_sum_2023 * 1e6 * 60 * 60 * 24,
  day_index = 16,
  title = "NO₂ Emissions - 16 Jan 2023"
)


