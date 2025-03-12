{{
    config(
        materialized='table',
        tags=['dbt_cicd_toolkit', 'reference']
    )
}}

-- This is a reference model to showcase the package features

WITH reference_data AS (
    SELECT 
        1 AS id,
        'Customer A' AS name,
        'Retail' AS segment,
        100 AS value,
        '2023-01-01' AS created_date
    
    UNION ALL
    
    SELECT 
        2 AS id,
        'Customer B' AS name,
        'Wholesale' AS segment,
        250 AS value,
        '2023-01-15' AS created_date
    
    UNION ALL
    
    SELECT 
        3 AS id,
        'Customer C' AS name,
        'Retail' AS segment,
        75 AS value,
        '2023-02-01' AS created_date
)

SELECT
    id,
    name,
    segment,
    value,
    created_date,
    -- Added derived columns to demonstrate transformations
    value * 1.1 AS projected_value,
    CASE
        WHEN segment = 'Retail' THEN 'B2C'
        WHEN segment = 'Wholesale' THEN 'B2B'
        ELSE 'Other'
    END AS business_type
FROM reference_data 