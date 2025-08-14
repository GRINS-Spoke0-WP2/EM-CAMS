# EM-CAMS v.3.0.0 Data Structure Documentation

## Overview

This document provides detailed information about the data structures, file formats, and output specifications for the EM-CAMS v.3.0.0 pipeline.

## Directory Structure

### Input Data (`data/raw/`)

```
data/raw/
├── CAMS-REG-ANT/                   # Regional anthropogenic emissions
│   ├── [yearly NetCDF files]      # Annual emission data by pollutant
│   └── [sector-specific files]    # GNFR sector emission data
├── CAMS-REG-TEMPO/                 # Regional temporal profiles
│   ├── CAMS-REG-TEMPO_EUR_0.1x0.1_tmp_weights_v3.1_daily.nc
│   └── CAMS-REG-TEMPO_EUR_0.1x0.1_tmp_weights_v3.1_monthly.nc
└── CAMS-REG-TEMPO-SIMPLIFIED/      # Simplified temporal profiles
    ├── CAMS_TEMPO_v4_1_simplified_Monthly_Factors_climatology.csv
    └── CAMS_TEMPO_v4_1_simplified_Weekly_Factors.csv
```

### Output Data (`data/processed/`)

```
data/processed/
├── ANT_data/                       # Processed anthropogenic data
│   ├── REG_ANT_yearly_data_*.rds  # Yearly emission data by pollutant
│   ├── GLOB_ANT_monthly_data_*.rds # Global monthly data
│   └── converted_lat_lon/         # Coordinate-converted versions
├── TEMPO_data/                     # Processed temporal profiles
│   ├── FM_F_monthly.rds           # Monthly factors for sector F
│   ├── FW_F_weekly.rds            # Weekly factors for sector F
│   ├── FD_*_*.rds                 # Daily factors by sector/pollutant
│   └── DailySimplifiedProfiles/   # Simplified profile data
└── DAILY_data/                     # Final daily emission inventories
    ├── DailyAlongYears/           # Daily data by sector (stacked years)
    ├── EM_sum/                    # Final aggregated inventories ⭐
    ├── SimplifiedDailyData/       # Simplified daily calculations
    └── DailyFromGLOB/            # Daily data from GLOB source
```

## File Formats and Data Structures

### 1. Yearly Anthropogenic Data
**Location**: `data/processed/ANT_data/REG_ANT_yearly_data_[pollutant].rds`

**Format**: R array  
**Dimensions**: `[longitude, latitude, sector, year]`
- **longitude**: 131 grid points (6.0°E to 19.0°E, 0.1° resolution)
- **latitude**: 131 grid points (35.0°N to 48.0°N, 0.1° resolution)  
- **sector**: 12 GNFR sectors (A through L)
- **year**: Years 2000-2022 (23 years)

**Units**: Varies by pollutant (typically kg/m²/s)

**Example Access**:
```r
data <- readRDS("data/processed/ANT_data/REG_ANT_yearly_data_nox.rds")
# Access NOx emissions for sector A in 2020
nox_A_2020 <- data[, , "A", "2020"]
```

### 2. Temporal Profiles
**Location**: `data/processed/TEMPO_data/`

#### Monthly Profiles (FM)
**File**: `FM_F_monthly.rds`  
**Format**: R array  
**Dimensions**: `[longitude, latitude, month]`
- **month**: 12 months (1-12)

#### Weekly Profiles (FW)  
**File**: `FW_F_weekly.rds`  
**Format**: R array  
**Dimensions**: `[longitude, latitude, day_of_week]`
- **day_of_week**: 7 days (1=Monday, 7=Sunday)

#### Daily Profiles (FD)
**File**: `FD_[sector]_[year]_[pollutant].rds`  
**Format**: R array  
**Dimensions**: `[longitude, latitude, day_of_year]`
- **day_of_year**: 365 or 366 days (depending on leap year)

### 3. Final Daily Emission Inventories ⭐
**Location**: `data/processed/DAILY_data/EM_sum/`  
**Files**: `[pollutant]_[year].rds`

**Format**: R array  
**Dimensions**: `[longitude, latitude, day_of_year]`
- **longitude**: 131 grid points  
- **latitude**: 131 grid points
- **day_of_year**: 365/366 days

**Description**: These are the primary final results containing daily emission data with all GNFR sectors aggregated.

**Units**: Varies by pollutant:
- **NOx, NH3, SO2**: kg/m²/s
- **CO, NMVOC**: kg/m²/s  
- **PM10, PM2.5**: kg/m²/s
- **CH4**: kg/m²/s
- **CO2_ff, CO2_bf**: kg/m²/s

**Example Access**:
```r
# Load NOx emissions for 2020
nox_2020 <- readRDS("data/processed/DAILY_data/EM_sum/NOx_2020.rds")

# Get emissions for specific day (day 100 = April 10th in non-leap year)
day_100_emissions <- nox_2020[, , 100]

# Get annual mean
annual_mean <- apply(nox_2020, c(1,2), mean, na.rm=TRUE)
```

### 4. Daily Data by Sector
**Location**: `data/processed/DAILY_data/DailyAlongYears/`  
**Files**: `[pollutant]_[sector]_[year].rds`

