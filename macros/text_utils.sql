{% macro remove_html_tags(column_name) %}
    regexp_replace({{ column_name }}, '<[^>]*>', '')
{% endmacro %}
