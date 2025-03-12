{% macro register_version(model_name, version, description=none, is_breaking=false) %}
  {{ return(adapter.dispatch('register_version', 'dbt_cicd_toolkit')(model_name, version, description, is_breaking)) }}
{% endmacro %}

{% macro default__register_version(model_name, version, description=none, is_breaking=false) %}
  {#- This macro registers a new version of a model -#}
  
  {%- if not model_name -%}
    {{ log("No model name provided. Cannot register version.", info=True) }}
    {{ return(none) }}
  {%- endif -%}
  
  {%- if not version -%}
    {{ log("No version provided. Cannot register version.", info=True) }}
    {{ return(none) }}
  {%- endif -%}
  
  {# Validate model exists #}
  {%- set model_exists = false -%}
  {%- for node_id, node in graph.nodes.items() -%}
    {%- if node.resource_type == 'model' and node.name == model_name -%}
      {%- set model_exists = true -%}
      {%- set model_unique_id = node.unique_id -%}
      {%- break -%}
    {%- endif -%}
  {%- endfor -%}
  
  {%- if not model_exists -%}
    {{ log("Model " ~ model_name ~ " does not exist. Cannot register version.", info=True) }}
    {{ return(none) }}
  {%- endif -%}
  
  {# Set the version directory path #}
  {%- set version_dir = target_path ~ '/versions' -%}
  {%- set model_version_file = version_dir ~ '/' ~ model_name ~ '.json' -%}
  
  {# Ensure the directory exists #}
  {% do dbt.filesystem.create_directory(version_dir) %}
  
  {# Read existing version file if it exists #}
  {%- set version_exists = dbt.filesystem.exists(model_version_file) -%}
  {%- if version_exists -%}
    {%- set version_history = fromjson(dbt.filesystem.read_file(model_version_file)) -%}
  {%- else -%}
    {%- set version_history = {'model': model_name, 'versions': []} -%}
  {%- endif -%}
  
  {# Check if version already exists #}
  {%- set version_already_exists = false -%}
  {%- for ver in version_history.versions -%}
    {%- if ver.version == version -%}
      {%- set version_already_exists = true -%}
      {%- break -%}
    {%- endif -%}
  {%- endfor -%}
  
  {%- if version_already_exists -%}
    {{ log("Version " ~ version ~ " already exists for model " ~ model_name ~ ". Cannot register duplicate version.", info=True) }}
    {{ return(none) }}
  {%- endif -%}
  
  {# Create new version entry #}
  {%- set timestamp = modules.datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S') -%}
  {%- set version_entry = {
    'version': version,
    'timestamp': timestamp,
    'is_breaking': is_breaking,
    'status': 'registered'
  } -%}
  
  {%- if description is not none -%}
    {%- do version_entry.update({'description': description}) -%}
  {%- endif -%}
  
  {# Add the version to history #}
  {%- do version_history.versions.append(version_entry) -%}
  
  {# Sort versions by timestamp descending #}
  {%- set version_history = version_history | dict_update({'versions': (
    version_history.versions | sort(attribute='timestamp', reverse=true)
  )}) -%}
  
  {# Write version file #}
  {% do dbt.filesystem.write_file(model_version_file, tojson(version_history)) %}
  
  {{ log("Registered version " ~ version ~ " for model " ~ model_name, info=True) }}
  {{ return(version_entry) }}
{% endmacro %} 