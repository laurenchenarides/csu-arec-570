###############################################
# Author: Lauren Chenarides
# Last updated: October 9, 2024
# Course: AREC 570
###############################################

rm(list=ls())

# Set your working directory
setwd("C:/Users/lachenar/OneDrive - Colostate/Teaching/Courses/CSU/AREC570/api_docs")

###############################################
# Script to Load Census Data Using ACS API
# Description: This script retrieves ACS data
#              (median income, population, employment 
#               status, median age)
#              for various years using Census API.
# API package: tidycensus
# Need API Key: Yes
###############################################

# Install and load necessary packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, sf, tidycensus, dplyr)

# Load Census API key
# Sign up for a key at https://api.census.gov/data/key_signup.html if you don't have one
# Once you receive the key, use the code below to install it
# Replace your api key with your actual key
census_api_key("946625c67cbce4cbdeb8b831281b8b15345b3a0d", install = TRUE)

# ================================================
# Pull Census data (median income, population, employment status, median age)
# ================================================

# Retrieve metadata about the variables available for the American Community Survey (ACS) 5-year estimates for each specified year (2019, 2020, 2021, and 2022)
v19 <- load_variables(2019, "acs5", cache = TRUE)
v20 <- load_variables(2020, "acs5", cache = TRUE)
v21 <- load_variables(2021, "acs5", cache = TRUE)
v22 <- load_variables(2022, "acs5", cache = TRUE)

# Before you fetch actual Census data, it's helpful to know which variables are available and what they represent. For example, you might want to retrieve the median household income (B19013_001), but you first use load_variables() to find the correct variable code for the year you're interested in.

# Define the variables you need
variables <- c(
  medInc = "B19013_001",   # Median Income
  totPop = "B01003_001",   # Total Population
  emp = "B23001_001",      # Employment Status
  medAge = "B01002_001"    # Median Age
)

# Initialize an empty data frame to store results
acs_all <- data.frame()

# Loop through the years you want to pull data for
for (year in 2019:2022) {
  
  # Fetch the data for each year
  medInc <- get_acs(geography = "county", variables = variables["medInc"], year = year)
  totPop <- get_acs(geography = "county", variables = variables["totPop"], year = year)
  emp <- get_acs(geography = "county", variables = variables["emp"], year = year)
  medAge <- get_acs(geography = "county", variables = variables["medAge"], year = year)
  
  # Merge data for the current year
  year_data <- medInc %>%
    select(GEOID, medInc = estimate) %>%
    left_join(totPop %>% select(GEOID, totPop = estimate), by = "GEOID") %>%
    left_join(emp %>% select(GEOID, emp = estimate), by = "GEOID") %>%
    left_join(medAge %>% select(GEOID, medAge = estimate), by = "GEOID") %>%
    mutate(year = year) # Add the year column
  
  # Append to the overall data frame
  acs_all <- bind_rows(acs_all, year_data)
}

# Preview the data
head(acs_all)

# Save the combined data to a CSV file (optional)
# write.csv(acs_all, "acs_data.csv", row.names = FALSE)


###############################################
# FRED Economic Data Time Series Analysis
# Description: This script retrieves wholesale price 
#              index data for carrots from KC FRED, 
#              converts it into a time series object.
# API package: tidyquant
# Need API Key: No
###############################################

# Set working directory if necessary (optional)
getwd()

# Install and load necessary packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(readr, dplyr, janitor, lubridate, tidyr, tidyquant, forecast)

# Load Economic Data from FRED
carrot <- tq_get(
  c("WPU01130212"), # FRED series for wholesale price index for carrots
  get = "economic.data",
  from = "2007-08-01",
  to = "2023-12-31"
)

# View the structure of the data
glimpse(carrot)

## Convert the data into a time series object
carrot_ts <- ts(carrot$price, frequency = 12, start = c(2007, 8))

# View the time series structure
glimpse(carrot_ts)

## Plot the time series
plot(carrot_ts, 
     main = "Wholesale Price Index for Carrots (2007-2023)", 
     xlab = "Year", 
     ylab = "Price Index", 
     col = "blue", 
     lwd = 2)


###############################################
# Unemployment Rate Data Visualization (1990-2000)
# Description: This script retrieves unemployment rate 
#              data from the FRED API and visualizes it 
#              as a time series graph for the period 
#              from 1990 to 2000.
# API package: fredr
# Need API Key: Yes 
###############################################

# Install and load the required package
if (!require("pacman")) install.packages("pacman")
packman::p_load(fredr, ggplot2, dplyr)  

# Sign up for an API key at https://fred.stlouisfed.org/docs/api/api_key.html if you don't have one
# Once you receive the key, use the code below to install it
# Replace your api key with your actual key
fredr_set_key("02d5b215c05482046c075f5289789fcc")

# Search for available series using a keyword, e.g., "unemployment rate"
series_list <- fredr_series_search_text(
  search_text = "unemployment rate",  # Replace with a keyword you're interested in
  limit = 50  # Number of results to return
) %>%
  arrange(id)

# Retrieve unemployment rate data from FRED
unemployment_data <- fredr(
  series_id = "UNRATE",  # FRED series ID for unemployment rate
  observation_start = as.Date("1990-01-01"),  # Start date
  observation_end = as.Date("2000-01-01")     # End date
)

# View the first few rows of the data
head(unemployment_data)

# Plot the unemployment rate data
ggplot(unemployment_data, aes(x = date, y = value)) +
  geom_line(color = "steelblue", size = 1) +
  labs(
    title = "Unemployment Rate in the USA (1990-2000)",
    x = "Year",
    y = "Unemployment Rate (%)"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis labels for readability


###############################################
# BLS API Data Retrieval
# Description: This script retrieves data from the 
#              Bureau of Labor Statistics (BLS) API, 
#              processes it into a usable format.
###############################################

# Go to GitHub repo: blsAPI — U.S. Bureau of Labor Statistics Data for R 
# Available at https://github.com/mikeasilva/blsAPI 



###############################################
# World Bank Data
# Description: This script retrieves total population 
#              data for the USA from the World Bank API 
#              and plots it as a bar chart over time.
# API package: wbstats 
# Need API Key: No 
###############################################

# Install and load the required package
if (!require("pacman")) install.packages("pacman")
packman::p_load(wbstats, ggplot2, scales)  

# Retrieve Population Data (total population)
pop_data <- wb_data("SP.POP.TOTL", start_date = 1960, end_date = 2020)

# Filter data for the USA
usa_pop_data <- pop_data[pop_data$iso3c == "USA",]

# Plot the population data for the USA as a bar chart
ggplot(usa_pop_data, aes(x = date, y = SP.POP.TOTL)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  labs(
    title = "Total Population in the USA (1960-2020)",
    x = "Year",
    y = "Population"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +  # Rotate x-axis labels for readability
  scale_y_continuous(labels = comma)  # Set y-axis lower limit and format labels



###############################################
# Build Your Own API
# Visit https://usda.library.cornell.edu/apidoc/index.html
# See extract_cattle.R 
###############################################

