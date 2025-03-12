{% macro promote_to_environment(target_environment, models=[], require_tests=true, update_state=true) %}
  {{ return(adapter.dispatch('promote_to_environment', 'dbt_cicd_toolkit')(target_environment, models, require_tests, update_state)) }}
{% endmacro %}

{% macro default__promote_to_environment(target_environment, models=[], require_tests=true, update_state=true) %}
  {#- This macro manages the promotion of models across environments -#}
  
  {%- if not target_environment -%}
    {{ log("No target environment specified.", info=True) }}
    {{ return(none) }}
  {%- endif -%}
  
  {%- if not models -%}
    {{ log("No models specified for promotion.", info=True) }}
    {{ return(none) }}
  {%- endif -%}
  
  {# Validate models exist #}
  {%- set valid_models = [] -%}
  {%- set invalid_models = [] -%}
  
  {%- for model_name in models -%}
    {%- set found = false -%}
    {%- for node_id, node in graph.nodes.items() -%}
      {%- if node.resource_type == 'model' and node.name == model_name -%}
        {%- set found = true -%}
        {%- do valid_models.append({'name': model_name, 'node': node}) -%}
        {%- break -%}
      {%- endif -%}
    {%- endfor -%}
    
    {%- if not found -%}
      {%- do invalid_models.append(model_name) -%}
    {%- endif -%}
  {%- endfor -%}
  
  {%- if invalid_models -%}
    {{ log("Warning: The following models do not exist and cannot be promoted: " ~ invalid_models | join(", "), info=True) }}
  {%- endif -%}
  
  {# Check if tests passed if required #}
  {%- if require_tests and valid_models -%}
    {%- set failing_tests = [] -%}
    
    {%- for model in valid_models -%}
      {%- for node_id, node in graph.nodes.items() -%}
        {%- if node.resource_type == 'test' and ('model.' ~ project_name ~ '.' ~ model.name) in node.depends_on.nodes -%}
          {%- if node.test_metadata and node.test_metadata.get('status') == 'fail' -%}
            {%- do failing_tests.append({'model': model.name, 'test': node.name}) -%}
          {%- endif -%}
        {%- endif -%}
      {%- endfor -%}
    {%- endfor -%}
    
    {%- if failing_tests -%}
      {{ log("Error: The following models have failing tests and cannot be promoted:", info=True) }}
      {%- for failing_test in failing_tests -%}
        {{ log("  Model: " ~ failing_test.model ~ ", Test: " ~ failing_test.test, info=True) }}
      {%- endfor -%}
      {{ return(none) }}
    {%- endif -%}
  {%- endif -%}
  
  {# Create promotion plan #}
  {%- set promotion_plan = {
    'target_environment': target_environment,
    'models': valid_models | map(attribute='name') | list,
    'timestamp': modules.datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
    'success': true 
  } -%}
  
  {# Save state if requested #}
  {%- if update_state -%}
    {%- do dbt_cicd_toolkit.update_promotion_state(promotion_plan) -%}
  {%- endif -%}
  
  {# Log promotion plan #}
  {{ log("Promotion plan:", info=True) }}
  {{ log("  Target environment: " ~ target_environment, info=True) }}
  {{ log("  Models to promote: " ~ valid_models | map(attribute='name') | join(', '), info=True) }}
  {{ log("  Timestamp: " ~ promotion_plan.timestamp, info=True) }}
  
  {# Return the promotion plan #}
  {{ return(promotion_plan) }}
{% endmacro %} 