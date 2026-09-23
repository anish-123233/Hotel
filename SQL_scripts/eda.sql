/*
===============================================================================
HOTEL PORTFOLIO SQL ANALYSIS
===============================================================================

Project:
    Hotel Revenue & Booking Analysis

Database:
    PostgreSQL

Purpose:
    Analyze hotel booking performance, revenue realization, cancellations,
    occupancy, booking behavior, and revenue leakage using SQL.

Analytical Approach:
    Level 1 → Portfolio Performance Baseline
    Level 2 → Trend & Benchmark Analysis
    Level 3 → Diagnostic & Segmentation Analysis

Core Tables:
    fact_bookings
    fact_aggregated_bookings
    dim_hotels

===============================================================================
*/


/*=============================================================================
1. HOTEL PORTFOLIO KPI BASELINE
===============================================================================

Analytical Level:
    Level 1 - Descriptive Analysis

Business Question:
    What is the overall performance of the hotel portfolio?

Purpose:
    Establish the portfolio-level baseline before moving into
    property, channel, and behavioral analysis.
=============================================================================*/

SELECT
    COUNT(*) AS total_bookings,

    -- Number of bookings that were cancelled
    COUNT(*) FILTER (
        WHERE booking_status = 'Cancelled'
    ) AS cancelled_bookings,

    -- Number of bookings where the guest completed the stay
    COUNT(*) FILTER (
        WHERE booking_status = 'Checked Out'
    ) AS completed_bookings,

    -- Percentage of total bookings that were cancelled
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE booking_status = 'Cancelled'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_perc,

    -- Total revenue generated from bookings
    ROUND(SUM(revenue_generated), 2) AS gross_revenue,

    -- Revenue actually realized by the hotel
    ROUND(SUM(revenue_realized), 2) AS realized_revenue,

    -- Percentage of generated revenue that was realized
    ROUND(
        100.0 * SUM(revenue_realized)
        / NULLIF(SUM(revenue_generated), 0),
        2
    ) AS realization_perc,

    -- Difference between generated and realized revenue
    ROUND(
        SUM(revenue_generated) - SUM(revenue_realized),
        2
    ) AS revenue_leakage,

    -- Average number of guests per booking
    ROUND(AVG(no_guests), 2) AS avg_guests_per_booking,

    -- Average number of days between check-in and check-out
    ROUND(
        AVG(checkout_date - check_in_date),
        2
    ) AS avg_length_of_stay_days

FROM fact_bookings;


/*=============================================================================
2. MONTHLY HOTEL PERFORMANCE TREND
===============================================================================

Analytical Level:
    Level 2 - Time-Based Analysis

Business Question:
    How do booking volume, cancellations, revenue realization,
    and length of stay change month by month?

Purpose:
    Identify changes in hotel performance over time.
=============================================================================*/

SELECT
    DATE_TRUNC('month', check_in_date)::date AS month,

    -- Booking volume
    COUNT(*) AS total_bookings,

    -- Number of completed stays
    COUNT(*) FILTER (
        WHERE booking_status = 'Checked Out'
    ) AS completed_bookings,

    -- Number of cancelled bookings
    COUNT(*) FILTER (
        WHERE booking_status = 'Cancelled'
    ) AS cancelled_bookings,

    -- Monthly cancellation rate
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE booking_status = 'Cancelled'
        ) / NULLIF(COUNT(*), 0)::numeric,
        2
    ) AS cancellation_perc,

    -- Percentage of generated revenue that was realized
    ROUND(
        100.0 * SUM(revenue_realized)
        / NULLIF(SUM(revenue_generated), 0)::numeric,
        2
    ) AS realization_perc,

    -- Difference between generated and realized revenue
    SUM(revenue_generated) - SUM(revenue_realized)
        AS revenue_leakage,

    -- Average length of stay
    ROUND(
        AVG(checkout_date - check_in_date),
        2
    ) AS avg_length_of_stay_days

FROM fact_bookings

GROUP BY
    DATE_TRUNC('month', check_in_date)::date

ORDER BY month;


