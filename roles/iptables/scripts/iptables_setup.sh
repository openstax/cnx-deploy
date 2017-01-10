#!/bin/bash

# This section sets up the firewall init when the network comes up
if [[ -d /etc/network/if-up.d ]] ; then
    if [[ -e /etc/network/if-up.d/iptables ]] ; then
        backup_file=/etc/network/if-up.d/iptables.bak
        if [[ -e $backup_file ]] ; then
            i=1
            backup_file=/etc/network/if-up.d/iptables.${i}.bak
            while [[ -e $backup_file ]] ; do
                backup_file="/etc/network/if-up.d/iptables.$((++i)).bak"
            done
        fi
        /bin/mv -vf /etc/network/if-up.d/iptables $backup_file
    fi
    cat > /etc/network/if-up.d/iptables <<-EOF
#!/bin/bash
[[ -e /etc/iptables.up.rules ]] && iptables-restore /etc/iptables.up.rules
EOF
    chmod 0755 /etc/network/if-up.d/iptables
fi
