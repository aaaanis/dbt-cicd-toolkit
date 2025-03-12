{% macro get_available_environments() %}
  {{ return(adapter.dispatch('get_available_environments', 'dbt_cicd_toolkit')()) }}
{% endmacro %}

{% macro default__get_available_environments() %}
  {#- This macro gets the list of available environments based on state files -#}
  
  {# Set the state directory path #}
  {%- set state_dir = target_path ~ '/promotion_states' -%}
  
  {# Check if the directory exists #}
  {%- if not dbt.filesystem.exists(state_dir) -%}
    {{ return([]) }}
  {%- endif -%}
  
  {# Get all JSON files in the directory #}
  {%- set files = dbt.filesystem.list_contents(state_dir) -%}
  {%- set environments = [] -%}
  
  {%- for file in files -%}
    {%- if file.endswith('.json') -%}
      {%- set env_name = file.replace('.json', '') -%}
      {%- do environments.append(env_name) -%}
    {%- endif -%}
  {%- endfor -%}
  
  {# If no environments found, add default environments #}
  {%- if not environments -%}
    {%- do environments.extend(['development', 'staging', 'production']) -%}
  {%- endif -%}
  
  {{ return(environments) }}
{% endmacro %}

{% macro get_promotion_states(environment) %}
  {{ return(adapter.dispatch('get_promotion_states', 'dbt_cicd_toolkit')(environment)) }}
{% endmacro %}

{% macro default__get_promotion_states(environment) %}
  {#- This macro gets the promotion states for a specific environment -#}
  
  {# Set the state file path #}
  {%- set state_dir = target_path ~ '/promotion_states' -%}
  {%- set state_file = state_dir ~ '/' ~ environment ~ '.json' -%}
  
  {# Check if the file exists #}
  {%- if dbt.filesystem.exists(state_file) -%}
    {%- set states = fromjson(dbt.filesystem.read_file(state_file)) -%}
  {%- else -%}
    {%- set states = {'promotions': []} -%}
  {%- endif -%}
  
  {{ return(states) }}
{% endmacro %} 