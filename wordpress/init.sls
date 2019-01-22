{% from "wordpress/map.jinja" import map with context %}

{% for id, site in salt['pillar.get']('wordpress:sites', {}).items() %}
{{ site.path }}:
  file.directory:
    - user: {{ site.dbuser }}
    - group: {{ site.dbuser }}
    - mode: 755
    - makedirs: True

# This command tells wp-cli to download wordpress
download_wordpress_{{ id }}:
 cmd.run:
  - cwd: {{ site.path }}
  - name: 'wget https://wordpress.org/latest.tar.gz'
  - runas: {{ site.dbuser }}
  - unless: test -f {{ site.path }}/latest.tar.gz

extract_wordpress_{{ id }}:
 cmd.run:
  - cwd: {{ site.path }}
  - name: 'tar -xzvf latest.tar.gz'
  - runas: {{ site.dbuser }}
  - unless: test -f {{ site.path }}/wp-settings.php
  - watch:
    - download_wordpress_{{ id }}

move_wordpress_{{ id }}:
 cmd.run:
  - cwd: {{ site.path }}
  - name: 'mv wordpress/* . && rm -rf wordpress'
  - runas: {{ site.dbuser }}
  - unless: test -f {{ site.path }}/wp-settings.php
  - watch:
    - extract_wordpress_{{ id }}

{{ site.path }}/wp-config.php:
  file.managed:
    - source: {{ site.path }}/wp-config-sample.php
    - user: {{ site.dbuser }}
    - group: {{ site.dbuser }}
    - mode: 655
    - watch:
      - move_wordpress_{{ id }}

wp-config-database:
  file.replace:
    - name: {{ site.path }}/wp-config.php
    - pattern: "^define('DB_NAME'"
    - repl: "define('DB_NAME', '{{ site.database }}');"
    - watch:
      - {{ site.path }}/wp-config.php

wp-config-dbuser:
  file.replace:
    - name: {{ site.path }}/wp-config.php
    - pattern: "^define('DB_USER'"
    - repl: "define('DB_NAME', '{{ site.dbuser }}');"
    - watch:
      - {{ site.path }}/wp-config.php

wp-config-dbpass:
  file.replace:
    - name: {{ site.path }}/wp-config.php
    - pattern: "^define('DB_PASSWORD'"
    - repl: "define('DB_NAME', '{{ site.dbpass }}');"
    - watch:
      - {{ site.path }}/wp-config.php

wp-config-dbhost:
  file.replace:
    - name: {{ site.path }}/wp-config.php
    - pattern: "^define('DB_HOST'"
    - repl: "define('DB_NAME', '{{ site.dbhost }}');"
    - watch:
      - {{ site.path }}/wp-config.php

#{{ site.path }}/wp-config.php:
#  file.managed:
#    - source: salt://wordpress/files/wp-config.php
#    - template: jinja
#    - context:
#      site: {{ site }}
#    - user: {{ site.dbuser }}
#    - group: {{ site.dbuser }}
#    - mode: 655

{{ site.path }}/.htaccess:
  file.managed:
    - source: salt://wordpress/files/htaccess
    - user: {{ site.dbuser }}
    - group: {{ site.dbuser }}
    - mode: 655

{% endfor %}
