# Impact Analysis

The impact analysis functionality helps you understand the downstream effects of changes to your dbt models. This is crucial for ensuring that changes don't have unintended consequences and for developing targeted testing strategies.

## Core Functions

### `get_impacted_models`

Identifies which models are impacted by changes to source files:

```sql
{{ dbt_cicd_toolkit.get_impacted_models(
    source_files=["models/staging/customers.sql"],
    include_sources=true,
    include_downstream=true,
    exclude_current=false
) }}
```

#### Parameters:

- `source_files`: List of files that have been changed
- `include_sources`: Whether to include source definitions in the analysis (default: true)
- `include_downstream`: Whether to include downstream models (default: true)
- `exclude_current`: Whether to exclude the current models in the output (default: false)

#### Returns:

A list of model names that are impacted by the changes.

### `visualize_impact`

Generates a visualization of the impact of changes:

```sql
{{ dbt_cicd_toolkit.visualize_impact(
    source_files=["models/staging/customers.sql"],
    output_format='markdown'
) }}
```

#### Parameters:

- `source_files`: List of files that have been changed
- `output_format`: Format for the output (options: 'text', 'json', 'markdown', default: 'text')

#### Returns:

A formatted visualization of the impact of changes.

## Usage in CI/CD Pipelines

### Automated PR Comments

Use impact analysis in GitHub Actions to automatically comment on PRs with the impact of changes:

```yaml
- name: Generate impact analysis
  run: |
    # Run the dbt macro to get impact analysis
    dbt run-operation visualize_impact \
      --args '{"source_files": ["models/staging/customers.sql"], "output_format": "markdown"}'
    
    # Save output to a file
    cat logs/dbt.log | grep -A 100 "# Impact Analysis Results" > impact_analysis.md

- name: Comment on PR
  uses: actions/github-script@v6
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    script: |
      const fs = require('fs');
      const impactReport = fs.readFileSync('impact_analysis.md', 'utf8');
      
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: `## Impact Analysis\n\n${impactReport}`
      });
```

### Integration with Selective Testing

Use impact analysis to determine which tests to run:

```python
# Get impacted models
impacted_models = run_dbt_command('run-operation', [
    'get_impacted_models',
    '--args', '{"source_files": ["models/staging/customers.sql"]}'
])

# Run tests only for impacted models
run_dbt_command('test', ['--models', '+'.join(impacted_models)])
```

## Best Practices

1. **Always run impact analysis on PRs** to understand the scope of changes
2. **Include impact analysis in commit messages** to document the intended and actual impact
3. **Use impact analysis for selective testing** to speed up CI/CD pipelines
4. **Consider the impact before making changes** to critical models
5. **Visualize the impact** to communicate changes to stakeholders 