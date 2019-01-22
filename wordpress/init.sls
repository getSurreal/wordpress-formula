{% from "wordpress/map.jinja" import map with context %}

{% for id, site in salt['pillar.get']('wordpress:sites', {}).items() %}
{{ site.get('path') }}:
  file.directory:
    - user: {{ site.get('dbuser') }}
    - group: {{ site.get('dbuser') }}
    - mode: 755
    - makedirs: True

# This command tells wp-cli to download wordpress
download_wordpress_{{ id }}:
 cmd.run:
  - cwd: {{ site.get('path') }}
  - name: 'wget https://wordpress.org/latest.tar.gz'
  - runas: {{ site.get('dbuser') }}
  - unless: test -f {{ site.get('path') }}/wp-config.php

extract_wordpress_{{ id }}:
 cmd.run:
  - cwd: {{ site.get('path') }}
  - name: 'tar -xzvf latest.tar.gz'
  - runas: {{ site.get('dbuser') }}
  - unless: test -f {{ site.get('path') }}/wp-config.php

move_wordpress_{{ id }}:
 cmd.run:
  - cwd: {{ site.get('path') }}
  - name: 'mv wordpress/* . && rm -rf wordpress'
  - runas: {{ site.get('dbuser') }}
  - unless: test -f {{ site.get('path') }}/wp-config.php

{{ site.get('path') }}/wp-config.php:
  file.managed:
    - source: salt://wordpress/files/wp-config.php
    - user: {{ site.get('dbuser') }}
    - group: {{ site.get('dbuser') }}
    - mode: 655

{{ site.get('path') }}/.htaccess:
  file.managed:
    - source: salt://wordpress/files/htaccess
    - user: {{ site.get('dbuser') }}
    - group: {{ site.get('dbuser') }}
    - mode: 655

{% endfor %}
