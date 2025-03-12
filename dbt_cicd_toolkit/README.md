# dbt-ci-cd-toolkit

A comprehensive toolkit for implementing advanced CI/CD patterns with dbt.

[![PyPI](https://img.shields.io/pypi/v/dbt-cicd-toolkit.svg)](https://pypi.org/project/dbt-cicd-toolkit/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

The `dbt-ci-cd-toolkit` is a collection of utilities that enhance dbt's CI/CD capabilities, particularly focused on:

1. **Automated Impact Analysis** - Identify the downstream impact of model changes to ensure targeted testing
2. **Selective Model Testing** - Run tests only on models affected by changes to speed up CI pipelines
3. **Environment Promotion Management** - Safely promote models across environments with proper validation

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

## Documentation

For detailed documentation, see the [docs](./docs) directory.

## Configuration

Configure the package in your `dbt_project.yml`:

```yaml
vars:
  dbt_cicd_toolkit:
    enable_impact_analysis: true
    enable_selective_testing: true
    enable_environment_promotion: true
    default_test_level: 'standard'  # Options: 'minimal', 'standard', 'comprehensive'
```

## License

[MIT](LICENSE) 