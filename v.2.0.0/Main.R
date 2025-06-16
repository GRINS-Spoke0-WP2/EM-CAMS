###############################################################################
## MAIN SCRIPT: main.R
## Version: 2.0.0
## This script is organized in multiple PHASES, each timed for benchmark purposes.
## No lines of your original code are removed, only reorganized.
###############################################################################

# 1. CONFIGURATION & SETUP
source("Config.R")
source("Utils.R")

###############################################################################
## USER CONFIGURATION - MODIFY THESE VARIABLES AS NEEDED
###############################################################################

# POLLUTANTS TO PROCESS - modify this list to select which pollutants to process
# Available: "nh3", "ch4", "co", "co2_bf", "co2_ff", "nmvoc", "nox", "pm2_5", "pm10", "so2"
# Examples:
#   pollutant_names <- c("nox")                    # Only NOx
#   pollutant_names <- c("nox", "nh3")             # Only NOx and NH3  
#   pollutant_names <- c("nox", "nh3", "pm2_5")    # NOx, NH3, and PM2.5
pollutant_names <- c("nh3", "ch4", "co", "co2_bf", "co2_ff", "nmvoc", "nox", "pm2_5", "pm10", "so2")  # All pollutants

# TIME RANGE - modify these years to change the processing period
start_year_global <- 2000
end_year_global   <- 2022

# PHASES TO RUN - modify this list to select which phases to execute
# Available phases: 1, 2, 3, 4, 5, 6, 7, 8, 9
# Examples:
#   phases_to_run <- c(1, 2, 3)     # Only phases 1, 2, and 3
#   phases_to_run <- c(7, 8)        # Only phases 7 and 8
#   phases_to_run <- c(9)           # Only coordinate conversion
phases_to_run <- c(5, 7, 8)  # Use existing FD and simplified profiles, skip 6 (uses existing profiles)

# PHASE 9 COORDINATE CONVERSION SETTINGS
# Directories to convert from [LON,LAT] to [LAT,LON] format
# Examples:
#   convert_directories <- c("Data/Processed/DAILY_data/EM_sum/")                    # Only EM_sum
#   convert_directories <- c("Data/Processed/DAILY_data/DailyFromGLOB/")            # Only GLOB data
#   convert_directories <- c()                                                      # No conversion
convert_directories <- c(
  "Data/Processed/DAILY_data/EM_sum/",
  "Data/Processed/DAILY_data/DailyFromGLOB/"
)

# SUMMARY OF CONFIGURATION
cat("📋 EM-CAMS v.2.0.0 Configuration:\n")
cat("   • Pollutants:", paste(toupper(pollutant_names), collapse=", "), "\n")
cat("   • Time range:", start_year_global, "-", end_year_global, "\n")
cat("   • Total years:", end_year_global - start_year_global + 1, "\n")
cat("   • Phases to run:", paste(phases_to_run, collapse=", "), "\n\n")

###############################################################################

