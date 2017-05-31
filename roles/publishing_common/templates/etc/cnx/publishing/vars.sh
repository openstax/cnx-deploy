# this is a shell script which can be sourced into other scripts
# to provide access to configuration values specific to this host

publishing_base_port="{{ publishing_base_port|default(default_publishing_base_port) }}"
publishing_count="{{ publishing_count|default(1) }}"
# NOTE: some of the hosts in this list may point to a different db_host
publishing_hosts_list=( "{{ groups.publishing | join(" ") }}" )

archive_db_name="{{ vault_archive_db_name }}"
archive_db_user="{{ vault_archive_db_user }}"
archive_db_host="{{ archive_db_host }}"
archive_db_port="{{ archive_db_port }}"
