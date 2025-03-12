# Version Management

The version management functionality helps you track and manage different versions of your models across environments, enabling controlled rollouts and versioning of your data models.

## Core Functions

### `register_version`

Registers a new version of a model:

```sql
{{ dbt_cicd_toolkit.register_version(
    model_name='customers',
    version='1.2.0',
    description='Added customer segment field',
    is_breaking=false
) }}
```

#### Parameters:

- `model_name`: Name of the model to version
- `version`: Version string (recommend semantic versioning)
- `description`: Optional description of the changes in this version
- `is_breaking`: Whether this version contains breaking changes (default: false)

#### Returns:

A version entry object with metadata about the registered version.

### `get_version_history`

Gets the version history of a model:

```sql
{{ dbt_cicd_toolkit.get_version_history(
    model_name='customers',
    environment='production'
) }}
```

#### Parameters:

- `model_name`: Name of the model to get history for
- `environment`: Optional environment to filter versions by

#### Returns:

A dictionary with the version history of the model.

### `deploy_version`

Deploys a specific version of a model to an environment:

```sql
{{ dbt_cicd_toolkit.deploy_version(
    model_name='customers',
    version='1.2.0',
    environment='staging',
    require_tests=true
) }}
```

#### Parameters:

- `model_name`: Name of the model to deploy
- `version`: Version to deploy
- `environment`: Environment to deploy to
- `require_tests`: Whether to require tests to pass before deployment (default: true)

#### Returns:

A version entry object with metadata about the deployed version.

## Version History Structure

Version history is stored in JSON files in the `target/versions/` directory:

```json
{
  "model": "customers",
  "versions": [
    {
      "version": "1.2.0",
      "timestamp": "2023-06-15 10:30:00",
      "description": "Added customer segment field",
      "is_breaking": false,
      "status": "deployed",
      "last_deployed": "2023-06-15 14:45:00",
      "environments": ["development", "staging"],
      "deployments": [
        {
          "environment": "development",
          "timestamp": "2023-06-15 11:30:00",
          "status": "success"
        },
        {
          "environment": "staging",
          "timestamp": "2023-06-15 14:45:00",
          "status": "success"
        }
      ]
    },
    {
      "version": "1.1.0",
      "timestamp": "2023-06-01 09:15:00",
      "description": "Added email validation",
      "is_breaking": false,
      "status": "deployed",
      "last_deployed": "2023-06-01 16:20:00",
      "environments": ["development", "staging", "production"],
      "deployments": [
        {
          "environment": "development",
          "timestamp": "2023-06-01 10:00:00",
          "status": "success"
        },
        {
          "environment": "staging",
          "timestamp": "2023-06-01 14:30:00",
          "status": "success"
        },
        {
          "environment": "production",
          "timestamp": "2023-06-01 16:20:00",
          "status": "success"
        }
      ]
    }
  ]
}
```

## Usage in CI/CD Pipelines

### Automatic Version Registration

Register a new version when changes are made:

```yaml
- name: Register new version
  run: |
    # Get current version and increment patch
    current_version=$(dbt run-operation get_latest_version --args '{"model_name": "customers"}')
    new_version=$(bump_version $current_version patch)
    
    # Register new version
    dbt run-operation register_version \
      --args '{"model_name": "customers", "version": "'$new_version'", "description": "Updated in CI"}'
```

### Version Deployment

Deploy versions through environments:

```yaml
- name: Deploy to staging
  if: github.ref == 'refs/heads/main'
  run: |
    # Get latest version
    latest_version=$(dbt run-operation get_latest_version --args '{"model_name": "customers"}')
    
    # Deploy to staging
    dbt run-operation deploy_version \
      --args '{"model_name": "customers", "version": "'$latest_version'", "environment": "staging"}'
```

### Breaking Change Detection

Detect and handle breaking changes:

```yaml
- name: Check for breaking changes
  run: |
    # Check if version is marked as breaking
    is_breaking=$(dbt run-operation check_breaking_version \
      --args '{"model_name": "customers", "version": "'$version'"}')
    
    if [ "$is_breaking" = "true" ]; then
      echo "This version contains breaking changes. Requires manual approval."
      exit 1
    fi
```

## Best Practices

1. **Use semantic versioning** (MAJOR.MINOR.PATCH) for your models
2. **Mark breaking changes** with `is_breaking=true`
3. **Include descriptive messages** when registering versions
4. **Test thoroughly** before deploying to higher environments
5. **Automate version registration** in your CI/CD pipeline
6. **Maintain version history** for auditing and rollbacks
7. **Consider requiring approvals** for deploying breaking changes 