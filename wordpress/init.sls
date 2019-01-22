{% from "wordpress/map.jinja" import map with context %}
{% from "wordpress/cli-allow-root.sls" import allowroot with context %}

include:
  - wordpress.cli

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
  - name: '/usr/local/bin/wp core download {{ allowroot }} --path="{{ site.get('path') }}/"'
  - runas: {{ site.get('dbuser') }}
  - unless: test -f {{ site.get('path') }}/wp-config.php

# This command tells wp-cli to create our wp-config.php, DB info needs to be the same as above
configure_{{ id }}:
 cmd.run:
  - name: '/usr/local/bin/wp core config {{ allowroot }} --dbname="{{ site.get('database') }}" --dbuser="{{ site.get('dbuser') }}" --dbpass="{{ site.get('dbpass') }}" --dbhost="{{ site.get('dbhost') }}" --path="{{ site.get('path') }}"'
  - cwd: {{ site.get('path') }}
  - runas: {{ site.get('dbuser') }}
  - unless: test -f {{ site.get('path') }}/wp-config.php  

# This command tells wp-cli to install wordpress
install_{{ id }}:
 cmd.run:
  - cwd: {{ site.get('path') }}
  - name: '/usr/local/bin/wp core install {{ allowroot }} --url="{{ site.get('url') }}" --title="{{ site.get('title') }}" --admin_user="{{ site.get('username') }}" --admin_password="{{ site.get('password') }}" --admin_email="{{ site.get('email') }}" --path="{{ site.get('path') }}/"'
  - runas: {{ site.get('dbuser') }}
  - unless: /usr/local/bin/wp core is-installed {{ allowroot }} --path="{{ site.get('path') }}"
{% endfor %}
