{%- macro sp_remove_html(col) -%}
    -- strip anything that looks like a tag
    regexp_replace({{ col }}, '<[^>]+>', ' ')
{%- endmacro %}

{%- macro sp_html_decode(col) -%}
    -- Spark doesn’t have a native “HTML unescape”, so replace the
    -- handful that show up 99 % of the time.
    regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(
            regexp_replace({{ col }}, '&nbsp;', ' '),
          '&amp;',  '&'),
        '&lt;',   '<'),
      '&gt;',   '>'),
    '&quot;', '"')
{%- endmacro %}

{%- macro sp_collapse_ws(col) -%}
    trim(regexp_replace({{ col }}, '\\s+', ' '))
{%- endmacro %}

{%- macro sp_dedupe_paragraphs(col) -%}
    {%- set delim = '¶' -%}         -- rare UTF-8 char
    array_join(
        array_distinct(
            filter(
                transform(split({{ col }}, '\\n+'), x -> trim(x)),
                x -> length(x) > 0
            )
        ),
        '{{ delim }}'
    )
{%- endmacro %}
