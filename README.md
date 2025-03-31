# EM-CAMS

## Introduction

EM-CAMS provides daily emission estimates for key atmospheric pollutants across the Italian territory for the period 2000–2022, with a high spatial resolution of 0.05° x 0.1°. By leveraging cutting-edge data from the Copernicus Atmosphere Monitoring Service (CAMS) inventories and temporal profiles, the EM-CAMS fills a critical gap in providing temporally granular emission data—moving beyond annual averages to day-by-day variations.

The primary goal of the EM-CAMS is to enable a deeper understanding of short-term emission dynamics. Such temporal detail supports refined air quality modeling, nuanced policy assessments, climate and health studies, and scenario evaluations that demand insights into when, how, and why emissions fluctuate over time.

## Thesis Preview

For a detailed explanation of the methodologies and scientific motivation behind the EM-CAMS v2.0.0, you can consult the author Bachelor Thesis directly:

[📄 View the IEDD Thesis (PDF)](Documentation/IEDD_Thesis.pdf)

---

## EM-CAMS Versions

Below is a concise comparison of the two current EM-CAMS versions:

| **EM-CAMS Version**         | **Temporal Coverage** | **Spatial Coverage** | **Spatial Resolution** | **Origin**                                                                          | **Temporal Resolution** | **Sectors**                               |
|-----------------------------|-----------------------|----------------------|------------------------|--------------------------------------------------------------------------------------|-------------------------|-------------------------------------------|
| **v1.0**                    | 2013–2023             | Italy                | 0.1° × 0.1°           | CAMS-GLOB-ANT v6.2                        | Daily                   | sum Sector          |
| **v2.0** (ongoing work)      | 2000–2022             | Italy                | 0.05° × 0.1°           | CAMS-REG-ANT v8.0 and CAMS-REG-TEMPO Simplified v4.1                          | Daily                   | GNFR sectors (A–L) + sum.sectors          |



## Repository Structure


- **Data**: (Not provided in this repository)  
  Processed data files (e.g., daily emission matrices in `.rds` or `.nc` format) are expected to be hosted externally due to their size. Instructions or links for downloading these data files will be provided as the dataset becomes publicly available.

- **Scripts**:  
  A set of R scripts are used to:
  - Load CAMS-REG-ANT and CAMS-REG-TEMPO data
  - Apply temporal profiles
  - Validate the outcomes
  - Generate final daily emission arrays

## EM-CAMS Scope and Foundational Concepts

Key aspects:
- **Why daily data?** Annual emissions mask the complex variability driven by daily changes in activities, weather, and policy interventions.
- **Relevance to Italy**: The Italian domain, with its industrialized Po Valley, diverse climates, and maritime activities, serves as a rich testing ground for daily-level analyses.
- **Intended users**: Scientists, policymakers, urban planners, NGOs, and stakeholders interested in short-term pollution events, targeted mitigation, and evaluating regulatory impacts.

## Underlying CAMS Inventories

The EM-CAMS draws its emission data and temporal factors from CAMS inventories:

- **CAMS-REG-ANT**: Supplies the annual gridded baseline of pollutant emissions, ensuring consistent, harmonized data across sectors and pollutants.
- **CAMS-REG-TEMPO**: Provides the temporal “keys” that transform annual totals into monthly, weekly, and daily profiles, capturing the dynamic nature of emission sources.

To learn more about these core datasets, their methodology, and their relevance to the IEDD, please consult [CAMS Inventories](Documentation/CAMSinventories.md).

## EM-CAMS Methodology

The construction of the EM-CAMS v.2.0.0 entails:
1. Starting from annual baseline emissions (CAMS-REG-ANT).
2. Applying temporal profiles (CAMS-REG-TEMPO) to disaggregate emissions into daily values.
3. Ensuring temporal consistency (sums over the year remain unchanged), handling leap years, and validating against independent data.

A detailed methodological guide is provided in [IEDD Thesis](Documentation/IEDD_Thesis.pdf) chapter Methodology. The following points are explained:
- Mathematical formulas for temporal disaggregation
- Sector- and pollutant-specific approaches
- Data quality checks and uncertainty considerations
- Step-by-step instructions for reproducing the results

## Getting Started

To start working with the EM-CAMS, follow these steps:

### 1. Clone the Repository

To begin, clone the EM-CAMS repository to your local machine. Use the following command:

```bash
git clone https://github.com/xxxxxxxx/EM-CAMS.git
```
### 2. Download Required CAMS Data

#### Register and Access ECCAD
- Visit [ECCAD](https://eccad.aeris-data.fr/) and create an account if you haven’t already.
- After logging in, navigate to the relevant CAMS emission inventory sections.

#### Download CAMS-REG-ANT Annual Files
- Choose the CAMS-REG-ANT versions covering the years 2000–2020 (e.g., v5.1 for 2000–2018 and v6.1 for 2019–2020).
- Download the NetCDF files for each pollutant of interest (e.g., NOx, SO₂, NH₃, CO, NMVOC, PM₁₀, PM₂.₅).
- Once downloaded, place these NetCDF files into:

```
/Demo/Data/Raw/CAMS-REG-ANT/
```

#### Download CAMS-REG-TEMPO Profiles
- Navigate to the CAMS-REG-TEMPO datasets on ECCAD.
- Download the NetCDF files containing monthly, weekly, and (if available) daily profiles.
- Place these files into:

```
IEDD/Demo/Data/Raw/CAMS-REG-TEMPO/
```

#### CAMS-REG-TEMPO v4.1 Simplified CSV Files
- If using simplified profiles, which come in CSV format (e.g., monthly and weekly factors), download them and place them into:

```
/Demo/Data/Raw/CAMS-REG-TEMPO-SIMPLIFIED/
```

### 3. Set Up R Environment

- **Install R**:
  - Ensure R (≥ 4.0) is installed on your system.

### Verifying Your Setup

Your directory structure should look like this after completing the previous steps:

```
v.2.0.0/
├─ Demo/
│  ├─ Data/
│  │  ├─ Raw/
│  │  │  ├─ CAMS-REG-ANT/              # Contains NetCDF files for CAMS-REG-ANT
│  │  │  ├─ CAMS-REG-TEMPO/            # Contains NetCDF files for CAMS-REG-TEMPO
│  │  │  ├─ CAMS-REG-TEMPO-SIMPLIFIED/ # Contains CSV files for simplified profiles
│  │                  # R scripts for processing and analysis
│  │                
```

---

## Future Plans and Contributions

The EM-CAMS is a living dataset, open to updates as new data, temporal profiles, or improved methodologies become available. Potential future developments include:

- Adding CH₄ and CO₂ emissions once daily profiles become robust.
- Extending the dataset beyond 2022.
- Integrating near-real-time activity data for more dynamic emission estimates.

Contributions from the community are welcome. Whether you identify data inconsistencies, propose methodological enhancements, or share your modeling experiences, your input can help refine and strengthen the IEDD.

---

## References and Licensing

- Please refer to the **References** section in each of the documentation files for the scientific and technical literature underlying CAMS data and temporal profiles.
- The code and documentation provided in this repository are released under the MIT License, allowing for broad reuse, modification, and redistribution. For details, see the `LICENSE.md` file.

---

## Contact and Support

For questions, bug reports, or further information:

- Open an issue on this repository’s issue tracker.
- Contact the maintainers or lead authors directly (contact information provided in the repository homepage or accompanying publications).

Your feedback is valuable and will help us improve the dataset’s quality, usability, and relevance.