**Format**: R array  
**Dimensions**: `[longitude, latitude, day_of_year]`

**Description**: Daily emission data for individual GNFR sectors before aggregation.

## Coordinate System

### Standard Convention
- **Order**: [Longitude, Latitude]
- **Longitude Range**: 6.0°E to 19.0°E (131 points, 0.1° resolution)
- **Latitude Range**: 35.0°N to 48.0°N (131 points, 0.1° resolution)
- **Projection**: Regular latitude-longitude grid (WGS84)

### Coordinate Conversion
Optional [Latitude, Longitude] versions available in `converted_lat_lon/` subdirectories.

### Grid Information
```r
# Standard grid definition
lon_values <- seq(6.0, 19.0, by = 0.1)  # 131 points
lat_values <- seq(35.0, 48.0, by = 0.1) # 131 points

# Grid cell area: approximately 11 km × 11 km at 45°N
```

## GNFR Sectors

| Sector | Description |
|--------|-------------|
| A | Energy industries |
| B | Residential, commercial institutional |
| C | Manufacturing industries |
| D | Production processes |
| E | Extraction and distribution of fossil fuels |
| F | Solvent use |
| G | Road transport |
| H | Shipping |
| I | Aviation |
| J | Off-road |
| K | Waste |
| L | Agriculture |

## Temporal Information

### Years Covered
- **Range**: 2000-2022 (23 years total)
- **Leap Years**: 2000, 2004, 2008, 2012, 2016, 2020 (366 days)
- **Regular Years**: All others (365 days)

### Day Numbering
- **January 1**: Day 1
- **December 31**: Day 365 (or 366 in leap years)
- **No missing days**: Complete temporal coverage

### Example Day Calculations
```r
# Convert date to day of year
library(lubridate)
date <- as.Date("2020-04-15")
day_of_year <- yday(date)  # Returns 106

# Convert day of year back to date
date_from_day <- as.Date(106, origin = "2020-01-01")  # Returns 2020-04-15
```

## Quality Control and Validation

### Data Integrity Checks
1. **Spatial Consistency**: All arrays have consistent spatial dimensions
2. **Temporal Consistency**: Complete time series without gaps
3. **Unit Consistency**: Consistent units within pollutant types
4. **Non-negative Values**: Emission values are non-negative
5. **Reasonable Magnitudes**: Values within expected scientific ranges

### Missing Data Handling
- **No Data Values**: Represented as `NA` in R arrays
- **Ocean/Sea Areas**: May contain `NA` or zero values
- **Land Areas**: Should contain positive emission values

## File Size Information

### Typical File Sizes
- **Yearly Data**: 50-200 MB per pollutant
- **Daily Inventories**: 100-500 MB per pollutant per year
- **Temporal Profiles**: 10-50 MB per profile type
- **Complete Dataset**: ~50-100 GB total

### Storage Recommendations
- **SSD Storage**: Recommended for processing speed
- **Backup Strategy**: Regular backup of processed results
- **Compression**: RDS files are automatically compressed

## Data Access Examples

### Loading and Examining Data
```r
# Load final daily emission inventory
data <- readRDS("data/processed/DAILY_data/EM_sum/NOx_2020.rds")

# Check dimensions
dim(data)  # Should be [131, 131, 366] for 2020 (leap year)

# Check coordinate names
dimnames(data)

# Calculate basic statistics
summary(as.vector(data))

# Plot spatial mean
spatial_mean <- apply(data, c(1,2), mean, na.rm=TRUE)
image(spatial_mean, main="NOx Annual Mean 2020")
```

### Temporal Analysis
```r
# Calculate monthly means from daily data
library(lubridate)

# Get dates for 2020
dates_2020 <- seq(as.Date("2020-01-01"), as.Date("2020-12-31"), by="day")
months_2020 <- month(dates_2020)

# Calculate monthly averages
monthly_data <- array(NA, dim=c(131, 131, 12))
for(m in 1:12) {
  monthly_data[,,m] <- apply(data[,,months_2020==m], c(1,2), mean, na.rm=TRUE)
}
```

### Spatial Analysis
```r
# Extract data for specific location (e.g., Rome: ~12.5°E, 41.9°N)
lon_idx <- which.min(abs(lon_values - 12.5))
lat_idx <- which.min(abs(lat_values - 41.9))

# Time series for Rome location
rome_timeseries <- data[lon_idx, lat_idx, ]

# Plot time series
plot(1:366, rome_timeseries, type="l", 
     xlab="Day of Year", ylab="NOx Emissions", 
     main="NOx Daily Emissions - Rome 2020")
```

## Technical Notes

### Performance Considerations
- **Memory Usage**: Large arrays may require 8-16 GB RAM
- **Processing Time**: Full pipeline takes 2-6 hours depending on hardware
- **Parallel Processing**: Utilize multiple cores for Phase 6

### Compatibility
- **R Version**: Requires R 4.0 or higher
- **Operating Systems**: Windows, macOS, Linux
- **File Format**: RDS files are cross-platform compatible

### Backup and Archival
- **Version Control**: Maintain version information for reproducibility
- **Metadata**: Document processing parameters and data sources
- **Long-term Storage**: Consider HDF5 format for long-term archival

---

This documentation should be updated whenever the data structure or processing pipeline changes.
