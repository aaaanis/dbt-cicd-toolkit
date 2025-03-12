{{
    config(
        materialized='table',
        tags=['dbt_cicd_toolkit', 'test_coverage']
    )
}}

/*
    DBT Models Catalog
    
    This model extracts information about all models in the dbt project
    to support the test coverage dashboard.
*/

WITH models AS (
    
    {% for node_id, node in graph.nodes.items() %}
        {% if node.resource_type == 'model' %}
            SELECT 
                '{{ node.unique_id }}' AS model_id,
                '{{ node.name }}' AS model_name,
                '{{ node.schema }}' AS model_schema,
                '{{ node.original_file_path }}' AS model_path,
                '{{ node.config.materialized }}' AS materialization,
                {% if node.description %}
                    '{{ node.description | replace("'", "''") }}' AS description,
                {% else %}
                    NULL AS description,
                {% endif %}
                '{{ node.package_name }}' AS package_name
            
            {% if not loop.last %}UNION ALL{% endif %}
        {% endif %}
    {% endfor %}
    
)

SELECT * FROM models 