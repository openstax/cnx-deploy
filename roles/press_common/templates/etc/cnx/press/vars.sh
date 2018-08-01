# this is a shell script which can be sourced into other scripts
# to provide access to configuration values specific to this application

SHARED_DIR="/var/cnx/apps/var"
DB_URL="postgresql://{{ press_db_user }}:{{ press_db_password }}@{{ press_db_host }}:{{ press_db_port }}/{{ press_db_name }}"
DB_SUPER_URL="postgresql://postgres@{{ press_db_host }}:{{ press_db_port }}/{{ press_db_name }}"
SENTRY_DSN="{{ sentry_dsn|default() }}"
AMQP_URL="amqp://{{ press_broker_user }}:{{ press_broker_password }}@{{ hostvars[groups.broker[0]].ansible_default_ipv4.address }}:{{ broker_port|default(5672) }}/{{ press_broker_vhost|default(default_press_broker_vhost) }}"
