{% macro visualize_impact(source_files=[], output_format='text') %}
  {{ return(adapter.dispatch('visualize_impact', 'dbt_cicd_toolkit')(source_files, output_format)) }}
{% endmacro %}

{% macro default__visualize_impact(source_files=[], output_format='text') %}
  {#- This macro generates a visualization of the impact of changes to source files -#}
  
  {%- if not source_files -%}
    {{ log("No source files provided. Returning empty visualization.", info=True) }}
    {{ return('') }}
  {%- endif -%}
  
  {%- set impacted_models = dbt_cicd_toolkit.get_impacted_models(
    source_files=source_files, 
    include_sources=true, 
    include_downstream=true,
    exclude_current=false
  ) -%}
  
  {%- if output_format == 'text' -%}
    {%- set output = [] -%}
    {%- do output.append("Impact Analysis Results:") -%}
    {%- do output.append("=======================") -%}
    {%- do output.append("Source Files:") -%}
    {%- for file in source_files -%}
      {%- do output.append("  - " ~ file) -%}
    {%- endfor -%}
    {%- do output.append("") -%}
    {%- do output.append("Impacted Models:") -%}
    {%- if impacted_models -%}
      {%- for model in impacted_models -%}
        {%- do output.append("  - " ~ model) -%}
      {%- endfor -%}
    {%- else -%}
      {%- do output.append("  No models impacted") -%}
    {%- endif -%}
    
    {{ return(output | join('\n')) }}
  
  {%- elif output_format == 'json' -%}
    {%- set json_output = {
      "source_files": source_files,
      "impacted_models": impacted_models
    } -%}
    
    {{ return(tojson(json_output)) }}
  
  {%- elif output_format == 'markdown' -%}
    {%- set output = [] -%}
    {%- do output.append("# Impact Analysis Results") -%}
    {%- do output.append("") -%}
    {%- do output.append("## Source Files") -%}
    {%- for file in source_files -%}
      {%- do output.append("- `" ~ file ~ "`") -%}
    {%- endfor -%}
    {%- do output.append("") -%}
    {%- do output.append("## Impacted Models") -%}
    {%- if impacted_models -%}
      {%- for model in impacted_models -%}
        {%- do output.append("- `" ~ model ~ "`") -%}
      {%- endfor -%}
    {%- else -%}
      {%- do output.append("*No models impacted*") -%}
    {%- endif -%}
    
    {{ return(output | join('\n')) }}
  
  {%- else -%}
    {{ log("Unsupported output format: " ~ output_format ~ ". Supported formats: text, json, markdown", info=True) }}
    {{ return('') }}
  {%- endif -%}
{% endmacro %} 