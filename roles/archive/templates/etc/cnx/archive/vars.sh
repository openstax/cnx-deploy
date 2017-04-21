# this is a shell script which can be sourced into other scripts
# to provide access to configuration values specific to this host

archive_db_name="{{ vault_archive_db_name }}"
archive_db_user="{{ vault_archive_db_user }}"
archive_db_host="{{ archive_db_host }}"
archive_db_port="{{ archive_db_port }}"
archive_host="{{ archive_host }}"
archive_base_port="{{ default_archive_base_port }}"
archive_count="{{ archive_count }}"
# NOTE: some of the hosts in this list may point to a different db_host
archive_hosts_list=( "{{ groups.archive | join(" ") }}" )
