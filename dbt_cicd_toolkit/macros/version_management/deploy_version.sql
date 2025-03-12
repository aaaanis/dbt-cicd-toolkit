{% macro deploy_version(model_name, version, environment, require_tests=true) %}
  {{ return(adapter.dispatch('deploy_version', 'dbt_cicd_toolkit')(model_name, version, environment, require_tests)) }}
{% endmacro %}

{% macro default__deploy_version(model_name, version, environment, require_tests=true) %}
  {#- This macro deploys a specific version of a model to an environment -#}
  
  {%- if not model_name -%}
    {{ log("No model name provided. Cannot deploy version.", info=True) }}
    {{ return(none) }}
  {%- endif -%}
  
  {%- if not version -%}
    {{ log("No version provided. Cannot deploy version.", info=True) }}
    {{ return(none) }}
  {%- endif -%}
  
  {%- if not environment -%}
    {{ log("No environment provided. Cannot deploy version.", info=True) }}
    {{ return(none) }}
  {%- endif -%}
  
  {# Get version history for the model #}
  {%- set version_history = dbt_cicd_toolkit.get_version_history(model_name) -%}
  
  {# Check if version exists #}
  {%- set version_exists = false -%}
  {%- set version_entry = none -%}
  {%- for ver in version_history.versions -%}
    {%- if ver.version == version -%}
      {%- set version_exists = true -%}
      {%- set version_entry = ver -%}
      {%- break -%}
    {%- endif -%}
  {%- endfor -%}
  
  {%- if not version_exists -%}
    {{ log("Version " ~ version ~ " does not exist for model " ~ model_name ~ ". Cannot deploy.", info=True) }}
    {{ return(none) }}
  {%- endif -%}
  
  {# Check if tests are required and run them #}
  {%- if require_tests -%}
    {%- set test_results = dbt_cicd_toolkit.run_selective_tests(
      changed_files=[],  # Empty because we're only testing this specific model
      test_level='comprehensive',
      include_upstream=false,
      include_downstream=false,
      specific_models=[model_name]
    ) -%}
    
    {%- if test_results and test_results.failed_tests > 0 -%}
      {{ log("Tests failed for model " ~ model_name ~ ". Cannot deploy version " ~ version ~ " to " ~ environment ~ ".", info=True) }}
      {{ return(none) }}
    {%- endif -%}
  {%- endif -%}
  
  {# Set the version directory path #}
  {%- set version_dir = target_path ~ '/versions' -%}
  {%- set model_version_file = version_dir ~ '/' ~ model_name ~ '.json' -%}
  
  {# Update version environments #}
  {%- if not version_entry.environments -%}
    {%- do version_entry.update({'environments': []}) -%}
  {%- endif -%}
  
  {%- if environment not in version_entry.environments -%}
    {%- do version_entry.environments.append(environment) -%}
  {%- endif -%}
  
  {# Update version deployment timestamp #}
  {%- set timestamp = modules.datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S') -%}
  {%- do version_entry.update({'last_deployed': timestamp}) -%}
  {%- do version_entry.update({'status': 'deployed'}) -%}
  
  {# Create deployment record #}
  {%- if not version_entry.deployments -%}
    {%- do version_entry.update({'deployments': []}) -%}
  {%- endif -%}
  
  {%- do version_entry.deployments.append({
    'environment': environment,
    'timestamp': timestamp,
    'status': 'success'
  }) -%}
  
  {# Write updated version history #}
  {% do dbt.filesystem.write_file(model_version_file, tojson(version_history)) %}
  
  {# Also update the promotion state #}
  {%- do dbt_cicd_toolkit.promote_to_environment(
    target_environment=environment,
    models=[model_name],
    require_tests=false,  # We already ran tests
    update_state=true
  ) -%}
  
  {{ log("Deployed version " ~ version ~ " of model " ~ model_name ~ " to environment " ~ environment, info=True) }}
  {{ return(version_entry) }}
{% endmacro %} 