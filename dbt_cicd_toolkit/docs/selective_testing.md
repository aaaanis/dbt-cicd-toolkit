# Selective Testing

Selective testing allows you to run tests only on models that are affected by changes to your dbt project. This can significantly speed up your CI/CD pipelines and provide faster feedback on changes.

## Core Functions

### `run_selective_tests`

Runs tests only on models that are affected by changes:

```sql
{{ dbt_cicd_toolkit.run_selective_tests(
    changed_files=["models/staging/customers.sql"],
    test_level='standard',
    include_upstream=false,
    include_downstream=true
) }}
```

#### Parameters:

- `changed_files`: List of files that have been changed
- `test_level`: Level of testing to perform (options: 'minimal', 'standard', 'comprehensive', default: 'standard')
- `include_upstream`: Whether to include upstream models in testing (default: false)
- `include_downstream`: Whether to include downstream models in testing (default: true)

#### Returns:

A list of test node IDs to run.

## Test Levels

The package supports three test levels:

1. **Minimal**: Only runs critical tests (not_null, unique, primary_key, accepted_values)
2. **Standard**: Runs all tests for impacted models
3. **Comprehensive**: Runs all tests in the project

## Command Line Usage

The package includes a Python script for running selective tests from the command line:

```bash
python dbt_cicd_toolkit/scripts/run_selective_tests.py \
  --changed-files models/staging/customers.sql,models/staging/orders.sql \
  --test-level standard \
  --include-downstream \
  --dbt-project-dir /path/to/dbt/project
```

Alternatively, you can provide a file with the list of changed files:

```bash
python dbt_cicd_toolkit/scripts/run_selective_tests.py \
  --changed-files-file changed_files.txt \
  --test-level standard
```

## Integration with CI/CD

### GitHub Actions Workflow

Here's how to integrate selective testing into a GitHub Actions workflow:

```yaml
- name: Get changed files
  id: changed-files
  uses: tj-actions/changed-files@v35
  with:
    separator: ","

- name: Filter dbt model files
  id: filter
  run: |
    CHANGED_FILES="${{ steps.changed-files.outputs.all_changed_files }}"
    DBT_MODEL_FILES=$(echo $CHANGED_FILES | tr ',' '\n' | grep -E '^models/.*\.sql$' | tr '\n' ',' | sed 's/,$//')
    echo "dbt_model_files=$DBT_MODEL_FILES" >> $GITHUB_OUTPUT

- name: Run selective tests
  if: steps.filter.outputs.dbt_model_files != ''
  run: |
    python dbt_cicd_toolkit/scripts/run_selective_tests.py \
      --changed-files ${{ steps.filter.outputs.dbt_model_files }} \
      --test-level standard
```

### GitLab CI Implementation

For GitLab CI, you can use:

```yaml
selective-tests:
  script:
    - CHANGED_FILES=$(git diff --name-only $CI_MERGE_REQUEST_TARGET_BRANCH_NAME...HEAD | grep -E '^models/.*\.sql$' | tr '\n' ',' | sed 's/,$//')
    - python dbt_cicd_toolkit/scripts/run_selective_tests.py --changed-files $CHANGED_FILES --test-level standard
  only:
    - merge_requests
```

## Best Practices

1. **Start with standard test level** and adjust based on project needs
2. **Include downstream models** to catch cascading issues
3. **Consider including upstream models** for critical changes
4. **Use comprehensive testing** for major releases or changes to core models
5. **Combine with impact analysis** to understand the scope of testing
6. **Document test level decisions** in commit messages or PR descriptions 