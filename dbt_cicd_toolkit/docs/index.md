# dbt-ci-cd-toolkit Documentation

Welcome to the documentation for dbt-ci-cd-toolkit, a comprehensive package that enhances dbt's CI/CD capabilities for data engineering teams.

## Features

- [**Impact Analysis**](./impact_analysis.md) - Identify the downstream impact of model changes to ensure targeted testing
- [**Selective Testing**](./selective_testing.md) - Run tests only on models affected by changes to speed up CI pipelines
- [**Environment Promotion**](./environment_promotion.md) - Safely promote models across environments with proper validation
- [**Pipeline Visualization**](./visualization.md) - Generate visual representations of your CI/CD pipeline
- [**Testing Dashboard**](./testing_dashboard.md) - Monitor test coverage and results across your dbt project
- [**Version Management**](./version_management.md) - Track and manage different versions of your models across environments

## Standard Workflows

### Standard CI/CD Pipeline

1. **Push Changes** - Developer pushes changes to a feature branch
2. **Impact Analysis** - Automatically analyze which models are affected by the changes
3. **Selective Testing** - Run tests only on affected models and their downstream dependencies
4. **Pipeline Visualization** - Generate a visualization of the CI/CD pipeline for code review
5. **Pull Request** - Approve and merge changes after successful testing
6. **Stage Promotion** - Promote models to staging environment after merge to main branch
7. **Production Promotion** - Promote models to production after validation in staging

### Version-Controlled Releases

1. **Register Version** - Register a new version of a model with semantic versioning
2. **Deploy to Development** - Deploy the new version to development environment
3. **Testing** - Run comprehensive tests on the new version
4. **Deploy to Staging** - Deploy the version to staging after successful tests
5. **Validation** - Perform additional validation in staging environment
6. **Deploy to Production** - Deploy the version to production with version tracking

## Integration Reference

Check out the [GitHub Actions workflow](./github_actions_workflow.yml) for a complete CI/CD pipeline implementation.

## Getting Started

To get started, see the [installation instructions](../README.md#installation) and configuration guide in the main README. 