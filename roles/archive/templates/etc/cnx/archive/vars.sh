# this is a shell script which can be sourced into other scripts
# to provide access to configuration values specific to this host

archive_db_name="{{ archive_db_name }}"
archive_db_user="{{ archive_db_user }}"
archive_db_host="{{ archive_db_host }}"
archive_db_port="{{ archive_db_port }}"
archive_base_port="{{ archive_base_port|default(default_archive_base_port) }}"
archive_count="{{ archive_count|default(1) }}"
# NOTE: some of the hosts in this list may point to a different db_host
archive_hosts_list=( "{{ groups.archive | join(" ") }}" )
