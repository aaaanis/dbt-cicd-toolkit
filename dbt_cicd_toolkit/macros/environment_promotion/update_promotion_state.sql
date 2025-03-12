{% macro update_promotion_state(promotion_plan) %}
  {{ return(adapter.dispatch('update_promotion_state', 'dbt_cicd_toolkit')(promotion_plan)) }}
{% endmacro %}

{% macro default__update_promotion_state(promotion_plan) %}
  {#- This macro updates the promotion state with a new promotion plan -#}
  
  {# Get the target path for state file #}
  {%- set state_dir = target_path ~ '/promotion_states' -%}
  {%- set target_env = promotion_plan.target_environment -%}
  {%- set state_file = state_dir ~ '/' ~ target_env ~ '.json' -%}
  
  {# Ensure the directory exists #}
  {% do dbt.filesystem.create_directory(state_dir) %}
  
  {# Read existing state file if it exists #}
  {%- set state_exists = dbt.filesystem.exists(state_file) -%}
  {%- if state_exists -%}
    {%- set current_state = fromjson(dbt.filesystem.read_file(state_file)) -%}
  {%- else -%}
    {%- set current_state = {'promotions': []} -%}
  {%- endif -%}
  
  {# Add current promotion to state #}
  {%- do current_state.promotions.append(promotion_plan) -%}
  
  {# Limit state history #}
  {%- if current_state.promotions | length > 10 -%}
    {%- set current_state = {'promotions': current_state.promotions[-10:]} -%}
  {%- endif -%}
  
  {# Write state file #}
  {% do dbt.filesystem.write_file(state_file, tojson(current_state)) %}
  
  {{ log("Updated promotion state for environment: " ~ target_env, info=True) }}
  {{ return(none) }}
{% endmacro %} 