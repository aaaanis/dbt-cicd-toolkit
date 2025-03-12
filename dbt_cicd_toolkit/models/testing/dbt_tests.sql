{{
    config(
        materialized='table',
        tags=['dbt_cicd_toolkit', 'test_coverage']
    )
}}

/*
    DBT Tests Catalog
    
    This model extracts information about all tests in the dbt project
    to support the test coverage dashboard.
*/

WITH tests AS (
    
    {% for node_id, node in graph.nodes.items() %}
        {% if node.resource_type == 'test' %}
            SELECT 
                '{{ node.unique_id }}' AS test_id,
                '{{ node.name }}' AS test_name,
                {% if node.test_metadata %}
                    {% if node.test_metadata.name %}
                        '{{ node.test_metadata.name }}' AS test_type,
                    {% else %}
                        'custom' AS test_type,
                    {% endif %}
                {% else %}
                    'custom' AS test_type,
                {% endif %}
                {% if node.depends_on and node.depends_on.nodes %}
                    {% for depends_node_id in node.depends_on.nodes %}
                        {% if depends_node_id.startswith('model.') %}
                            '{{ depends_node_id }}' AS model_id,
                            {% break %}
                        {% endif %}
                    {% endfor %}
                {% else %}
                    NULL AS model_id,
                {% endif %}
                {% if node.column_name %}
                    '{{ node.column_name }}' AS column_name,
                {% else %}
                    NULL AS column_name,
                {% endif %}
                {% if node.test_metadata %}
                    {% if node.test_metadata.status %}
                        '{{ node.test_metadata.status }}' AS status,
                    {% else %}
                        'unknown' AS status,
                    {% endif %}
                {% else %}
                    'unknown' AS status,
                {% endif %}
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

SELECT * FROM tests 