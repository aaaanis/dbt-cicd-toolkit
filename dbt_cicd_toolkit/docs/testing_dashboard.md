# Testing Dashboard

The testing dashboard provides analytics on test coverage and results across your dbt project, helping you identify areas that need more testing and track test quality over time.

## Core Models

### `test_coverage_dashboard`

This model provides analytics on test coverage across your dbt project:

```sql
SELECT * FROM {{ ref('test_coverage_dashboard') }}
```

#### Columns:

- **Model Details**:
  - `model_id`: Unique identifier for the model
  - `model_name`: Name of the model
  - `model_schema`: Schema where the model is defined
  - `model_path`: File path to the model
  
- **Test Metrics**:
  - `total_tests`: Total number of tests for the model
  - `schema_tests`: Number of schema tests
  - `data_tests`: Number of data tests
  - `passed_tests`: Number of tests that pass
  - `failed_tests`: Number of tests that fail
  - `columns_tested`: Number of columns that have tests
  - `test_status`: Summary status (No tests, All passing, Has failures)
  
- **Project Metrics**:
  - `total_models`: Total number of models in the project
  - `models_with_tests`: Number of models that have tests
  - `model_coverage_pct`: Percentage of models with tests
  - `project_total_tests`: Total number of tests in the project
  - `project_test_pass_rate`: Percentage of tests that pass

### Supporting Models

The dashboard is supported by these models:

- `dbt_models`: Information about all models in the project
- `dbt_tests`: Information about all tests in the project

## Usage

### Running the Dashboard

```bash
# Build the test coverage dashboard
dbt run --select test_coverage_dashboard

# Materialize as a table for better performance
dbt run --select test_coverage_dashboard --vars '{"test_coverage_dashboard_materialized": "table"}'
```

### Querying the Dashboard

#### Identifying Models Without Tests

```sql
SELECT
  model_name,
  model_path
FROM {{ ref('test_coverage_dashboard') }}
WHERE total_tests = 0
ORDER BY model_name
```

#### Finding Models with Failing Tests

```sql
SELECT
  model_name,
  failed_tests,
  total_tests,
  ROUND(100.0 * failed_tests / NULLIF(total_tests, 0), 2) AS failure_rate
FROM {{ ref('test_coverage_dashboard') }}
WHERE failed_tests > 0
ORDER BY failure_rate DESC
```

#### Test Coverage Report

```sql
SELECT
  model_schema,
  COUNT(*) AS models,
  SUM(CASE WHEN total_tests > 0 THEN 1 ELSE 0 END) AS models_with_tests,
  ROUND(100.0 * SUM(CASE WHEN total_tests > 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS coverage_pct,
  SUM(total_tests) AS total_tests,
  SUM(passed_tests) AS passed_tests,
  SUM(failed_tests) AS failed_tests,
  ROUND(100.0 * SUM(passed_tests) / NULLIF(SUM(total_tests), 0), 2) AS pass_rate
FROM {{ ref('test_coverage_dashboard') }}
GROUP BY model_schema
ORDER BY models DESC
```

## Integration with CI/CD

### Adding Test Coverage Goals

Set test coverage goals in your dbt project:

```yaml
# dbt_project.yml
vars:
  test_coverage_goals:
    model_coverage_pct: 80.0  # Aim for 80% of models to have tests
    test_pass_rate: 95.0      # Aim for 95% test pass rate
```

### CI/CD Pipeline Implementation

```yaml
- name: Check test coverage
  run: |
    # Run test coverage dashboard
    dbt run --select test_coverage_dashboard
    
    # Extract metrics and compare to goals
    coverage=$(dbt run-operation extract_test_coverage --args '{"metric": "model_coverage_pct"}')
    pass_rate=$(dbt run-operation extract_test_coverage --args '{"metric": "test_pass_rate"}')
    
    echo "Model coverage: $coverage%"
    echo "Test pass rate: $pass_rate%"
    
    # Fail if below goals
    if (( $(echo "$coverage < 80.0" | bc -l) )); then
      echo "Model coverage is below goal of 80%"
      exit 1
    fi
    
    if (( $(echo "$pass_rate < 95.0" | bc -l) )); then
      echo "Test pass rate is below goal of 95%"
      exit 1
    fi
```

## Best Practices

1. **Include the dashboard in your project** to track test coverage over time
2. **Set coverage goals** based on the criticality of your models
3. **Focus on high-value models first** when improving test coverage
4. **Add tests incrementally** as part of normal development workflow
5. **Use the dashboard in code reviews** to ensure test coverage doesn't decrease
6. **Monitor trends** in test coverage and pass rates over time 