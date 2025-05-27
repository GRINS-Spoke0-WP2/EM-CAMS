# EM-CAMS: Italian Emission Daily Dataset via Copernicus

**EM-CAMS** (Copernicus Emission Daily Dataset) is a high-resolution daily inventory of anthropogenic emissions over Italy, built using Copernicus Atmosphere Monitoring Service (CAMS) data.

> 🚨 **Note:** This README provides only a **brief overview** of the work performed. For a **detailed methodology** behind the 2000–2022 dataset, please refer to the [IEDD repository](https://github.com/aminb00/IEDD). Detailed explanations for the CAMS-GLOB-ANT extension will be added soon. This README covers:

1. Spatial and temporal coverage
2. Data sources and structure of CAMS-REG-ANT and CAMS-GLOB-ANT inventories
3. CAMS-REG-TEMPO temporal profiles (V3.1, simplified V4.1)
4. Dataset construction methodology
5. Mapping of global sectors to GNFR (table)
6. Data processing workflow
7. Recommendations for harmonizing the periods 2000–2022 vs. 2023–2025

---

## 1. Spatial and Temporal Coverage

* **Geographic domain**: Entire Italian territory (35°N–47°N, 6°E–19°E).
* **Spatial resolution**:

  * **2000–2022**: 0.05° × 0.1° grid (\~5.5 km × 11 km).
  * **2023–2025**: 0.1° × 0.1° grid (\~11 km × 11 km), resampled to 0.05° × 0.1° for consistency.
* **Temporal coverage**:

  * **2000–2022**: Daily emissions via CAMS-REG-ANT + CAMS-REG-TEMPO.
  * **2023–2025**: Monthly emissions from CAMS-GLOB-ANT disaggregated to daily using CAMS-REG-TEMPO v4.1 simplified.

## 2. Data Sources

### 2.1 CAMS-REG-ANT

* Regional anthropogenic emission inventory (TNO/CAMS) for Europe.
* Resolution: 0.05° × 0.1°.
* Temporal coverage: annual totals, 2000–2022 (versions v5.1, v6.1, v7.0).
* Pollutants: NOₓ, SO₂, NMVOC, NH₃, CO, PM₁₀, PM₂.₅, CO₂\_ff, CO₂\_bf, CH₄.
* Sectors: 16 GNFR categories (A–L, F1–F4).
* Units: areal fluxes (kg·m⁻²·s⁻¹).

### 2.2 CAMS-GLOB-ANT

* Global anthropogenic emission inventory (CAMS v5.3, EDGAR-derived).
* Resolution: 0.1° × 0.1°, resampled for EM-CAMS.
* Temporal coverage: monthly, 2000–2023 (extrapolated to 2025).
* Species: 36+ pollutants (air pollutants and greenhouse gases), units kg·m⁻²·s⁻¹.
* Sectors: 17 macro-categories aggregated from EDGAR/CEDS to align with GNFR.

### 2.3 CAMS-REG-TEMPO

* Temporal profiles for disaggregating annual emissions into daily.
* **V3.1**: detailed daily, weekly, and monthly profiles per grid cell and pollutant.
* **V4.1 simplified**: country-level monthly, weekly, and hourly profiles (CSV).

## 3. Construction Methodology

### 3.1 Period 2000–2022 (original IEDD)

1. **Annual data** from CAMS-REG-ANT: \$E\_{i,s,j}\$ (grid cell i, sector s, year j).
2. **Daily disaggregation**:
   $E_{i,s}(t) = E_{i,s,j} \times x_{s,m(t)} \times y_{s,d(t)},$
   where \$x\_{s,m}\$ = monthly profile, \$y\_{s,d}\$ = weekly profile.
3. **Output**: daily emissions on a 0.05° × 0.1° grid for 16 GNFR sectors (+ sub-sectors).

### 3.2 Period 2023–2025 (extended EM-CAMS)

1. **Monthly data** from CAMS-GLOB-ANT (0.1° × 0.1°).
2. **Spatial resampling** to 0.05° × 0.1°.
3. **Seasonal alignment**:

   * Compute annual total \$T\_s\$ as the sum of the 12 global monthly values \$E^{\mathrm{glob}}\_{s,m}\$.
   * Apply CAMS-REG-TEMPO monthly profiles: \$E^{\mathrm{corr}}*{s,m} = T\_s \times x*{s,m}\$.
   * Compute correction factors \$\alpha\_{s,m} = E^{\mathrm{corr}}*{s,m} / E^{\mathrm{glob}}*{s,m}\$.
   * Apply \$\alpha\_{s,m}\$ pixel-wise to the global monthly maps.
4. **Daily disaggregation**:

   * Use weekly profiles \$y\_{s,d}\$ to split each month into days.
   * Daily map = corrected monthly map \$\times \frac{y\_{s,d}}{\sum\_{t \in m} y\_{s,d(t)}}\$.
5. **Missing sectors**: F1–F4, I remain unpopulated (future estimates possible).

## 4. Mapping of GLOB Sectors to GNFR

| CAMS-GLOB-ANT Category  | GNFR in EM-CAMS           | Notes                                        |
| ----------------------- | ------------------------- | -------------------------------------------- |
| Energy                  | A (Public Power)          | Power and heat generation                    |
| Industry                | B (Industry)              | Manufacturing and industrial processes       |
| Residential/Commercial  | C (Other Stationary)      | Residential and commercial heating           |
| Fugitive Emissions      | D (Fugitives)             | Fuel extraction and distribution losses      |
| Solvent & Products      | E (Solvents)              | Solvent use and industrial chemicals         |
| Road Transport          | F (Road Transport)        | Aggregate of F1–F4 sub-sectors               |
| Shipping                | G (Shipping)              | Inland and maritime navigation               |
| Aviation                | H (Aviation)              | Landing/take-off and cruise emissions        |
| Off-Road Machinery      | **I (OffROAD)**           | **Not available**                            |
| Waste Management        | J (Waste)                 | Landfills, wastewater, incineration          |
| Agriculture - Livestock | K (Agriculture-Livestock) | Livestock farming emissions                  |
| Agriculture - Other     | L (Agriculture-Other)     | Fertilizers and agricultural residue burning |

> **Note**: Sectors I and sub-sectors F1–F4 are not separately provided by CAMS-GLOB-ANT and remain zero in EM-CAMS.

## 5. Data Processing Workflow

```text
1. Download CAMS-REG-ANT annual data
2. Download CAMS-GLOB-ANT monthly data
3. Dowload CAMS-REG-TEMPO V3.1 & V4.1 simplified profiles (CSV)
4. Daily disaggregation using TEMPO profiles and TEMPO simplified profiles
5. Export daily maps in rds files



**Contact & Collaboration**: For questions or contributions, open an Issue or contact the maintainer.

**License**: MIT. Feel free to use and adapt, citing EM-CAMS and CAMS.

---
*Generated by the EM-CAMS Team*

```