cat("\n🚀 Starting EM-CAMS processing...\n")
cat(paste(rep("=", 50), collapse=""), "\n")
###############################################################################
## PHASE 1: CONFIGURATION, SETUP STRUCTURE, AND CAMS-REG-ANT YEARLY DATA EXTRACTION
###############################################################################
if(1 %in% phases_to_run) {
  cat("\n⚙️ PHASE 1: REG-ANT yearly data extraction\n")
  start_time_phase1 <- Sys.time()

  # 2. SETUP STRUCTURE
  source("setup_structure.R")

  # 3. NEW CAMS-REG-ANT YEARLY DATA EXTRACTION
  source("ExtractANT/ExtractANT.R")

  nc_directory <- "Data/Raw/CAMS-REG-ANT/"
  lon_lat_idx <- readRDS("Data/Processed/lon_lat_idx.rds")

  cat("Processing", length(pollutant_names), "pollutants:", paste(toupper(pollutant_names), collapse=", "), "\n")

  for (pollutant_name in pollutant_names) {
    cat("Processing pollutant:", toupper(pollutant_name), "\n")
    nc_file_paths <- list.files(nc_directory, pattern = paste0(pollutant_name, "_v"), full.names = TRUE)
    nc_file_paths <- nc_file_paths[order(as.numeric(gsub(".*_v([0-9.]+)_.*", "\\1", nc_file_paths)))]
    all_data_list <- list()
    for (nc_file_path in nc_file_paths) {
      all_data_list <- add_new_years_data_updated(nc_file_path, all_data_list)
    }
    all_data_list_final <- lapply(all_data_list, function(x) x$data)
    all_data_matrix <- build_yearly_matrix(all_data_list_final, lon_lat_idx)
    save_path <- paste0("Data/Processed/ANT_data/REG_ANT_yearly_data_", pollutant_name, ".rds")
    saveRDS(all_data_matrix, file = save_path)
    rm(all_data_matrix, all_data_list, all_data_list_final)
    gc()
    cat("✅ Saved:", save_path, "\n")
  }

  cat("All REG RDS files saved.\n")
  end_time_phase1 <- Sys.time()
  cat("==> PHASE 1 completed in:", round(difftime(end_time_phase1, start_time_phase1, units="secs"), 2), "seconds.\n\n")
} else {
  cat("⏭️ Skipping Phase 1\n")
}