/*=============================================================================
3. MONTH-OVER-MONTH REVENUE GROWTH
===============================================================================

Analytical Level:
    Level 2 - Trend / Growth Analysis

Business Question:
    How is realized revenue changing month over month?

Purpose:
    Measure monthly revenue growth relative to the previous month.
=============================================================================*/

WITH monthly_data AS (

    SELECT
        DATE_TRUNC('month', check_in_date)::date AS month,

        COUNT(*) AS total_bookings,

        COUNT(*) FILTER (
            WHERE booking_status = 'Cancelled'
        ) AS cancelled_bookings,

        ROUND(
            SUM(revenue_realized)::numeric,
            2
        ) AS realized_revenue

    FROM fact_bookings

    GROUP BY
        DATE_TRUNC('month', check_in_date)::date
),

revenue_growth AS (

    SELECT
        month,
        total_bookings,
        cancelled_bookings,
        realized_revenue,

        -- Previous month's realized revenue
        LAG(realized_revenue) OVER (
            ORDER BY month
        ) AS previous_month_revenue

    FROM monthly_data
)

SELECT
    month,
    total_bookings,
    cancelled_bookings,
    realized_revenue,
    previous_month_revenue,

    -- Month-over-month realized revenue growth
    ROUND(
        100.0 * (
            realized_revenue - previous_month_revenue
        ) / NULLIF(previous_month_revenue, 0)::numeric,
        2
    ) AS mom_revenue_growth_perc

FROM revenue_growth

ORDER BY month;


/*=============================================================================
4. PROPERTY-LEVEL PERFORMANCE BENCHMARKING
===============================================================================

Analytical Level:
    Level 2 - Property Benchmarking

Business Question:
    How does each property perform across key business KPIs?

Purpose:
    Compare properties based on bookings, cancellations,
    revenue realization, guest volume, and length of stay.
=============================================================================*/

WITH property_metrics AS (

    SELECT
        d.property_id,
        d.property_name,
        d.city,

        COUNT(*) AS total_bookings,

        -- Number of completed stays
        COUNT(*) FILTER (
            WHERE f.booking_status = 'Checked Out'
        ) AS completed_bookings,

        -- Number of cancelled bookings
        COUNT(*) FILTER (
            WHERE f.booking_status = 'Cancelled'
        ) AS cancelled_bookings,

        -- Total generated revenue
        SUM(f.revenue_generated) AS gross_revenue,

        -- Total realized revenue
        SUM(f.revenue_realized) AS realized_revenue,

        -- Average guests per booking
        ROUND(
            AVG(f.no_guests)::numeric,
            2
        ) AS avg_guests_per_booking,

        -- Average length of stay
        ROUND(
            AVG(f.checkout_date - f.check_in_date)::numeric,
            2
        ) AS avg_length_of_stay_days

    FROM dim_hotels d

    JOIN fact_bookings f
        ON d.property_id = f.property_id

    GROUP BY
        d.property_id,
        d.property_name,
        d.city
)

SELECT
    property_id,
    property_name,
    city,
    total_bookings,
    completed_bookings,
    cancelled_bookings,

    -- Property-level cancellation rate
    ROUND(
        100.0 * cancelled_bookings
        / NULLIF(total_bookings, 0)::numeric,
        2
    ) AS cancellation_pct,

    gross_revenue,
    realized_revenue,

    -- Percentage of generated revenue that was realized
    ROUND(
        100.0 * realized_revenue
        / NULLIF(gross_revenue, 0)::numeric,
        2
    ) AS realization_perc,

    -- Difference between generated and realized revenue
    gross_revenue - realized_revenue AS revenue_leakage,

    avg_guests_per_booking,
    avg_length_of_stay_days

FROM property_metrics

ORDER BY realized_revenue DESC;


/*=============================================================================
5. HIGH-REVENUE PROPERTIES WITH LOW REVENUE REALIZATION
===============================================================================

Analytical Level:
    Level 3 - Diagnostic Analysis

Business Question:
    Which high-revenue properties have relatively poor
    revenue realization?

Purpose:
    Identify properties with lower revenue realization
    than the portfolio average.
=============================================================================*/

