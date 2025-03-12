{% macro run_selective_tests(changed_files=[], test_level='standard', include_upstream=false, include_downstream=true, specific_models=none) %}
  {{ return(adapter.dispatch('run_selective_tests', 'dbt_cicd_toolkit')(changed_files, test_level, include_upstream, include_downstream, specific_models)) }}
{% endmacro %}

{% macro default__run_selective_tests(changed_files=[], test_level='standard', include_upstream=false, include_downstream=true, specific_models=none) %}
  {#- This macro runs selective tests on models based on changed files and test level -#}
  
  {%- set impacted_models = [] -%}
  
  {# If specific models are provided, use those instead of detecting from changed files #}
  {%- if specific_models is not none -%}
    {%- set impacted_models = specific_models -%}
  {%- elif changed_files -%}
    {# Get impacted models based on changed files #}
    {%- set impacted_models = dbt_cicd_toolkit.get_impacted_models(
      source_files=changed_files, 
      include_sources=true, 
      include_downstream=include_downstream,
      exclude_current=false
    ) -%}
  {%- else -%}
    {{ log("No changed files or specific models provided. No tests will be run.", info=True) }}
    {{ return(none) }}
  {%- endif -%}
  
  {# Add upstream models if requested #}
  {%- if include_upstream and not specific_models -%}
    {%- set upstream_models = [] -%}
    {%- for model_name in impacted_models -%}
      {%- set model_node = graph.nodes['model.' ~ project_name ~ '.' ~ model_name] -%}
      {%- if model_node.depends_on.nodes -%}
        {%- for upstream_node_id in model_node.depends_on.nodes -%}
          {%- if upstream_node_id.startswith('model.') -%}
            {%- set upstream_model_name = upstream_node_id.split('.')[-1] -%}
            {%- do upstream_models.append(upstream_model_name) -%}
          {%- endif -%}
        {%- endfor -%}
      {%- endif -%}
    {%- endfor -%}
    {%- set impacted_models = impacted_models + upstream_models -%}
    {%- set impacted_models = impacted_models | unique | list -%}
  {%- endif -%}
  
  {# Get tests to run based on test level #}
  {%- set tests_to_run = [] -%}
  {%- set passing_tests = [] -%}
  {%- set failing_tests = [] -%}
  
  {%- for node_id, node in graph.nodes.items() -%}
    {%- if node.resource_type == 'test' -%}
      {%- set should_run_test = false -%}
      
      {%- if test_level == 'comprehensive' -%}
        {# Run all tests for comprehensive level #}
        {%- set should_run_test = true -%}
      {%- else -%}
        {# For standard and minimal levels, check test dependencies #}
        {%- for model_name in impacted_models -%}
          {%- if ('model.' ~ project_name ~ '.' ~ model_name) in node.depends_on.nodes -%}
            {%- if test_level == 'standard' -%}
              {# Run all tests for standard level #}
              {%- set should_run_test = true -%}
              {%- break -%}
            {%- elif test_level == 'minimal' -%}
              {# For minimal level, only run critical tests (not_null, primary_key, etc.) #}
              {%- set test_name = node.name -%}
              {%- if 'not_null' in test_name or 'unique' in test_name or 'primary_key' in test_name or 'accepted_values' in test_name -%}
                {%- set should_run_test = true -%}
                {%- break -%}
              {%- endif -%}
            {%- endif -%}
          {%- endif -%}
        {%- endfor -%}
      {%- endif -%}
      
      {%- if should_run_test -%}
        {%- do tests_to_run.append(node.unique_id) -%}
        
        {# Track test status for results #}
        {%- if node.test_metadata and node.test_metadata.status -%}
          {%- if node.test_metadata.status == 'pass' -%}
            {%- do passing_tests.append(node.unique_id) -%}
          {%- elif node.test_metadata.status == 'fail' -%}
            {%- do failing_tests.append(node.unique_id) -%}
          {%- endif -%}
        {%- endif -%}
      {%- endif -%}
    {%- endif -%}
  {%- endfor -%}
  
  {# Log test execution plan #}
  {{ log("Test execution plan:", info=True) }}
  {{ log("  Test level: " ~ test_level, info=True) }}
  {{ log("  Models to test: " ~ impacted_models | join(', '), info=True) }}
  {{ log("  Number of tests to run: " ~ tests_to_run | length, info=True) }}
  
  {# Create test results object #}
  {%- set test_results = {
    'test_level': test_level,
    'models_tested': impacted_models,
    'total_tests': tests_to_run | length,
    'passing_tests': passing_tests | length,
    'failing_tests': failing_tests | length,
    'test_ids': tests_to_run
  } -%}
  
  {# Return the test results #}
  {{ return(test_results) }}
{% endmacro %} 