#!/usr/bin/env Rscript
###############################################################################
## PHASE 2: CAMS-GLOB-ANT → GNFR-monthly → GNFR-daily (SUPER DEBUG)
###############################################################################
if(2 %in% phases_to_run) {
  cat("\n⚙️ PHASE 2: GLOB-ANT processing\n")
  start_time <- Sys.time()
  library(ncdf4); library(abind); library(lubridate)

  # Carica sorgenti
  source("ExtractANT/ExtractGLOB.R")    # build_5D_GLOB_from_files()
  source("MapGLOBtoGNFR.R")             # map_GLOB_to_GNFR()
  source("GLOB_MonthlyToDaily.R")       # CreateWeeklyProfile(), MonthlyToDaily()

  # Parametri
  glob_nc_dir        <- "Data/Raw/CAMS-GLOB-ANT"
  ant_out_dir        <- "Data/Processed/ANT_data"
  lonlat_idx_rds     <- "Data/Processed/lon_lat_idx_GLOB.rds"
  weekly_csv         <- "Data/Raw/CAMS-REG-TEMPO-SIMPLIFIED/CAMS_TEMPO_v4_1_simplified_Weekly_Factors.csv"
  tempo_base_dir     <- "Data/Processed/TEMPO_data"
  daily_out_base_dir <- "Data/Processed/DAILY_data/DailyFromGLOB"

  # Helper anno/file
  get_year <- function(f) as.integer(sub(".*_(\\d{4})\\.nc$", "\\1", basename(f)))
  get_poll <- function(f) tolower(sub(".*anthro_([^_]+)_.*","\\1",basename(f)))

  nc_files <- list.files(glob_nc_dir, "\\.nc$", full.names=TRUE)
  cat("DEBUG: Found NetCDF files:\n"); print(nc_files); cat("\n")
  if(!length(nc_files)) {
    cat("⚠️ No .nc files found in", glob_nc_dir, "- skipping GLOB processing\n")
  } else {
    unique_polls <- unique(sapply(nc_files, get_poll))
    
    # Filter pollutants based on selection
    available_polls <- intersect(unique_polls, pollutant_names)
    if(length(available_polls) == 0) {
      cat("⚠️ No selected pollutants found in GLOB data - skipping GLOB processing\n")
    } else {
      cat("DEBUG: Processing selected pollutants:", paste(toupper(available_polls), collapse=", "), "\n\n")

      for(poll in available_polls){
        POL <- toupper(poll)
        cat("\n============================\n")
        cat("START Pollutant:", POL, "\n")
        
        # 1) Estrarre 5D monthly GLOB
        these_nc   <- nc_files[sapply(nc_files,get_poll)==poll]
        raw5d_file <- file.path(ant_out_dir, sprintf("GLOB_ANT_monthly_data_%s.rds",poll))
        cat("DEBUG: these_nc:\n"); print(these_nc)
        cat("DEBUG: raw5d_file =", raw5d_file, "\n")
        
        tryCatch({
          data5d <- build_5D_GLOB_from_files(
            netcdf_files      = these_nc,
            boundary          = boundary,
            sector_names_GLOB = sector_names_GLOB,
            output_file       = raw5d_file
          )
          cat("DEBUG: data5d dim ="); print(dim(data5d))
          cat("DEBUG: data5d dimnames lon,lat,sector,month,year:\n")
          print(lapply(dimnames(data5d), function(x) head(x,3)))
          cat("\n")
          
          # 2) Map GLOB→GNFR
          gnfr5d_file <- file.path(ant_out_dir, sprintf("GLOB_GNFR_ANT_monthly_data_%s.rds",poll))
          cat("DEBUG: gnfr5d_file =", gnfr5d_file, "\n")
          gnfr5d <- map_GLOB_to_GNFR(data5d)
          cat("DEBUG: gnfr5d dim ="); print(dim(gnfr5d))
          cat("DEBUG: gnfr5d dimnames head:\n")
            print(lapply(dimnames(gnfr5d), function(x) head(x,3)))
          saveRDS(gnfr5d, gnfr5d_file)
          cat("DEBUG: after saveRDS(gnfr5d): exists? ", file.exists(gnfr5d_file), "\n\n")
          
          # 3) Monthly→Daily GNFR
          cat("DEBUG: Preparing MonthlyToDaily for", POL, "\n")
          weekly_dir <- file.path(tempo_base_dir,"DailySimplifiedProfiles",POL,"WeeklyProfiles")
          weekly_rds <- file.path(weekly_dir,paste0("S_W_simplified_",POL,".rds"))
          cat("DEBUG: weekly_rds =", weekly_rds, "\n")
          if(!file.exists(weekly_rds)){
            cat("DEBUG: Creating weekly profile...\n")
            CreateWeeklyProfile(weekly_csv,poll,weekly_dir)
          }
          out_daily <- file.path(daily_out_base_dir,poll)
          years_avail <- sort(unique(get_year(these_nc)))
          cat("DEBUG: years_avail =", years_avail, "\n")
          
          MonthlyToDaily(
            monthly_rds    = gnfr5d_file,
            weekly_rds     = weekly_rds,
            lonlat_idx_rds = lonlat_idx_rds,
            pollutant      = POL,
            output_dir     = out_daily,
            years          = years_avail
          )
          
          # verifica cartella
          cat("DEBUG: Listing out_daily:\n")
          print(list.files(out_daily, recursive=TRUE))
          cat("✅ Completed pollutant:", POL, "\n")
          
        }, error = function(e) {
          cat("❌ Error processing", POL, ":", e$message, "\n")
        })
      }
    }
  }

  cat("\n==> PHASE 2 (GLOB-ANT) completed in", round(difftime(Sys.time(), start_time, units="secs"), 2), "seconds.\n\n")
} else {
  cat("⏭️ Skipping Phase 2\n")
}

