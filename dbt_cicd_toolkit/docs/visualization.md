# Pipeline Visualization

The pipeline visualization functionality helps you understand the flow of your models through the CI/CD pipeline, including dependencies and environment promotions.

## Core Functions

### `generate_pipeline_graph`

Generates a visual representation of the CI/CD pipeline for models:

```sql
{{ dbt_cicd_toolkit.generate_pipeline_graph(
    model_selection=['customers', 'orders'],
    include_environments=true,
    output_format='mermaid'
) }}
```

#### Parameters:

- `model_selection`: List of models to include in the graph (default: all models)
- `include_environments`: Whether to include environment promotions in the graph (default: true)
- `output_format`: Format for the output (options: 'mermaid', 'dot', 'json', default: 'mermaid')

#### Returns:

A formatted graph representation of the pipeline.

## Output Formats

### Mermaid

Mermaid is a markdown-based diagramming language that can be embedded in documentation and renders in GitHub:

```
graph TD
    customers[customers]
    orders[orders]
    customers --> orders
    orders --> staging_orders:::promoted
    staging_orders(staging)
    classDef promoted fill:#afa,stroke:#5a5,stroke-width:2px
```

### DOT (Graphviz)

DOT format can be used with Graphviz to generate visual diagrams:

```
digraph CI_CD_Pipeline {
    rankdir=TB;
    node [shape=box, style=filled, fillcolor=lightblue];
    "customers" [label="customers"];
    "orders" [label="orders"];
    "customers" -> "orders";
    "staging_orders" [label="staging", shape=ellipse, fillcolor=lightgreen];
    "orders" -> "staging_orders";
}
```

### JSON

JSON format for programmatic consumption:

```json
{
  "nodes": [
    {"id": "customers", "label": "customers", "type": "model"},
    {"id": "orders", "label": "orders", "type": "model"},
    {"id": "staging_orders", "label": "staging", "type": "environment", "promoted": true, "last_promotion": "2023-06-15 10:30:00"}
  ],
  "edges": [
    {"source": "customers", "target": "orders", "type": "dependency"},
    {"source": "orders", "target": "staging_orders", "type": "promotion"}
  ]
}
```

## Usage in CI/CD Pipelines

### Generating Documentation

Generate pipeline visualizations for documentation:

```bash
# Generate Mermaid diagram
dbt run-operation generate_pipeline_graph \
  --args '{"output_format": "mermaid"}' \
  > pipeline_diagram.md

# Generate Graphviz DOT file
dbt run-operation generate_pipeline_graph \
  --args '{"output_format": "dot"}' \
  > pipeline_diagram.dot

# Generate SVG using Graphviz
dot -Tsvg pipeline_diagram.dot > pipeline_diagram.svg
```

### GitHub Actions Integration

Include pipeline visualizations in pull request comments:

```yaml
- name: Generate pipeline graph
  run: |
    dbt run-operation generate_pipeline_graph \
      --args '{"model_selection": ["customers", "orders"], "output_format": "mermaid"}' \
      > pipeline_graph.md

- name: Comment on PR with pipeline graph
  uses: actions/github-script@v6
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    script: |
      const fs = require('fs');
      const pipelineGraph = fs.readFileSync('pipeline_graph.md', 'utf8');
      
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: `## CI/CD Pipeline Graph\n\n\`\`\`mermaid\n${pipelineGraph}\n\`\`\``
      });
```

## Best Practices

1. **Include environment information** to understand what's deployed where
2. **Filter model selection** for large projects to focus on relevant models
3. **Use mermaid format** for GitHub and documentation
4. **Use JSON format** for programmatic consumption
5. **Generate pipeline graphs automatically** as part of CI/CD processes
6. **Include pipeline graphs in pull requests** to visualize changes 