WITH property_metrics AS (

    SELECT
        d.property_id,
        d.property_name,
        d.city,

        COUNT(*) AS total_bookings,

        SUM(f.revenue_generated) AS gross_revenue,
        SUM(f.revenue_realized) AS realized_revenue,

        -- Property-level revenue realization
        ROUND(
            100.0 * SUM(f.revenue_realized)
            / NULLIF(SUM(f.revenue_generated), 0)::numeric,
            2
        ) AS realization_perc

    FROM dim_hotels d

    JOIN fact_bookings f
        ON d.property_id = f.property_id

    GROUP BY
        d.property_id,
        d.property_name,
        d.city
),

portfolio_metrics AS (

    SELECT
        ROUND(
            AVG(realization_perc),
            2
        ) AS avg_realization_perc

    FROM property_metrics
)

SELECT
    p.property_id,
    p.property_name,
    p.city,
    p.total_bookings,
    p.gross_revenue,
    p.realized_revenue,
    p.realization_perc,

    -- Difference between generated and realized revenue
    p.gross_revenue - p.realized_revenue AS revenue_leakage,

    -- Difference from portfolio average realization
    p.realization_perc - pm.avg_realization_perc
        AS vs_portfolio_avg_pct_points

FROM property_metrics p

CROSS JOIN portfolio_metrics pm

WHERE p.realization_perc < pm.avg_realization_perc

ORDER BY p.realized_revenue DESC;


/*=============================================================================
6. BOOKING PLATFORM PERFORMANCE
===============================================================================

Analytical Level:
    Level 2 - Channel / Platform Analysis

Business Question:
    How does each booking platform perform across bookings,
    cancellations, revenue, and length of stay?

Purpose:
    Compare booking platforms based on booking volume,
    cancellation behavior, revenue realization, and stay duration.
=============================================================================*/

SELECT
    booking_platform,

    -- Booking volume
    COUNT(*) AS total_bookings,

    -- Number of completed stays
    COUNT(*) FILTER (
        WHERE booking_status = 'Checked Out'
    ) AS completed_bookings,

    -- Number of cancelled bookings
    COUNT(*) FILTER (
        WHERE booking_status = 'Cancelled'
    ) AS cancelled_bookings,

    -- Cancellation rate by booking platform
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE booking_status = 'Cancelled'
        ) / NULLIF(COUNT(*), 0)::numeric,
        2
    ) AS cancellation_perc,

    -- Total realized revenue
    ROUND(
        SUM(revenue_realized)::numeric,
        2
    ) AS realized_revenue,

    -- Revenue realization by booking platform
    ROUND(
        100.0 * SUM(revenue_realized)
        / NULLIF(SUM(revenue_generated), 0),
        2
    ) AS realization_perc,

    -- Average length of stay
    ROUND(
        AVG(checkout_date - check_in_date)::numeric,
        2
    ) AS avg_length_of_stays

FROM fact_bookings

GROUP BY booking_platform

ORDER BY total_bookings DESC;


/*=============================================================================
7. CANCELLATION ANALYSIS BY BOOKING LEAD TIME
===============================================================================

Analytical Level:
    Level 3 - Booking Behavior / Cancellation Analysis

Business Question:
    How does cancellation behavior vary with booking lead time?

Purpose:
    Group bookings into lead-time ranges and compare
    cancellation and revenue realization patterns.
=============================================================================*/

WITH booking_lead_time AS (

    SELECT
        booking_id,
        booking_status,
        revenue_generated,
        revenue_realized,

        -- Number of days between booking and check-in
        check_in_date - booking_date AS lead_time_days

    FROM fact_bookings
)