###############################################################################
## PHASE 2B: CAMS-REG-TEMPO PROFILES EXTRACTION
###############################################################################
if(3 %in% phases_to_run) {
  cat("\n⚙️ PHASE 2B: REG-TEMPO profile extraction\n")
  start_time_phase2 <- Sys.time()

  source("ExtractTEMPO/ExtractTEMPO.R")
  #get lon,lat indices 
  #get_lon_lat_indices("Data/Raw/CAMS-REG-TEMPO/CAMS-REG-TEMPO_EUR_0.1x0.1_tmp_weights_v3.1_daily.nc",boundary)

  # Define paths
  nc_file_path_daily_weekly <- "Data/Raw/CAMS-REG-TEMPO/CAMS-REG-TEMPO_EUR_0.1x0.1_tmp_weights_v3.1_daily.nc"
  nc_file_path_monthly      <- "Data/Raw/CAMS-REG-TEMPO/CAMS-REG-TEMPO_EUR_0.1x0.1_tmp_weights_v3.1_monthly.nc"
  output_dir                <- "Data/Processed/TEMPO_data"

  # Process Profiles
  process_profile(nc_file_path_daily_weekly, nc_file_path_monthly, "FM_F",       output_dir)
  process_profile(nc_file_path_daily_weekly, nc_file_path_monthly, "FW_F",       output_dir)
  #process_profile(nc_file_path_daily_weekly, nc_file_path_monthly, "FW_H",     output_dir)
  process_profile(nc_file_path_daily_weekly, nc_file_path_monthly, "FD_C",       output_dir)
  process_profile(nc_file_path_daily_weekly, nc_file_path_monthly, "FD_L_nh3",   output_dir)
  process_profile(nc_file_path_daily_weekly, nc_file_path_monthly, "FD_K_nh3_nox", output_dir)
  #process_profile(nc_file_path_daily_weekly, nc_file_path_monthly, "FM_B", NULL, output_dir)
  #process_profile(nc_file_path_daily_weekly, nc_file_path_monthly, "FW_B", NULL, output_dir)

  end_time_phase2 <- Sys.time()
  cat("==> PHASE 2B (CAMS-REG-TEMPO Profiles Extraction) completed in:", 
      round(difftime(end_time_phase2, start_time_phase2, units="secs"), 2), "seconds.\n\n")
} else {
  cat("⏭️ Skipping Phase 2B\n")
}

###############################################################################
## PHASE 3: SIMPLIFIED-CAMS-REG-TEMPO PROFILE EXTRACTION (CSV-based)
###############################################################################
if(4 %in% phases_to_run) {
  cat("\n⚙️ PHASE 3: Simplified TEMPO profiles\n")
  start_time_phase3 <- Sys.time()

  # Extract data from CSV files
  Path_MonthlySimplified <- "Data/Raw/CAMS-REG-TEMPO-SIMPLIFIED/CAMS_TEMPO_v4_1_simplified_Monthly_Factors_climatology.csv"
  Path_WeeklySimplified  <- "Data/Raw/CAMS-REG-TEMPO-SIMPLIFIED/CAMS_TEMPO_v4_1_simplified_Weekly_Factors.csv"

  Path_simplifiedProfilesCSV <- c(Path_MonthlySimplified, Path_WeeklySimplified)

  # Extract ALL available pollutants from CSV (no filtering based on selection)
  # This avoids naming inconsistencies between our config (nox, pm2_5, so2) 
  # and CSV format (NOx, PM2.5, SOx)
  available_pollutants_csv <- c("CO", "NH3", "NMVOC", "NOx", "PM10", "PM2.5", "SOx")
  
  cat("Processing simplified profiles for ALL available pollutants:", paste(available_pollutants_csv, collapse=", "), "\n")
  cat("(This ensures all profiles are available regardless of current pollutant selection)\n")

  for (poll in available_pollutants_csv) {
    cat("Creating simplified profile for:", poll, "\n")
    tryCatch({
      SimpleProfilesCreation(Path_simplifiedProfilesCSV, poll, start_year_global, end_year_global)
      cat("✅ Successfully created profiles for:", poll, "\n")
    }, error = function(e) {
      cat("❌ Error creating profiles for", poll, ":", e$message, "\n")
    })
  }

  end_time_phase3 <- Sys.time()
  cat("==> PHASE 3 (Simplified-CAMS-REG-TEMPO CSV extraction) completed in:",
      round(difftime(end_time_phase3, start_time_phase3, units="secs"), 2), "seconds.\n\n")
} else {
  cat("⏭️ Skipping Phase 3\n")
}


