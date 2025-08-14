# Librerie
library(terra)
library(ggplot2)
library(sf)
library(dplyr)
library(tmap)

# --- PARAMETRI SELEZIONABILI ---
# Scegli area da analizzare: "Lombardia", "Nord", oppure nome di provincia (e.g., "Bergamo")
area_target <- "Lombardia"

tmap_mode("plot")

# --- Carica emissioni ---
emissioni <- Daily_sum_2000_2020_CO
giorno_index <- 15
emissioni_corr <- aperm(emissioni, c(2, 1, 3))
emissioni_giorno <- emissioni_corr[,,giorno_index] * 10^6 * 60 * 60 * 24

# --- Crea raster ---
lat_vals <- as.numeric(dimnames(emissioni)[[2]])
lon_vals <- as.numeric(dimnames(emissioni)[[1]])
r <- rast(nrows = length(lat_vals), ncols = length(lon_vals),
          xmin = min(lon_vals), xmax = max(lon_vals),
          ymin = min(lat_vals), ymax = max(lat_vals),
          crs = "EPSG:4326")
emissioni_giorno_flipped <- emissioni_giorno[nrow(emissioni_giorno):1, ]
values(r) <- as.vector(t(emissioni_giorno_flipped))

# --- Carica shapefile comuni, province, regioni ---
base_path <- "/Users/aminborqal/Documents/Projects/R/IEDD/Demo/Data/Raw/MAPS/ITA-Administrative-maps-2024"
comuni <- st_read(file.path(base_path, "Com01012024_g/Com01012024_g_WGS84.shp"), options = "ENCODING=UTF-8") %>% st_transform("EPSG:4326")
province <- st_read(file.path(base_path, "ProvCM01012024_g/ProvCM01012024_g_WGS84.shp"), options = "ENCODING=UTF-8") %>% st_transform("EPSG:4326")
regioni <- st_read(file.path(base_path, "Reg01012024_g/Reg01012024_g_WGS84.shp"), options = "ENCODING=UTF-8") %>% st_transform("EPSG:4326")

# --- Crea bounding box in base all'area_target ---
sf_use_s2(FALSE)

if (area_target == "Lombardia") {
  lombardia_poly <- regioni[regioni$DEN_REG == "Lombardia", ]
  comuni_area <- comuni[comuni$COD_REG == lombardia_poly$COD_REG, ]
  province_area <- province[province$COD_REG == lombardia_poly$COD_REG, ]
  regioni_area <- lombardia_poly
  titolo_area <- "Lombardia"
  
} else if (area_target == "Nord") {
  bbox_area <- st_as_sfc(st_bbox(c(xmin = 6.5, xmax = 14.5, ymin = 44.0, ymax = 47.5), crs = st_crs(4326)))
  comuni_area <- st_crop(comuni, bbox_area)
  province_area <- st_crop(province, bbox_area)
  regioni_area <- st_crop(regioni, bbox_area)
  titolo_area <- "Nord Italia"
  
} else {
  province_sel <- province[grepl(area_target, province$DEN_PCM, ignore.case = TRUE), ]
  comuni_area <- comuni[comuni$COD_PRO %in% province_sel$COD_PRO, ]
  province_area <- province_sel
  regioni_area <- st_crop(regioni, st_bbox(province_sel))
  titolo_area <- paste("Provincia di", area_target)
}

# --- Assegna ID ai comuni ---
comuni_area$ID <- seq_len(nrow(comuni_area))

# --- Estrai valori pesati ---
comuni_vect <- vect(comuni_area)

extract_df <- terra::extract(
  r,
  comuni_vect,
  weights = TRUE,
  normalizeWeights = TRUE,
  na.rm = TRUE,
  ID = TRUE
)

emissioni_pesate <- extract_df %>%
  mutate(val_pesato = lyr.1 * weight) %>%
  group_by(ID) %>%
  summarise(CO_2000_15_01 = sum(val_pesato, na.rm = TRUE))

comuni_area <- left_join(comuni_area, emissioni_pesate, by = "ID")

# --- Mappa finale ---
tm_shape(comuni_area) +
  tm_polygons(
    fill = "CO_2000_15_01",
    fill.scale = tm_scale_intervals(style = "jenks", n = 6, values = "plasma"),
    fill.legend = tm_legend(title = "CO (media areale)")
  ) +
  tm_borders(lwd = 0.4, col = "grey30") +
  tm_shape(province_area) +
  tm_borders(col = "white", lwd = 1.2) +
  tm_shape(regioni_area) +
  tm_borders(col = "black", lwd = 1.5) +
  tm_title(paste("Emissioni CO - 15/01/2000 -", titolo_area)) +
  tm_layout(legend.outside = TRUE)

# --- Esporta ---
st_write(comuni_area, paste0("Emissioni_CO_", gsub(" ", "_", titolo_area), "_20000115_media.shp"), delete_layer = TRUE)
