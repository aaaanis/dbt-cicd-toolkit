{% macro check_breaking_version(model_name, version) %}
  {{ return(adapter.dispatch('check_breaking_version', 'dbt_cicd_toolkit')(model_name, version)) }}
{% endmacro %}

{% macro default__check_breaking_version(model_name, version) %}
  {#- This macro checks if a version is marked as a breaking change -#}
  
  {%- if not model_name -%}
    {{ log("No model name provided. Cannot check breaking version.", info=True) }}
    {{ return(none) }}
  {%- endif -%}
  
  {%- if not version -%}
    {{ log("No version provided. Cannot check breaking version.", info=True) }}
    {{ return(none) }}
  {%- endif -%}
  
  {# Get version history for the model #}
  {%- set version_history = dbt_cicd_toolkit.get_version_history(model_name) -%}
  
  {# Check if version exists and is breaking #}
  {%- set is_breaking = false -%}
  {%- for ver in version_history.versions -%}
    {%- if ver.version == version -%}
      {%- set is_breaking = ver.is_breaking -%}
      {%- break -%}
    {%- endif -%}
  {%- endfor -%}
  
  {{ return(is_breaking) }}
{% endmacro %} 