###############################################################################
## PHASE 4: CAMS-REG-TEMPO DAILY PROFILE CREATION using FM & FW
###############################################################################
if(5 %in% phases_to_run) {
  cat("\n⚙️ PHASE 4: Daily profiles from FM & FW\n")
  start_time_phase4 <- Sys.time()

  source("Computation/ComputeFinal.R")

  FM_profile <- readRDS("Data/Processed/TEMPO_data/FM_F_monthly.rds")
  FW_profile <- readRDS("Data/Processed/TEMPO_data/FW_F_weekly.rds")

  DailyPRF_fromFMFW(FM_profile, FW_profile, "F")

  end_time_phase4 <- Sys.time()
  cat("==> PHASE 4 (Daily profiles from FM & FW) completed in:",
      round(difftime(end_time_phase4, start_time_phase4, units="secs"), 2), "seconds.\n\n")
} else {
  cat("⏭️ Skipping Phase 4\n")
}


###############################################################################
## PHASE 5: COMPUTE DAILY DATA WITH FD PROFILES
###############################################################################
if(6 %in% phases_to_run) {
  cat("\n⚙️ PHASE 5: Compute daily data with FD profiles\n")
  start_time_phase5 <- Sys.time()

  source("Computation/ComputeNormalDaily.R")
  source("Computation/ComputeFinal.R")

  # Example usage
  temporal_profile_folder <- "Data/Processed/TEMPO_data"
  output_folder           <- "Data/Processed/DAILY_data"

  # Process only selected pollutants that have FD profiles
  fd_pollutants <- intersect(pollutant_names, c("nh3", "nox", "so2", "pm10", "pm2_5", "nmvoc", "co", "ch4", "co2_ff", "co2_bf"))
  
  cat("Processing FD profiles for:", paste(toupper(fd_pollutants), collapse=", "), "\n")

  for(pollutant_name in fd_pollutants) {
    cat("Processing FD profile for:", toupper(pollutant_name), "\n")
    sector         <- "F"
    yearly_data_file <- paste0("Data/Processed/ANT_data/REG_ANT_yearly_data_", pollutant_name, ".rds")
    
    if(file.exists(yearly_data_file)) {
      tryCatch({
        calculate_from_FD(pollutant_name, yearly_data_file, temporal_profile_folder, output_folder, sector)
        cat("✅ Completed FD processing for:", toupper(pollutant_name), "\n")
      }, error = function(e) {
        cat("❌ Error processing", toupper(pollutant_name), ":", e$message, "\n")
      })
    } else {
      cat("⚠️ Yearly data file not found for:", toupper(pollutant_name), "\n")
    }
  }

  end_time_phase5 <- Sys.time()
  cat("==> PHASE 5 (Compute daily data with FD) completed in:",
      round(difftime(end_time_phase5, start_time_phase5, units="secs"), 2), "seconds.\n\n")
} else {
  cat("⏭️ Skipping Phase 5\n")
}

