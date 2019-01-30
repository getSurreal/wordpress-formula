{% from "wordpress/map.jinja" import map with context %}

{% for id, site in salt['pillar.get']('wordpress:sites', {}).items() %}
{{ site.path }}:
  file.directory:
    - user: {{ site.dbuser }}
    - group: {{ site.dbuser }}
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True

# This command tells wp-cli to download wordpress
download_wordpress_{{ id }}:
 cmd.run:
  - cwd: {{ site.path }}
  - name: 'wget https://wordpress.org/latest.tar.gz'
  - runas: {{ site.dbuser }}
  - unless: test -f {{ site.path }}/wp-settings.php

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
    - group: {{ map.www_group }}
    - mode: 640
    - unless: test -f {{ site.path }}/wp-config.php

wp-config-database_{{ id }}:
  file.line:
    - name: {{ site.path }}/wp-config.php
    - match: ^define\('DB_NAME'.
    - content: "define('DB_NAME', '{{ site.database }}');"
    - mode: replace

wp-config-dbuser_{{ id }}:
  file.line:
    - name: {{ site.path }}/wp-config.php
    - match: ^define\('DB_USER'.
    - content: "define('DB_USER', '{{ site.dbuser }}');"
    - mode: replace

wp-config-dbpass_{{ id }}:
  file.line:
    - name: {{ site.path }}/wp-config.php
    - match: ^define\('DB_PASSWORD'.
    - content: "define('DB_PASSWORD', '{{ site.dbpass }}');"
    - mode: replace

wp-config-dbhost_{{ id }}:
  file.line:
    - name: {{ site.path }}/wp-config.php
    - match: ^define\('DB_HOST'.
    - content: "define('DB_HOST', '{{ site.dbhost }}');"
    - mode: replace

wp-config-AUTH_KEY_{{ id }}:
  file.line:
    - name: {{ site.path }}/wp-config.php
    - match: ^define\('AUTH_KEY'.
    - content: "define('AUTH_KEY', '{{ salt['random.get_str'](32) }}');"
    - mode: replace
    - onchanges:
      - wp-config-dbhost_{{ id }}

wp-config-SECURE_AUTH_KEY_{{ id }}:
  file.line:
    - name: {{ site.path }}/wp-config.php
    - match: ^define\('SECURE_AUTH_KEY'.
    - content: "define('SECURE_AUTH_KEY', '{{ salt['random.get_str'](32) }}');"
    - mode: replace
    - onchanges:
      - wp-config-dbhost_{{ id }}

wp-config-LOGGED_IN_KEY_{{ id }}:
  file.line:
    - name: {{ site.path }}/wp-config.php
    - match: ^define\('LOGGED_IN_KEY'.
    - content: "define('LOGGED_IN_KEY', '{{ salt['random.get_str'](32) }}');"
    - mode: replace
    - onchanges:
      - wp-config-dbhost_{{ id }}

wp-config-NONCE_KEY_{{ id }}:
  file.line:
    - name: {{ site.path }}/wp-config.php
    - match: ^define\('NONCE_KEY'.
    - content: "define('NONCE_KEY', '{{ salt['random.get_str'](32) }}');"
    - mode: replace
    - onchanges:
      - wp-config-dbhost_{{ id }}

wp-config-AUTH_SALT_{{ id }}:
  file.line:
    - name: {{ site.path }}/wp-config.php
    - match: ^define\('AUTH_SALT'.
    - content: "define('AUTH_SALT', '{{ salt['random.get_str'](32) }}');"
    - mode: replace
    - onchanges:
      - wp-config-dbhost_{{ id }}

wp-config-SECURE_AUTH_SALT_{{ id }}:
  file.line:
    - name: {{ site.path }}/wp-config.php
    - match: ^define\('SECURE_AUTH_SALT'.
    - content: "define('SECURE_AUTH_SALT', '{{ salt['random.get_str'](32) }}');"
    - mode: replace
    - onchanges:
      - wp-config-dbhost_{{ id }}

wp-config-LOGGED_IN_SALT_{{ id }}:
  file.line:
    - name: {{ site.path }}/wp-config.php
    - match: ^define\('LOGGED_IN_SALT'.
    - content: "define('LOGGED_IN_SALT', '{{ salt['random.get_str'](32) }}');"
    - mode: replace
    - onchanges:
      - wp-config-dbhost_{{ id }}

wp-config-NONCE_SALT_{{ id }}:
  file.line:
    - name: {{ site.path }}/wp-config.php
    - match: ^define\('NONCE_SALT'.
    - content: "define('NONCE_SALT', '{{ salt['random.get_str'](32) }}');"
    - mode: replace
    - onchanges:
      - wp-config-dbhost_{{ id }}

{{ site.path }}/.htaccess:
  file.managed:
    - source: salt://wordpress/files/htaccess
    - user: {{ site.dbuser }}
    - group: {{ site.dbuser }}
    - mode: 644
    - unless: test -f {{ site.path }}/.htaccess

{{ site.path }}/wp-content:
  file.directory:
    - user: {{ site.dbuser }}
    - group: {{ map.www_group }}
    - group_mode: 775
    - file_mode: 664
    - recurse:
      - user
      - group
      - mode


{% endfor %}
