{% macro to_timestamp_from_unix(column_name, milliseconds=true) %}
  {#
    Converts a Unix timestamp (seconds or milliseconds since epoch) to a standard timestamp.

    Args:
        column_name (str): The name of the column containing the Unix timestamp.
        milliseconds (bool, optional): Whether the input timestamp is in milliseconds. 
                                       Defaults to true (divides by 1000). 
                                       If false, assumes seconds.
  #}
  {% if milliseconds %}
    from_unixtime({{ column_name }} / 1000)::TIMESTAMP
  {% else %}
    from_unixtime({{ column_name }})::TIMESTAMP
  {% endif %}
{% endmacro %}

{% macro convert_milliseconds_to_seconds(column_name) %}
    ({{ column_name }} / 1000)
{% endmacro %}
