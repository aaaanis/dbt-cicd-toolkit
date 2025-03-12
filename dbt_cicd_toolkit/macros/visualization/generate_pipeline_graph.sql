{% macro generate_pipeline_graph(model_selection=none, include_environments=true, output_format='mermaid') %}
  {{ return(adapter.dispatch('generate_pipeline_graph', 'dbt_cicd_toolkit')(model_selection, include_environments, output_format)) }}
{% endmacro %}

{% macro default__generate_pipeline_graph(model_selection=none, include_environments=true, output_format='mermaid') %}
  {#- This macro generates a visual representation of the CI/CD pipeline for models -#}
  
  {# Get models to include in the graph #}
  {%- if model_selection is none -%}
    {%- set models_to_include = [] -%}
    {%- for node_id, node in graph.nodes.items() -%}
      {%- if node.resource_type == 'model' -%}
        {%- do models_to_include.append(node.name) -%}
      {%- endif -%}
    {%- endfor -%}
  {%- else -%}
    {%- set models_to_include = model_selection -%}
  {%- endif -%}
  
  {# Get environment information if requested #}
  {%- if include_environments -%}
    {%- set environments = dbt_cicd_toolkit.get_available_environments() -%}
    {%- set promotion_status = dbt_cicd_toolkit.get_promotion_status(models=models_to_include) -%}
  {%- endif -%}
  
  {# Generate graph based on output format #}
  {%- if output_format == 'mermaid' -%}
    {%- set output_lines = [] -%}
    {%- do output_lines.append("graph TD") -%}
    
    {# Add model nodes and relationships #}
    {%- for model_name in models_to_include -%}
      {%- set node = graph.nodes['model.' ~ project_name ~ '.' ~ model_name] -%}
      {%- set model_id = model_name | replace(' ', '_') | replace('-', '_') -%}
      
      {# Add the model node #}
      {%- do output_lines.append("    " ~ model_id ~ "[" ~ model_name ~ "]") -%}
      
      {# Add dependencies #}
      {%- if node.depends_on and node.depends_on.nodes -%}
        {%- for upstream_id in node.depends_on.nodes -%}
          {%- if upstream_id.startswith('model.') -%}
            {%- set upstream_name = upstream_id.split('.')[-1] -%}
            {%- set upstream_id_clean = upstream_name | replace(' ', '_') | replace('-', '_') -%}
            {%- if upstream_name in models_to_include -%}
              {%- do output_lines.append("    " ~ upstream_id_clean ~ " --> " ~ model_id) -%}
            {%- endif -%}
          {%- endif -%}
        {%- endfor -%}
      {%- endif -%}
      
      {# Add environment status #}
      {%- if include_environments -%}
        {%- for env in environments -%}
          {%- set env_status = promotion_status[env][model_name] -%}
          {%- if env_status.promoted -%}
            {%- set env_id = env ~ "_" ~ model_id -%}
            {%- do output_lines.append("    " ~ env_id ~ "(" ~ env ~ ")") -%}
            {%- do output_lines.append("    " ~ model_id ~ " --> " ~ env_id ~ ":::promoted") -%}
          {%- endif -%}
        {%- endfor -%}
      {%- endif -%}
    {%- endfor -%}
    
    {# Add class definitions #}
    {%- do output_lines.append("    classDef promoted fill:#afa,stroke:#5a5,stroke-width:2px") -%}
    
    {# Join lines and return #}
    {{ return(output_lines | join('\n')) }}
  
  {%- elif output_format == 'dot' -%}
    {%- set output_lines = [] -%}
    {%- do output_lines.append("digraph CI_CD_Pipeline {") -%}
    {%- do output_lines.append("    rankdir=TB;") -%}
    {%- do output_lines.append("    node [shape=box, style=filled, fillcolor=lightblue];") -%}
    
    {# Add model nodes and relationships #}
    {%- for model_name in models_to_include -%}
      {%- set node = graph.nodes['model.' ~ project_name ~ '.' ~ model_name] -%}
      {%- set model_id = model_name | replace(' ', '_') | replace('-', '_') -%}
      
      {# Add the model node #}
      {%- do output_lines.append("    \"" ~ model_id ~ "\" [label=\"" ~ model_name ~ "\"];") -%}
      
      {# Add dependencies #}
      {%- if node.depends_on and node.depends_on.nodes -%}
        {%- for upstream_id in node.depends_on.nodes -%}
          {%- if upstream_id.startswith('model.') -%}
            {%- set upstream_name = upstream_id.split('.')[-1] -%}
            {%- set upstream_id_clean = upstream_name | replace(' ', '_') | replace('-', '_') -%}
            {%- if upstream_name in models_to_include -%}
              {%- do output_lines.append("    \"" ~ upstream_id_clean ~ "\" -> \"" ~ model_id ~ "\";") -%}
            {%- endif -%}
          {%- endif -%}
        {%- endfor -%}
      {%- endif -%}
      
      {# Add environment status #}
      {%- if include_environments -%}
        {%- for env in environments -%}
          {%- set env_status = promotion_status[env][model_name] -%}
          {%- if env_status.promoted -%}
            {%- set env_id = env ~ "_" ~ model_id -%}
            {%- do output_lines.append("    \"" ~ env_id ~ "\" [label=\"" ~ env ~ "\", shape=ellipse, fillcolor=lightgreen];") -%}
            {%- do output_lines.append("    \"" ~ model_id ~ "\" -> \"" ~ env_id ~ "\";") -%}
          {%- endif -%}
        {%- endfor -%}
      {%- endif -%}
    {%- endfor -%}
    
    {%- do output_lines.append("}") -%}
    
    {# Join lines and return #}
    {{ return(output_lines | join('\n')) }}
  
  {%- elif output_format == 'json' -%}
    {%- set graph_data = {
      "nodes": [],
      "edges": []
    } -%}
    
    {# Add model nodes #}
    {%- for model_name in models_to_include -%}
      {%- set node = graph.nodes['model.' ~ project_name ~ '.' ~ model_name] -%}
      {%- set model_id = model_name | replace(' ', '_') | replace('-', '_') -%}
      
      {%- do graph_data.nodes.append({
        "id": model_id,
        "label": model_name,
        "type": "model"
      }) -%}
      
      {# Add environment nodes #}
      {%- if include_environments -%}
        {%- for env in environments -%}
          {%- set env_status = promotion_status[env][model_name] -%}
          {%- if env_status.promoted -%}
            {%- set env_id = env ~ "_" ~ model_id -%}
            {%- do graph_data.nodes.append({
              "id": env_id,
              "label": env,
              "type": "environment",
              "promoted": true,
              "last_promotion": env_status.last_promotion
            }) -%}
            {%- do graph_data.edges.append({
              "source": model_id,
              "target": env_id,
              "type": "promotion"
            }) -%}
          {%- endif -%}
        {%- endfor -%}
      {%- endif -%}
      
      {# Add dependency edges #}
      {%- if node.depends_on and node.depends_on.nodes -%}
        {%- for upstream_id in node.depends_on.nodes -%}
          {%- if upstream_id.startswith('model.') -%}
            {%- set upstream_name = upstream_id.split('.')[-1] -%}
            {%- set upstream_id_clean = upstream_name | replace(' ', '_') | replace('-', '_') -%}
            {%- if upstream_name in models_to_include -%}
              {%- do graph_data.edges.append({
                "source": upstream_id_clean,
                "target": model_id,
                "type": "dependency"
              }) -%}
            {%- endif -%}
          {%- endif -%}
        {%- endfor -%}
      {%- endif -%}
    {%- endfor -%}
    
    {# Return JSON data #}
    {{ return(tojson(graph_data)) }}
  
  {%- else -%}
    {{ log("Unsupported output format: " ~ output_format ~ ". Supported formats: mermaid, dot, json", info=True) }}
    {{ return('') }}
  {%- endif -%}
{% endmacro %} 