SELECT
    CASE
        WHEN lead_time_days < 1 THEN 'Same Day'
        WHEN lead_time_days BETWEEN 1 AND 3 THEN '1-3 Days'
        WHEN lead_time_days BETWEEN 4 AND 7 THEN '4-7 Days'
        WHEN lead_time_days BETWEEN 8 AND 14 THEN '8-14 Days'
        WHEN lead_time_days BETWEEN 15 AND 30 THEN '15-30 Days'
        WHEN lead_time_days BETWEEN 31 AND 60 THEN '31-60 Days'
        ELSE '60+ Days'
    END AS lead_time_bucket,

    -- Booking volume
    COUNT(*) AS total_bookings,

    -- Number of cancelled bookings
    COUNT(*) FILTER (
        WHERE booking_status = 'Cancelled'
    ) AS cancelled_bookings,

    -- Cancellation rate within each lead-time bucket
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE booking_status = 'Cancelled'
        ) / NULLIF(COUNT(*), 0)::numeric,
        2
    ) AS cancellation_perc,

    -- Revenue generated by each lead-time bucket
    SUM(revenue_generated) AS gross_revenue,

    -- Revenue realized by each lead-time bucket
    SUM(revenue_realized) AS realized_revenue,

    -- Revenue realization by lead-time bucket
    ROUND(
        100.0 * SUM(revenue_realized)
        / NULLIF(SUM(revenue_generated), 0)::numeric,
        2
    ) AS realization_perc

FROM booking_lead_time

GROUP BY
    CASE
        WHEN lead_time_days < 1 THEN 'Same Day'
        WHEN lead_time_days BETWEEN 1 AND 3 THEN '1-3 Days'
        WHEN lead_time_days BETWEEN 4 AND 7 THEN '4-7 Days'
        WHEN lead_time_days BETWEEN 8 AND 14 THEN '8-14 Days'
        WHEN lead_time_days BETWEEN 15 AND 30 THEN '15-30 Days'
        WHEN lead_time_days BETWEEN 31 AND 60 THEN '31-60 Days'
        ELSE '60+ Days'
    END

ORDER BY MIN(lead_time_days);


/*=============================================================================
8. CANCELLATION ANALYSIS BY BOOKING PLATFORM AND LEAD TIME
===============================================================================

Analytical Level:
    Level 3 - Cross-Dimensional Booking Behavior Analysis

Business Question:
    How does cancellation behavior vary by booking platform
    and booking lead time?

Purpose:
    Combine booking platform and lead-time dimensions to identify
    specific combinations with different cancellation and
    revenue realization patterns.
=============================================================================*/

WITH booking_lead_time AS (

    SELECT
        booking_platform,
        booking_status,
        revenue_generated,
        revenue_realized,

        -- Number of days between booking and check-in
        check_in_date - booking_date AS lead_time_days

    FROM fact_bookings
),

bucketed_bookings AS (

    SELECT
        booking_platform,
        booking_status,
        revenue_generated,
        revenue_realized,

        -- Categorize bookings by lead time
        CASE
            WHEN lead_time_days < 1 THEN 'Same Day'
            WHEN lead_time_days BETWEEN 1 AND 3 THEN '1-3 Days'
            WHEN lead_time_days BETWEEN 4 AND 7 THEN '4-7 Days'
            WHEN lead_time_days BETWEEN 8 AND 14 THEN '8-14 Days'
            WHEN lead_time_days BETWEEN 15 AND 30 THEN '15-30 Days'
            WHEN lead_time_days BETWEEN 31 AND 60 THEN '31-60 Days'
            ELSE '60+ Days'
        END AS lead_time_bucket,

        -- Numeric ordering for lead-time buckets
        CASE
            WHEN lead_time_days < 1 THEN 1
            WHEN lead_time_days BETWEEN 1 AND 3 THEN 2
            WHEN lead_time_days BETWEEN 4 AND 7 THEN 3
            WHEN lead_time_days BETWEEN 8 AND 14 THEN 4
            WHEN lead_time_days BETWEEN 15 AND 30 THEN 5
            WHEN lead_time_days BETWEEN 31 AND 60 THEN 6
            ELSE 7
        END AS bucket_order

    FROM booking_lead_time
)

