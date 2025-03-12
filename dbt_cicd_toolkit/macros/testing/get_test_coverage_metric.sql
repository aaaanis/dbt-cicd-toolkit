{% macro get_test_coverage_metric(metric_name) %}
  {{ return(adapter.dispatch('get_test_coverage_metric', 'dbt_cicd_toolkit')(metric_name)) }}
{% endmacro %}

{% macro default__get_test_coverage_metric(metric_name) %}
  {#- This macro retrieves a test coverage metric -#}
  
  {%- if not metric_name -%}
    {{ log("No metric name provided. Cannot get test coverage metric.", info=True) }}
    {{ return(none) }}
  {%- endif -%}
  
  {# Set up metric calculation logic #}
  {%- set total_models = 0 -%}
  {%- set models_with_tests = 0 -%}
  {%- set total_tests = 0 -%}
  {%- set passing_tests = 0 -%}
  {%- set failing_tests = 0 -%}
  
  {# Calculate metrics for each model #}
  {%- for node_id, node in graph.nodes.items() -%}
    {%- if node.resource_type == 'model' -%}
      {%- set total_models = total_models + 1 -%}
      
      {%- set model_tests = [] -%}
      {%- set model_passing_tests = 0 -%}
      {%- set model_failing_tests = 0 -%}
      
      {# Find tests for this model #}
      {%- for test_id, test in graph.nodes.items() -%}
        {%- if test.resource_type == 'test' and test.depends_on and test.depends_on.nodes -%}
          {%- if node.unique_id in test.depends_on.nodes -%}
            {%- do model_tests.append(test) -%}
            
            {# Check test status #}
            {%- if test.test_metadata and test.test_metadata.status -%}
              {%- if test.test_metadata.status == 'pass' -%}
                {%- set model_passing_tests = model_passing_tests + 1 -%}
              {%- elif test.test_metadata.status == 'fail' -%}
                {%- set model_failing_tests = model_failing_tests + 1 -%}
              {%- endif -%}
            {%- endif -%}
          {%- endif -%}
        {%- endif -%}
      {%- endfor -%}
      
      {# Update project metrics #}
      {%- if model_tests | length > 0 -%}
        {%- set models_with_tests = models_with_tests + 1 -%}
      {%- endif -%}
      
      {%- set total_tests = total_tests + (model_tests | length) -%}
      {%- set passing_tests = passing_tests + model_passing_tests -%}
      {%- set failing_tests = failing_tests + model_failing_tests -%}
    {%- endif -%}
  {%- endfor -%}
  
  {# Calculate derived metrics #}
  {%- set model_coverage_pct = (models_with_tests / total_models * 100) if total_models > 0 else 0 -%}
  {%- set test_pass_rate = (passing_tests / total_tests * 100) if total_tests > 0 else 0 -%}
  
  {# Return the requested metric #}
  {%- if metric_name == 'total_models' -%}
    {{ return(total_models) }}
  {%- elif metric_name == 'models_with_tests' -%}
    {{ return(models_with_tests) }}
  {%- elif metric_name == 'model_coverage_pct' -%}
    {{ return(model_coverage_pct | round(2)) }}
  {%- elif metric_name == 'total_tests' -%}
    {{ return(total_tests) }}
  {%- elif metric_name == 'passing_tests' -%}
    {{ return(passing_tests) }}
  {%- elif metric_name == 'failing_tests' -%}
    {{ return(failing_tests) }}
  {%- elif metric_name == 'test_pass_rate' -%}
    {{ return(test_pass_rate | round(2)) }}
  {%- else -%}
    {{ log("Unknown metric name: " ~ metric_name, info=True) }}
    {{ return(none) }}
  {%- endif -%}
{% endmacro %} 