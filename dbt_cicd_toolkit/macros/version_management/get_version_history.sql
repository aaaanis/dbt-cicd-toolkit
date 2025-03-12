{% macro get_version_history(model_name, environment=none) %}
  {{ return(adapter.dispatch('get_version_history', 'dbt_cicd_toolkit')(model_name, environment)) }}
{% endmacro %}

{% macro default__get_version_history(model_name, environment=none) %}
  {#- This macro retrieves the version history of a model -#}
  
  {%- if not model_name -%}
    {{ log("No model name provided. Cannot get version history.", info=True) }}
    {{ return(none) }}
  {%- endif -%}
  
  {# Set the version directory path #}
  {%- set version_dir = target_path ~ '/versions' -%}
  {%- set model_version_file = version_dir ~ '/' ~ model_name ~ '.json' -%}
  
  {# Check if version file exists #}
  {%- set version_exists = dbt.filesystem.exists(model_version_file) -%}
  {%- if not version_exists -%}
    {{ log("No version history found for model " ~ model_name, info=True) }}
    {{ return({'model': model_name, 'versions': []}) }}
  {%- endif -%}
  
  {# Read version history #}
  {%- set version_history = fromjson(dbt.filesystem.read_file(model_version_file)) -%}
  
  {# Filter versions by environment if specified #}
  {%- if environment is not none -%}
    {%- set filtered_versions = [] -%}
    {%- for version in version_history.versions -%}
      {%- if version.environments and environment in version.environments -%}
        {%- do filtered_versions.append(version) -%}
      {%- endif -%}
    {%- endfor -%}
    {%- set version_history = version_history | dict_update({'versions': filtered_versions}) -%}
  {%- endif -%}
  
  {{ return(version_history) }}
{% endmacro %} 