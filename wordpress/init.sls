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

wp-config-database_{{ id }}:
  file.line:
    - name: {{ site.path }}/wp-config.php
    - match: "^define('DB_NAME'"
    - content: "define('DB_NAME', '{{ site.database }}');"
    - mode: replace

wp-config-dbuser_{{ id }}:
  file.line:
    - name: {{ site.path }}/wp-config.php
    - match: "^define('DB_USER'"
    - content: "define('DB_NAME', '{{ site.dbuser }}');"
    - mode: replace

wp-config-dbpass_{{ id }}:
  file.line:
    - name: {{ site.path }}/wp-config.php
    - match: "^define('DB_PASSWORD'"
    - content: "define('DB_NAME', '{{ site.dbpass }}');"
    - mode: replace

wp-config-dbhost_{{ id }}:
  file.line:
    - name: {{ site.path }}/wp-config.php
    - match: ^define\('DB_HOST'.
    - content: "define('DB_NAME', '{{ site.dbhost }}');"
    - mode: replace

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
