# Introduction
The purpose of this code is to take a dataset of geocoded addresses and extract different Census Decennial map vintages. The output will be a SAS dataset with a specified GEOID with the map vintage of the selected map_year parameter.

## Requirements
1. SAS software
1. A SAS dataset with the following data elements:
    1. Record ID
    1. X coordinates or longitude
    1. Y coordinates or latitude
    1. State

## Output
This code will produce the same dataaset as the input datset with the addition of the following data elements:
1. GEOID of the selected map vintage renamed to the geoid_var parameter.