SELECT
    booking_platform,
    lead_time_bucket,

    -- Booking volume
    COUNT(*) AS total_bookings,

    -- Number of cancelled bookings
    COUNT(*) FILTER (
        WHERE booking_status = 'Cancelled'
    ) AS cancelled_bookings,

    -- Cancellation rate
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE booking_status = 'Cancelled'
        ) / NULLIF(COUNT(*), 0)::numeric,
        2
    ) AS cancellation_perc,

    -- Revenue generated
    SUM(revenue_generated) AS gross_revenue,

    -- Revenue realized
    SUM(revenue_realized) AS realized_revenue,

    -- Revenue realization
    ROUND(
        100.0 * SUM(revenue_realized)
        / NULLIF(SUM(revenue_generated), 0)::numeric,
        2
    ) AS realization_perc,

    -- Revenue leakage
    SUM(revenue_generated) - SUM(revenue_realized)
        AS revenue_leakage

FROM bucketed_bookings

GROUP BY
    booking_platform,
    lead_time_bucket,
    bucket_order

ORDER BY
    booking_platform,
    bucket_order;


/*=============================================================================
9. LENGTH OF STAY ANALYSIS
===============================================================================

Analytical Level:
    Level 3 - Stay Behavior Analysis

Business Question:
    How does length of stay relate to booking volume,
    revenue, and revenue realization?

Purpose:
    Compare booking and revenue behavior across
    different stay-duration ranges.
=============================================================================*/

WITH booking_los AS (

    SELECT
        booking_id,
        booking_status,
        revenue_generated,
        revenue_realized,

        -- Number of days between check-in and check-out
        checkout_date - check_in_date AS length_of_stay

    FROM fact_bookings
)

SELECT
    CASE
        WHEN length_of_stay BETWEEN 0 AND 1 THEN '0-1 Days'
        WHEN length_of_stay BETWEEN 2 AND 3 THEN '2-3 Days'
        WHEN length_of_stay BETWEEN 4 AND 6 THEN '4-6 Days'
        ELSE '6+ Days'
    END AS length_of_stay_bucket,

    -- Booking volume
    COUNT(*) AS total_bookings,

    -- Number of cancelled bookings
    COUNT(*) FILTER (
        WHERE booking_status = 'Cancelled'
    ) AS cancelled_bookings,

    -- Cancellation rate
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE booking_status = 'Cancelled'
        ) / NULLIF(COUNT(*), 0)::numeric,
        2
    ) AS cancellation_perc,

    -- Revenue generated
    SUM(revenue_generated) AS gross_revenue,

    -- Revenue realized
    SUM(revenue_realized) AS realized_revenue,

    -- Revenue realization
    ROUND(
        100.0 * SUM(revenue_realized)
        / NULLIF(SUM(revenue_generated), 0)::numeric,
        2
    ) AS realization_perc,

    -- Average realized revenue per booking
    ROUND(
        AVG(revenue_realized)::numeric,
        2
    ) AS avg_realized_revenue_per_booking

FROM booking_los

GROUP BY
    CASE
        WHEN length_of_stay BETWEEN 0 AND 1 THEN '0-1 Days'
        WHEN length_of_stay BETWEEN 2 AND 3 THEN '2-3 Days'
        WHEN length_of_stay BETWEEN 4 AND 6 THEN '4-6 Days'
        ELSE '6+ Days'
    END

ORDER BY MIN(length_of_stay);


/*=============================================================================
10. OCCUPANCY AND REVENUE ANALYSIS BY PROPERTY
===============================================================================

Analytical Level:
    Level 3 - Occupancy / Revenue Analysis

Business Question:
    How does room occupancy relate to realized revenue
    across properties?

Purpose:
    Compare property-level occupancy with revenue generation
    and revenue realization.
=============================================================================*/

WITH property_metrics AS (

    SELECT
        property_id,

        -- Number of bookings where guests completed their stay
        COUNT(*) FILTER (
            WHERE booking_status = 'Checked Out'
        ) AS checked_out,

        -- Total generated revenue
        SUM(revenue_generated) AS gross_revenue,

        -- Total realized revenue
        SUM(revenue_realized) AS realized_revenue

    FROM fact_bookings

    GROUP BY property_id
),

