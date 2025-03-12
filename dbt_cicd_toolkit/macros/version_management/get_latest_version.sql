{% macro get_latest_version(model_name, environment=none) %}
  {{ return(adapter.dispatch('get_latest_version', 'dbt_cicd_toolkit')(model_name, environment)) }}
{% endmacro %}

{% macro default__get_latest_version(model_name, environment=none) %}
  {#- This macro gets the latest version of a model, optionally filtered by environment -#}
  
  {%- if not model_name -%}
    {{ log("No model name provided. Cannot get latest version.", info=True) }}
    {{ return(none) }}
  {%- endif -%}
  
  {# Get version history for the model #}
  {%- set version_history = dbt_cicd_toolkit.get_version_history(model_name, environment) -%}
  
  {# Return the latest version #}
  {%- if version_history.versions | length > 0 -%}
    {%- set latest_version = version_history.versions[0].version -%}
    {{ return(latest_version) }}
  {%- else -%}
    {{ log("No versions found for model " ~ model_name, info=True) }}
    {{ return("0.0.0") }}
  {%- endif -%}
{% endmacro %} 