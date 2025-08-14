# Phase 12: Spacetime Conversion Guide

## Overview
Phase 12 converts AQ_EM_sum array data to spacetime objects compatible with advanced spatio-temporal analysis code.

## What it does
- **Input**: Array data with `dimnames = [lat, lon, time]` (character format)
- **Output**: STFDF objects with `@time` and `@sp@coords` slots
- **Purpose**: Enable compatibility with code requiring spacetime structure

## Usage

### 1. Basic execution
```r
# Run only Phase 12 (requires Phase 11 output)
phases_to_run <- c(12)
source("Main.R")
```

### 2. Full pipeline to spacetime
```r
# Complete pipeline ending with spacetime objects
phases_to_run <- c(1, 2, 3, 4, 5, 6, 7, 8, 11, 12)
source("Main.R")
```

### 3. Quick conversion (if AQ_EM_sum already exists)
```r
# Convert existing AQ_EM_sum to spacetime
phases_to_run <- c(11, 12)  # Final conversion + spacetime
source("Main.R")
```

## Target Code Compatibility

After Phase 12, your data is compatible with code like:
```r
# Load spacetime object
EM_CAMS_v100_ST <- readRDS("data/processed/DAILY_data/SPACETIME_EM_sum/nox_2020_ST.rds")

# Use target code directly
sub_t <- index(EM_CAMS_v100_ST@time)[1:10]  # First 10 dates
A4_em_cams <- EM_CAMS_v100_ST[, which(index(EM_CAMS_v100_ST@time) %in% sub_t)]

# Spatial subsetting
bbox <- c(7, 18, 36, 47)  # [lon_min, lon_max, lat_min, lat_max] for Italy
A4_em_cams <- A4_em_cams[
  A4_em_cams@sp@coords[, 1] > bbox[1] &
  A4_em_cams@sp@coords[, 1] < bbox[2] &
  A4_em_cams@sp@coords[, 2] > bbox[3] &
  A4_em_cams@sp@coords[, 2] < bbox[4], 
]
```

## Output Structure

### Directory
```
data/processed/DAILY_data/SPACETIME_EM_sum/
├── nox_2020_ST.rds
├── nox_2021_ST.rds
├── nox_2022_ST.rds
└── ... (other pollutants/years)
```

### Object Structure
```r
class(EM_CAMS_v100_ST)
# [1] "STFDF"

str(EM_CAMS_v100_ST)
# Formal class 'STFDF' [package "spacetime"] with 4 slots
#   ..@ data   :'data.frame': X obs. of 1 variable:
#   .. ..$ emissions: num [1:X] ...
#   ..@ sp     :Formal class 'SpatialPoints' with 2 slots
#   .. .. ..@ coords     : num [1:Y, 1:2] ... (lon, lat coordinates)
#   .. .. ..@ proj4string:Formal class 'CRS' ...
#   ..@ time   :An 'xts' object with Z index entries
#   ..@ endTime: POSIXct[1:Z]
```

## Requirements
- **Prerequisites**: Phase 11 must be completed (AQ_EM_sum files must exist)
- **R Packages**: `spacetime`, `sp` (auto-installed if missing)
- **Memory**: Sufficient RAM for loading full spatio-temporal arrays

## Troubleshooting

### "AQ_EM_sum directory not found"
- **Solution**: Run Phase 11 first: `phases_to_run <- c(11)`

### "Package 'spacetime' not available"
- **Solution**: Install manually: `install.packages(c("spacetime", "sp"))`

### Memory issues with large datasets
- **Solution**: Process subset of years or pollutants in `Main.R` configuration

### Time conversion errors
- **Solution**: Ensure Phase 11 produced valid CF-compliant time dimension

## Technical Notes

1. **Coordinate Order**: Maintains lon,lat order for consistency with spacetime package
2. **Time Format**: Converts from CF numeric to R Date objects automatically  
3. **Spatial Grid**: Creates regular lon-lat grid from array dimensions
4. **Data Structure**: Preserves emission values in long format suitable for spatio-temporal analysis