capacity_metrics AS (

    SELECT
        property_id,

        -- Total room capacity available
        SUM(capacity) AS total_capacity

    FROM fact_aggregated_bookings

    GROUP BY property_id
)

SELECT
    p.property_id,
    d.property_name,
    d.city,
    p.checked_out,
    c.total_capacity,

    -- Occupancy based on completed stays versus total capacity
    ROUND(
        100.0 * p.checked_out
        / NULLIF(c.total_capacity, 0)::numeric,
        2
    ) AS occupancy_perc,

    p.gross_revenue,
    p.realized_revenue,

    -- Revenue realization
    ROUND(
        100.0 * p.realized_revenue
        / NULLIF(p.gross_revenue, 0)::numeric,
        2
    ) AS realization_perc

FROM property_metrics p

JOIN capacity_metrics c
    ON p.property_id = c.property_id

JOIN dim_hotels d
    ON p.property_id = d.property_id

ORDER BY
    property_name,
    occupancy_perc;


/*=============================================================================
11. PROPERTY REVENUE LEAKAGE ANALYSIS
===============================================================================

Analytical Level:
    Level 3 - Revenue Leakage Analysis

Business Question:
    Which properties contribute the most to total
    revenue leakage?

Purpose:
    Quantify property-level revenue leakage and determine
    each property's contribution to total portfolio leakage.
=============================================================================*/

WITH property_leakage AS (

    SELECT
        d.property_id,
        d.property_name,
        d.city,

        COUNT(*) AS total_bookings,

        SUM(f.revenue_generated) AS gross_revenue,
        SUM(f.revenue_realized) AS realized_revenue,

        -- Difference between generated and realized revenue
        SUM(f.revenue_generated)
        - SUM(f.revenue_realized) AS revenue_leakage

    FROM fact_bookings f

    JOIN dim_hotels d
        ON d.property_id = f.property_id

    GROUP BY
        d.property_id,
        d.property_name,
        d.city
)

SELECT
    property_id,
    property_name,
    city,
    total_bookings,
    gross_revenue,
    realized_revenue,
    revenue_leakage,

    -- Revenue leakage as a percentage of gross revenue
    ROUND(
        100.0 * revenue_leakage
        / NULLIF(gross_revenue, 0)::numeric,
        2
    ) AS leakage_perc,

    -- Property's contribution to total portfolio leakage
    ROUND(
        100.0 * revenue_leakage
        / NULLIF(
            SUM(revenue_leakage) OVER (),
            0
        )::numeric,
        2
    ) AS portfolio_leakage_share_perc

FROM property_leakage

ORDER BY revenue_leakage DESC;


/*=============================================================================
12. PROPERTY + BOOKING PLATFORM REVENUE LEAKAGE
===============================================================================

Analytical Level:
    Level 3 - Cross-Dimensional Revenue Leakage Analysis

Business Question:
    Which property + booking platform combinations
    contribute the most revenue leakage?

Purpose:
    Identify combinations of properties and booking platforms
    associated with higher revenue leakage.
=============================================================================*/

WITH property_platform AS (

    SELECT
        d.property_id,
        d.property_name,
        d.city,
        f.booking_platform,

        COUNT(*) AS total_bookings,

        SUM(f.revenue_generated) AS gross_revenue,
        SUM(revenue_realized) AS realized_revenue,

        -- Difference between generated and realized revenue
        SUM(f.revenue_generated)
        - SUM(f.revenue_realized) AS revenue_leakage

    FROM fact_bookings f

    JOIN dim_hotels d
        ON f.property_id = d.property_id

    GROUP BY
        d.property_id,
        d.property_name,
        d.city,
        f.booking_platform
)

SELECT
    property_id,
    property_name,
    city,
    booking_platform,
    total_bookings,
    gross_revenue,
    realized_revenue,
    revenue_leakage,

    -- Leakage as a percentage of gross revenue
    ROUND(
        100.0 * revenue_leakage
        / NULLIF(gross_revenue, 0)::numeric,
        2
    ) AS leakage_perc,

    -- Platform's share of the property's total leakage
    ROUND(
        100.0 * revenue_leakage
        / NULLIF(
            SUM(revenue_leakage) OVER (
                PARTITION BY property_id
            ),
            0
        )::numeric,
        2
    ) AS property_leakage_share_perc