###############################################################################
## PHASE 6: COMPUTE DAILY DATA WITH SIMPLIFIED PROFILES (IN PARALLEL)
###############################################################################
if(7 %in% phases_to_run) {
  cat("\n⚙️ PHASE 6: Compute daily data (simplified profiles)\n")
  start_time_phase6 <- Sys.time()

  library(foreach)
  library(doParallel)

  # Setup parallel
  n_cores <- parallel::detectCores()
  cl <- makeCluster(n_cores)
  registerDoParallel(cl)

  clusterEvalQ(cl, {
    source("Config.R")
    source("Utils.R")
    source("Computation/ComputeSimplifiedDaily.R")
  })

  # Map each pollutant name to the corresponding RDS file suffix
  pollutant_file_map <- list(
    "NH3"   = "nh3",
    "PM10"  = "pm10",
    "PM2.5" = "pm2_5",
    "NOx"   = "nox",
    "NMVOC" = "nmvoc",
    "SOx"   = "so2",
    "CO"    = "co"
  )

  # Filter selected pollutants for simplified processing
  simplified_mapping <- list(
    "nh3" = "NH3", "pm10" = "PM10", "pm2_5" = "PM2.5", 
    "nox" = "NOx", "nmvoc" = "NMVOC", "so2" = "SOx", "co" = "CO"
  )
  
  selected_simplified_polls <- simplified_mapping[intersect(names(simplified_mapping), pollutant_names)]
  selected_simplified_polls <- unlist(selected_simplified_polls)
  
  cat("Processing simplified profiles for:", paste(selected_simplified_polls, collapse=", "), "\n")

  # Parallel loop to process each pollutant's data
  foreach(poll = selected_simplified_polls, .packages = c("base")) %dopar% {
    file_name <- paste0("Data/Processed/ANT_data/REG_ANT_yearly_data_", 
                        pollutant_file_map[[poll]], ".rds")
    if(file.exists(file_name)) {
      yearly_data <- readRDS(file_name)
      DailyDataFromSimplified(yearly_data, start_year_global, end_year_global, poll)
      cat(paste("✔️ Done simplified daily data for:", poll, "\n"))
    } else {
      cat(paste("⚠️ File not found for:", poll, "\n"))
    }
  }

  stopCluster(cl)
  cat("==> Phase 6: Daily data computed for selected pollutants (simplified profiles).\n")

  end_time_phase6 <- Sys.time()
  cat("==> PHASE 6 (Compute daily data with Simplified) completed in:",
      round(difftime(end_time_phase6, start_time_phase6, units="secs"), 2), "seconds.\n\n")
} else {
  cat("⏭️ Skipping Phase 6\n")
}

###############################################################################
## PHASE 7: STACK DAILY DATA ALONG YEARS (SEQUENTIALLY) AND SUM ALL SECTORS
###############################################################################
if(8 %in% phases_to_run) {
  cat("\n⚙️ PHASE 7: Stacking and summing daily data\n")
  start_time_phase7 <- Sys.time()

  # Source your configuration and utility scripts
  source("Config.R")
  source("Utils.R")
  source("Computation/ComputeFinal.R")  # Contiene StackDailyData e SumAllSectorsIntoOne

  # Impostazioni generali utilizzando la configurazione selezionata
  input_folder   <- "Data/Processed/DAILY_data"
  
  # Settori e inquinanti da processare - utilizzare solo i pollutant selezionati
  sectors     <- LETTERS[1:12]
  
  # Map pollutant names to uppercase for processing
  polls_stack <- toupper(simplified_mapping[intersect(names(simplified_mapping), pollutant_names)])
  polls_stack <- unlist(polls_stack)
  
  cat("Stacking data for pollutants:", paste(polls_stack, collapse=", "), "\n")
  cat("Time range:", start_year_global, "-", end_year_global, "\n")

  ###############################################################################
  # A) Stack daily data per ogni (sector, pollutant)
  ###############################################################################
  cat("Phase 7A: Stacking daily data for all sectors/pollutants\n")
  for (sector in sectors) {
    for (pollutant in polls_stack) {
      cat("Stacking sector", sector, "pollutant", pollutant, "\n")
      tryCatch({
        StackDailyData(
          input_folder = input_folder,
          sector       = sector,
          pollutant    = pollutant,
          start_year   = start_year_global,
          end_year     = end_year_global
        )
      }, error = function(e) {
        cat("❌ Error stacking", sector, pollutant, ":", e$message, "\n")
      })
    }
  }
  cat("==> PHASE 7A: Stacking of daily data for all sectors/pollutants completed.\n\n")

  ###############################################################################
  # B) Somma di tutti i settori anno per anno in EM_sum
  ###############################################################################
  cat("Phase 7B: Summing all sectors\n")
  stacked_folder  <- file.path(input_folder, "DailyAlongYears")
  out_folder_EM   <- file.path(input_folder, "EM_sum")
  dir.create(out_folder_EM, recursive = TRUE, showWarnings = FALSE)

  for (poll in polls_stack) {
    message("Summing all sectors for pollutant: ", poll)
    tryCatch({
      SumAllSectorsIntoOne(
        input_folder  = stacked_folder,   # leggi i file impilati
        pollutant     = poll,
        start_year    = start_year_global,
        end_year      = end_year_global,
        output_folder = out_folder_EM     # qui i file per anno
      )
      message("✔️  Saved summed data for ", poll, " in ", out_folder_EM, "\n")
    }, error = function(e) {
      message("❌ Error summing ", poll, ": ", e$message, "\n")
    })
  }

  cat("==> PHASE 7B: Summation of daily data across all sectors completed.\n")
  cat("I file aggregati per anno sono in: ", out_folder_EM, "\n\n")

  ###############################################################################
  # Final status
  ###############################################################################
  end_time_phase7 <- Sys.time()
  cat("==> PHASE 7 completed in:",
      round(difftime(end_time_phase7, start_time_phase7, units = "secs"), 2),
      "seconds.\n\n")
  cat("All steps completed successfully.\n",
      "Data are in:\n",
      " - 'Data/Processed/DAILY_data/DailyAlongYears' (per-sector)\n",
      " - 'Data/Processed/DAILY_data/EM_sum' (sector-summed per anno)\n\n")
} else {
  cat("⏭️ Skipping Phase 7\n")
}

