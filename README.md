# dbt-ci-cd-toolkit

A comprehensive toolkit for implementing advanced CI/CD patterns with dbt.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

The `dbt-ci-cd-toolkit` is a collection of utilities that enhance dbt's CI/CD capabilities, particularly focused on:

1. **Automated Impact Analysis** - Identify the downstream impact of model changes to ensure targeted testing
2. **Selective Model Testing** - Run tests only on models affected by changes to speed up CI pipelines
3. **Environment Promotion Management** - Safely promote models across environments with proper validation
4. **Pipeline Visualization** - Generate visual representations of your CI/CD pipeline
5. **Testing Dashboard** - Monitor test coverage and results across your dbt project
6. **Version Management** - Track and manage different versions of your models across environments

## Installation

Add the following to your `packages.yml` file:

```yaml
packages:
  - package: username/dbt_cicd_toolkit
    version: [">=0.1.0", "<0.2.0"]
```

Then run:

```
dbt deps
```

## Features

### Automated Impact Analysis

Identify which models are impacted by changes to source files:

```
dbt run-operation get_impacted_models --args '{source_files: ["models/staging/customers.sql", "models/staging/orders.sql"]}'
```

### Selective Model Testing

Run tests only on models impacted by changes:

```
dbt run-operation run_selective_tests --args '{changed_files: ["models/staging/customers.sql"], test_level: "comprehensive"}'
```

Test levels available:
- `minimal`: Run only the most critical tests
- `standard`: Run commonly useful tests
- `comprehensive`: Run all available tests

### Environment Promotion Management

Manage the promotion of models across environments:

```
dbt run-operation promote_to_environment --args '{target_environment: "production", models: ["customers", "orders"]}'
```

### Pipeline Visualization

Generate visual representations of your CI/CD pipeline:

```
dbt run-operation generate_pipeline_graph --args '{model_selection: ["customers", "orders"], output_format: "mermaid"}'
```

### Testing Dashboard

Monitor test coverage and results:

```
dbt run --select test_coverage_dashboard
```

### Version Management

Track and manage different versions of your models:

```
dbt run-operation register_version --args '{model_name: "customers", version: "1.2.0", description: "Added customer segment"}'

dbt run-operation deploy_version --args '{model_name: "customers", version: "1.2.0", environment: "staging"}'
```

## Documentation

For detailed documentation, see the [docs](./dbt_cicd_toolkit/docs) directory:

- [Impact Analysis](./dbt_cicd_toolkit/docs/impact_analysis.md)
- [Selective Testing](./dbt_cicd_toolkit/docs/selective_testing.md)
- [Environment Promotion](./dbt_cicd_toolkit/docs/environment_promotion.md)
- [Pipeline Visualization](./dbt_cicd_toolkit/docs/visualization.md)
- [Testing Dashboard](./dbt_cicd_toolkit/docs/testing_dashboard.md)
- [Version Management](./dbt_cicd_toolkit/docs/version_management.md)
- [GitHub Actions Workflow](./dbt_cicd_toolkit/docs/github_actions_workflow.yml)

## Configuration

Configure the package in your `dbt_project.yml`:

```yaml
vars:
  dbt_cicd_toolkit:
    enable_impact_analysis: true
    enable_selective_testing: true
    enable_environment_promotion: true
    enable_pipeline_visualization: true
    enable_testing_dashboard: true
    enable_version_management: true
    default_test_level: 'standard'  # Options: 'minimal', 'standard', 'comprehensive'
```

## License

[MIT](./dbt_cicd_toolkit/LICENSE) 