FROM property_platform

ORDER BY
    property_id,
    revenue_leakage DESC;


/*=============================================================================
13. PROPERTY PERFORMANCE SEGMENTATION
===============================================================================

Analytical Level:
    Level 3 - Property Segmentation

Business Question:
    How do properties compare across realized revenue
    and revenue realization?

Purpose:
    Segment properties using portfolio-average realized revenue
    and revenue realization as benchmarks.
=============================================================================*/

WITH property_metrics AS (

    SELECT
        d.property_id,
        d.property_name,
        d.city,

        COUNT(*) AS total_bookings,

        SUM(f.revenue_generated) AS gross_revenue,
        SUM(f.revenue_realized) AS realized_revenue,

        -- Property-level revenue realization
        ROUND(
            100.0 * SUM(f.revenue_realized)
            / NULLIF(SUM(f.revenue_generated), 0)::numeric,
            2
        ) AS realization_perc

    FROM fact_bookings f

    JOIN dim_hotels d
        ON f.property_id = d.property_id

    GROUP BY
        d.property_id,
        d.property_name,
        d.city
),

portfolio_benchmark AS (

    SELECT
        AVG(realized_revenue) AS avg_realized_revenue,
        AVG(realization_perc) AS avg_realization_perc

    FROM property_metrics
)

SELECT
    p.property_id,
    p.property_name,
    p.city,
    p.total_bookings,
    p.gross_revenue,
    p.realized_revenue,
    p.realization_perc,

    -- Segment properties using portfolio-average benchmarks
    CASE
        WHEN p.realized_revenue >= b.avg_realized_revenue
             AND p.realization_perc >= b.avg_realization_perc
            THEN 'High Revenue / High Realization'

        WHEN p.realized_revenue >= b.avg_realized_revenue
             AND p.realization_perc < b.avg_realization_perc
            THEN 'High Revenue / Low Realization'

        WHEN p.realized_revenue < b.avg_realized_revenue
             AND p.realization_perc >= b.avg_realization_perc
            THEN 'Low Revenue / High Realization'

        ELSE 'Low Revenue / Low Realization'
    END AS performance_segment

FROM property_metrics p

CROSS JOIN portfolio_benchmark b

ORDER BY 8;


/*=============================================================================
14. REVENUE CONCENTRATION ACROSS PROPERTIES
===============================================================================

Analytical Level:
    Level 3 - Revenue Concentration Analysis

Business Question:
    How concentrated is realized revenue across properties?

Purpose:
    Rank properties by realized revenue and measure both
    individual and cumulative contribution to portfolio revenue.
=============================================================================*/

WITH property_revenue AS (

    SELECT
        d.property_id,
        d.property_name,
        d.city,

        SUM(f.revenue_realized) AS realized_revenue

    FROM fact_bookings f

    JOIN dim_hotels d
        ON f.property_id = d.property_id

    GROUP BY
        d.property_id,
        d.property_name,
        d.city
)

SELECT
    property_id,
    property_name,
    city,
    realized_revenue,

    -- Rank properties by realized revenue
    RANK() OVER (
        ORDER BY realized_revenue DESC
    ) AS revenue_rank,

    -- Individual property's contribution to total revenue
    ROUND(
        100.0 * realized_revenue
        / NULLIF(
            SUM(realized_revenue) OVER (),
            0
        )::numeric,
        2
    ) AS revenue_contribution_perc,

    -- Cumulative contribution to total portfolio revenue
    ROUND(
        100.0 * SUM(realized_revenue) OVER (
            ORDER BY realized_revenue DESC
        )
        / NULLIF(
            SUM(realized_revenue) OVER (),
            0
        )::numeric,
        2
    ) AS cumulative_revenue_perc

FROM property_revenue

ORDER BY revenue_rank;
```
