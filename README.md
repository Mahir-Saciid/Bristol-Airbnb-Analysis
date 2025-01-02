# Bristol-Airbnb-Analysis
## Project Overview

This project analyses the Bristol Airbnb market to provide data-driven insights for property investors and hosts. Using data from Inside Airbnb, the analysis focuses on understanding pricing dynamics, seasonal patterns, and factors influencing property performance across Bristol's neighbourhoods.

## Business Questions

The analysis addresses four key questions from stakeholders:

1. When and where should hosts list their properties to maximize revenue?
2. What amenities correlate with higher ratings and prices?
3. How do seasonal patterns affect pricing and availability?
4. Which neighbourhoods offer the best value for travellers?

## Data Pipeline

### Data Collection and Preparation

Using Python, we developed an automated ETL pipeline that:

- Downloads quarterly Airbnb data for Bristol by web scraping ‘insideairbnb.com’
- Processes listings and reviews data across multiple quarters
- Handles data cleaning tasks including price normalization and text standardization
- Retrieves geographical data for Bristol neighbourhoods

### Data Warehouse Implementation

The SQL implementation follows a two-stage approach:

- Staging tables for initial data landing and validation
- Production tables with proper constraints and relationships
- Custom views and stored procedures for analysis

### Data Visualization

The Power BI dashboard consists of four main pages:

1. Geographic Analysis: Neighborhood price distribution and performance metrics
2. Amenity Impact: Correlation between property features and performance
3. Neighbourhood Value: Correlation between neighbourhood ratings and price 
4. Market Overview: Host growth trends and property type distribution

## Key Findings

Our analysis revealed several actionable insights:

![image](https://github.com/user-attachments/assets/885cff94-2c75-48b0-903c-87eef8c2dc96)
Property Performance:

- Central neighbourhoods (Hotwells & Harbourside, Central, Clifton) generate the highest monthly revenue
- Average occupancy rate of 57% suggests room for optimisation
- Price peaks occur in December, while host & listings peak during June

![image](https://github.com/user-attachments/assets/38672d9c-9480-4c7d-8717-ae01b39ca60c)
Market Dynamics:

- The market shows maturity with peak host registration during 2014-2016
- Entire homes and rental units dominate the market (41% combined)
- Properties/neighbourhoods with high ratings don't necessarily command premium prices e.g. St George, Hengrove, Henbury, and Bishopsworth all have average ratings of 4.8 and above but are cheaper than the bristol average price of GBP110

![image](https://github.com/user-attachments/assets/f1a9429d-bd92-41dc-b285-fb750c22bf60)
Amenities:

- Amenities scatter follow a normal distribution around the mean price. with the basic amenities being most common (smoke alarm, wifi, silverware, refrigerator, self-check-in)
- With more niche amenities being found in higher priced and rated listings (Bluetooth sound system, lake access, theme room, pool table, espresso machine)

![image](https://github.com/user-attachments/assets/c30d3e2d-ea08-4dad-bd03-4579e658afc5)

## Technical Stack

- Python: pandas for data processing and web scraping/API interaction
- SQL Server: Data warehousing and analytical queries
- Power BI: Interactive visualizations and dashboard creation

## Skills Demonstrated

- Data Collection and web scraping
- ETL Pipeline Development
- Data Warehouse Design
- SQL View and Stored Procedure Creation
- Data Visualization and Dashboard Design
- Business Intelligence and Analytics
