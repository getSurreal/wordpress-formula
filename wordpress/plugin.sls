{% from "wordpress/map.jinja" import map with context %}
{% from "wordpress/cli-allow-root.sls" import allowroot with context %}
{% for name, site in pillar['wordpress']['sites'].items() %}
  {% if 'plugins' in pillar['wordpress']['sites'][name] %}
    {% for plugin_name in pillar['wordpress']['sites'][name]['plugins'] %}  

configure_plugin_{{ plugin_name }}:
 cmd.run:
  - name: '/usr/local/bin/wp plugin install {{ allowroot }} --activate {{ plugin_name }}'
  - cwd: {{ site.path }}
  - runas: {{ site.user }}
  - unless: '/usr/local/bin/wp plugin is-installed {{ allowroot }} {{ plugin_name }}'
    {% endfor %}
  {% endif %}
{% endfor %}
