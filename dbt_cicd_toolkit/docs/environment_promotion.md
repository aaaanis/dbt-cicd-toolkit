# Environment Promotion Management

Environment promotion management helps you safely promote dbt models across environments (development, staging, production) with validation and tracking.

## Core Functions

### `promote_to_environment`

Promotes models to a target environment:

```sql
{{ dbt_cicd_toolkit.promote_to_environment(
    target_environment='production',
    models=['customers', 'orders'],
    require_tests=true,
    update_state=true
) }}
```

#### Parameters:

- `target_environment`: The target environment to promote to
- `models`: List of model names to promote
- `require_tests`: Whether to require tests to pass before promotion (default: true)
- `update_state`: Whether to update the promotion state (default: true)

#### Returns:

A dictionary with the promotion plan.

### `get_promotion_status`

Gets the promotion status of models in an environment:

```sql
{{ dbt_cicd_toolkit.get_promotion_status(
    environment='production',
    models=['customers', 'orders']
) }}
```

#### Parameters:

- `environment`: The environment to check (default: all environments)
- `models`: List of model names to check (default: all models)

#### Returns:

A dictionary with the promotion status of each model in each environment.

## Command Line Usage

The package includes a Python script for promoting models from the command line:

```bash
python dbt_cicd_toolkit/scripts/promote_models.py \
  --target-environment production \
  --models customers,orders \
  --dbt-project-dir /path/to/dbt/project \
  --output-format markdown
```

Options:

- `--skip-tests`: Skip test validation before promotion
- `--dry-run`: Validate but do not update promotion state
- `--output-format`: Format for output (text, json, markdown)

## Promotion Workflow

A typical promotion workflow follows these steps:

1. **Development**: Changes are made in a development environment
2. **Testing**: Tests are run on the changes (can be selective)
3. **Staging Promotion**: Changes are promoted to staging with test validation
4. **Staging Validation**: Additional validation in staging environment
5. **Production Promotion**: Changes are promoted to production with test validation

## Integration with CI/CD

### GitHub Actions Workflow for Production Promotion

```yaml
promote-to-production:
  needs: [validate-staging]
  runs-on: ubuntu-latest
  if: github.ref == 'refs/heads/main'
  environment: production
  steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Install dependencies
      run: |
        pip install dbt-core dbt-postgres
        pip install -e .

    - name: Get models to promote
      run: |
        # Get models that are ready for production
        MODELS=$(dbt run-operation get_staging_validated_models --args '{"min_days_in_staging": 1}')
        echo "models_to_promote=$MODELS" >> $GITHUB_ENV

    - name: Promote to production
      if: env.models_to_promote != ''
      run: |
        python dbt_cicd_toolkit/scripts/promote_models.py \
          --target-environment production \
          --models "${{ env.models_to_promote }}" \
          --output-format markdown
```

## Promotion Status Tracking

The package tracks promotion history in state files:

- Located in `target/promotion_states/<environment>.json`
- Contains history of all promotions
- Tracks timestamps and success/failure status
- Keeps the last 10 promotions for each environment

## Best Practices

1. **Always run tests before promotion** to ensure model quality
2. **Use staging environment** as an intermediate step
3. **Implement additional validation** in staging before promoting to production
4. **Track promotion history** to understand when models were promoted
5. **Use dry runs** to validate promotion plans without updating state
6. **Automate routine promotions** but require approval for critical ones
7. **Document promotion decisions** in commit messages or PR descriptions 