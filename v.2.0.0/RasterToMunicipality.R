library(terra)
library(ggplot2)

emissioni <- Daily_sum_2000_2020_CO

# 1. Trasponi l’array da [lon, lat, giorni] a [lat, lon, giorni]
emissioni_corr <- aperm(emissioni, c(2, 1, 3))

# 2. Estrai il giorno da plottare (es. giorno 15)
giorno_index <- 15
emissioni_giorno <- emissioni_corr[,,giorno_index]
emissioni_giorno <- emissioni_giorno * 10^6 * 60 * 60 * 24

# 3. Coordinate
lat_vals <- as.numeric(dimnames(emissioni)[[2]])
lon_vals <- as.numeric(dimnames(emissioni)[[1]])

# 4. Crea raster
r <- rast(
  nrows = length(lat_vals),
  ncols = length(lon_vals),
  xmin = min(lon_vals),
  xmax = max(lon_vals),
  ymin = min(lat_vals),
  ymax = max(lat_vals),
  crs = "EPSG:4326"
)

# 5. Assegna valori
emissioni_giorno_flipped <- emissioni_giorno[nrow(emissioni_giorno):1, ]
values(r) <- as.vector(t(emissioni_giorno_flipped))

# 6. Plot con terra
plot(r, main = "CO Emissions - 15/01/2000")
plot(log10(r), main = "CO Emissions - 15/01/2000 (log10 scale)")

# 7. ggplot
df_plot <- as.data.frame(r, xy = TRUE)
colnames(df_plot) <- c("lon", "lat", "value")
df_plot$value[df_plot$value <= 0] <- NA

ggplot(df_plot, aes(x = lon, y = lat, fill = value)) +
  geom_tile() +
  scale_fill_gradientn(
    colors = c("black", "purple", "blue", "cyan", "green", "yellow", "orange", "red"),
    trans = "log10",
    name = "CO Emissions"
  ) +
  coord_fixed(1.3) +
  theme_minimal() +
  theme(legend.position = "bottom") +
  labs(
    title = "CO Emissions - 15/01/2000",
    x = "Longitude",
    y = "Latitude"
  )

# --- Mappa aggregata per comuni ---
library(sf)
library(dplyr)
library(tmap)

comuni_path <- "/Users/aminborqal/Documents/Projects/R/IEDD/Demo/Data/Raw/MAPS/ITA-Administrative-maps-2024/Com01012024_g"
comuni <- st_read(paste0(comuni_path, "/Com01012024_g_WGS84.shp")) %>%
  st_transform("EPSG:4326")

sf::sf_use_s2(FALSE)

milano_bbox <- st_as_sfc(st_bbox(c(
  xmin = 8.5,
  xmax = 10.5,
  ymin = 45.0,
  ymax = 46.8
), crs = st_crs(4326)))

comuni_milano <- st_crop(comuni, milano_bbox)
comuni_milano$ID <- 1:nrow(comuni_milano)

extract_df <- terra::extract(
  r,
  vect(comuni_milano),
  weights = TRUE,
  normalizeWeights = TRUE,
  na.rm = TRUE,
  ID = TRUE
)

emissioni_pesate <- extract_df %>%
  mutate(val_pesato = lyr.1 * weight) %>%
  group_by(ID) %>%
  summarise(CO_2000_15_01 = sum(val_pesato, na.rm = TRUE))

comuni_milano <- left_join(comuni_milano, emissioni_pesate, by = "ID")

# tmap v4 compatibile
tmap_mode("plot")

tm_shape(comuni_milano) +
  tm_polygons(
    fill = "CO_2000_15_01",
    fill.scale = tm_scale_intervals(
      style = "jenks",
      n = 6,
      values = "plasma"
    ),
    fill.legend = tm_legend(title = "CO (media areale)")
  ) +
  tm_title("Emissioni CO - 15/01/2000 (Media areale) - Zona Milano") +
  tm_layout(legend.outside = TRUE)

st_write(comuni_milano, "Comuni_Milano_emissioni_CO_20000115_media.shp", delete_layer = TRUE)

