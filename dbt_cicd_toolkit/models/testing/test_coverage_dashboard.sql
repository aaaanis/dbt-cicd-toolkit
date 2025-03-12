{{
    config(
        materialized='table',
        tags=['dbt_cicd_toolkit', 'test_coverage']
    )
}}

/*
    Test Coverage Dashboard Model
    
    This model provides analytics on test coverage across your dbt project.
    It helps identify models that need more testing and track test results over time.
*/

WITH 

-- Get all models in the project
models AS (
    SELECT
        model_id,
        model_name,
        model_schema,
        model_path
    FROM {{ ref('dbt_models') }}
),

-- Get all tests in the project
tests AS (
    SELECT
        test_id,
        test_name,
        test_type,
        model_id,
        column_name,
        status
    FROM {{ ref('dbt_tests') }}
),

-- Calculate test coverage metrics
model_test_coverage AS (
    SELECT
        m.model_id,
        m.model_name,
        m.model_schema,
        m.model_path,
        COUNT(DISTINCT t.test_id) AS total_tests,
        COUNT(DISTINCT CASE WHEN t.test_type = 'schema' THEN t.test_id END) AS schema_tests,
        COUNT(DISTINCT CASE WHEN t.test_type = 'data' THEN t.test_id END) AS data_tests,
        COUNT(DISTINCT CASE WHEN t.status = 'pass' THEN t.test_id END) AS passed_tests,
        COUNT(DISTINCT CASE WHEN t.status = 'fail' THEN t.test_id END) AS failed_tests,
        COUNT(DISTINCT CASE WHEN t.column_name IS NOT NULL THEN t.column_name END) AS columns_tested,
        CASE 
            WHEN COUNT(DISTINCT t.test_id) = 0 THEN 'No tests'
            WHEN COUNT(DISTINCT CASE WHEN t.status = 'pass' THEN t.test_id END) = COUNT(DISTINCT t.test_id) THEN 'All passing'
            WHEN COUNT(DISTINCT CASE WHEN t.status = 'fail' THEN t.test_id END) > 0 THEN 'Has failures'
            ELSE 'Unknown'
        END AS test_status
    FROM models m
    LEFT JOIN tests t ON m.model_id = t.model_id
    GROUP BY 1, 2, 3, 4
),

-- Calculate project-level metrics
project_metrics AS (
    SELECT
        COUNT(DISTINCT model_id) AS total_models,
        COUNT(DISTINCT CASE WHEN total_tests > 0 THEN model_id END) AS models_with_tests,
        ROUND(100.0 * COUNT(DISTINCT CASE WHEN total_tests > 0 THEN model_id END) / 
              NULLIF(COUNT(DISTINCT model_id), 0), 2) AS model_coverage_pct,
        SUM(total_tests) AS total_tests,
        SUM(schema_tests) AS schema_tests,
        SUM(data_tests) AS data_tests,
        SUM(passed_tests) AS passed_tests,
        SUM(failed_tests) AS failed_tests,
        ROUND(100.0 * SUM(passed_tests) / NULLIF(SUM(total_tests), 0), 2) AS test_pass_rate
    FROM model_test_coverage
)

-- Combine model-level and project-level metrics
SELECT
    m.model_id,
    m.model_name,
    m.model_schema,
    m.model_path,
    m.total_tests,
    m.schema_tests,
    m.data_tests,
    m.passed_tests,
    m.failed_tests,
    m.columns_tested,
    m.test_status,
    p.total_models,
    p.models_with_tests,
    p.model_coverage_pct,
    p.total_tests AS project_total_tests,
    p.schema_tests AS project_schema_tests,
    p.data_tests AS project_data_tests,
    p.passed_tests AS project_passed_tests,
    p.failed_tests AS project_failed_tests,
    p.test_pass_rate AS project_test_pass_rate
FROM model_test_coverage m
CROSS JOIN project_metrics p 