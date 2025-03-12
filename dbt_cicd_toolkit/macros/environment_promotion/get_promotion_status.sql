{% macro get_promotion_status(environment=none, models=none) %}
  {{ return(adapter.dispatch('get_promotion_status', 'dbt_cicd_toolkit')(environment, models)) }}
{% endmacro %}

{% macro default__get_promotion_status(environment=none, models=none) %}
  {#- This macro gets the promotion status of models in a specific environment -#}
  
  {# Default to all environments if none specified #}
  {%- if not environment -%}
    {%- set environments = dbt_cicd_toolkit.get_available_environments() -%}
  {%- else -%}
    {%- set environments = [environment] -%}
  {%- endif -%}
  
  {# Default to all models if none specified #}
  {%- if not models -%}
    {%- set models = [] -%}
    {%- for node_id, node in graph.nodes.items() -%}
      {%- if node.resource_type == 'model' -%}
        {%- do models.append(node.name) -%}
      {%- endif -%}
    {%- endfor -%}
  {%- endif -%}
  
  {# Initialize result dictionary #}
  {%- set result = {} -%}
  
  {# Check each environment #}
  {%- for env in environments -%}
    {%- set env_result = {} -%}
    
    {# Get the promotion states for this environment #}
    {%- set states = dbt_cicd_toolkit.get_promotion_states(env) -%}
    
    {# Check each model #}
    {%- for model_name in models -%}
      {%- set model_status = {
        'name': model_name,
        'promoted': false,
        'last_promotion': none,
        'promotion_history': []
      } -%}
      
      {# Check each promotion for this model #}
      {%- for promotion in states.promotions -%}
        {%- if model_name in promotion.models -%}
          {%- if not model_status.last_promotion or promotion.timestamp > model_status.last_promotion -%}
            {%- do model_status.update({'last_promotion': promotion.timestamp, 'promoted': true}) -%}
          {%- endif -%}
          {%- do model_status.promotion_history.append({
            'timestamp': promotion.timestamp,
            'success': promotion.success
          }) -%}
        {%- endif -%}
      {%- endfor -%}
      
      {# Sort promotion history by timestamp #}
      {%- if model_status.promotion_history -%}
        {%- set model_status = model_status | dict_update({'promotion_history': (
          model_status.promotion_history | sort(attribute='timestamp', reverse=true)
        )}) -%}
      {%- endif -%}
      
      {%- do env_result.update({model_name: model_status}) -%}
    {%- endfor -%}
    
    {%- do result.update({env: env_result}) -%}
  {%- endfor -%}
  
  {{ return(result) }}
{% endmacro %} 