###############################################################################
## FINAL SUMMARY
###############################################################################
cat("\n🎉 EM-CAMS PROCESSING COMPLETED\n")
cat(paste(rep("=", 60), collapse=""), "\n")
cat("📋 Processing Summary:\n")
cat("   ✅ Selected pollutants:", paste(toupper(pollutant_names), collapse=", "), "\n")
cat("   ✅ Time range:", start_year_global, "-", end_year_global, "\n")
cat("   ✅ Executed phases:", paste(phases_to_run, collapse=", "), "\n")

if(exists("start_time_phase1")) {
  total_end_time <- Sys.time()
  total_duration <- difftime(total_end_time, start_time_phase1, units = "mins")
  cat("   ⏱️  Total execution time:", round(total_duration, 2), "minutes\n")
}

cat("\n📁 Output directories:\n")
if(1 %in% phases_to_run) cat("   • REG-ANT yearly data: Data/Processed/ANT_data/\n")
if(2 %in% phases_to_run) cat("   • GLOB-ANT data: Data/Processed/ANT_data/ & Data/Processed/DAILY_data/DailyFromGLOB/\n")
if(3 %in% phases_to_run) cat("   • TEMPO profiles: Data/Processed/TEMPO_data/\n")
if(6 %in% phases_to_run || 7 %in% phases_to_run) cat("   • Daily data: Data/Processed/DAILY_data/\n")
if(8 %in% phases_to_run) cat("   • Summed data: Data/Processed/DAILY_data/EM_sum/\n")

cat("\n🔧 Optional Phase 9: Coordinate Converter\n")
cat("   To convert coordinates from [LON,LAT] to [LAT,LON], run:\n")
cat("   source('phase9_coordinate_converter.R')\n")

cat("\n✅ EM-CAMS v.2.0.0 PROCESSING COMPLETED SUCCESSFULLY!\n")
cat(paste(rep("=", 70), collapse=""), "\n")
## COORDINATE CONVERTER (OPZIONALE)
###############################################################################
# Carica coordinate converter per conversioni [LON,LAT] → [LAT,LON]
source("coordinate_converter.R")

# Conversioni directory principali (decommentare se necessario):
convert_directory("Data/Processed/DAILY_data/EM_sum/", "Data/Processed/DAILY_data/EM_sum_lat_lon/")
convert_directory("Data/Processed/DAILY_data/DailyFromGLOB/", "Data/Processed/DAILY_data/DailyFromGLOB_lat_lon/")

total_end_time <- Sys.time()
if (exists("start_time_phase1")) {
  total_duration <- difftime(total_end_time, start_time_phase1, units = "mins")
  cat("⏱️  TEMPO TOTALE ESECUZIONE:", round(total_duration, 2), "minuti\n\n")
}

cat("✅ PROGETTO EM-CAMS v.2.0.0 COMPLETATO CON SUCCESSO!\n")
cat(paste(rep("=", 70), collapse=""), "\n")
