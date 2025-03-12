{% macro get_impacted_models(source_files=[], include_sources=true, include_downstream=true, exclude_current=false) %}
  {{ return(adapter.dispatch('get_impacted_models', 'dbt_cicd_toolkit')(source_files, include_sources, include_downstream, exclude_current)) }}
{% endmacro %}

{% macro default__get_impacted_models(source_files=[], include_sources=true, include_downstream=true, exclude_current=false) %}
  {#- This macro returns a list of models that are impacted by changes to specified source files -#}
  
  {%- if not source_files -%}
    {{ log("No source files provided. Returning empty list.", info=True) }}
    {%- set impacted_models = [] -%}
    {{ return(impacted_models) }}
  {%- endif -%}
  
  {%- set directly_modified_nodes = [] -%}
  {%- set modified_node_ids = [] -%}
  
  {#- Identify directly modified nodes -#}
  {%- for file_path in source_files -%}
    {%- set file_path = file_path | replace('\\', '/') -%}
    
    {#- Find node by file path -#}
    {%- for node_id, node in graph.nodes.items() -%}
      {%- if node.original_file_path and (node.original_file_path | replace('\\', '/') == file_path) -%}
        {%- do directly_modified_nodes.append(node) -%}
        {%- do modified_node_ids.append(node.unique_id) -%}
      {%- endif -%}
    {%- endfor -%}
    
    {#- Check for source file if requested -#}
    {%- if include_sources -%}
      {%- for source_id, source in graph.sources.items() -%}
        {%- if source.original_file_path and (source.original_file_path | replace('\\', '/') == file_path) -%}
          {%- do directly_modified_nodes.append(source) -%}
          {%- do modified_node_ids.append(source.unique_id) -%}
        {%- endif -%}
      {%- endfor -%}
    {%- endif -%}
  {%- endfor -%}
  
  {%- set all_impacted_nodes = [] -%}
  
  {#- Add directly modified nodes -#}
  {%- if not exclude_current -%}
    {%- for node in directly_modified_nodes -%}
      {%- do all_impacted_nodes.append(node) -%}
    {%- endfor -%}
  {%- endif -%}
  
  {#- Find downstream nodes if requested -#}
  {%- if include_downstream -%}
    {%- for node_id, node in graph.nodes.items() -%}
      {%- if node.depends_on.nodes -%}
        {%- set is_downstream = false -%}
        {%- for upstream_node_id in node.depends_on.nodes -%}
          {%- if upstream_node_id in modified_node_ids -%}
            {%- set is_downstream = true -%}
            {%- break -%}
          {%- endif -%}
        {%- endfor -%}
        
        {%- if is_downstream -%}
          {%- do all_impacted_nodes.append(node) -%}
          {%- do modified_node_ids.append(node.unique_id) -%}
        {%- endif -%}
      {%- endif -%}
    {%- endfor -%}
  {%- endif -%}
  
  {#- Extract model names from impacted nodes -#}
  {%- set impacted_models = [] -%}
  {%- for node in all_impacted_nodes -%}
    {%- if node.resource_type == 'model' -%}
      {%- do impacted_models.append(node.name) -%}
    {%- endif -%}
  {%- endfor -%}
  
  {{ log("Impacted models: " ~ impacted_models | join(", "), info=True) }}
  {{ return(impacted_models | unique | list) }}
{% endmacro %} 