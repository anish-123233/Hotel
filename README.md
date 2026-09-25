# Project Background

Atliq Group operates in the **hospitality industry**, managing hotel properties across multiple cities, room categories, and booking channels. The business generates revenue through room bookings while monitoring occupancy, pricing, cancellations, and overall property performance.

This project analyzes historical booking and operational data to evaluate hotel performance, identify demand and booking patterns, and uncover opportunities to improve revenue and operational efficiency.

The analysis focuses on key business metrics including **Revenue, Occupancy Rate, Average Daily Rate (ADR), RevPAR, Realization Rate, Bookings, Cancellations, and No-Shows**.

Key areas of analysis include:

- **Revenue & Booking Trends:** Analysis of booking volumes and revenue patterns across properties and time periods.
- **Hotel & Room Performance:** Evaluation of property and room-category performance using occupancy, ADR, and RevPAR.
- **Booking & Cancellation Analysis:** Analysis of booking statuses, cancellations, and no-shows to identify potential revenue leakage.
- **Operational Performance:** Evaluation of occupancy, realization rates, and other operational KPIs to identify performance gaps and improvement opportunities.

Key metrics and measures for the hotel industry used in this project can be found [here.](metrics list.xlsx)

The python scripts utilized to clean and quarantine data can be found [here.](data_cleaning/src/quality_pipeline.ipynb)

The python scripts utilized to inspect and perform quality checks can be found [here.](data_cleaning/tests/test_data_quality.py)

The pipeline runner used to automate execution and enforce the data quality gate can be found [here.](data_cleaning/run_pipeline.py)

The automation script used to run the data quality pipeline and execute automated Pytest validations can be found [here.](data_cleaning/run_pipeline.py)

The SQL script used to perform data transformations for analysis can be found [here.](SQL_scripts/transformations.sql)

The SQL queries used to perform the hotel portfolio analysis can be found [here.](SQL_scripts/eda.sql)



# Data Schema and Structure

The Atliq database follows a Star Schema consisting of 5 tables: 2 fact tables and 3 dimension tables, with a total of 143,911 records.

![Hotel Data Model](Images/data_model.png)



# Executive Summary

### Overview of Findings

Atliq Group of Hotels generated ₹1.69Bn (160 crores) in revenue across 3 months, with Luxury properties contributing 61.62% of that total versus 38.38% from Business, positioning the hotel as a predominantly luxury-focused hotel group where premium pricing, not room volume, is the main revenue driver. 

Demand also skews toward weekends: Weekend RevPAR (₹7,971.63) and occupancy (44.22%) both outpace weekdays (₹7,082.53 and 39.06%), even though ADR is nearly identical across the two, meaning the gap comes from more rooms selling on weekends, not from charging more for them.

Together, these patterns point to a portfolio that could grow revenue further by extending weekend-level demand into weekdays, and by protecting the luxury pricing that drives the bulk of its income.

<p align="center">
  <img src="Images/KPI.png" width="100%">
</p>
![Revenue](Images/revenue_split.png)

