# EM-CAMS v.3.0.0 - European Daily Emission Dataset

[![R](https://img.shields.io/badge/R-4.0%2B-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-3.0.0-orange.svg)](CHANGELOG.md)

# Introduction

EM-CAMS v.3.0.0 provides **comprehensive daily emission estimates** for key atmospheric pollutants across the Italian territory for the **extended period 2000–2025**. This major version represents a complete evolution from the previous IEDD (Italian Emission Daily Dataset) approach into a sophisticated **12-phase modular pipeline architecture** that transforms emission data processing through flexible, reproducible, and scalable workflows optimized for scientific research and air quality modeling applications.

By leveraging cutting-edge data from the Copernicus Atmosphere Monitoring Service (CAMS) inventories—including **CAMS-REG-ANT v8.0** (2000-2022) at high spatial resolution (0.05° × 0.1°), **CAMS-REG-TEMPO v4.1**, and **CAMS-GLOB-ANT v6.2** (2023-2025) at 0.1° × 0.1° resolution—EM-CAMS v.3.0.0 fills a critical gap in providing temporally granular emission data. This version moves beyond annual averages to capture **day-by-day variations** with enhanced air quality modeling compatibility through specialized data format conversions and coordinate system alignments.


# Highlights

### 🔧 **12-Phase Modular Architecture**
Complete restructuring from monolithic processing to modular phases enabling:
- Individual phase execution and debugging
- Reproducible scientific workflows  
- Scalable processing for different computational environments
- Enhanced maintainability and collaboration
- **Extended temporal coverage**: REG data (2000-2022) + GLOB data (2023-2025)

### 🌍 **Output**
Four specialized output formats for different scientific applications:
- **AQ_EM_REG_sum**: [LAT,LON,TIME] matrices per pollutant and year saved as rds file (2000-2022)
- **AQ_EM_GLOB_sum**: [LAT,LON,TIME] matrices per pollutant and year  saved as rds file  (2023-2025)

### ⏱️ **Extended Temporal Coverage** 
- **REG Data Period**: 2000-2022 (23 years) from CAMS-REG-ANT v8.0
- **GLOB Data Period**: 2023-2025 (3 years) from CAMS-GLOB-ANT v6.2
- **Total Coverage**: 26 years of continuous daily emission data
- **Seamless Integration**: Consistent methodology across data sources




### EM-CAMS Version Evolution and Dataset Comparison

| **Dataset Version** | **Temporal Coverage** | **Spatial Coverage** | **Spatial Resolution** | **Origin** | **Architecture** | **Output Formats** |
|-------------------|----------------------|---------------------|----------------------|------------|------------------|-------------------|
| **IEDD v1.0** | 2000–2020 | Italy | 0.05° × 0.1° | CAMS-REG-ANT v5.1+v6.0+v7.1, CAMS-REG-TEMPO v4.1 | Monolithic | Basic EM_sum |
| **IEDD v2.0** | 2000–2022 | Italy | 0.05° × 0.1° | CAMS-REG-ANT v8.0, CAMS-REG-TEMPO Simplified v4.1 | Monolithic | Standard EM_sum |
| **EM-CAMS v3.0** | **2000–2025** | **Italy** | **(0.05° × 0.1°) & (0.1° × 0.1)** | **CAMS-REG-ANT v8.0 + CAMS-GLOB-ANT v6.2** | **12-Phase Modular** | **2 Formats** |

### Evolution Highlights
- **Extended Coverage**: From 21 years (IEDD v1.0) to **26 years** (EM-CAMS v3.0)
- **Dual Data Sources**: Integration of regional (REG) and global (GLOB) emission inventories
- **Enhanced Compatibility**: From basic arrays to air quality modeling-ready formats
- **Modular Architecture**: From single scripts to reproducible 12-phase pipeline



## EM-CAMS Scope and Scientific Motivation

The development of EM-CAMS v.3.0.0 addresses fundamental questions in atmospheric science and environmental policy:

### Why Daily Emission Data?
- **Temporal Dynamics**: Annual emissions mask complex variability driven by daily changes in activities, weather patterns, and seasonal cycles
- **Air Quality Modeling**: Atmospheric models require high temporal resolution inputs to accurately simulate pollution events
- **Policy Assessment**: Understanding when and how emissions occur enables targeted interventions and regulatory impact evaluation
- **Health Studies**: Daily resolution supports epidemiological research linking short-term exposure to health outcomes

### Scientific Applications
- **Atmospheric Modeling**: Direct integration with WRF, CMAQ, and other air quality models
- **Climate Research**: 26-year dataset enables long-term trend analysis and climate impact studies
- **Environmental Policy**: Sector-specific daily data supports evidence-based policy development
- **Urban Planning**: High-resolution spatial data aids in city-level emission management strategies

### Italian Domain Focus
Italy serves as an ideal study region due to:
- **Diverse Emission Sources**: Industrial Po Valley, urban centers, shipping corridors, and agricultural regions
- **Complex Topography**: Alps, Apennines, and coastal areas create unique meteorological patterns
- **Policy Relevance**: EU emission regulations and national air quality standards
- **Scientific Heritage**: Extensive monitoring networks and research infrastructure


## Project Structure

```
EM-CAMS/v.3.0.0/
├── Main.R                          # Main orchestrator script with 12-phase control
├── scripts/
│   ├── phases/                     # Processing phase modules (Phases 1-12)
│   │   ├── phase1_reg_ant.R       # CAMS-REG-ANT yearly data extraction
│   │   ├── phase2_tempo_profiles.R # CAMS-REG-TEMPO profiles extraction
│   │   ├── phase3_simplified_profiles.R # Simplified TEMPO profiles
│   │   ├── phase4_daily_profiles.R # Daily profile creation (FM & FW)
│   │   ├── phase5_fd_daily_computation.R # FD daily data computation
│   │   ├── phase6_simplified_daily_computation.R # Simplified daily computation
│   │   ├── phase7_stacking_aggregation.R # Data stacking and EM_sum creation
│   │   ├── phase8_glob_ant.R      # CAMS-GLOB-ANT data processing & DailyFromGLOB creation
│   │   ├── phase9_coordinate_conversion.R # Optional coordinate conversion
│   │   ├── phase10_time_conversion.R # Time format conversion
│   │   ├── phase11_final_conversion.R # AQ_EM_sum modeling format conversion
│   │   └── phase12_spacetime_conversion.R # SPACETIME_EM_sum advanced objects
│   ├── utils/                      # Utility functions
│   │   ├── Config.R               # Configuration parameters
│   │   ├── Utils.R                # General utility functions
│   │   ├── coordinate_converter.R # Coordinate system conversion
│   │   └── NumericDimnames.R      # Numeric dimname conversion utilities
│   ├── extraction/                 # Data extraction modules
│   │   ├── ExtractANT/           # Anthropogenic data extraction
│   │   ├── ExtractTEMPO/         # Temporal profile extraction
│   │   └── ExtractGLOB/          # Global emission data extraction
│   └── computation/               # Data computation modules
│       ├── GLOB_MonthlyToDaily.R  # GLOB temporal disaggregation
│       ├── MapGLOBtoGNFR.R       # GLOB-GNFR sector mapping
│       └── Computation/          # Final computation algorithms
├── data/
│   ├── Raw/                       # Raw input data
│   │   ├── CAMS-REG-ANT/         # Regional anthropogenic emissions (2000-2022)
│   │   ├── CAMS-REG-TEMPO/       # Regional temporal profiles
│   │   ├── CAMS-REG-TEMPO-SIMPLIFIED/ # Simplified temporal profiles
│   │   └── CAMS-GLOB-ANT/        # Global anthropogenic emissions (2023-2025)
│   └── processed/                 # Processed output data
│       ├── ANT_data/             # Processed anthropogenic data
│       ├── TEMPO_data/           # Processed temporal profiles
│       ├── GLOB_data/            # Processed global emission data
│       └── DAILY_data/           # Final daily emission inventories ⭐
│           ├── EM_sum/           # REG format [LON,LAT,TIME] (2000-2022)
│           ├── AQ_EM_sum/        # AQ-ready [LAT,LON,CF_TIME] (2000-2022)
│           ├── DailyFromGLOB/    # GLOB daily data (2023-2025)
│           └── SPACETIME_EM_sum/ # Spatio-temporal objects (advanced)
├── docs/                          # Documentation
│   ├── README.md                  # This comprehensive guide
│   ├── DATA_STRUCTURE.md         # Detailed data format specifications
│   ├── PHASE_GUIDES/             # Individual phase documentation
│   └── METHODOLOGY.md            # Scientific methodology and validation
└── tests/                         # Testing and verification
    ├── verify_system.R           # Complete system verification
    ├── test_phase_outputs.R      # Individual phase testing
    └── validate_outputs.R        # Output quality validation
```

## Supported Pollutants

| Pollutant | Description | File Suffix | EM_sum | GLOB |
|-----------|-------------|-------------|---------|------|
| CO | Carbon Monoxide | `co` | ✅ | ✅ |
| NOx | Nitrogen Oxides | `nox` | ✅ | ✅ |
| NH3 | Ammonia | `nh3` | ✅ | ✅ |
| NMVOC | Non-Methane Volatile Organic Compounds | `nmvoc` | ✅ | ✅ |
| PM10 | Particulate Matter (10μm) | `pm10` | ✅ | ✅ |
| PM2.5 | Particulate Matter (2.5μm) | `pm2_5` | ✅ | ✅ |
| SOx/SO2 | Sulfur Dioxide | `so2` | ✅ | ✅ |


## Processing Phases - Complete 12-Phase Architecture


### **CAMS-REG-ANT Data Processing (Phases 1-7): CAMS-REG-ANT 2000-2022**

### Phase 1: CAMS-REG-ANT Yearly Data Extraction
- Extracts yearly anthropogenic emission data from CAMS-REG-ANT v8.0
- Processes 10 pollutants across 12 GNFR sectors (A-L)
- **Outputs**: `REG_ANT_yearly_data_[pollutant].rds`
- **Coverage**: 2000-2022 (23 years) at 0.05° x 0.1° resolution

### Phase 2: CAMS-REG-TEMPO Profiles Extraction
- Extracts temporal profiles from CAMS-REG-TEMPO v4.1 (monthly, weekly, daily)
- Processes FM_F, FW_F, FD_C, FD_L_nh3, FD_K_nh3_nox profiles
- **Outputs**: Temporal profile files in `TEMPO_data/`
- **Method**: NetCDF profile extraction with sector-specific temporal variations

### Phase 3: Simplified CAMS-REG-TEMPO Profile Extraction
- Processes CSV-based simplified temporal profiles for rapid computation
- Creates climatological monthly and weekly factors
- **Outputs**: Simplified profiles for 7 pollutants
- **Benefit**: Faster processing alternative for preliminary analyses

### Phase 4: Daily Profile Creation from FM & FW  
- Combines monthly (FM) and weekly (FW) factors into comprehensive daily profiles
- Creates integrated temporal variations accounting for seasonal and weekly patterns
- **Outputs**: Daily temporal profiles for sector F
- **Method**: Mathematical integration of monthly × weekly factors

### Phase 5: Daily Data Computation with FD Profiles
- Computes daily emission data using detailed FD temporal profiles
- Processes all 10 pollutants for sector F with full temporal complexity
- **Outputs**: High-resolution daily emission arrays in `DAILY_data/`
- **Accuracy**: Maximum temporal fidelity using sector-specific daily profiles

### Phase 6: Daily Data Computation with Simplified Profiles
- Parallel processing of simplified daily data for computational efficiency
- Uses multiple CPU cores for accelerated processing
- **Outputs**: Simplified daily emission data for sectors A-E, G-L
- **Performance**: Optimized for large-scale batch processing

### Phase 7: Data Stacking and Sector Aggregation (EM_sum Creation)
- Stacks daily data along years (2000-2022) creating continuous time series
- **Aggregates emissions across all GNFR sectors** creating EM_sum totals
- **Outputs**: `EM_sum/` directory - **Final REG emission inventories (2000-2022)**
- **Format**: [LON,LAT,TIME_DDMMYYYY] with string-based dimnames
- **EM_sum Calculation**: `EM_sum = Σ(sectors A-L)` for each pollutant, grid cell, and day

### **GLOB Data Processing (Phase 8): CAMS-GLOB-ANT 2023-2025**

### Phase 8: CAMS-GLOB-ANT Data Processing ⭐ **DailyFromGLOB OUTPUT CREATION**
- Processes global emission data from CAMS-GLOB-ANT v6.2 for **2023-2025 period**
- **Advanced Temporal Disaggregation**: Monthly GLOB data → daily resolution using REG-TEMPO profiles
- **Sector Integration**: Global emission categories → GNFR equivalent sectors with cross-sector mapping
- **Spatial Interpolation**: Global grid (0.1° × 0.1°) → Italian domain with consistent alignment
- **Enhanced Methodology**: Climatological temporal profiles mapped onto GLOB monthly data
- **Outputs**: `DailyFromGLOB/` directory - **Final GLOB emission inventories (2023-2025)**
- **Coverage**: Extends EM-CAMS temporal coverage beyond REG data availability
- **Format**: Consistent with EM_sum structure for seamless integration
- **Quality Control**: Spatial and temporal consistency validation

### **Advanced Format Conversion (Phases 9-12)**

### Phase 9: Optional Coordinate Conversion
- Converts from [LON,LAT] to [LAT,LON] if needed for specific applications
- Maintains data integrity and metadata during conversion
- **Outputs**: Converted files in `converted_lat_lon/` subdirectories
- **Use Case**: Applications requiring latitude-first coordinate ordering

### Phase 10: Time Format Conversion
- Converts time dimension from DDMMYYYY to CF standard format
- Implements numeric time values (days since 1850-01-01)
- **Outputs**: CF-compliant time dimensions for atmospheric model compatibility
- **Benefits**: Enhanced integration with NetCDF and climate data standards

### Phase 11: Final Conversion for Air Quality Modeling ⭐ **AQ_EM_sum CREATION**
- **Combined coordinate conversion**: [LON,LAT] → [LAT,LON] for spatial library compatibility
- **Advanced time conversion**: DDMMYYYY → CF standard (days since 1850-01-01)
- **Outputs**: `AQ_EM_sum/` directory - **Air quality modeling-ready format (2000-2022)**
- **Format**: [LAT,LON,TIME_CF_numeric] optimized for atmospheric models
- **Applications**: Direct use with WRF, CMAQ, and spatial analysis packages

### Phase 12: Spatio-Temporal Object Conversion ⭐ **SPACETIME_EM_sum CREATION**
- Converts AQ_EM_sum arrays to advanced spatio-temporal objects (STFDF)
- Creates objects with `@time` and `@sp@coords` slots for scientific applications
- **Outputs**: `SPACETIME_EM_sum/` directory - **Advanced spatio-temporal objects**
- **Format**: R spacetime package compatible objects (`*_ST.rds`)
- **Applications**: Complex spatio-temporal analysis, geostatistics, and advanced modeling
- **Compatibility**: Direct integration with R spatial ecology and time series packages

## Installation and Requirements

### System Requirements
- R version 4.0 or higher
- Minimum 8GB RAM (16GB recommended)
- 50GB+ free disk space for full dataset processing
- Multi-core CPU (for parallel processing)

### Required R Packages
```r
# Install required packages
packages <- c(
  "ncdf4",          # NetCDF file handling
  "raster",         # Spatial data processing  
  "foreach",        # Parallel processing
  "doParallel",     # Parallel backend
  "data.table",     # Fast data manipulation
  "lubridate",      # Date/time handling
  "abind"           # Array binding operations
)

install.packages(packages)
```

## Getting Started

To start working with EM-CAMS v.3.0.0, follow these steps:

### 1. Clone the Repository

To begin, clone the EM-CAMS repository to your local machine:

```bash
git clone https://github.com/aminb00/EM-CAMS.git
cd EM-CAMS/v.3.0.0
```

### 2. Download Required CAMS Data

#### Register and Access ECCAD
- Visit [ECCAD](https://eccad.aeris-data.fr/) and create an account if you haven't already
- After logging in, navigate to the relevant CAMS emission inventory sections

#### Download CAMS-REG-ANT Data (2000-2022)
- Choose CAMS-REG-ANT v8.0 covering the years 2000–2022
- Download the NetCDF files for each pollutant of interest (NOx, SO₂, NH₃, CO, NMVOC, PM₁₀, PM₂.₅, CH₄, CO₂)
- Place these NetCDF files into:

```
EM-CAMS/v.3.0.0/data/Raw/CAMS-REG-ANT/
```

#### Download CAMS-REG-TEMPO Profiles
- Navigate to CAMS-REG-TEMPO v4.1 datasets on ECCAD
- Download the NetCDF files containing monthly, weekly, and daily profiles
- Place these files into:

```
EM-CAMS/v.3.0.0/data/Raw/CAMS-REG-TEMPO/
```

#### CAMS-REG-TEMPO Simplified CSV Files
- Download simplified profiles in CSV format (monthly and weekly factors)
- Place them into:

```
EM-CAMS/v.3.0.0/data/Raw/CAMS-REG-TEMPO-SIMPLIFIED/
```

#### Download CAMS-GLOB-ANT Data (2023-2025)
- Choose CAMS-GLOB-ANT v6.2 for the years 2023–2025
- Download monthly NetCDF files for the same pollutants
- Place these files into:

```
EM-CAMS/v.3.0.0/data/Raw/CAMS-GLOB-ANT/
```

### 3. Set Up R Environment

- **Install R**: Ensure R (≥ 4.0) is installed on your system
- **Install Required Packages**:

```r
# Install required packages
packages <- c(
  "ncdf4",          # NetCDF file handling
  "raster",         # Spatial data processing  
  "foreach",        # Parallel processing
  "doParallel",     # Parallel backend
  "data.table",     # Fast data manipulation
  "lubridate",      # Date/time handling
  "abind",          # Array binding operations
  "spacetime",      # Spatio-temporal objects
  "sp"              # Spatial objects
)

install.packages(packages)
```

### Verifying Your Setup

Your directory structure should look like this after completing the setup:

```
EM-CAMS/v.3.0.0/
├─ Main.R                              # Main orchestrator script
├─ data/
│  ├─ Raw/
│  │  ├─ CAMS-REG-ANT/                 # REG-ANT NetCDF files (2000-2022)
│  │  ├─ CAMS-REG-TEMPO/               # REG-TEMPO NetCDF files
│  │  ├─ CAMS-REG-TEMPO-SIMPLIFIED/    # REG-TEMPO CSV files
│  │  └─ CAMS-GLOB-ANT/                # GLOB-ANT NetCDF files (2023-2025)
│  └─ processed/                       # Output will be generated here
├─ scripts/                            # Processing scripts
├─ docs/                               # Documentation
└─ tests/                              # Verification tools
```

### Run the the phases in file Main.R


## EM-CAMS Methodology

EM-CAMS v.3.0.0 follows a sophisticated 12-phase methodology that transforms annual emission inventories into comprehensive daily datasets:

### Core Processing Methodology

#### 1. **Temporal Disaggregation Process**
The fundamental EM-CAMS methodology applies temporal profiles to disaggregate annual emissions:

```r
# Mathematical formulation:
EM_daily(pollutant, sector, lon, lat, day) = 
  EM_annual(pollutant, sector, lon, lat) × 
  FM(sector, lon, lat, month) × 
  FW(sector, lon, lat, day_of_week) × 
  FD(sector, pollutant, lon, lat, day_of_year)
```

**Where:**
- `EM_annual`: Annual emission baseline from CAMS-REG-ANT
- `FM`: Monthly temporal factors from CAMS-REG-TEMPO
- `FW`: Weekly temporal factors from CAMS-REG-TEMPO
- `FD`: Daily temporal factors (sector-specific)

#### 2. **Quality Assurance Principles**
- **Mass Conservation**: Total annual emissions are preserved during temporal disaggregation
- **Leap Year Handling**: Proper calendar arithmetic for 366-day years
- **Spatial Consistency**: Grid-cell alignment across all processing phases
- **Temporal Consistency**: No gaps in daily time series (2000-2025)

#### 3. **Sector Aggregation Strategy**
```r
# EM_sum calculation methodology:
for each (pollutant, lon, lat, day) {
  EM_sum = 0
  for each GNFR_sector in [A, B, C, D, E, F, G, H, I, J, K, L] {
    EM_sum += EM_daily(pollutant, GNFR_sector, lon, lat, day)
  }
  # Result: Total anthropogenic emissions per grid cell per day
}
```

### Data Integration Approach

#### GLOB Data Processing (Phase 8)
For extended temporal coverage (2023-2025), EM-CAMS integrates global emission data:

1. **Data extraction**
2. **Temporal Disaggregation**: Monthly GLOB → daily using climatological REG-TEMPO profiles
3. **Sector Mapping**: Global emission categories → GNFR-equivalent sectors

### Format Conversion Methodology (Phases 11-12)

#### Phase 11: Air Quality Model Preparation
```r
# Coordinate transformation: [LON,LAT] → [LAT,LON]
aq_data <- aperm(standard_data, c(2, 1, 3))

# Time conversion: DDMMYYYY → CF standard
cf_time <- as.numeric(as.Date(time_strings, format="%d%m%Y") - as.Date("1850-01-01"))

# Numeric dimnames for spatial library compatibility
dimnames(aq_data) <- list(
  lat = as.numeric(lat_values),
  lon = as.numeric(lon_values),
  time = cf_time
)
```

#### Phase 12: Spatio-Temporal Objects
Conversion to R spacetime objects enables advanced scientific applications:
- **Geostatistical Analysis**: Spatial interpolation and kriging
- **Time Series Analysis**: Temporal trend detection and seasonality assessment
- **Spatio-Temporal Modeling**: Complex interaction between space and time


#### Uncertainty Considerations
- **Temporal Profile Uncertainty**: Regional variations in activity patterns
- **Spatial Interpolation Uncertainty**: Grid resolution limitations
- **Sector Mapping Uncertainty**: GLOB to GNFR category approximations
- **Future Projections**: GLOB data uncertainty for 2023-2025 period

## Future Plans and Enhancements

EM-CAMS v.3.0.0 is designed for continuous improvement and community contributions

### Community Contributions Welcome
- **Methodology Enhancements**: Improved temporal disaggregation techniques
- **New Output Formats**: Additional spatial and temporal data formats
- **Validation Studies**: Independent verification using observational data
- **Performance Optimization**: Code efficiency and parallel processing improvements

## Data Management and Version Control

### Git Integration and Large File Handling

EM-CAMS v.3.0.0 includes a comprehensive `.gitignore` configuration that automatically excludes large data files from version control:

#### What's Tracked by Git ✅
- **Source Code**: All R scripts, configuration files, and processing modules
- **Documentation**: README files, methodology guides, and project documentation  
- **Directory Structure**: Empty directories with `.gitkeep` files to maintain project structure
- **Small Configuration Files**: Settings and parameters needed for processing

#### What's Ignored by Git ❌ 
- **Raw Input Data**: All CAMS NetCDF files (typically several GB each)
  ```
  data/Raw/CAMS-REG-ANT/*.nc
  data/Raw/CAMS-REG-TEMPO/*.nc
  data/Raw/CAMS-GLOB-ANT/*.nc
  ```
- **Processed Output Data**: All heavy .rds files from pipeline processing
  ```
  data/processed/**/*.rds        # All RDS output files
  data/processed/DAILY_data/EM_sum/*.rds      # Main outputs
  data/processed/DAILY_data/AQ_EM_sum/*.rds   # AQ-ready outputs
  data/processed/DAILY_data/DailyFromGLOB/*.rds # GLOB outputs
  data/processed/DAILY_data/SPACETIME_EM_sum/*.rds # Spacetime objects
  ```
- **Temporary Files**: Log files, intermediate processing files, plots, and system files

#### Data Sharing Strategy

For collaborative projects involving EM-CAMS processed data:

1. **Repository Sharing**: Share the complete codebase via Git (lightweight, <100MB)
2. **Data Distribution**: 
   - **Small Teams**: Use cloud storage (Google Drive, Dropbox) for processed .rds files
   - **Large Projects**: Consider institutional data repositories or dedicated file servers
   - **Public Release**: Use scientific data repositories (Zenodo, Figshare) with DOI assignment

#### Setting Up a New Environment

When cloning EM-CAMS to a new machine:

```bash
# 1. Clone the repository (gets code and structure)
git clone https://github.com/aminb00/EM-CAMS.git
cd EM-CAMS/v.3.0.0

# 2. The data directories are ready but empty
ls data/Raw/                    # Shows .gitkeep files
ls data/processed/              # Empty, ready for pipeline outputs

# 3. Download CAMS data from ECCAD into Raw/ directories
# 4. Run pipeline to generate processed outputs
```

#### File Size Considerations

| **Data Category** | **Typical Size** | **Number of Files** | **Total Size** | **Git Status** |
|-------------------|------------------|---------------------|----------------|----------------|
| **Raw CAMS Data** | 2-8 GB per file | ~100-200 files | ~500 GB - 1 TB | ❌ Ignored |
| **Processed Outputs** | 50-500 MB per file | ~300-1000 files | ~100-300 GB | ❌ Ignored |
| **Source Code** | <1 MB per file | ~50 files | <50 MB | ✅ Tracked |
| **Documentation** | <5 MB per file | ~10 files | <20 MB | ✅ Tracked |

#### Best Practices for Data Management

1. **Local Processing**: Always run EM-CAMS pipeline locally to generate your specific outputs
2. **Backup Strategy**: Maintain backups of processed data separately from Git repository
3. **Documentation**: Keep detailed records of processing parameters and data versions used
4. **Reproducibility**: Use Git tags/releases to mark stable versions of processing pipeline
5. **Collaboration**: Share processing configurations and coordinate data sharing through dedicated channels



## Data Citation

When using EM-CAMS v.3.0.0 processed data, please cite:

### Primary Data Sources
- **CAMS-REG-ANT v8.0**: Kuenen, J., et al. (2024). CAMS-REG-ANT: High resolution European anthropogenic emissions inventory for air quality modeling. *Atmospheric Environment*.
- **CAMS-REG-TEMPO v4.1**: Guevara, M., et al. (2024). CAMS-REG-TEMPO: Temporal profiles for European anthropogenic emissions. *Earth System Science Data*.
- **CAMS-GLOB-ANT v6.2**: Granier, C., et al. (2024). CAMS-GLOB-ANT: Global anthropogenic emissions inventory. *Earth System Science Data*.

### This Processing Pipeline
- **EM-CAMS v.3.0.0**: Borqal, A. (2024). EM-CAMS v.3.0.0: Modular pipeline for daily European emission inventory processing with air quality modeling compatibility. *Software/Data Processing Pipeline*.

### Recommended Citation Format
```bibtex
@software{emcams_v300_2024,
  author = {Borqal, Amin},
  title = {EM-CAMS v.3.0.0: European Daily Emission Dataset},
  year = {2024},
  version = {3.0.0},
  url = {https://github.com/aminb00/EM-CAMS},
  note = {Modular pipeline for daily European emission inventory processing with air quality modeling compatibility}
}
```

## References and Licensing

### CAMS Data References
Please refer to the [ECCAD portal](https://eccad.aeris-data.fr/) and individual CAMS inventory documentation for comprehensive references.

### License
The code and documentation provided in this repository are released under the **MIT License**, allowing for broad reuse, modification, and redistribution. For details, see the `LICENSE` file.

**Note**: While the EM-CAMS processing pipeline is open source, the underlying CAMS data has its own licensing terms. Users must comply with ECCAD/CAMS data usage policies.

## Contact and Support

For questions, bug reports, or collaboration opportunities:

- **Issues**: Open an issue on this repository's [GitHub Issues](https://github.com/aminb00/EM-CAMS/issues) page
- **Discussions**: Use [GitHub Discussions](https://github.com/aminb00/EM-CAMS/discussions) for broader questions
- **Email**: Contact the maintainer directly for technical or collaboration inquiries

### Contributing to EM-CAMS

We welcome contributions! Whether you:
- Identify data inconsistencies or bugs
- Propose methodological enhancements  
- Share validation results with observational data
- Improve documentation or add translations
- Optimize performance or add new features

Your input helps strengthen EM-CAMS for the entire atmospheric research community.

---

*EM-CAMS v.3.0.0 - Empowering atmospheric science with comprehensive daily emission data*

